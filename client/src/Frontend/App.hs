{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.App (appWidget, headWidget, uiWidget) where

import Control.Monad (join)
import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Data.UUID.Types (UUID)
import Frontend.Editor (editorWidget)
import Frontend.Style.DSL qualified as S
import Frontend.Util (widgetHoldE)
import Reflex.Dom.Core
import Reflex.Dom.GadtApi.WebSocket (TaggedResponse, tagRequests)

import Api.Reflex (GameView (..), ServerPush (..), WsMessage (..))
import Api.Request qualified as Req
import Api.Types (LogEntry, Phase (..))
import Core.Primitives (ActorId, Identified (..))
import Core.State
  ( ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , CoreCardState (..)
  , MapMode (..)
  , identifiedLookup
  )

import Frontend.Game.Class
import Frontend.Game.Defense (DefenseAction (..), DefenseTarget (..))
import Frontend.Game.DefenseWidget (defenseWidget)
import Frontend.Game.Hand (handWidget)
import Frontend.Game.MapBoard (mapBoardWidget)

import Frontend.Game.Planning (StagingState)
import Frontend.Game.Sidebar (ViewMode (..), sidebarWidget)
import Frontend.Game.SidebarRight (getActiveDefenseTarget, sidebarRightWidget)

import Frontend.Style.Common (Style, componentS, divS)

-- | Root layout for the app (full-screen row)
appRoot :: Style
appRoot = S.flexRow <> S.hScreen <> S.bgTransparent <> S.text1 <> S.overflowHidden

-- | Main content area (right of sidebar)
mainContent :: Style
mainContent = S.flexCol <> S.flex1 <> S.relative <> S.bgTransparent <> S.css "min-w-0" "min-width" "0"

appWidget :: (MonadWidget t m, Prerender t m) => T.Text -> UUID -> m ()
appWidget wsBaseUrl clientId = do
  rec -- RequesterT loop
      -- TODO: Load initial actor from local storage
      sessionState <- makeSessionState pushEvt
      (_, requests) <-
        runRequesterT (runGameT sessionState (uiWidget Nothing Nothing)) responses
      (taggedReqs, responses) <- tagRequests requests taggedResps

      let reqsEncoded = fmap (map (decodeUtf8 . BL.toStrict . encode)) taggedReqs
      (pushEvt, taggedResps) <- connectWebSocket wsUrl reqsEncoded

  pure ()
  where
    wsUrl = wsBaseUrl <> "?clientId=" <> T.pack (show clientId)

-- | Establishes the WebSocket connection and decodes messages into Push/Response events.
connectWebSocket
  :: (MonadWidget t m)
  => T.Text
  -> Event t [T.Text]
  -> m (Event t ServerPush, Event t TaggedResponse)
connectWebSocket wsUrl sendEvt = do
  let wsConfig = def{_webSocketConfig_send = sendEvt}
  ws <- webSocket wsUrl wsConfig
  let rawMsg = _webSocket_recv ws
      decodeResult = eitherDecode . BL.fromStrict <$> rawMsg
      wsMsg = fmapMaybe (either (const Nothing) Just) decodeResult
      decodeErrors = fmapMaybe (either Just (const Nothing)) decodeResult
      pushEvt = fmapMaybe (\case WsMsgPush p -> Just p; _ -> Nothing) wsMsg
      taggedResps = fmapMaybe (\case WsMsgResponse r -> Just r; _ -> Nothing) wsMsg

  performEvent_ $ ffor decodeErrors $ \err ->
    liftIO $ putStrLn $ "WS Decode Error: " <> err

  pure (pushEvt, taggedResps)

-- | Pure update helpers for foldDyn
updateActors :: ServerPush -> Map.Map ActorId ActorState -> Map.Map ActorId ActorState
updateActors (PushWelcome{game = a}) _ = a.actors
updateActors (PushUpdate{game = a}) _ = a.actors
updateActors _ old = old

updateLogs :: ServerPush -> [LogEntry] -> [LogEntry]
updateLogs (PushNewLogs newLogs) logs = logs ++ newLogs
updateLogs (PushWelcome{history = h}) _ = h
updateLogs (PushError _) logs = logs
updateLogs _ logs = logs

updatePhase :: ServerPush -> Phase -> Phase
updatePhase (PushWelcome{phase = p}) _ = p
updatePhase (PushUpdate{newPhase = Just p}) _ = p
updatePhase _ old = old

updateMapMode :: ServerPush -> MapMode -> MapMode
updateMapMode (PushWelcome{game = a}) _ = fromMaybe MapModeGrid a.mapMode
updateMapMode (PushUpdate{game = a}) _ = fromMaybe MapModeGrid a.mapMode
updateMapMode _ old = old

-- | Constructs the session state by folding incoming server push events.
makeSessionState
  :: (Reflex t, MonadHold t m, MonadFix m)
  => Event t ServerPush
  -> m (SessionState t)
makeSessionState pushEvt = do
  actorsMapDyn <- foldDyn updateActors Map.empty pushEvt
  logsDyn <- foldDyn updateLogs [] pushEvt
  phaseDyn <- holdUniqDyn =<< foldDyn updatePhase Planning pushEvt
  mapModeDyn <- holdUniqDyn =<< foldDyn updateMapMode MapModeGrid pushEvt
  pure $ SessionState actorsMapDyn logsDyn phaseDyn mapModeDyn

data ViewModeChange
  = UserChange ViewMode
  | ServerMapModeChange MapMode

applyChange :: ViewModeChange -> ViewMode -> ViewMode
applyChange (UserChange vm) _ = vm
applyChange (ServerMapModeChange mm) currentMode =
  case currentMode of
    ViewCardEditor -> ViewCardEditor
    _ -> mapModeToViewMode mm

mapModeToViewMode :: MapMode -> ViewMode
mapModeToViewMode MapModeGrid = ViewGridMap
mapModeToViewMode MapModeRank = ViewRanksMode

uiWidget
  :: (GameWidgetIO t m)
  => Maybe StagingState
  -- ^ Optional initial staging state
  -> Maybe ActorId
  -- ^ Initial active actor
  -> m ()
uiWidget mStaging initialActorId = componentS "app-container" (S.flexCol <> S.hScreen <> S.overflowHidden) $ do
  mapModeDyn <- askMapMode
  rec -- View mode state handling
      let changeEvt =
            leftmost
              [ UserChange <$> viewModeUserEvt
              , ServerMapModeChange <$> updated mapModeDyn
              ]
      initialMapMode <- sample (current mapModeDyn)
      currentViewModeDyn <- foldDyn applyChange (mapModeToViewMode initialMapMode) changeEvt

      -- Trigger server map mode update if user selected Grid Map or Ranks Mode
      let mapModeRequestEvt =
            fmapMaybe
              ( \case
                  UserChange ViewGridMap -> Just (Req.SetMapMode MapModeGrid)
                  UserChange ViewRanksMode -> Just (Req.SetMapMode MapModeRank)
                  _ -> Nothing
              )
              changeEvt
      _ <- requestGame mapModeRequestEvt

      viewModeUserEvt <- divS appRoot $ do
        rec selectedActorId <- holdDyn initialActorId (leftmost [sidebarActiveChange, mapActiveChange])
            (sidebarActiveChange, resumeDefenseEvt, viewModeUserEvt') <-
              sidebarWidget selectedActorId currentViewModeDyn
            mapActiveChange <- mainContentWidget mStaging selectedActorId currentViewModeDyn

        -- Right Sidebar — now returns Event t DefenseTarget from challenge clicks
        openDefenseEvt <- sidebarRightWidget selectedActorId

        -- Render defense modal overlay and handle defense actions
        defenseModalWidget initialActorId selectedActorId resumeDefenseEvt openDefenseEvt

        return viewModeUserEvt'
  pure ()

-- | Interactive map board and hand widget feedback loop.
mapWidget
  :: (GameWidgetIO t m)
  => Maybe StagingState
  -> Dynamic t (Maybe ActorId)
  -> m (Event t (Maybe ActorId))
mapWidget mStaging selectedActorId = do
  rec (mapChange, rankMoveClickEvt) <- mapBoardWidget selectedActorId stagingStateDyn rankMoveStagingDyn

      actorsMapDyn <- askActors
      initialSelectedActorId <- sample (current selectedActorId)
      initialActorsMap <- sample (current actorsMapDyn)

      let initialWidget = case initialSelectedActorId >>= \aid -> identifiedLookup aid initialActorsMap of
            Nothing -> return (constDyn Nothing, constDyn Nothing)
            Just (Identified i c) -> do
              let actorDyn = ffor actorsMapDyn $ \actors ->
                    fromMaybe (Identified i c) (identifiedLookup i actors)
              handWidget mStaging rankMoveClickEvt actorDyn

      let triggerEvt = attach (current actorsMapDyn) (updated selectedActorId)
      handWidgetResDyn <- widgetHold initialWidget $ ffor triggerEvt $ \(actorsMap, mId) ->
        case mId >>= \aid -> identifiedLookup aid actorsMap of
          Nothing -> return (constDyn Nothing, constDyn Nothing)
          Just (Identified i c) -> do
            let actorDyn = ffor actorsMapDyn $ \actors ->
                  fromMaybe (Identified i c) (identifiedLookup i actors)
            handWidget mStaging rankMoveClickEvt actorDyn

      stagingStateDyn <- holdUniqDyn (fst =<< handWidgetResDyn)
      rankMoveStagingDyn <- holdUniqDyn (snd =<< handWidgetResDyn)

  return mapChange

-- | Main content wrapper hosting card editor or map widget.
mainContentWidget
  :: (GameWidgetIO t m)
  => Maybe StagingState
  -> Dynamic t (Maybe ActorId)
  -> Dynamic t ViewMode
  -> m (Event t (Maybe ActorId))
mainContentWidget mStaging selectedActorId currentViewModeDyn = componentS "main-content" mainContent $ do
  let mapWidgetBranch = mapWidget mStaging selectedActorId
      editorWidgetBranch = do
        editorWidget
        return never

  let viewSelectorDyn = (== ViewCardEditor) <$> currentViewModeDyn
  initialViewIsEditor <- sample (current viewSelectorDyn)
  let initialWidget = if initialViewIsEditor then editorWidgetBranch else mapWidgetBranch
  widgetHoldDyn <-
    widgetHold
      initialWidget
      ( ffor (updated viewSelectorDyn) $ \case
          True -> editorWidgetBranch
          False -> mapWidgetBranch
      )
  return (switch (current widgetHoldDyn))

-- | Handles the defense modal overlay and maps defense actions to API requests.
defenseModalWidget
  :: (GameWidget t m, Adjustable t m, MonadIO m)
  => Maybe ActorId
  -> Dynamic t (Maybe ActorId)
  -> Event t ActorId
  -> Event t DefenseTarget
  -> m ()
defenseModalWidget initialActorId selectedActorId resumeDefenseEvt openDefenseEvt = do
  actorsMapDyn <- askActors
  logsDyn <- askLogs
  rec let closePanelEvt = ffilter (\case ClosePanel -> True; EndDefense -> True; _ -> False) defenseWidgetEvt

      let actorSelectedEvt = updated selectedActorId
      pb <- getPostBuild
      let actorSelectedOrBuildEvt = leftmost [actorSelectedEvt, initialActorId <$ pb]
          autoOpenEvt =
            attachWith
              (\(actorsMap, history) mActorId -> getActiveDefenseTarget mActorId actorsMap history)
              (current (zipDyn actorsMapDyn logsDyn))
              actorSelectedOrBuildEvt

          manualResumeEvt =
            attachWith
              (\(actorsMap, history) actorId -> getActiveDefenseTarget (Just actorId) actorsMap history)
              (current (zipDyn actorsMapDyn logsDyn))
              resumeDefenseEvt

      -- Defense modal state: Nothing = closed, Just target = open
      --
      -- When a challenge is clicked, we check if the selected actor already has
      -- an active defense. If so, we redirect to that defense (conflict detection)
      defenseTargetDyn <-
        holdDyn Nothing $
          leftmost
            [ Just
                <$> attachWith
                  ( \(mActorId, actorsMap) newTarget ->
                      -- Conflict detection: if actor is already defending a different challenge,
                      -- open that defense instead.
                      let mActiveDefense = do
                            actorId <- mActorId
                            actorState <- Map.lookup actorId actorsMap
                            _defending <- actorState.coreState.defending
                            pure (actorState, _defending)
                       in case mActiveDefense of
                            Just (_actorState, defending) ->
                              if defending.activeChallenge.id /= newTarget.challenge.id
                                then -- Actor is defending a different challenge — keep active defense
                                  newTarget{challenge = defending.activeChallenge}
                                else newTarget
                            Nothing -> newTarget
                  )
                  (current (zipDyn selectedActorId actorsMapDyn))
                  openDefenseEvt
            , autoOpenEvt
            , manualResumeEvt
            , Nothing <$ closePanelEvt
            ]

      let triggerDyn = zipDyn defenseTargetDyn selectedActorId
          triggerWithMapEvt = attach (current actorsMapDyn) (updated triggerDyn)

      initialTrigger <- sample (current triggerDyn)
      initialActorsMap <- sample (current actorsMapDyn)

      let renderDefense target actorId actorState = do
            let actorStateDyn = ffor actorsMapDyn $ \m ->
                  fromMaybe actorState (Map.lookup actorId m)
            actionEvt <- defenseWidget (constDyn target) actorStateDyn
            let defenseReqs = fmapMaybe (toDefenseRequest actorId target) actionEvt
            _ <- requestGame defenseReqs
            return actionEvt

      let initialWidget = case initialTrigger of
            (Just target, Just actorId)
              | Just actorState <- Map.lookup actorId initialActorsMap ->
                  renderDefense target actorId actorState
            _ -> return never

      defenseWidgetEvt <- widgetHoldE initialWidget $ ffor triggerWithMapEvt $ \(actorsMap, (mTarget, mActorId)) ->
        case (mTarget, mActorId) of
          (Just target, Just actorId)
            | Just actorState <- Map.lookup actorId actorsMap ->
                renderDefense target actorId actorState
          _ -> return never
  pure ()
  where
    -- \| Route a DefenseAction to the appropriate API request.
    toDefenseRequest actorId target = \case
      FlipCard ->
        Just (Req.Defend actorId target.challenge.id)
      TakeConsequence mSev ->
        Just (Req.AddConsequence actorId mSev)
      EndDefense ->
        Just (Req.EndDefense actorId)
      ClosePanel ->
        Nothing -- UI-only: no API call

headWidget :: (DomBuilder t m) => m ()
headWidget = do
  elAttr "meta" ("charset" =: "utf-8") blank
  elAttr "meta" ("name" =: "viewport" <> "content" =: "width=device-width, initial-scale=1") blank
  el "title" $ text "CardPG"
  elAttr
    "link"
    ( "rel" =: "stylesheet"
        <> "href"
          =: "https://fonts.googleapis.com/css2?family=Cinzel:wght@400;700;900&family=Lora:ital,wght@0,400;0,700;1,400&family=Almendra:ital,wght@0,400;0,700;1,400;1,700&display=swap"
    )
    blank
  elAttr "link" ("rel" =: "stylesheet" <> "href" =: "https://unpkg.com/open-props") blank
  elAttr "link" ("href" =: "base.css" <> "rel" =: "stylesheet") blank
  elAttr "link" ("href" =: "atomic.css" <> "rel" =: "stylesheet") blank
