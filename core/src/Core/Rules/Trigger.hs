{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Core.Rules.Trigger
  ( TriggerDef (..)
  , triggerParser
  , layoutTriggerDef
  ) where

import Data.Aeson.TH (deriveJSON)
import GHC.Generics (Generic)
import Text.Megaparsec.Char (space, space1, string')

import Core.DSL (Parser, hspace)
import Core.Json (cardpgJsonDef)
import Core.Language (cmdWhen, sepArrow)
import Core.Layout (LayoutItem (..))
import Core.NonEmptyText (NonEmptyText, getRawText, takeWhilePNonEmptyStripped)
import Core.RichText (RichText, richTextParser)
import Core.Rules.Common (effectArrow)

-- | Triggered Effects (When)
-- | Addresses: "When removed -> Add 1 Wound"
data TriggerDef = TriggerDef
  { trigger :: NonEmptyText
  , effect :: RichText
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''TriggerDef)

layoutTriggerDef :: TriggerDef -> [LayoutItem]
layoutTriggerDef def =
  [ Keyword cmdWhen
  , Space
  , Literal (getRawText def.trigger)
  , Space
  , Literal sepArrow
  , Space
  , RichContent def.effect
  ]

-- Trigger (When)
-- When [Trigger] -> [Effect]
triggerParser :: Parser TriggerDef
triggerParser = do
  _ <- string' cmdWhen
  _ <- space1
  trigger <-
    takeWhilePNonEmptyStripped (Just "Trigger condition") (\c -> c /= '-' && c /= '>' && c /= '→')
  _ <- space
  _ <- effectArrow
  _ <- hspace
  TriggerDef trigger <$> richTextParser
