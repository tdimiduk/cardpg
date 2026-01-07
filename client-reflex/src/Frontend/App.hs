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
      selectEvt <- divClass "flex flex-row h-screen bg-slate-950 text-slate-100 overflow-hidden" $ do
        -- Sidebar (Left)
        selEvt <- sidebarWidget selectedActorId actorsMapDyn

        -- Main Content Area (Right)
        divClass "flex-1 relative bg-slate-900 overflow-hidden flex flex-col" $ do
          -- Top Bar / Game Board Area (Placeholder)
          divClass "flex-1 flex items-center justify-center text-slate-700" $
            text "Game Board Area"

          -- Player Hand Area (Bottom Overlay)
          dyn_ $ ffor selectedActorId $ maybe blank $ \aid -> handWidget $ Map.lookup aid <$> actorsMapDyn
        return selEvt

  return ()
  where
    wsUrl = "ws://localhost:3004/api?clientId=" <> T.pack (show clientId) <> "&name=ReflexReflex"
    joinMsg = Api.Join "ReflexReflex" Nothing
