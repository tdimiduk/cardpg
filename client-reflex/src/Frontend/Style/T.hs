{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- | StyleWriterT monad transformer for collecting CSS rules.
--
-- This transformer wraps any monad and provides a MonadStyle instance
-- that actually collects CSS rules for static generation.
module Frontend.Style.T
  ( StyleWriterT (..)
  , runStyleWriterT
  ) where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Ref (MonadAtomicRef, MonadRef)
import Control.Monad.Trans.Class (MonadTrans (..))
import Control.Monad.Trans.Reader (ReaderT (..), ask, runReaderT)
import Data.IORef (IORef, atomicModifyIORef', newIORef, readIORef)
import Data.Set qualified as Set
import Reflex.Dom.Core
import Reflex.Host.Class (MonadReflexCreateTrigger (..))
import Web.Atomic.Types (CSS (..), Rule)

import Frontend.Style.Class (MonadStyle (..))

type CollectedRules = Set.Set Rule

-- | A monad transformer that collects CSS rules using an IORef.
newtype StyleWriterT m a = StyleWriterT {unStyleWriterT :: ReaderT (IORef CollectedRules) m a}
  deriving
    ( Functor
    , Applicative
    , Monad
    , MonadFix
    , MonadIO
    , MonadRef
    , MonadAtomicRef
    )

-- Reflex Instances deriving
deriving newtype instance (MonadHold t m) => MonadHold t (StyleWriterT m)
deriving newtype instance (MonadSample t m) => MonadSample t (StyleWriterT m)
deriving newtype instance (PostBuild t m) => PostBuild t (StyleWriterT m)
deriving newtype instance (PerformEvent t m) => PerformEvent t (StyleWriterT m)
deriving newtype instance (TriggerEvent t m) => TriggerEvent t (StyleWriterT m)
deriving newtype instance
  (MonadReflexCreateTrigger t m) => MonadReflexCreateTrigger t (StyleWriterT m)

instance (Adjustable t m, MonadHold t m) => Adjustable t (StyleWriterT m) where
  runWithReplace (StyleWriterT a) e = StyleWriterT $ ReaderT $ \r ->
    runWithReplace (runReaderT a r) (fmap (\(StyleWriterT x) -> runReaderT x r) e)

  traverseDMapWithKeyWithAdjust f m e = StyleWriterT $ ReaderT $ \r ->
    traverseDMapWithKeyWithAdjust (\k v -> let (StyleWriterT x) = f k v in runReaderT x r) m e

  traverseDMapWithKeyWithAdjustWithMove f m e = StyleWriterT $ ReaderT $ \r ->
    traverseDMapWithKeyWithAdjustWithMove (\k v -> let (StyleWriterT x) = f k v in runReaderT x r) m e

-- | Run the StyleWriterT and extract collected CSS rules.
runStyleWriterT :: (MonadIO m) => StyleWriterT m a -> m (a, [Rule])
runStyleWriterT (StyleWriterT r) = do
  ref <- liftIO $ newIORef mempty
  res <- runReaderT r ref
  rules <- liftIO $ readIORef ref
  return (res, Set.toList rules)

instance MonadTrans StyleWriterT where
  lift = StyleWriterT . lift

-- | MonadStyle instance that collects CSS rules.
instance (MonadIO m) => MonadStyle (StyleWriterT m) where
  registerStyles (CSS rules) = StyleWriterT $ do
    ref <- ask
    liftIO $ atomicModifyIORef' ref $ \cs -> (Set.union (Set.fromList rules) cs, ())
