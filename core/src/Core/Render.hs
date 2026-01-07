{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Core.Render
  ( Render (..)
  , IconMode (..)
  ) where

import Data.Default (Default (..))
import Data.List.NonEmpty (NonEmpty)
import Data.Vector (Vector)

class (Monad m, Default (RenderConfig a)) => Render a m where
  type RenderConfig a
  type RenderConfig a = ()

  render :: (Default (RenderConfig a)) => a -> m ()
  render = renderWith def

  renderWith :: RenderConfig a -> a -> m ()
  default renderWith :: (RenderConfig a ~ ()) => RenderConfig a -> a -> m ()
  renderWith _ = render

data IconMode = IconInline | IconBlock | IconResponsive
  deriving (Eq, Show, Enum, Bounded)

instance Default IconMode where
  def = IconInline

instance (Render a m, Monad m) => Render (Maybe a) m where
  type RenderConfig (Maybe a) = RenderConfig a
  renderWith _ Nothing = pure ()
  renderWith c (Just a) = renderWith c a

instance (Render a m, Monad m) => Render (NonEmpty a) m where
  type RenderConfig (NonEmpty a) = RenderConfig a
  renderWith c = mapM_ (renderWith c)

instance {-# OVERLAPPABLE #-} (Render a m, Monad m) => Render [a] m where
  type RenderConfig [a] = RenderConfig a
  renderWith c = mapM_ (renderWith c)

instance (Render a m, Monad m) => Render (Vector a) m where
  type RenderConfig (Vector a) = RenderConfig a
  renderWith c = mapM_ (renderWith c)

instance
  (Render a m, Render b m, Default (RenderConfig a), Default (RenderConfig b)) =>
  Render (Either a b) m
  where
  type RenderConfig (Either a b) = (RenderConfig a, RenderConfig b)
  renderWith (ca, _) (Left a) = renderWith ca a
  renderWith (_, cb) (Right b) = renderWith cb b
