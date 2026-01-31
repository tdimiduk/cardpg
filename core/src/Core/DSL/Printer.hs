{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Core.DSL.Printer (prettyRule, prettyAttack, richToString, prettyModifier) where

import Control.Monad.Writer (Writer, execWriter, tell)
import Data.Text (Text)
import Data.Text qualified as T

import Core.Render (IconMode (..), Render (..), RenderMode (..), RenderStrategy (..))
import Core.Render.Rule ()
import Core.Render.Stats ()
import Core.Render.Util (renderSpace)
import Core.RichText (RichText)
import Core.RuleDefs (AttackDef, Rule (..))
import Core.Stats (Difficulty (..), ResourceType (..), prettyModifier)
import Core.Util (tshow)

-- PrinterM Monad
type PrinterM = Writer [Text]

instance RenderStrategy 'TextMode ResourceType PrinterM where
  type StrategyConfig 'TextMode ResourceType = IconMode
  renderStrategyWith _ Red = tell ["{Red}"]
  renderStrategyWith _ Yellow = tell ["{Yellow}"]
  renderStrategyWith _ Blue = tell ["{Blue}"]

instance RenderStrategy 'TextMode Difficulty PrinterM where
  type StrategyConfig 'TextMode Difficulty = IconMode
  renderStrategyWith _ (Difficulty attr val) = do
    render attr
    renderSpace
    render (tshow val)
instance RenderStrategy 'TextMode Rule PrinterM where
  renderStrategy (RuleGeneral def) = render def
  renderStrategy (RuleOngoing def) = render def
  renderStrategy (RulePassive def) = render def
  renderStrategy (RuleTask def) = render def
  renderStrategy (RuleTrigger def) = render def
  renderStrategy (RuleNarrative rt) = render rt

prettyRule :: Rule -> Text
prettyRule rule = T.concat $ execWriter (render rule)

prettyAttack :: AttackDef -> Text
prettyAttack def = T.concat $ execWriter (render def)

richToString :: RichText -> Text
richToString rt = T.concat $ execWriter (render rt)
