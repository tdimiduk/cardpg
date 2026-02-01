{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Explicit HTML rendering functions for rules and rich text.
-- | These replace the RenderStrategy 'HtmlMode instances for rule types.
module Frontend.Render.Rules
  ( renderRule
  , renderRichText
  , renderInline
  , renderAttackDef
  , renderGeneralDef
  , renderOngoingDef
  , renderPassiveDef
  , renderTaskDef
  , renderTriggerDef
  , renderStackPower
  , renderDifficulty
  , renderStatValue
  , renderResourceType
  ) where

import Data.Maybe (catMaybes)
import Data.Text (Text)
import Reflex.Dom.Core hiding (Space)

import Core.Language
  ( cmdAction
  , cmdAttack
  , cmdOngoing
  , cmdPassive
  , cmdTask
  , cmdWhen
  , kwCheck
  , kwCost
  , kwStr
  , kwTime
  , sepColon
  , sepSemi
  )

import Core.Layout
  ( LayoutItem (..)
  , layoutAttackDef
  , layoutRule
  )
import Core.NonEmptyText (NonEmptyText, getRawText)
import Core.RichText (Inline (..), RichText (..), TextStyle (..), getInlines)

-- Import types but avoid Render.Rules exporting Rule again if not needed, or just import types
import Core.RuleDefs
  ( AttackDef (..)
  , GeneralDef (..)
  , OngoingDef (..)
  , PassiveDef (..)
  , Rule (..)
  , TaskDef (..)
  , TriggerDef (..)
  )
import Core.RuleDefs hiding (Rule (..))
import Core.Stats (Difficulty (..), ResourceType (..), StackPower (..), StatValue (..))
import Core.Util (tshow)
import Frontend.Render.Common (IconMode (..), renderNonEmptyText, renderResourceType)

import Frontend.Style qualified as Style

--------------------------------------------------------------------------------
-- Core Rendering Primitives
--------------------------------------------------------------------------------

-- | Render a StatValue as an icon with a number
renderStatValue :: (DomBuilder t m) => IconMode -> StatValue -> m ()
renderStatValue mode s = renderResourceType mode s.color $ Just $ tshow s.value

-- | Render a Difficulty as an icon with a number
renderDifficulty :: (DomBuilder t m) => IconMode -> Difficulty -> m ()
renderDifficulty mode d = renderResourceType mode d.attribute $ Just $ tshow d.value

-- | Render a StackPower
renderStackPower :: (DomBuilder t m) => IconMode -> StackPower -> m ()
renderStackPower = undefined -- Replaced by Layout-based rendering, keeping for export compatibility if needed until full cleanup

--------------------------------------------------------------------------------
-- Inline and RichText Rendering
--------------------------------------------------------------------------------

-- | Render a single Inline element
renderInline :: (DomBuilder t m) => Inline -> m ()
renderInline (TextRun style content) =
  case style of
    Nothing -> text (getRawText content)
    Just Bold -> el "b" $ text (getRawText content)
    Just Italic -> el "i" $ text (getRawText content)
    Just GameKeyword -> el "strong" $ text (getRawText content)
renderInline (ColorValue v) = renderStatValue IconInline v
renderInline (DifficultyValue d) = renderDifficulty IconInline d
renderInline Break = el "br" $ pure ()

-- | Render a RichText as a sequence of Inlines
renderRichText :: (DomBuilder t m) => RichText -> m ()
renderRichText rt = mapM_ renderInline (getInlines rt)

--------------------------------------------------------------------------------
-- Layout Rendering
--------------------------------------------------------------------------------

renderLayoutItem :: (DomBuilder t m) => LayoutItem -> m ()
renderLayoutItem (Keyword t) = el "strong" $ text t
renderLayoutItem (Symbol r t) = renderResourceType IconInline r t
renderLayoutItem (Literal t) = text t
renderLayoutItem (RichContent rt) = renderRichText rt
renderLayoutItem (Group items) = do
  text "("
  mapM_ renderLayoutItem items
  text ")"
renderLayoutItem Space = text " "

renderLayout :: (DomBuilder t m) => [LayoutItem] -> m ()
renderLayout = mapM_ renderLayoutItem

--------------------------------------------------------------------------------
-- Rule Definition Rendering
--------------------------------------------------------------------------------

-- | Render an AttackDef using Layout
-- "Attack" keyword is now handled in the layout
renderAttackDef :: (DomBuilder t m) => AttackDef -> m ()
renderAttackDef def = do
  el "strong" $ text cmdAttack
  text " "
  renderLayout (layoutAttackDef def)

-- | Render any Rule variant using Layout
renderRule :: (DomBuilder t m) => Rule -> m ()
renderRule rule = renderLayout (layoutRule rule)

-- | Deprecated specific renderers (redirect to generic rule render if possible, or undefined if unused)
-- We keep the exports but implemented via generic layout if easy, or remove if unused.
-- The previous exports were used in `Frontend.Render.Rules`, so let's check usages.
-- Currently only renderRule and renderAttackDef are used externally commonly.
-- Stubs for compatibility:
renderGeneralDef :: (DomBuilder t m) => GeneralDef -> m ()
renderGeneralDef def = renderRule (RuleGeneral def)

renderOngoingDef :: (DomBuilder t m) => OngoingDef -> m ()
renderOngoingDef def = renderRule (RuleOngoing def)

renderPassiveDef :: (DomBuilder t m) => PassiveDef -> m ()
renderPassiveDef def = renderRule (RulePassive def)

renderTaskDef :: (DomBuilder t m) => TaskDef -> m ()
renderTaskDef def = renderRule (RuleTask def)

renderTriggerDef :: (DomBuilder t m) => TriggerDef -> m ()
renderTriggerDef def = renderRule (RuleTrigger def)
