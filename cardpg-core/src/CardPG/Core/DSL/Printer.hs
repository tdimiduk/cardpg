{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module CardPG.Core.DSL.Printer (prettyRule, richToString, prettyModifier) where

import Control.Monad.Writer (Writer, execWriter, tell)
import Data.Text (Text)
import Data.Text qualified as T

import CardPG.Core.NonEmptyText (NonEmptyText, getRawText)
import CardPG.Core.Render (Render (..))
import CardPG.Core.Render.Rule ()
import CardPG.Core.Render.Stats ()
import CardPG.Core.Render.Util (renderSpace)
import CardPG.Core.RichText
  ( Inline (..)
  , RichText
  , TextStyle (..)
  , getInlines
  )
import CardPG.Core.RuleDefs (Rule (..))
import CardPG.Core.Stats (Difficulty (..), ResourceType (..), StatValue (..), prettyModifier)
import CardPG.Core.Util (tshow)

-- PrinterM Monad
type PrinterM = Writer [Text]

instance Render Text PrinterM where
  render t = tell [t]

instance Render ResourceType PrinterM where
  render Red = tell ["{Red}"]
  render Yellow = tell ["{Yellow}"]
  render Blue = tell ["{Blue}"]

instance Render RichText PrinterM where
  render rt = mapM_ render (getInlines rt)

instance Render Inline PrinterM where
  render (TextRun (Just Bold) content) = tell [wrapped "**" $ getRawText content]
  render (TextRun (Just Italic) content) = tell [wrapped "*" $ getRawText content]
  render (TextRun (Just GameKeyword) content) = tell [wrapped "`" $ getRawText content]
  render (TextRun _ content) = tell [getRawText content]
  render (ColorValue power) = tell [prettyStatValue power]
  render (DifficultyValue diff) = tell [prettyDifficulty diff]
  render Break = tell ["\n"]

instance Render NonEmptyText PrinterM where
  render net = tell [getRawText net]

instance Render Difficulty PrinterM where
  render (Difficulty attr val) = do
    render attr
    renderSpace
    render (tshow val)

instance Render Rule PrinterM where
  render (RuleAttack def) = render def
  render (RuleGeneral def) = render def
  render (RuleOngoing def) = render def
  render (RulePassive def) = render def
  render (RuleTask def) = render def
  render (RuleTrigger def) = render def
  render (RuleNarrative rt) = render rt

prettyRule :: Rule -> Text
prettyRule rule = T.concat $ execWriter (render rule)

richToString :: RichText -> Text
richToString rt = T.concat $ execWriter (render rt)

prettyStatValue :: StatValue -> Text
prettyStatValue s = "{" <> tshow s.color <> ":" <> tshow s.value <> "}"

prettyDifficulty :: Difficulty -> Text
prettyDifficulty (Difficulty attr val) = prettyResource attr <> " " <> tshow val

prettyResource :: ResourceType -> Text
prettyResource Red = "{Red}"
prettyResource Yellow = "{Yellow}"
prettyResource Blue = "{Blue}"

wrapped :: Text -> Text -> Text
wrapped wrapper t = wrapper <> t <> wrapper
