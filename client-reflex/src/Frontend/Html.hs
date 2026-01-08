{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Frontend.Html
  ( Render (..)
  , resourceSymbol -- Exporting helper if needed, though mostly used via Render
  ) where

import Data.Text (Text)
import Reflex.Dom.Core

import Core.Render (IconMode (..), Render (..))
import Core.Render.Rule ()
import Core.Render.Stats ()
import Core.RichText (Block (..), Inline (..), RichText (..), TextStyle (..), getInlines)
import Core.Stats (Difficulty (..), ResourceType (..), StatValue (..))
import Core.Util (tshow)

import Frontend.Style qualified as Style
import Frontend.Svg (renderCircle, renderDiamond, renderSquare)

-- Base text instance
instance {-# OVERLAPPING #-} (Monad m, DomBuilder t m) => Render Text m where
  render = text

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

instance (Monad m, DomBuilder t m) => Render ResourceType m where
  type RenderConfig ResourceType = IconMode
  renderWith mode r = resourceSymbol mode r Nothing

instance (Monad m, DomBuilder t m) => Render RichText m where
  render rt = mapM_ render (getInlines rt)

instance (Monad m, DomBuilder t m) => Render Inline m where
  render (TextRun style content) =
    case style of
      Nothing -> render content
      Just Bold -> el "b" $ render content
      Just Italic -> el "i" $ render content
      Just GameKeyword -> el "strong" $ render content
  render (ColorValue v) = render v
  render (DifficultyValue d) = render d
  render Break = el "br" $ pure ()

instance (Monad m, DomBuilder t m) => Render Block m where
  render (Paragraph b) = el "p" $ render b
  render Rule = el "hr" $ pure ()
  render (Header t) = el "h3" $ render t
  render (BulletList items) = el "ul" $ mapM_ (el "li" . render) items

instance (Monad m, DomBuilder t m) => Render Difficulty m where
  type RenderConfig Difficulty = IconMode
  renderWith mode d = resourceSymbol mode (d.attribute) $ Just $ tshow (d.value)

instance (Monad m, DomBuilder t m) => Render StatValue m where
  type RenderConfig StatValue = IconMode
  renderWith mode s = resourceSymbol mode (s.color) $ Just $ tshow (s.value)
