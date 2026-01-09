{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.App where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO)
import Data.Aeson (decode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map
import Data.Text qualified as T
import Data.UUID (UUID)
import Reflex.Dom.Core
import Reflex.Dom.GadtApi.WebSocket (tagRequests)

import Api.Reflex (GameView (..), ServerPush (..), WsMessage (..))
import Api.Request (ApiRequest (..))
import Core.Primitives (ActorId, Identified (..))
import Core.State (ActorState, identifiedLookup)

import Frontend.Game.Hand (handWidget)
import Frontend.Game.Sidebar (sidebarWidget)
import Frontend.Style

-- | Root layout for the app (full-screen row)
appRoot :: [CssClass]
appRoot =
  [ flex
  , flexRow
  , "h-screen"
  , "bg-slate-950"
  , "text-slate-100"
  , "overflow-hidden"
  ]

-- | Main content area (right of sidebar)
mainContent :: [CssClass]
mainContent =
  [ "flex-1"
  , relative
  , "bg-slate-900"
  , "overflow-hidden"
  , flex
  , flexCol
  ]

-- | Placeholder for game board
gameBoardPlaceholder :: [CssClass]
gameBoardPlaceholder = ["flex-1", flex, itemsCenter, justifyCenter, "text-slate-700"]

appWidget :: (MonadWidget t m, Prerender t m) => UUID -> m ()
appWidget clientId = do
  rec -- RequesterT loop
      -- TODO: Load initial actor from local storage
      (_, requests) <- runRequesterT (uiWidget Nothing actorsMapDyn) responses
      (taggedReqs, responses) <- tagRequests requests taggedResps

      let sendEvt = fmap (map (BL.toStrict . encode)) taggedReqs

      ws <- webSocket wsUrl (def{_webSocketConfig_send = sendEvt})

      let wsMsg = fmapMaybe (decode . BL.fromStrict) (_webSocket_recv ws)
          pushEvt = fmapMaybe (\case WsMsgPush p -> Just p; _ -> Nothing) wsMsg
          taggedResps = fmapMaybe (\case WsMsgResponse r -> Just r; _ -> Nothing) wsMsg

          updateActors (PushWelcome _ a) _ = a.actors
          updateActors (PushUpdate a) _ = a.actors
          updateActors (PushError _) old = old
          updateActors (PushChat _) old = old
          updateActors (PushLog _) old = old

      actorsMapDyn <- foldDyn updateActors (Map.empty :: Map.Map ActorId ActorState) pushEvt

  pure ()
  where
    wsUrl = "ws://localhost:3004/api?clientId=" <> T.pack (show clientId)

uiWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadIO m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => Maybe ActorId
  -- ^ Initial active actor
  -> Dynamic t (Map.Map ActorId ActorState)
  -> m ()
uiWidget initialActorId actorsMapDyn = divStyle appRoot $ do
  rec selectedActorId <- holdDyn initialActorId activeActorChange
      activeActorChange <- sidebarWidget selectedActorId actorsMapDyn

      let activeActor = ffor2 selectedActorId actorsMapDyn (\mId actors -> mId >>= \aid -> identifiedLookup aid actors)

  -- Main Content Area (Right)
  divStyle mainContent $ do
    -- Top Bar / Game Board Area (Placeholder)
    divStyle gameBoardPlaceholder $ text "Game Board Area"

    let activeActorMap = ffor activeActor $ \case
          Nothing -> Map.empty
          Just (Identified i c) -> Map.singleton i c

    _ <- listWithKey activeActorMap $ \k vDyn ->
      handWidget (Identified k <$> vDyn)

    return ()
  pure ()
