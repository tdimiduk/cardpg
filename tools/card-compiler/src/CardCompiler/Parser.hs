{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}

module CardCompiler.Parser where

import Data.Aeson (ToJSON (..), Value (..))
import Data.Aeson.TH (defaultOptions, deriveJSON)
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
  { name :: Text
  , actor :: Maybe Text
  , red :: Maybe Value
  , yellow :: Maybe Value
  , blue :: Maybe Value
  , cost :: Maybe Value
  , keywordProvide :: Maybe Text
  , action :: Maybe Text
  , effect :: Maybe Text
  , details :: Maybe Text
  , flavor :: Maybe Text
  }
  deriving (Show, Generic)

$(deriveJSON defaultOptions ''RawCard)

-- | Conversion function
convertCard :: RawCard -> Either String ParsedCard
convertCard RawCard{..} = do
  case mkNonEmptyText (T.strip name) of
    Nothing -> Left "Skipping empty card row"
    Just validName -> do
      let _name = validName
          _tags = Nothing
          _traits = keywordProvide >>= NE.nonEmpty . filter (not . T.null) . map T.strip . T.splitOn ","
          _flavor = flavor >>= simpleString
          _id = Nothing
          _weight = Nothing
          _value = Nothing
          _defense = Nothing
          _resilience = Nothing
          _passive = nonEmptyText action

      case (toIntMaybe red, toIntMaybe yellow, toIntMaybe blue) of
        (Nothing, Nothing, Nothing) ->
          if Just (T.toLower (getNonEmptyText validName)) == (T.toLower <$> actor)
            then
              pure $
                PNature
                  NatureCard
                    { _specialDefend = parseSpecialDefend red yellow blue
                    , ..
                    }
            else pure $ PItem ItemCard{..}
        (Just r, Just y, Just b) -> do
          let _stats = Stats r y b
              _cost = toIntMaybe cost
          rules <- parseRules action effect details
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
