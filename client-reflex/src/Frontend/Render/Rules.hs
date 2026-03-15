{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Explicit HTML rendering functions for rules and rich text.
-- | These replace the RenderStrategy 'HtmlMode instances for rule types.
module Frontend.Render.Rules
  ( renderRule
  , renderRichText
  , renderInline
  , renderAttackDef
  , renderDifficulty
  , renderStatValue
  , renderResourceType
  , renderBlock
  ) where

import Reflex.Dom.Core hiding (Space)

import Core.Language (TextStyle (..))
import Core.Layout hiding (renderLayoutItem)
import Core.NonEmptyText (getRawText)
import Core.RichText (Block (..), Inline (..), RichText (..), getInlines)
import Core.Rules (AttackDef (..), Rule (..), layoutAttackDef, layoutRule)
import Core.Stats (Difficulty (..), StatValue (..))
import Core.Util (tshow)

import Frontend.Render.Common (IconMode (..), renderResourceType)

--------------------------------------------------------------------------------
-- Core Rendering Primitives
--------------------------------------------------------------------------------

-- | Render a StatValue as an icon with a number
renderStatValue :: (DomBuilder t m) => IconMode -> StatValue -> m ()
renderStatValue mode s = renderResourceType mode s.color $ Just $ tshow s.value

-- | Render a Difficulty as an icon with a number
renderDifficulty :: (DomBuilder t m) => IconMode -> Difficulty -> m ()
renderDifficulty mode d = renderResourceType mode d.attribute $ Just $ tshow d.value

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
renderAttackDef = renderLayout . layoutAttackDef

-- | Render any Rule variant using Layout
renderRule :: (DomBuilder t m) => Rule -> m ()
renderRule rule = renderLayout (layoutRule rule)

--------------------------------------------------------------------------------
-- Block Rendering
--------------------------------------------------------------------------------

-- | Render a Block element
renderBlock :: (DomBuilder t m) => Block -> m ()
renderBlock (Paragraph rt) = el "p" $ renderRichText rt
renderBlock Rule = el "hr" $ pure ()
renderBlock (Header rt) = el "h3" $ renderRichText rt
renderBlock (BulletList items) = el "ul" $ mapM_ (el "li" . renderRichText) items
