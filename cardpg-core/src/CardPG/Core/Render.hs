{-# LANGUAGE FlexibleInstances #-}

module CardPG.Core.Render
  ( Render (..)
  ) where

import Data.List.NonEmpty (NonEmpty)
import Data.Vector (Vector)

class (Monad m) => Render a m where
  render :: a -> m ()

instance (Render a m, Monad m) => Render (Maybe a) m where
  render Nothing = pure ()
  render (Just a) = render a

instance (Render a m, Monad m) => Render (NonEmpty a) m where
  render = mapM_ render

instance {-# OVERLAPPABLE #-} (Render a m, Monad m) => Render [a] m where
  render = mapM_ render

instance (Render a m, Monad m) => Render (Vector a) m where
  render = mapM_ render

instance (Render a m, Render b m) => Render (Either a b) m where
  render (Right a) = render a
  render (Left b) = render b
