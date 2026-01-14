{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Core.Render
  ( Render (..)
  , RenderMode (..)
  , ComputeRenderMode
  , RenderStrategy (..)
  , IconMode (..)
  ) where

import Data.Default (Default (..))
import Data.List.NonEmpty (NonEmpty)
import Data.Vector (Vector)

import Control.Monad.Writer (Writer, tell)
import Data.Text (Text)

data RenderMode = TextMode | HtmlMode

type family ComputeRenderMode m :: RenderMode where
  ComputeRenderMode (Writer [Text]) = 'TextMode
  ComputeRenderMode _ = 'HtmlMode

class (Monad m) => RenderStrategy (mode :: RenderMode) a m where
  type StrategyConfig mode a
  type StrategyConfig mode a = ()

  renderStrategy :: (Default (StrategyConfig mode a)) => a -> m ()
  renderStrategy = renderStrategyWith @mode def

  renderStrategyWith :: StrategyConfig mode a -> a -> m ()
  default renderStrategyWith :: (StrategyConfig mode a ~ ()) => StrategyConfig mode a -> a -> m ()
  renderStrategyWith _ = renderStrategy @mode

class (Monad m) => Render a m where
  render :: a -> m ()
  renderWith
    :: (RenderStrategy (ComputeRenderMode m) a m) => StrategyConfig (ComputeRenderMode m) a -> a -> m ()

instance
  (Monad m, mode ~ ComputeRenderMode m, RenderStrategy mode a m, Default (StrategyConfig mode a))
  => Render a m
  where
  {-# INLINE render #-}
  render = renderStrategy @mode
  {-# INLINE renderWith #-}
  renderWith = renderStrategyWith @mode

data IconMode = IconInline | IconBlock | IconResponsive
  deriving (Eq, Show, Enum, Bounded)

instance Default IconMode where
  def = IconInline

-- Generic Instances (Polymorphic in Mode)

instance (RenderStrategy mode a m, Monad m) => RenderStrategy mode (Maybe a) m where
  type StrategyConfig mode (Maybe a) = StrategyConfig mode a
  renderStrategyWith _ Nothing = pure ()
  renderStrategyWith c (Just a) = renderStrategyWith @mode c a

instance (RenderStrategy mode a m, Monad m) => RenderStrategy mode (NonEmpty a) m where
  type StrategyConfig mode (NonEmpty a) = StrategyConfig mode a
  renderStrategyWith c = mapM_ (renderStrategyWith @mode c)

instance {-# OVERLAPPABLE #-} (RenderStrategy mode a m, Monad m) => RenderStrategy mode [a] m where
  type StrategyConfig mode [a] = StrategyConfig mode a
  renderStrategyWith c = mapM_ (renderStrategyWith @mode c)

instance (RenderStrategy mode a m, Monad m) => RenderStrategy mode (Vector a) m where
  type StrategyConfig mode (Vector a) = StrategyConfig mode a
  renderStrategyWith c = mapM_ (renderStrategyWith @mode c)

instance
  ( RenderStrategy mode a m
  , RenderStrategy mode b m
  , Default (StrategyConfig mode a)
  , Default (StrategyConfig mode b)
  )
  => RenderStrategy mode (Either a b) m
  where
  type StrategyConfig mode (Either a b) = (StrategyConfig mode a, StrategyConfig mode b)
  renderStrategyWith (ca, _) (Left a) = renderStrategyWith @mode ca a
  renderStrategyWith (_, cb) (Right b) = renderStrategyWith @mode cb b

instance RenderStrategy 'TextMode Text (Writer [Text]) where
  renderStrategy t = tell [t]
