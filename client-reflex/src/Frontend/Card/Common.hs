{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

module Frontend.Card.Common
  ( art
  , inParensLS
  ) where

import Reflex.Dom.Core

import Frontend.Html (Render (..))

art :: (DomBuilder t m) => m ()
art = divClass "art" blank

inParensLS :: (Monad m, DomBuilder t m, Render a m) => a -> m ()
inParensLS a = text " (" >> render a >> text ")"
