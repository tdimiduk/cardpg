{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.App where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Data.UUID.Types (UUID)
import Frontend.Style.DSL qualified as S
import Reflex.Dom.Core
import Reflex.Dom.GadtApi.WebSocket (tagRequests)

import Api.Reflex (GameView (..), ServerPush (..), WsMessage (..))
import Api.Types (LogEntry, Phase (..))
import Core.Primitives (ActorId, Identified (..))
import Core.State (ActorState, identifiedLookup, isActorPC, isActorReady)

import Frontend.Game.Hand (handWidget)
import Frontend.Game.PhaseDisplay (PhaseDisplayConfig (..))
import Frontend.Game.Sidebar (sidebarWidget)
import Frontend.Game.SidebarRight (sidebarRightWidget)

import Frontend.Style.Class (MonadStyle)
import Frontend.Style.Common (Style, componentT)
import Frontend.Style.DSL qualified as S

import Frontend.Util

-- | Root layout for the app (full-screen row)
appRoot :: Style
appRoot = S.flexRow . S.hScreen . S.bgSlate950 . S.textSlate100 . S.overflowHidden

-- | Main content area (right of sidebar)
mainContent :: Style
mainContent = S.flexCol . S.flex1 . S.relative . S.bgSlate900 . S.overflowHidden

-- | Placeholder for game board
gameBoardPlaceholder :: Style
gameBoardPlaceholder = S.flex1 . S.flex . S.itemsCenter . S.justifyCenter . S.textSlate700

appWidget :: (MonadWidget t m, MonadStyle m, Prerender t m) => T.Text -> UUID -> m ()
appWidget wsBaseUrl clientId = do
  rec -- RequesterT loop
      -- TODO: Load initial actor from local storage
      (_, requests) <-
        runRequesterT (uiWidget Nothing actorsMapDyn logsDyn phaseDyn readyDyn totalDyn) responses
      (taggedReqs, responses) <- tagRequests requests taggedResps

      let reqsEncoded = fmap (map (decodeUtf8 . BL.toStrict . encode)) taggedReqs

      let wsConfig =
            def
              { _webSocketConfig_send = reqsEncoded
              }

      ws <- webSocket wsUrl wsConfig

      -- Decode incoming messages, logging any parse failures
      let rawMsg = _webSocket_recv ws
          decodeResult = eitherDecode . BL.fromStrict <$> rawMsg
          wsMsg = fmapMaybe (either (const Nothing) Just) decodeResult
          decodeErrors = fmapMaybe (either Just (const Nothing)) decodeResult
          pushEvt = fmapMaybe (\case WsMsgPush p -> Just p; _ -> Nothing) wsMsg
          taggedResps = fmapMaybe (\case WsMsgResponse r -> Just r; _ -> Nothing) wsMsg

      -- Log decode errors to console (visible in browser dev tools)
      performEvent_ $ ffor decodeErrors $ \err ->
        liftIO $ putStrLn $ "WS Decode Error: " <> err

      let updateActors (PushWelcome{game = a}) _ = a.actors
          updateActors (PushUpdate{game = a}) _ = a.actors
          updateActors _ old = old

      actorsMapDyn <- foldDyn updateActors (Map.empty :: Map.Map ActorId ActorState) pushEvt

      let updateLogs (PushNewLogs newLogs) logs = newLogs ++ logs
          updateLogs (PushWelcome{history = h}) _ = reverse h
          updateLogs (PushError _) logs = logs -- Errors handled separately or should be?
          updateLogs _ logs = logs

      logsDyn <- foldDyn updateLogs ([] :: [LogEntry]) pushEvt

      let updatePhase (PushWelcome{phase = p}) _ = p
          updatePhase (PushUpdate{newPhase = Just p}) _ = p
          updatePhase _ old = old

      phaseDyn <- foldDyn updatePhase Planning pushEvt

      let totalDyn = fmap (Map.size . Map.filter isActorPC) actorsMapDyn
          readyDyn = fmap (Map.size . Map.filter (\a -> isActorPC a && isActorReady a)) actorsMapDyn

  pure ()
  where
    wsUrl = wsBaseUrl <> "?clientId=" <> T.pack (show clientId)

uiWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadIO m
     , MonadStyle m
     , ApiRequester t m
     , Prerender t m
     )
  => Maybe ActorId
  -- ^ Initial active actor
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t [LogEntry]
  -> Dynamic t Phase
  -> Dynamic t Int
  -- ^ Ready Count
  -> Dynamic t Int
  -- ^ Total Count
  -> m ()
uiWidget initialActorId actorsMapDyn logsDyn phaseDyn readyDyn totalDyn = componentT "app-container" appRoot $ do
  rec -- Construct config for Phase Display
      let phaseConfig =
            PhaseDisplayConfig
              { phase = phaseDyn
              , readyCount = readyDyn
              , totalCount = totalDyn
              }

      selectedActorId <- holdDyn initialActorId activeActorChange
      let activeActor = ffor2 selectedActorId actorsMapDyn (\mId actors -> mId >>= \aid -> identifiedLookup aid actors)
      activeActorChange <- sidebarWidget activeActor actorsMapDyn

  -- Main Content Area (Right)
  componentT "main-content" mainContent $ do
    -- Top Bar / Game Board Area (Placeholder)
    componentT "game-board" gameBoardPlaceholder $ text "Game Board Area"

    let activeActorMap = ffor activeActor $ \case
          Nothing -> Map.empty
          Just (Identified i c) -> Map.singleton i c

    _ <- listWithKey activeActorMap $ \k vDyn ->
      handWidget (Identified k <$> vDyn)

    return ()

  -- Right Sidebar
  sidebarRightWidget activeActor logsDyn phaseConfig

  pure ()
