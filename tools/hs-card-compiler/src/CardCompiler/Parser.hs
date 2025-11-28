{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TupleSections #-}

module CardCompiler.Parser where

import Control.Applicative ((<|>), optional, many, some)
import Control.Monad (void, mfilter)
import Data.Maybe (fromMaybe)
import Data.Aeson (FromJSON(..), ToJSON(..), withObject, (.:), (.:?), Value(..), genericToJSON, defaultOptions)
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

import CardPG.Core.Card (CoreCard(..), ItemCard(..), Rule(..), Stats(..), AttackDef(..), DefendDef(..), GeneralDef(..))
import CardPG.Core.RichText (RichString, Inline(..), TextRunDef(..), IconDef(..), StackPower(..), simpleString)
import CardPG.Core.Types (ResourceType(..))
-- We need to map the parsed structures to CardPG.Core.Card types
-- The existing CardParser.hs produced Common.Card types which are slightly different.
-- We will adapt the parsers to produce CardPG.Core.Card types directly.

-- | Sum type for different card types
data ParsedCard
  = PCore CoreCard
  | PItem ItemCard
  deriving (Show, Generic)

instance ToJSON ParsedCard where
  toJSON (PCore c) = toJSON c
  toJSON (PItem i) = toJSON i

type MParser = Parsec Void Text

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
  r1 <- case nonEmpty actionStr of
          Nothing -> pure []
          Just s -> (: []) <$> parseAction s
  r2 <- case nonEmpty effectStr of
          Nothing -> pure []
          Just s -> (: []) <$> parseEffect s
  r3 <- case nonEmpty detailsStr of
          Nothing -> pure []
          Just s -> (: []) <$> parseDetails s
  pure (r1 ++ r2 ++ r3)

nonEmpty :: Maybe Text -> Maybe Text
nonEmpty Nothing = Nothing
nonEmpty (Just t)
  | T.null (T.strip t) = Nothing
  | otherwise = Just t

-- | Parsers adapted from CardParser.hs

parseAction :: Text -> Either String Rule
parseAction t = case parse actionParser "" t of
  Left err -> Left $ errorBundlePretty err
  Right r -> Right r

parseEffect :: Text -> Either String Rule
parseEffect t = Right $ RuleNarrative $ simpleString t

parseDetails :: Text -> Either String Rule
parseDetails t = Right $ RuleNarrative $ simpleString t

actionParser :: MParser Rule
actionParser = try (attackParser <* eof) <|> try (defendParser <* eof) <|> (generalParser <* eof)

orSep :: MParser ()
orSep = void $ choice
  [ try (space1 >> string' "or" >> space1)
  , try (space >> char ',' >> space)
  ]

-- Attack
attackParser :: MParser Rule
attackParser = do
  _ <- string' "attack"
  _ <- space1
  resistedBy <- resourceSymbol
  _ <- optional (char ':')
  _ <- space1
  power <- stackPowerParser
  extra <- takeWhileP Nothing (const True)
  let extraOpt = if T.null (T.strip extra) then Nothing else Just extra
  pure $ RuleAttack $ AttackDef power resistedBy (fmap simpleString extraOpt)

-- Defend
defendParser :: MParser Rule
defendParser = do
  _ <- string' "defend"
  _ <- space1
  resists <- sepBy1 resourceSymbol orSep
  _ <- optional (char ':')
  power <- optional (space1 >> stackPowerParser)
  extra <- takeWhileP Nothing (const True)
  let extraOpt = if T.null (T.strip extra) then Nothing else Just extra
  let p = maybe (StackPower Red 0) id power 
  pure $ RuleDefend $ DefendDef p (NE.fromList resists) (fmap simpleString extraOpt)

-- General
generalParser :: MParser Rule
generalParser = do
  text <- takeWhile1P Nothing (const True)
  pure $ RuleNarrative $ simpleString text

-- Helpers
resourceSymbol :: MParser ResourceType
resourceSymbol = do
  _ <- char '|'
  r <- (Red <$ char 'x') <|> (Yellow <$ char 'y') <|> (Blue <$ char 'z')
  _ <- char '|'
  pure r

stackPowerParser :: MParser StackPower
stackPowerParser = do
  _ <- optional $ try $ do
    _ <- string' "strength"
    _ <- space
    _ <- optional (char '=')
    space
  base <- resourceSymbol
  _ <- space
  modVal <- optional $ do
    sign <- (id <$ char '+') <|> (negate <$ char '-')
    _ <- space
    n <- L.decimal
    pure (sign n)
  pure $ StackPower base (maybe 0 id modVal)
