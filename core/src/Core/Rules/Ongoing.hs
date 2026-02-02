{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Core.Rules.Ongoing
  ( OngoingDef (..)
  , ongoingParser
  , layoutOngoingDef
  ) where

import Data.Aeson.TH (deriveJSON)
import GHC.Generics (Generic)
import Text.Megaparsec.Char (space, string')

import Core.DSL (Parser)
import Core.Json (cardpgJsonDef)
import Core.Language (cmdOngoing, sepArrow)
import Core.Layout (LayoutItem (..), layoutWrapper)
import Core.RichText (RichText, richTextParser, richTextParserWith)
import Core.Rules.Common (betweenParens, separatorParser)

-- | Persistent Effects: Ongoing (Stance, Channel, Prime)
-- | Addresses: "Stance (1 min): +1 Strength", "Until triggered: ..."
data OngoingDef = OngoingDef
  { life :: RichText
  -- ^ Duration or Condition: "1 min", "Until triggered", "While holding a shield"
  , effect :: RichText
  -- ^ The mechanical or narrative effect
  }
  deriving (Show, Eq, Generic)

$(deriveJSON cardpgJsonDef ''OngoingDef)

layoutOngoingDef :: OngoingDef -> [LayoutItem]
layoutOngoingDef def =
  [ Keyword cmdOngoing
  , Space
  , Group (layoutWrapper [RichContent def.life])
  , Literal sepArrow
  , Space
  , RichContent def.effect
  ]

-- Ongoing (Life) -> Effect
ongoingParser :: Parser OngoingDef
ongoingParser = do
  _ <- string' cmdOngoing
  _ <- space
  life <- betweenParens (richTextParserWith [')'])
  _ <- separatorParser
  OngoingDef life <$> richTextParser
