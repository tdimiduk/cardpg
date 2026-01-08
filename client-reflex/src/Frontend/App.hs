{-# LANGUAGE MonoLocalBinds #-}

module Frontend.App where

import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map

import Data.Text qualified as T
import Data.UUID (UUID)
import Reflex.Dom.Core

import Api.Reflex (ReflexServerMessage (..))
import Api.Types qualified as Api
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

appWidget :: (MonadWidget t m) => UUID -> m ()
appWidget clientId = do
  rec let sendEvt = fmap (const [BL.toStrict $ encode joinMsg]) (_webSocket_open ws)

      ws <- webSocket wsUrl (def{_webSocketConfig_send = sendEvt})

      let
        serverMsgEvt = fmap (eitherDecode . BL.fromStrict) (_webSocket_recv ws)
        updateActors (Right (ReflexWelcome _ a)) _ = a
        updateActors (Right (ReflexUpdate a)) _ = a
        updateActors _ old = old

      actorsMapDyn <- foldDyn updateActors Map.empty serverMsgEvt

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
          dyn_ $ ffor selectedActorId $ maybe blank $ \aid -> handWidget $ Map.lookup aid <$> actorsMapDyn
        return selEvt

  return ()
  where
    wsUrl = "ws://localhost:3004/api?clientId=" <> T.pack (show clientId) <> "&name=ReflexReflex"
    joinMsg = Api.Join "ReflexReflex" Nothing
