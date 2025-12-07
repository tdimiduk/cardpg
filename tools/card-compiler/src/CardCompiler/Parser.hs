{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE DuplicateRecordFields #-}

module CardCompiler.Parser where

import Data.Maybe (fromMaybe)
import Data.Aeson (FromJSON(..), ToJSON(..), withObject, (.:), (.:?), Value(..))
import qualified Data.List.NonEmpty as NE
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Read as TR
import GHC.Generics (Generic)

import CardPG.Core.Card (CoreCard, ItemCard, CoreCardT(..), ItemCardT(..), Stats(..))
import CardPG.Core.RuleDefs (DSLBase, RuleT(..), AttackDefT(..), DSLRule(..))
import CardPG.Core.RichText (RichString, mkRichString, Inline(..), simpleString)
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.NonEmptyText (mkNonEmptyText)

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
  , rcId :: Maybe Text
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
    rcId <- v .:? "id"
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
          { _id = rcId
          , _name = name
          , _tags = rcTags >>= NE.nonEmpty
          , _flavor = rcFlavor >>= simpleString
          , _weight = Nothing
          , _value = Nothing
          , _traits = rcKeywordProvide >>= NE.nonEmpty . filter (not . T.null) . map T.strip . T.splitOn ","
          , _passive = nonEmptyText rcAction
          , _defense = Nothing
          , _resilience = Nothing
          }
        (Just r, Just y, Just b) -> do
          let _name = name
              _id = rcId
              _tags = rcTags >>= NE.nonEmpty
              _stats = Stats r y b
              _cost = toIntMaybe rcCost
              _flavor = rcFlavor >>= simpleString 
          rules <- parseRules rcAction rcEffect rcDetails
          let _rules = NE.nonEmpty (map DSLRule rules)
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

parseRules :: Maybe Text -> Maybe Text -> Maybe Text -> Either String [DSLBase]
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
    (Just ra, Just re) -> pure $ ra : re : r3
    (Just ra, Nothing) -> pure $ ra : r3
    (Nothing, Just re) -> pure $ re : r3
    (Nothing, Nothing) -> pure r3

mergeEffect :: AttackDefT RichString -> RichString -> AttackDefT RichString
mergeEffect (AttackDef p r e) rt = AttackDef p r (mergeRichString e rt)

mergeRichString Nothing new = Just new
mergeRichString (Just old) new = 
  case mkRichString [Break] of
    Just br -> Just (old <> br <> new)
    Nothing -> Just (old <> new) -- Should not happen for [Break] but safe fallback

nonEmptyText :: Maybe Text -> Maybe Text
nonEmptyText Nothing = Nothing
nonEmptyText (Just t)
  | T.null (T.strip t) = Nothing
  | otherwise = Just t

parseAction :: Text -> Either String DSLBase
parseAction t = parseRule t

parseEffect :: Text -> Either String DSLBase
parseEffect t = parseRule t

parseDetails :: Text -> Either String DSLBase
parseDetails t = parseRule t
