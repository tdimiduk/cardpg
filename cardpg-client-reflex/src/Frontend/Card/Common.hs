{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Frontend.Card.Common
  ( art
  , tshow
  , inParensLS
  ) where

import Data.Text (Text)
import Data.Text qualified as T

import Reflex.Dom.Core

import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.Primitives (Difficulty (..), ResourceType (..), StackPower (..))
import CardPG.Core.RichText (Block (..), Inline (..), RichText (..), TextStyle (..), getInlines)

import Frontend.Html

tshow :: (Show a) => a -> Text
tshow = T.pack . show

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
  render (ColorValue (StackPower r i _)) = resourceSymbol r (if i > 0 then Just (tshow i) else Nothing)
  render (DifficultyValue d) = render d
  render Break = el "br" $ pure ()

instance (DomBuilder t m) => Render RichText m where
  render rt = mapM_ render (getInlines rt)

inParensLS :: (DomBuilder t m, Render a m) => a -> m ()
inParensLS a = text " (" >> render a >> text ")"

instance (DomBuilder t m) => Render Difficulty m where
  render d = resourceSymbol (d.attribute) $ Just $ tshow (d.value)
