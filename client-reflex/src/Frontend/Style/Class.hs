{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

-- | Core styling types and MonadStyle typeclass.
--
-- This module provides the infrastructure for registering CSS rules
-- within the Reflex monad stack. The MonadStyle typeclass allows
-- widgets to register their styles at render time, which are collected
-- for static CSS generation.
module Frontend.Style.Class
  ( MonadStyle (..)
  , StyledDomBuilder
  , registerEnumStyles
  ) where

import Control.Monad.Trans.Class (MonadTrans, lift)
import Control.Monad.Trans.Except (ExceptT)
import Control.Monad.Trans.Reader (ReaderT)
import Control.Monad.Trans.State (StateT)
import Control.Monad.Trans.Writer (WriterT)
import Reflex.Dom.Core
  ( DomBuilder
  , HydratableT
  , PostBuildT
  , Reflex
  , RequesterT
  , StaticDomBuilderT
  , TriggerEventT
  )
import Web.Atomic.Types (CSS, Rule)

-- | Typeclass for monads that can track style usage.
-- The default implementation is a no-op, suitable for runtime widgets.
-- StyleWriterT provides a custom implementation that collects rules.
class (Monad m) => MonadStyle m where
  registerStyles :: CSS [Rule] -> m ()
  default registerStyles :: (MonadTrans t, MonadStyle n, m ~ t n) => CSS [Rule] -> m ()
  registerStyles = lift . registerStyles

-- | Register styles for all values of a bounded enum.
registerEnumStyles :: (Enum a, Bounded a, MonadStyle m) => (a -> CSS [Rule]) -> m ()
registerEnumStyles f = mapM_ (registerStyles . f) [minBound .. maxBound]

-- | Universal overlappable instance for any monad - no-op at runtime.
-- This allows the constraint to be satisfied by any monad stack.
-- StyleWriterT provides its own overlapping instance that actually collects.
instance {-# OVERLAPPABLE #-} (Monad m) => MonadStyle m where
  registerStyles _ = pure ()

-- | Lifting instances for standard transformers
instance {-# OVERLAPPING #-} (MonadStyle m) => MonadStyle (ReaderT r m)

instance {-# OVERLAPPING #-} (MonadStyle m) => MonadStyle (StateT s m)
instance {-# OVERLAPPING #-} (Monoid w, MonadStyle m) => MonadStyle (WriterT w m)
instance {-# OVERLAPPING #-} (MonadStyle m) => MonadStyle (ExceptT e m)

-- | Lifting instances for Reflex transformers
instance {-# OVERLAPPING #-} (Reflex t, MonadStyle m) => MonadStyle (PostBuildT t m)

instance {-# OVERLAPPING #-} (Reflex t, MonadStyle m) => MonadStyle (RequesterT t request response m)
instance {-# OVERLAPPING #-} (Reflex t, MonadStyle m) => MonadStyle (TriggerEventT t m)
instance {-# OVERLAPPING #-} (Reflex t, MonadStyle m) => MonadStyle (StaticDomBuilderT t m)
instance {-# OVERLAPPING #-} (MonadStyle m) => MonadStyle (HydratableT m)

-- | Alias for widgets that can build DOM and utilize atomic styles
type StyledDomBuilder t m = (DomBuilder t m, MonadStyle m)
