{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Frontend.Html
  ( Render (..)
  , resourceSymbol -- Exporting helper if needed, though mostly used via Render
  ) where

import Data.Default (Default (..))
import Data.Text (Text)
import Data.Text qualified as T
import Reflex.Dom.Core

import Core.NonEmptyText (NonEmptyText, getRawText)
import Core.Render (IconMode (..), Render (..))
import Core.Render.Rule ()
import Core.Render.Stats ()
import Core.RichText (Block (..), Inline (..), RichText (..), TextStyle (..), getInlines)
import Core.Stats (Difficulty (..), ResourceType (..), StatValue (..))
import Core.Util (tshow)

import Frontend.Svg (renderCircle, renderDiamond, renderSquare)

-- Base text instance
instance {-# OVERLAPPING #-} (Monad m, DomBuilder t m) => Render Text m where
  render = text

-- Style helpers
resourceSymbol :: (DomBuilder t m) => IconMode -> ResourceType -> Maybe Text -> m ()
resourceSymbol mode r t = case r of
  Red -> renderSquare (color <> " " <> style) t
  Yellow -> renderCircle (color <> " " <> style) t
  Blue -> renderDiamond (color <> " " <> style) t
  where
    color = T.toLower (tshow r)
    style = case mode of
      IconInline ->
        "w-[1em] h-[1em] ml-[-0.15em] mr-[-0.05em] align-middle inline-block transform translate-y-[-0.1em]"
      IconBlock -> "w-10 h-10 font-bold text-xl"
      IconResponsive -> "h-[30%] w-auto aspect-square font-bold"

instance (Monad m, DomBuilder t m) => Render ResourceType m where
  type RenderConfig ResourceType = IconMode
  renderWith mode r = resourceSymbol mode r Nothing

instance (Monad m, DomBuilder t m) => Render RichText m where
  render rt = mapM_ render (getInlines rt)

instance (Monad m, DomBuilder t m) => Render Inline m where
  render (TextRun style content) =
    let txt = getRawText content
     in case style of
          Nothing -> text txt
          Just Bold -> el "b" $ text txt
          Just Italic -> el "i" $ text txt
          Just GameKeyword -> el "strong" $ text txt
  render (ColorValue v) = render v
  render (DifficultyValue d) = render d
  render Break = el "br" $ pure ()

instance (Monad m, DomBuilder t m) => Render Block m where
  render (Paragraph b) = el "p" $ render b
  render Rule = el "hr" $ pure ()
  render (Header t) = el "h3" $ render t
  render (BulletList items) = el "ul" $ mapM_ (el "li" . render) items

instance (Monad m, DomBuilder t m) => Render NonEmptyText m where
  render net = text (getRawText net)

instance (Monad m, DomBuilder t m) => Render Difficulty m where
  type RenderConfig Difficulty = IconMode
  renderWith mode d = resourceSymbol mode (d.attribute) $ Just $ tshow (d.value)

instance (Monad m, DomBuilder t m) => Render StatValue m where
  type RenderConfig StatValue = IconMode
  renderWith mode s = resourceSymbol mode (s.color) $ Just $ tshow (s.value)
