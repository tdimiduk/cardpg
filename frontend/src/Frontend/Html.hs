module Frontend.Html
  ( Render(..) )
where

import Data.List.NonEmpty (NonEmpty)
import Data.Text (Text, pack)
import Data.Vector (Vector)

import Reflex.Dom.Core

class Render a m where
  render :: a -> m ()

instance (Render a m, Monad m) => Render (Maybe a) m where
  render Nothing = blank
  render (Just a) = render a

instance (Render a m, Monad m) => Render (NonEmpty a) m where
  render = mapM_ render

instance {-# OVERLAPPABLE #-} (Render a m, Monad m) => Render [a] m where
  render = mapM_ render

instance (Render a m, Monad m) => Render (Vector a) m where
  render = mapM_ render

instance {-# OVERLAPPING #-} (DomBuilder t m) => Render Text m where
  render = text

instance (DomBuilder t m) => Render [Char] m where
  render = text . pack

instance (Render a m, Render b m, DomBuilder t m) => Render (Either a b) m where
  render (Right a) = render a
  render (Left b) = text "error: " >> render b
