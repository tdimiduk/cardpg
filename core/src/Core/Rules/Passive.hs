{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Core.Rules.Passive
  ( PassiveDef (..)
  , passiveParser
  , layoutPassiveDef
  ) where

import Data.Aeson.TH (deriveJSON)
import GHC.Generics (Generic)
import Text.Megaparsec (takeWhileP)
import Text.Megaparsec.Char (space, string')

import Core.DSL (Parser)
import Core.Json (cardpgJsonDef)
import Core.Language (cmdPassive)
import Core.Layout (LayoutItem (..))
import Core.NonEmptyText (NonEmptyText, getRawText, mkNonEmptyText)
import Core.Rules.Common (layoutStackPower)
import Core.Stats (StackPower, stackPowerParser)

-- | A static modifier.
-- | Addresses: "+2 to resource values when used in a defense stack"
data PassiveDef = PassiveDef
  { bonus :: StackPower
  , condition :: Maybe NonEmptyText
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''PassiveDef)

layoutPassiveDef :: PassiveDef -> [LayoutItem]
layoutPassiveDef def =
  [ Keyword cmdPassive
  , Space
  ]
    <> layoutStackPower def.bonus
    <> maybe [] (\c -> [Space, Literal (getRawText c)]) def.condition

-- Passive
passiveParser :: Parser PassiveDef
passiveParser = do
  _ <- string' cmdPassive
  _ <- space
  bonus <- stackPowerParser
  condStr <- takeWhileP Nothing (const True)
  let condition = mkNonEmptyText condStr
  pure $ PassiveDef bonus condition
