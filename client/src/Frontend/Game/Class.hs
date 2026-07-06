{-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Frontend.Game.Class
  ( SessionState (SessionState)
  , MonadGame (..)
  , GameWidget
  , GameWidgetIO
  , GameT (..)
  , runGameT
  , askReadyCount
  , askTotalCount
  ) where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO)
import Control.Monad.Primitive (PrimMonad)
import Control.Monad.Ref (MonadAtomicRef (..), MonadRef (..))
import Control.Monad.Trans.Class (MonadTrans (..))
import Control.Monad.Trans.Reader (ReaderT (..), asks, runReaderT)
import Data.Map qualified as Map
import Data.Text (Text)
import Language.Javascript.JSaddle (MonadJSM)
import Reflex.Dom.Core
import Reflex.Host.Class (MonadReflexCreateTrigger)
import Unsafe.Coerce (unsafeCoerce)

import Api.Request (ApiRequest)
import Api.Types (LogEntry, Phase)
import Core.Primitives (ActorId)
import Core.State (ActorState, MapMode, isActorPC, isActorReady)

-- | SessionState packages all fine-grained Dynamics folded from WS events.
data SessionState t = SessionState
  { actors :: Dynamic t (Map.Map ActorId ActorState)
  , logs :: Dynamic t [LogEntry]
  , phase :: Dynamic t Phase
  , mapMode :: Dynamic t MapMode
  }

-- | Type-safe context class that abstracts state reads and request dispatching.
class (Monad m) => MonadGame t m | m -> t where
  askActors :: m (Dynamic t (Map.Map ActorId ActorState))
  askLogs :: m (Dynamic t [LogEntry])
  askPhase :: m (Dynamic t Phase)
  askMapMode :: m (Dynamic t MapMode)
  requestGame :: Event t (ApiRequest a) -> m (Event t (Either Text a))

type GameWidget t m = (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, MonadGame t m)
type GameWidgetIO t m =
  (GameWidget t m, MonadIO m, Adjustable t m, Prerender t m, MonadGame t (Client m))

-- | Auto-derived derived stats
askReadyCount :: (MonadGame t m, Reflex t) => m (Dynamic t Int)
askReadyCount = fmap (Map.size . Map.filter (\a -> isActorPC a && isActorReady a)) <$> askActors

askTotalCount :: (MonadGame t m, Reflex t) => m (Dynamic t Int)
askTotalCount = fmap (Map.size . Map.filter isActorPC) <$> askActors

-- | GameT is the concrete production monad transformer implementing MonadGame.
newtype GameT t m a = GameT (ReaderT (SessionState t) m a)
  deriving newtype
    ( Functor
    , Applicative
    , Monad
    , MonadFix
    , MonadIO
    )

unGameT :: GameT t m a -> ReaderT (SessionState t) m a
unGameT (GameT x) = x

instance MonadTrans (GameT t) where
  lift = GameT . lift

runGameT :: SessionState t -> GameT t m a -> m a
runGameT state (GameT action) = runReaderT action state

-- Standalone deriving instances to resolve type-kind ambiguities
deriving newtype instance (PostBuild t m) => PostBuild t (GameT t m)
deriving newtype instance (TriggerEvent t m) => TriggerEvent t (GameT t m)
deriving newtype instance (PerformEvent t m) => PerformEvent t (GameT t m)
deriving newtype instance (MonadHold t m) => MonadHold t (GameT t m)
deriving newtype instance (MonadSample t m) => MonadSample t (GameT t m)
deriving newtype instance (NotReady t m) => NotReady t (GameT t m)
deriving newtype instance
  (DomBuilder t m, MonadFix m, NotReady t m, MonadHold t m) => DomBuilder t (GameT t m)
deriving newtype instance (MonadRef m) => MonadRef (GameT t m)
deriving newtype instance (MonadAtomicRef m) => MonadAtomicRef (GameT t m)
deriving newtype instance (DomRenderHook t m) => DomRenderHook t (GameT t m)
#if !defined(ghcjs_HOST_OS) && !defined(javascript_HOST_ARCH)
deriving newtype instance (MonadJSM m) => MonadJSM (GameT t m)
#endif
deriving newtype instance (MonadReflexCreateTrigger t m) => MonadReflexCreateTrigger t (GameT t m)
deriving newtype instance (PrimMonad m) => PrimMonad (GameT t m)

-- | HasDocument instance for GameT.
--
-- WHY IS THIS SAFE?
-- 1. GameT is a newtype wrapper around ReaderT, which at runtime is erased to a function `r -> m a`.
--    Hence, `GameT t m` and `m` have identical runtime representations.
-- 2. Under the hood, `DomBuilderSpace (GameT t m)` simplifies to `DomBuilderSpace m`.
-- 3. GHC's type role checker cannot solve equations involving non-injective associated type families
--    (like `RawDocument` and `DomBuilderSpace`) across newtypes, meaning standard `coerce` does not compile.
--    `unsafeCoerce` is purely a compile-time cast with zero runtime overhead.
--
-- GOTCHAS & FUTURE WARNINGS:
-- * If `GameT` is ever changed from a newtype to a data type (e.g. adding caching, logs, or other runtime fields
--   directly inside GameT instead of SessionState), `unsafeCoerce` will immediately become representationally
--   unsafe and crash at runtime. Keep `GameT` a newtype!
-- * If the underlying associated type families (`RawDocument` or `DomBuilderSpace`) are customized to map
--   to structurally different types under different environments, this cast may break.
instance (HasDocument m) => HasDocument (GameT t m) where
  askDocument = GameT $ ReaderT $ \_ -> unsafeCoerce (askDocument :: m (RawDocument (DomBuilderSpace m)))

instance (Prerender t m, Monad m) => Prerender t (GameT t m) where
  type Client (GameT t m) = GameT t (Client m)
  prerender (GameT server) (GameT client) = GameT $ ReaderT $ \r ->
    prerender (runReaderT server r) (runReaderT client r)

instance (Adjustable t m, MonadFix m, MonadHold t m) => Adjustable t (GameT t m) where
  runWithReplace a b = GameT $ runWithReplace (unGameT a) (fmap unGameT b)
  traverseIntMapWithKeyWithAdjust f dm ev =
    GameT $
      traverseIntMapWithKeyWithAdjust (\k v -> unGameT (f k v)) dm ev
  traverseDMapWithKeyWithAdjust f dm ev =
    GameT $
      traverseDMapWithKeyWithAdjust (\k v -> unGameT (f k v)) dm ev

-- | MonadGame instance for the production implementation GameT t m.
-- It delegates requesting to the underlying Requester context.
instance
  (Reflex t, Requester t m, Request m ~ ApiRequest, Response m ~ Either Text, Monad m)
  => MonadGame t (GameT t m)
  where
  askActors = GameT $ asks (.actors)
  askLogs = GameT $ asks (.logs)
  askPhase = GameT $ asks (.phase)
  askMapMode = GameT $ asks (.mapMode)
  requestGame = lift . requesting
