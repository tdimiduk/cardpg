{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module CardCompiler.Parser where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), withObject, (.:), (.:?))
import qualified Data.List.NonEmpty as NE
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Read as TR
import GHC.Generics (Generic)

import CardPG.Core.Card
  ( CoreCard
  , CoreCardT (..)
  , ItemCard
  , ItemCardT (..)
  , NatureCard
  , NatureCardT (..)
  , SpecialDefend (..)
  , Stats (..)
  )
import CardPG.Core.DSL.Parser (parseRule)
import CardPG.Core.NonEmptyText (getNonEmptyText, mkNonEmptyText)
import CardPG.Core.RichText (Inline (..), RichString, mkRichString, simpleString)
import CardPG.Core.RuleDefs (AttackDefT (..), DSLBase, DSLRule (..), RuleT (..))
import CardPG.Core.Types (ResourceType (..))

-- | Sum type for different card types
data ParsedCard
  = PCore CoreCard
  | PItem ItemCard
  | PNature NatureCard
  deriving (Show, Generic)

instance ToJSON ParsedCard where
  toJSON (PCore c) = toJSON c
  toJSON (PItem i) = toJSON i
  toJSON (PNature n) = toJSON n

compareParsedCard :: ParsedCard -> ParsedCard -> Ordering
compareParsedCard (PItem _) (PCore _) = LT
compareParsedCard (PCore _) (PItem _) = GT
compareParsedCard (PNature _) (PCore _) = LT
compareParsedCard (PCore _) (PNature _) = GT
compareParsedCard (PItem _) (PNature _) = LT
compareParsedCard (PNature _) (PItem _) = GT
compareParsedCard _ _ = EQ

-- | Raw JSON Card structure
data RawCard = RawCard
  { _name :: Text
  , rcActor :: Maybe Text
  , rcRed :: Maybe Value
  , rcYellow :: Maybe Value
  , rcBlue :: Maybe Value
  , rcCost :: Maybe Value
  , _passive :: Maybe Text -- was rcAction, used as passive for Item/Nature
  , rcAction :: Maybe Text -- raw action string, kept for CoreCard parsing
  , rcEffect :: Maybe Text
  , rcDetails :: Maybe Text
  , _flavor :: Maybe RichString
  , _tags :: Maybe (NE.NonEmpty Text)
  , _traits :: Maybe (NE.NonEmpty Text)
  , _id :: Maybe Text
  , _weight :: Maybe Int
  , _value :: Maybe Int
  , _defense :: Maybe Int
  , _resilience :: Maybe Int
  }
  deriving (Show, Generic)

instance FromJSON RawCard where
  parseJSON = withObject "RawCard" $ \v -> do
    _name <- v .: "name"
    rcActor <- v .:? "actor"
    rcRed <- v .:? "red"
    rcYellow <- v .:? "yellow"
    rcBlue <- v .:? "blue"
    rcCost <- v .:? "cost"

    rawAction <- v .:? "action"
    let _passive = nonEmptyText rawAction
        rcAction = rawAction

    rcEffect <- v .:? "effect"
    rcDetails <- v .:? "details"

    rawFlavor <- v .:? "flavor"
    let _flavor = rawFlavor >>= simpleString

    rawTags <- v .:? "tags"
    let _tags = rawTags >>= NE.nonEmpty

    rawProvide <- v .:? "keywordProvide"
    let _traits = rawProvide >>= NE.nonEmpty . filter (not . T.null) . map T.strip . T.splitOn ","

    _id <- v .:? "id"

    -- Placeholder defaults for now as they aren't in JSON yet or handled by other logic
    let _weight = Nothing
        _value = Nothing
        _defense = Nothing
        _resilience = Nothing

    pure RawCard{..}

-- | Conversion function
convertCard :: RawCard -> Either String ParsedCard
convertCard RawCard{..} = do
  case mkNonEmptyText (T.strip _name) of
    Nothing -> Left "Skipping empty card row"
    Just name -> do
      let _name = name

      case (toIntMaybe rcRed, toIntMaybe rcYellow, toIntMaybe rcBlue) of
        (Nothing, Nothing, Nothing) ->
          if Just (T.toLower (getNonEmptyText name)) == (T.toLower <$> rcActor)
            then
              pure $
                PNature
                  NatureCard
                    { _specialDefend = parseSpecialDefend rcRed rcYellow rcBlue
                    , ..
                    }
            else pure $ PItem ItemCard{..}
        (Just r, Just y, Just b) -> do
          let _stats = Stats r y b
              _cost = toIntMaybe rcCost
          rules <- parseRules rcAction rcEffect rcDetails
          let _rules = NE.nonEmpty (map DSLRule rules)
          pure $ PCore CoreCard{..}
        _ ->
          Left
            "Data Error: Partial stats found. Either all stats (red, yellow, blue) must be present, or none."

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

mergeRichString :: Maybe RichString -> RichString -> Maybe RichString
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
parseAction = parseRule

parseEffect :: Text -> Either String DSLBase
parseEffect = parseRule

parseDetails :: Text -> Either String DSLBase
parseDetails = parseRule

parseSpecialDefend :: Maybe Value -> Maybe Value -> Maybe Value -> Maybe SpecialDefend
parseSpecialDefend r y b =
  let redDef = parseDefenseColor r Red
      yellowDef = parseDefenseColor y Yellow
      blueDef = parseDefenseColor b Blue
   in if redDef == Red && yellowDef == Yellow && blueDef == Blue
        then Nothing
        else Just $ SpecialDefend redDef yellowDef blueDef

parseDefenseColor :: Maybe Value -> ResourceType -> ResourceType
parseDefenseColor (Just (String s)) _
  | s == "x" = Red
  | s == "y" = Yellow
  | s == "z" = Blue
  | s == "b" = Blue
parseDefenseColor _ def = def
