{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Core.Rules.Attack
  ( AttackDef (..)
  , attackParser
  , layoutAttackDef
  ) where

import Control.Applicative (optional)
import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), genericParseJSON)
import GHC.Generics (Generic)
import Text.Megaparsec (try)
import Text.Megaparsec.Char (space, space1, string, string')

import Core.DSL (Parser, TextRep (..), parseText)
import Core.Json (cardpgJsonOptions)
import Core.Language (cmdAttack, kwStr, sepArrow, sepColon)
import Core.Layout (LayoutItem (..), renderLayoutText)
import Core.RichText (RichText, richTextParser)
import Core.Rules.Common (layoutStackPower, separatorParser)
import Core.Stats (ResourceType (..), StackPower (..), resourceSymbol, stackPowerParser)

-- | Standard Attack Logic
data AttackDef = AttackDef
  { power :: StackPower
  , resistedBy :: ResourceType
  , effect :: Maybe RichText
  }
  deriving (Show, Eq, Generic)

-- AttackDef instances
instance TextRep AttackDef where
  -- Drop the first two items: "Attack" keyword and space since they are redundant in the YAML context
  toText = renderLayoutText . drop 2 . layoutAttackDef
  textParser = attackParser

instance ToJSON AttackDef where
  toJSON = String . toText

instance FromJSON AttackDef where
  parseJSON (String t) = case parseText t of
    Right r -> pure r
    Left err -> fail $ "Attack DSL parse failed: " ++ err
  parseJSON v = genericParseJSON (cardpgJsonOptions "AttackDef") v

layoutAttackDef :: AttackDef -> [LayoutItem]
layoutAttackDef def =
  [ Keyword cmdAttack
  , Space
  , Symbol def.resistedBy Nothing
  , Literal sepColon
  , Space
  , Keyword kwStr
  , Literal " = "
  ]
    <> layoutStackPower def.power
    <> case def.effect of
      Nothing -> []
      Just e ->
        [ Space
        , Literal sepArrow
        , Space
        , RichContent e
        ]

-- Attack Parser
attackParser :: Parser AttackDef
attackParser = do
  _ <- optional $ try $ do
    _ <- string' cmdAttack
    space1
  resistedBy <- resourceSymbol
  _ <- space
  _ <- optional (string sepColon)
  _ <- space1
  power <- stackPowerParser
  _ <- separatorParser
  extra <- optional richTextParser
  pure $ AttackDef power resistedBy extra
