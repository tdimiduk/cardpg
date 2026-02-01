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
import Reflex.Dom.Core

import Core.Language
  ( cmdAction
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

import Core.NonEmptyText (NonEmptyText, getRawText)
import Core.RichText (Inline (..), RichText (..), TextStyle (..), getInlines)
import Core.RuleDefs
  ( AttackDef (..)
  , GeneralDef (..)
  , OngoingDef (..)
  , PassiveDef (..)
  , Rule (..)
  , TaskDef (..)
  , TriggerDef (..)
  )
import Core.Stats
  ( Difficulty (..)
  , ResourceType (..)
  , StackPower (..)
  , StatValue (..)
  , prettyModifier
  )
import Core.Util (tshow)
import Frontend.Render.Common (IconMode (..))

import Frontend.Style qualified as Style
import Frontend.Svg (renderCircle, renderDiamond, renderSquare)

--------------------------------------------------------------------------------
-- Core Rendering Primitives
--------------------------------------------------------------------------------

-- | Render a ResourceType as an SVG icon
renderResourceType :: (DomBuilder t m) => IconMode -> ResourceType -> Maybe Text -> m ()
renderResourceType mode r t = case r of
  Red -> renderSquare (color <> style) t
  Yellow -> renderCircle (color <> style) t
  Blue -> renderDiamond (color <> style) t
  where
    color = case r of
      Red -> [Style.textRed500]
      Yellow -> [Style.textYellow400]
      Blue -> [Style.textBlue500]
    style = case mode of
      IconInline -> Style.iconInline
      IconBlock -> Style.iconBlock
      IconResponsive -> Style.iconResponsive

-- | Render a StatValue as an icon with a number
renderStatValue :: (DomBuilder t m) => IconMode -> StatValue -> m ()
renderStatValue mode s = renderResourceType mode s.color $ Just $ tshow s.value

-- | Render a Difficulty as an icon with a number
renderDifficulty :: (DomBuilder t m) => IconMode -> Difficulty -> m ()
renderDifficulty mode d = renderResourceType mode d.attribute $ Just $ tshow d.value

-- | Render a StackPower
renderStackPower :: (DomBuilder t m) => IconMode -> StackPower -> m ()
renderStackPower mode (StackPower base 0 Nothing) = renderResourceType mode base Nothing
renderStackPower mode (StackPower base modifier conditional) = do
  renderResourceType mode base Nothing
  text " "
  text (prettyModifier modifier)
  case conditional of
    Nothing -> pure ()
    Just a -> do
      text " "
      text a

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
-- Rule Definition Rendering
--------------------------------------------------------------------------------

-- | Render a NonEmptyText as plain text
renderNonEmptyText :: (DomBuilder t m) => NonEmptyText -> m ()
renderNonEmptyText = text . getRawText

-- | Render an arrow (→)
renderArrow :: (DomBuilder t m) => m ()
renderArrow = text " → "

-- | Render content in parentheses
renderParens :: (DomBuilder t m) => m () -> m ()
renderParens inner = do
  text "("
  inner
  text ")"

-- | Render an AttackDef
renderAttackDef :: (DomBuilder t m) => AttackDef -> m ()
renderAttackDef def = do
  renderResourceType IconInline def.resistedBy Nothing
  text sepColon
  text " "
  text kwStr
  text " = "
  renderStackPower IconInline def.power
  case def.effect of
    Nothing -> pure ()
    Just e -> do
      renderArrow
      renderRichText e

-- | Render a GeneralDef (Action)
renderGeneralDef :: (DomBuilder t m) => GeneralDef -> m ()
renderGeneralDef def = do
  text cmdAction
  text " "
  renderNonEmptyText def.name
  case def.cost of
    Nothing -> pure ()
    Just c -> do
      text " "
      renderParens (renderRichText c)
  case def.difficulty of
    Nothing -> pure ()
    Just d -> do
      text " "
      renderDifficulty IconInline d
  renderArrow
  renderRichText def.effect

-- | Render an OngoingDef
renderOngoingDef :: (DomBuilder t m) => OngoingDef -> m ()
renderOngoingDef def = do
  text cmdOngoing
  text " "
  renderParens (renderRichText def.life)
  renderArrow
  renderRichText def.effect

-- | Render a PassiveDef
renderPassiveDef :: (DomBuilder t m) => PassiveDef -> m ()
renderPassiveDef def = do
  text cmdPassive
  text " "
  renderStackPower IconInline def.bonus
  case def.condition of
    Nothing -> pure ()
    Just c -> do
      text " "
      renderNonEmptyText c

-- | Render a TaskDef
renderTaskDef :: (DomBuilder t m) => TaskDef -> m ()
renderTaskDef def = do
  text cmdTask
  text " "
  renderNonEmptyText def.name
  let parts =
        catMaybes
          [ fmap (\c -> (kwCheck, renderDifficulty IconInline c)) def.check
          , fmap (\t -> (kwTime, renderRichText t)) def.time
          , fmap (\c -> (kwCost, renderRichText c)) def.cost
          ]

  if null parts
    then pure ()
    else do
      text " "
      renderParens $ renderParts parts

  renderArrow
  renderRichText def.effect
  where
    renderParts :: (DomBuilder t m) => [(Text, m ())] -> m ()
    renderParts [] = pure ()
    renderParts [(label, val)] = do
      text label
      text " "
      val
    renderParts ((label, val) : rest) = do
      text label
      text " "
      val
      text sepSemi
      text " "
      renderParts rest

-- | Render a TriggerDef
renderTriggerDef :: (DomBuilder t m) => TriggerDef -> m ()
renderTriggerDef def = do
  text cmdWhen
  text " "
  renderNonEmptyText def.trigger
  renderArrow
  renderRichText def.effect

-- | Render any Rule variant
renderRule :: (DomBuilder t m) => Rule -> m ()
renderRule (RuleGeneral def) = renderGeneralDef def
renderRule (RuleOngoing def) = renderOngoingDef def
renderRule (RulePassive def) = renderPassiveDef def
renderRule (RuleTask def) = renderTaskDef def
renderRule (RuleTrigger def) = renderTriggerDef def
renderRule (RuleNarrative rt) = renderRichText rt
