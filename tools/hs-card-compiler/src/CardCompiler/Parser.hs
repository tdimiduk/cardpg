{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TupleSections #-}

module CardCompiler.Parser where

import Control.Applicative ((<|>), optional, many, some)
import Control.Monad (void, mfilter)
import Data.Maybe (fromMaybe)
import Data.Aeson (FromJSON(..), ToJSON(..), withObject, (.:), (.:?), Value(..), genericToJSON, defaultOptions, object, (.=))
import Data.Aeson.Types (Parser)
import Data.List.NonEmpty (NonEmpty(..))
import qualified Data.List.NonEmpty as NE
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Read as TR
import Data.Void (Void)
import GHC.Generics (Generic)
import Text.Megaparsec (Parsec, parse, errorBundlePretty, try, takeWhile1P, takeWhileP, label, sepBy1, between, eof, choice)
import Text.Megaparsec.Char (char, string, string', space1, space)
import qualified Text.Megaparsec.Char.Lexer as L

import CardPG.Core.Card (CoreCard(..), ItemCard(..), Rule(..), Stats(..), AttackDef(..), DefendDef(..), GeneralDef(..), Actor(..))
import CardPG.Core.RichText (RichString, Inline(..), TextRunDef(..), IconDef(..), StackPower(..), simpleString)
import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)

-- | Sum type for different card types
data ParsedCard
  = PCore CoreCard
  | PItem ItemCard
  deriving (Show, Generic)

instance ToJSON ParsedCard where
  toJSON (PCore c) = toJSON c
  toJSON (PItem i) = toJSON i

compareParsedCard :: ParsedCard -> ParsedCard -> Ordering
compareParsedCard (PItem _) (PCore _) = LT
compareParsedCard (PCore _) (PItem _) = GT
compareParsedCard _ _ = EQ

-- | Raw JSON Card structure
data RawCard = RawCard
  { rcName :: Text
  , rcActor :: Maybe Text
  , rcRed :: Maybe Value
  , rcYellow :: Maybe Value
  , rcBlue :: Maybe Value
  , rcCost :: Maybe Value
  , rcAction :: Maybe Text
  , rcEffect :: Maybe Text
  , rcDetails :: Maybe Text
  , rcFlavor :: Maybe Text
  , rcTags :: Maybe [Text]
  , rcKeywordProvide :: Maybe Text
  } deriving (Show, Generic)

instance FromJSON RawCard where
  parseJSON = withObject "RawCard" $ \v -> do
    rcName <- v .: "name"
    rcActor <- v .:? "actor"
    rcRed <- v .:? "red"
    rcYellow <- v .:? "yellow"
    rcBlue <- v .:? "blue"
    rcCost <- v .:? "cost"
    rcAction <- v .:? "action"
    rcEffect <- v .:? "effect"
    rcDetails <- v .:? "details"
    rcFlavor <- v .:? "flavor"
    rcTags <- v .:? "tags"
    rcKeywordProvide <- v .:? "keywordProvide"
    pure RawCard{..}

-- | Export Types for DSL Output

data ExportActor = ExportActor
  { _exportItems :: [ItemCard]
  , _exportDeck :: [ExportCoreCard]
  } deriving (Show, Generic)

instance ToJSON ExportActor where
  toJSON ExportActor{..} = object
    [ "items" .= _exportItems
    , "deck" .= _exportDeck
    ]

data ExportCoreCard = ExportCoreCard
  { _ecName :: Text
  , _ecId :: Maybe Text
  , _ecTags :: [Text]
  , _ecStats :: Stats
  , _ecCost :: Maybe Int
  , _ecRules :: [Text]
  , _ecFlavor :: Maybe RichString
  } deriving (Show, Generic)

instance ToJSON ExportCoreCard where
  toJSON ExportCoreCard{..} = object
    [ "name" .= _ecName
    , "id" .= _ecId
    , "tags" .= _ecTags
    , "stats" .= _ecStats
    , "cost" .= _ecCost
    , "rules" .= _ecRules
    , "flavor" .= _ecFlavor
    ]

-- | Convert Actor to ExportActor with validation
toExportActor :: Actor -> Either String ExportActor
toExportActor Actor{..} = do
  exportDeck <- mapM toExportCoreCard _deck
  pure $ ExportActor _items exportDeck

toExportCoreCard :: CoreCard -> Either String ExportCoreCard
toExportCoreCard CoreCard{..} = do
  rules <- mapM convertRule _rules
  pure $ ExportCoreCard _name _id _tags _stats _cost rules _flavor

convertRule :: Rule -> Either String Text
convertRule r = do
  let printed = prettyRule r
  case parseRule printed of
    Left err -> Left $ "Round-trip verification failed for rule: " ++ show r ++ "\nError: " ++ err
    Right parsed -> 
      -- We compare the parsed rule with the original rule.
      -- Note: The parser might not support all features yet (e.g. rich text styles if not implemented fully),
      -- but we expect exact match for now as we just verified it in core tests.
      if parsed == r
        then Right printed
        else Left $ "Round-trip mismatch for rule: " ++ show r ++ "\nParsed: " ++ show parsed ++ "\nPrinted: " ++ show printed

-- | Conversion function
convertCard :: RawCard -> Either String ParsedCard
convertCard RawCard{..} = do
  let mRed = toIntMaybe rcRed
      mYellow = toIntMaybe rcYellow
      mBlue = toIntMaybe rcBlue

  case (mRed, mYellow, mBlue) of
    (Nothing, Nothing, Nothing) -> do
       let _id = Nothing
           _name = rcName
           _tags = maybe [] id rcTags
           _flavor = fmap simpleString rcFlavor
           _weight = Nothing
           _value = Nothing
           _traits = maybe [] (map T.strip . T.splitOn ",") rcKeywordProvide
           _passive = rcAction
           _defense = Nothing
           _resilience = Nothing
       pure $ PItem ItemCard{..}

    (Just r, Just y, Just b) -> do
      let _name = rcName
          _id = Nothing -- Generated later or from ID field if present
          _tags = maybe [] id rcTags
          _stats = Stats r y b
          _cost = toIntMaybe rcCost
          _flavor = fmap simpleString rcFlavor 

      rules <- parseRules rcAction rcEffect rcDetails
      let _rules = rules
      
      pure $ PCore CoreCard{..}

    _ -> Left "Data Error: Partial stats found. Either all stats (red, yellow, blue) must be present, or none."

toIntMaybe :: Maybe Value -> Maybe Int
toIntMaybe (Just (Number n)) = Just (floor n)
toIntMaybe (Just (String s)) = case TR.signed TR.decimal s of
  Right (n, "") -> Just n
  _ -> Nothing
toIntMaybe _ = Nothing

toInt :: Maybe Value -> Int
toInt = fromMaybe 0 . toIntMaybe

parseRules :: Maybe Text -> Maybe Text -> Maybe Text -> Either String [Rule]
parseRules actionStr effectStr detailsStr = do
  r1 <- case nonEmptyText actionStr of
          Nothing -> pure []
          Just s -> (: []) <$> parseAction s
  r2 <- case nonEmptyText effectStr of
          Nothing -> pure []
          Just s -> (: []) <$> parseEffect s
  r3 <- case nonEmptyText detailsStr of
          Nothing -> pure []
          Just s -> (: []) <$> parseDetails s
  pure (r1 ++ r2 ++ r3)

nonEmptyText :: Maybe Text -> Maybe Text
nonEmptyText Nothing = Nothing
nonEmptyText (Just t)
  | T.null (T.strip t) = Nothing
  | otherwise = Just t

parseAction :: Text -> Either String Rule
parseAction t = parseRule t

parseEffect :: Text -> Either String Rule
parseEffect t = Right $ RuleNarrative $ simpleString t

parseDetails :: Text -> Either String Rule
parseDetails t = Right $ RuleNarrative $ simpleString t
