{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.App where

import Control.Monad.Fix (MonadFix)
import Data.Aeson (decode, eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map
import Data.Text qualified as T
import Data.UUID (UUID)
import Reflex.Dom.Core
import Reflex.Dom.GadtApi.WebSocket (TaggedRequest, TaggedResponse, tagRequests)

import Api.Reflex (GameView (..), ServerPush (..), WsMessage (..))
import Api.Request (ApiRequest (..))
import Api.Types qualified as Api

import Core.Primitives (ActorId)
import Core.State (ActorState)
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
      (_, requests) <- runRequesterT (uiWidget clientId actorsMapDyn) responses
      (taggedReqs, responses) <- tagRequests requests taggedResps

      let sendEvt = fmap (map (BL.toStrict . encode)) taggedReqs

      wsConfig <- holdDyn def (def{_webSocketConfig_send = sendEvt} <$ _webSocket_open ws)

      ws <- webSocket wsUrl (def{_webSocketConfig_send = sendEvt})

      let wsMsg = fmapMaybe (decode . BL.fromStrict) (_webSocket_recv ws)
          pushEvt = fmapMaybe (\case WsMsgPush p -> Just p; _ -> Nothing) wsMsg
          taggedResps = fmapMaybe (\case WsMsgResponse r -> Just r; _ -> Nothing) wsMsg

          updateActors (PushWelcome _ a) _ = a.actors
          updateActors (PushUpdate a) _ = a.actors
          updateActors (PushError _) old = old

      actorsMapDyn <- foldDyn updateActors (Map.empty :: Map.Map ActorId ActorState) pushEvt

  pure ()
  where
    wsUrl = "ws://localhost:3004/api?clientId=" <> T.pack (show clientId)

uiWidget ::
  (MonadWidget t m, Requester t m, Request m ~ ApiRequest) =>
  UUID ->
  Dynamic t (Map.Map ActorId ActorState) ->
  m ()
uiWidget clientId actorsMapDyn = do
  -- Actor Selection State
  rec selectedActorId <- holdDyn Nothing (leftmost [selectEvt])

      -- Layout: Sidebar + Main Content
      selectEvt <- divStyle appRoot $ do
        -- Sidebar (Left)
        selEvt <- sidebarWidget selectedActorId actorsMapDyn

        -- Main Content Area (Right)
        divStyle mainContent $ do
          -- Top Bar / Game Board Area (Placeholder)
          divStyle gameBoardPlaceholder $
            text "Game Board Area"

          -- Player Hand Area (Bottom Overlay)
          dyn_ $ ffor selectedActorId $ maybe blank $ \aid ->
            handWidget $ Map.lookup aid <$> actorsMapDyn
        return selEvt
  pure ()
