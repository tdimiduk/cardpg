{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Frontend.Html
  ( Render (..)
  , RenderHtml
  , resourceSymbol -- Exporting helper if needed, though mostly used via Render
  , renderInlineHtml
  ) where

import Data.Text (Text)
import Reflex.Dom.Core

import Core.Render
  ( ComputeRenderMode
  , IconMode (..)
  , Render (..)
  , RenderMode (..)
  , RenderStrategy (..)
  )

import Core.Render.Rule ()
import Core.Render.Stats ()
import Core.RichText (Block (..), Inline (..), TextStyle (..))
import Core.Stats (Difficulty (..), ResourceType (..), StatValue (..))
import Core.Util (tshow)

import Frontend.Style qualified as Style
import Frontend.Svg (renderCircle, renderDiamond, renderSquare)

-- | Constraint alias for Monads that render to HTML
type RenderHtml m = ComputeRenderMode m ~ 'HtmlMode

-- Base text instance
instance (Monad m, DomBuilder t m) => RenderStrategy 'HtmlMode Text m where
  renderStrategy = text

-- Style helpers
resourceSymbol :: (DomBuilder t m) => IconMode -> ResourceType -> Maybe Text -> m ()
resourceSymbol mode r t = case r of
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

instance (Monad m, DomBuilder t m) => RenderStrategy 'HtmlMode ResourceType m where
  type StrategyConfig 'HtmlMode ResourceType = IconMode
  renderStrategyWith mode r = resourceSymbol mode r Nothing

instance (Monad m, DomBuilder t m) => RenderStrategy 'HtmlMode Inline m where
  renderStrategy = renderInlineHtml

renderInlineHtml :: (DomBuilder t m, Monad m) => Inline -> m ()
renderInlineHtml (TextRun style content) =
  case style of
    Nothing -> renderStrategy @'HtmlMode content
    Just Bold -> el "b" $ renderStrategy @'HtmlMode content
    Just Italic -> el "i" $ renderStrategy @'HtmlMode content
    Just GameKeyword -> el "strong" $ renderStrategy @'HtmlMode content
renderInlineHtml (ColorValue v) = renderStrategy @'HtmlMode v
renderInlineHtml (DifficultyValue d) = renderStrategy @'HtmlMode d
renderInlineHtml Break = el "br" $ pure ()

instance (Monad m, DomBuilder t m) => RenderStrategy 'HtmlMode Block m where
  renderStrategy (Paragraph b) = el "p" $ renderStrategy @'HtmlMode b
  renderStrategy Rule = el "hr" $ pure ()
  renderStrategy (Header t) = el "h3" $ renderStrategyWith @'HtmlMode def t
  renderStrategy (BulletList items) = el "ul" $ mapM_ (el "li" . renderStrategyWith @'HtmlMode def) items

instance (Monad m, DomBuilder t m) => RenderStrategy 'HtmlMode Difficulty m where
  type StrategyConfig 'HtmlMode Difficulty = IconMode
  renderStrategyWith mode d = resourceSymbol mode (d.attribute) $ Just $ tshow (d.value)

instance (Monad m, DomBuilder t m) => RenderStrategy 'HtmlMode StatValue m where
  type StrategyConfig 'HtmlMode StatValue = IconMode
  renderStrategyWith mode s = resourceSymbol mode (s.color) $ Just $ tshow (s.value)
