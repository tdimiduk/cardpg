{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.App (appWidget, headWidget, uiWidget) where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Data.UUID.Types (UUID)
import Frontend.Style.DSL qualified as S
import Reflex.Dom.Core
import Reflex.Dom.GadtApi.WebSocket (tagRequests)

import Api.Reflex (GameView (..), ServerPush (..), WsMessage (..))
import Api.Request qualified as Req
import Api.Types (LogEntry, Phase (..))
import Core.Primitives (ActorId, Identified (..))
import Core.State
  ( ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , CoreCardState (..)
  , identifiedLookup
  )

import Frontend.Game.Class
import Frontend.Game.Defense (DefenseAction (..), DefenseTarget (..))
import Frontend.Game.DefenseWidget (defenseWidget)
import Frontend.Game.Hand (handWidget)
import Frontend.Game.MapBoard (mapBoardWidget)

import Frontend.Game.Planning (StagingState)
import Frontend.Game.Sidebar (sidebarWidget)
import Frontend.Game.SidebarRight (getActiveDefenseTarget, sidebarRightWidget)

import Frontend.Style.Common (Style, componentS)

-- | Root layout for the app (full-screen row)
appRoot :: Style
appRoot = S.flexRow . S.hScreen . S.bgTransparent . S.text1 . S.overflowHidden

-- | Main content area (right of sidebar)
mainContent :: Style
mainContent = S.flexCol . S.flex1 . S.relative . S.bgTransparent . S.css "min-w-0" "min-width" "0"

appWidget :: (MonadWidget t m, Prerender t m) => T.Text -> UUID -> m ()
appWidget wsBaseUrl clientId = do
  rec -- RequesterT loop
      -- TODO: Load initial actor from local storage
      let sessionState = SessionState actorsMapDyn logsDyn phaseDyn
      (_, requests) <-
        runRequesterT (runGameT sessionState (uiWidget Nothing Nothing)) responses
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
     , Prerender t m
     , MonadGame t m
     , MonadGame t (Client m)
     )
  => Maybe StagingState
  -- ^ Optional initial staging state
  -> Maybe ActorId
  -- ^ Initial active actor
  -> m ()
uiWidget mStaging initialActorId = componentS "app-container" appRoot $ do
  rec selectedActorId <- holdDyn initialActorId (leftmost [sidebarActiveChange, mapActiveChange])
      (sidebarActiveChange, resumeDefenseEvt) <- sidebarWidget selectedActorId

      -- Main Content Area (Right)
      mapActiveChange <- componentS "main-content" mainContent $ do
        -- Top Bar / Game Board Area (Map Board Widget)
        mapChange <- mapBoardWidget selectedActorId

        actorsMapDyn <- askActors
        let activeActorMap = ffor2 selectedActorId actorsMapDyn $ \mId actors ->
              case mId >>= \aid -> identifiedLookup aid actors of
                Nothing -> Map.empty
                Just (Identified i c) -> Map.singleton i c

        _ <- listWithKey activeActorMap $ \k vDyn ->
          handWidget mStaging (Identified k <$> vDyn)

        return mapChange

  -- Right Sidebar — now returns Event t DefenseTarget from challenge clicks
  openDefenseEvt <- sidebarRightWidget selectedActorId

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
      -- an active defense. If so, we redirect to that defense (conflict detection).
      defenseTargetDyn <-
        foldDyn applyDefenseEvent Nothing $
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

      -- Render defense widget when active, routing actions to API requests
      widgetActionEvt <- dyn $
        ffor (zipDyn defenseTargetDyn (zipDyn selectedActorId actorsMapDyn)) $
          \(mTarget, (mActorId, actorsMap)) ->
            case (mTarget, mActorId, mActorId >>= \aid -> Map.lookup aid actorsMap) of
              (Just target, Just actorId, Just actorState) -> do
                let actorStateDyn = ffor actorsMapDyn $ \m ->
                      fromMaybe actorState (Map.lookup actorId m)

                actionEvt <- defenseWidget (constDyn target) actorStateDyn

                -- Route DefenseAction events to API requests
                let defenseReqs = fmapMaybe (toDefenseRequest actorId target) actionEvt
                _ <- requestGame defenseReqs

                return actionEvt
              _ -> return never

      defenseWidgetEvt <- switchHold never widgetActionEvt

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

    -- \| Apply a defense open/close event to the current state.
    applyDefenseEvent mNew _old = mNew

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
