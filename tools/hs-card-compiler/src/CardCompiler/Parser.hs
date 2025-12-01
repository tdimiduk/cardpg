{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TupleSections #-}

module CardCompiler.Parser where

import Control.Applicative ((<|>), optional, many, some)
import Control.Monad (void, mfilter)
import Data.Maybe (fromMaybe, catMaybes)
import Data.Aeson (FromJSON(..), ToJSON(..), withObject, (.:), (.:?), (.!=), Value(..), genericToJSON, defaultOptions, object, (.=))
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
import CardPG.Core.RichText (RichString, mkRichString, Inline(..), TextRunDef(..), IconDef(..), StackPower(..), simpleString)
import CardPG.Core.Types (ResourceType(..))
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.DSL.Printer (prettyRule)
import CardPG.Core.NonEmptyText (unsafeNonEmptyText, mkNonEmptyText)

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



-- | Conversion function
convertCard :: RawCard -> Either String ParsedCard
convertCard RawCard{..} = do
  let mRed = toIntMaybe rcRed
      mYellow = toIntMaybe rcYellow
      mBlue = toIntMaybe rcBlue

  case mkNonEmptyText (T.strip rcName) of
    Nothing -> Left "Skipping empty card row"
    Just name -> do
      case (mRed, mYellow, mBlue) of
        (Nothing, Nothing, Nothing) -> pure $ PItem ItemCard 
          { _id = Nothing
          , _name = name
          , _tags = rcTags >>= NE.nonEmpty
          , _flavor = fmap simpleString rcFlavor
          , _weight = Nothing
          , _value = Nothing
          , _traits = rcKeywordProvide >>= NE.nonEmpty . filter (not . T.null) . map T.strip . T.splitOn ","
          , _passive = nonEmptyText rcAction
          , _defense = Nothing
          , _resilience = Nothing
          }
        (Just r, Just y, Just b) -> do
          let _name = name
              _id = Nothing -- Generated later or from ID field if present
              _tags = rcTags >>= NE.nonEmpty
              _stats = Stats r y b
              _cost = toIntMaybe rcCost
              _flavor = fmap simpleString rcFlavor 
          rules <- parseRules rcAction rcEffect rcDetails
          let _rules = NE.nonEmpty rules
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
          Nothing -> pure Nothing
          Just s -> Just <$> parseAction s
  
  r2 <- case nonEmptyText effectStr of
          Nothing -> pure Nothing
          Just s -> Just <$> parseEffect s

  r3 <- case nonEmptyText detailsStr of
          Nothing -> pure []
          Just s -> (: []) <$> parseDetails s

  case (r1, r2) of
    (Just (RuleAttack def), Just (RuleNarrative rt)) -> 
      pure $ RuleAttack (mergeEffect def rt) : r3
    (Just (RuleDefend def), Just (RuleNarrative rt)) -> 
      pure $ RuleDefend (mergeEffectDef def rt) : r3
    (Just ra, Just re) -> pure $ ra : re : r3
    (Just ra, Nothing) -> pure $ ra : r3
    (Nothing, Just re) -> pure $ re : r3
    (Nothing, Nothing) -> pure r3

mergeEffect :: AttackDef -> RichString -> AttackDef
mergeEffect (AttackDef p r e) rt = AttackDef p r (mergeRichString e rt)

mergeEffectDef :: DefendDef -> RichString -> DefendDef
mergeEffectDef (DefendDef p r e) rt = DefendDef p r (mergeRichString e rt)

mergeRichString :: Maybe RichString -> RichString -> Maybe RichString
mergeRichString Nothing new = Just new
mergeRichString (Just old) new = Just (old <> mkRichString (Break NE.:| []) <> new)

nonEmptyText :: Maybe Text -> Maybe Text
nonEmptyText Nothing = Nothing
nonEmptyText (Just t)
  | T.null (T.strip t) = Nothing
  | otherwise = Just t

parseAction :: Text -> Either String Rule
parseAction t = parseRule t

parseEffect :: Text -> Either String Rule
parseEffect t = parseRule t

parseDetails :: Text -> Either String Rule
parseDetails t = parseRule t
