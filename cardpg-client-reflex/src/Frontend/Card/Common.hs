{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Frontend.Card.Common
  ( art
  , inParensLS
  ) where

import Data.Text (Text)
import Data.Text qualified as T

import Reflex.Dom.Core

import CardPG.Core.DSL.Printer (prettyModifier)
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.RichText (Block (..), Inline (..), RichText (..), TextStyle (..), getInlines)
import CardPG.Core.Stats (Difficulty (..), ResourceType (..), StackPower (..), StatValue (..))
import CardPG.Core.Util (tshow)

import Frontend.Html

resourceSymbol :: (DomBuilder t m) => ResourceType -> Maybe Text -> m ()
resourceSymbol r t =
  divClass cls $
    divClass "resource-number" $
      mapM_ text t
  where
    cls = "resource-symbol " <> T.toLower (tshow r)

art :: (DomBuilder t m) => m ()
art = divClass "art" blank

instance (DomBuilder t m) => Render Block m where
  render (Paragraph b) = el "p" $ render b
  render Rule = el "hr" $ pure ()
  render (Header t) = el "h3" $ render t
  render (BulletList items) = el "ul" $ mapM_ (el "li" . render) items

instance (DomBuilder t m) => Render Inline m where
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

instance (DomBuilder t m) => Render RichText m where
  render rt = mapM_ render (getInlines rt)

inParensLS :: (DomBuilder t m, Render a m) => a -> m ()
inParensLS a = text " (" >> render a >> text ")"

instance (DomBuilder t m) => Render Difficulty m where
  render d = resourceSymbol (d.attribute) $ Just $ tshow (d.value)

instance (DomBuilder t m) => Render StatValue m where
  render s = resourceSymbol (s.color) $ Just $ tshow (s.value)

instance (DomBuilder t m) => Render StackPower m where
  render s = do
    render s.source
    text $ " " <> prettyModifier s.modifier
    maybe blank text s.conditional

instance (DomBuilder t m) => Render ResourceType m where
  render = flip resourceSymbol Nothing
