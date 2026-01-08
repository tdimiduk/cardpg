{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Core.DSL.Printer (prettyRule, richToString, prettyModifier) where

import Control.Monad.Writer (Writer, execWriter, tell)
import Data.Text (Text)
import Data.Text qualified as T

import Core.Language (styleDelimiter)
import Core.NonEmptyText (getRawText)
import Core.Render (IconMode (..), Render (..))
import Core.Render.Rule ()
import Core.Render.Stats ()
import Core.Render.Util (renderSpace)
import Core.RichText
  ( Inline (..)
  , RichText
  , getInlines
  )
import Core.RuleDefs (Rule (..))
import Core.Stats (Difficulty (..), ResourceType (..), StatValue (..), prettyModifier)
import Core.Util (tshow)

-- PrinterM Monad
type PrinterM = Writer [Text]

instance Render Text PrinterM where
  render t = tell [t]

instance Render ResourceType PrinterM where
  type RenderConfig ResourceType = IconMode
  renderWith _ Red = tell ["{Red}"]
  renderWith _ Yellow = tell ["{Yellow}"]
  renderWith _ Blue = tell ["{Blue}"]

instance Render RichText PrinterM where
  render rt = mapM_ render (getInlines rt)

instance Render Inline PrinterM where
  render (TextRun (Just style) content) = tell [wrapped (styleDelimiter style) $ getRawText content]
  render (TextRun Nothing content) = render content
  render (ColorValue power) = tell [prettyStatValue power]
  render (DifficultyValue diff) = tell [prettyDifficulty diff]
  render Break = tell ["\n"]

instance Render Difficulty PrinterM where
  type RenderConfig Difficulty = IconMode
  renderWith _ (Difficulty attr val) = do
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
