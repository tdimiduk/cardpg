{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TupleSections #-}

module Frontend.App (appWidget, headWidget, uiWidget) where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map
import Data.Maybe (fromMaybe, isJust)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Data.UUID.Types (UUID)
import Data.UUID.Types qualified as UUID
import Frontend.Editor (editorWidget)
import Frontend.Style.DSL qualified as S
import Frontend.Util (widgetHoldE)
import Reflex.Dom.Core hiding (button)
import Reflex.Dom.GadtApi.WebSocket (TaggedResponse, tagRequests)

import Api.Reflex (ClientInfo (..), GameView (..), ServerPush (..), WsMessage (..))
import Api.Request qualified as Req
import Api.Types (ClientRole (..), LogEntry, Phase (..))
import Core.Primitives (ActorId (..), Identified (..))
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
import Language.Javascript.JSaddle (eval, liftJSM, valToText)

import Frontend.Game.Planning (StagingState)
import Frontend.Game.Sidebar (ViewMode (..), sidebarWidget)
import Frontend.Game.SidebarRight (getActiveDefenseTarget, sidebarRightWidget)

import Frontend.Style.Common (Style, classNames, componentS, divS, elS, textGoldBright)
import Frontend.UI.Button

-- | Root layout for the app (full-screen row)
appRoot :: Style
appRoot = S.flexRow <> S.hScreen <> S.bgTransparent <> S.text1 <> S.overflowHidden

-- | Main content area (right of sidebar)
mainContent :: Style
mainContent = S.flexCol <> S.flex1 <> S.relative <> S.bgTransparent <> S.css "min-w-0" "min-width" "0"

appWidget :: (MonadWidget t m, Prerender t m) => T.Text -> m ()
appWidget wsBaseUrl = do
  profileDyn <- prerender (pure Nothing) $ liftJSM $ do
    cidVal <-
      eval
        ( "(function() { \
          \ var id = localStorage.getItem('cardpg_client_id'); \
          \ if (!id) { \
          \   id = typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : \
          \     'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) { \
          \       var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8); \
          \       return v.toString(16); \
          \     }); \
          \   localStorage.setItem('cardpg_client_id', id); \
          \ } \
          \ return id; \
          \})()"
            :: String
        )
    cidStr <- valToText cidVal

    nameVal <- eval ("localStorage.getItem('cardpg_client_name') || ''" :: String)
    nameStr <- valToText nameVal

    roleVal <- eval ("localStorage.getItem('cardpg_client_role') || ''" :: String)
    roleStr <- valToText roleVal

    let mCid = UUID.fromText cidStr
        role =
          if
            | roleStr == "GM" -> RoleGM
            | "player:" `T.isPrefixOf` roleStr ->
                case UUID.fromText (T.drop 7 roleStr) of
                  Just rId -> RolePlayer (ActorId rId)
                  Nothing -> RoleUnassigned
            | otherwise -> RoleUnassigned

    case mCid of
      Nothing -> return Nothing
      Just clientId -> return $ Just (clientId, if T.null nameStr then Nothing else Just nameStr, role)

  pb <- getPostBuild
  let clientReadyEvt = fmapMaybe id $ leftmost [current profileDyn <@ pb, updated profileDyn]
  _ <- widgetHold (divS (S.p S.S4 <> S.textCenter <> S.text S.Gray 5) (text "Loading Profile...")) $ ffor clientReadyEvt $ \(clientId, mName, initialRole) -> do
    (identityUpdateEvt, triggerIdentityUpdate) <- newTriggerEvent
    identityDyn <- holdDyn (fmap (,initialRole) mName) identityUpdateEvt

    (openEvt, triggerOpen) <- newTriggerEvent

    performEvent_ $ ffor (updated identityDyn) $ \case
      Nothing -> liftJSM $ do
        _ <- eval ("localStorage.removeItem('cardpg_client_name')" :: String)
        _ <- eval ("localStorage.removeItem('cardpg_client_role')" :: String)
        pure ()
      Just (name, role) -> liftJSM $ do
        _ <- eval ("localStorage.setItem('cardpg_client_name', " <> show name <> ")" :: String)
        let roleStr = case role of
              RoleGM -> "GM"
              RoleUnassigned -> "unassigned"
              RolePlayer (ActorId uuid) -> "player:" <> show uuid
        _ <- eval ("localStorage.setItem('cardpg_client_role', " <> show roleStr <> ")" :: String)
        pure ()

    rec let wsUrl = wsBaseUrl <> "?clientId=" <> T.pack (show clientId)
            reqsEncoded = fmap (map (decodeUtf8 . BL.toStrict . encode)) taggedReqs
        (wsOpenEvt, pushEvt, taggedResps) <- connectWebSocket wsUrl reqsEncoded

        sessionState <- makeSessionState pushEvt identityDyn

        (_, requests) <-
          runRequesterT
            (runGameT sessionState (appMainWidget mName initialRole triggerIdentityUpdate openEvt identityDyn))
            responses
        (taggedReqs, responses) <- tagRequests requests taggedResps

    prerender_ (pure ()) $ do
      performEvent_ $ ffor wsOpenEvt $ \_ -> do
        liftIO $ triggerOpen ()
    pure ()
  pure ()

appMainWidget
  :: (GameWidgetIO t m)
  => Maybe Text
  -> ClientRole
  -> (Maybe (Text, ClientRole) -> IO ())
  -> Event t ()
  -> Dynamic t (Maybe (Text, ClientRole))
  -> m ()
appMainWidget initialName initialRole triggerIdentityUpdate openEvt identityDyn = do
  actorsMapDyn <- askActors
  activeClientsDyn <- askActiveClients

  -- Auto-sync profile when identity changes or connection is established
  let welcomeSyncEvt = attach (current identityDyn) openEvt
      syncDataEvt =
        leftmost
          [ fmapMaybe fst welcomeSyncEvt
          , fmapMaybe id (updated identityDyn)
          ]
      joinReq = fmap (\(name, _) -> Req.Join name) syncDataEvt
      roleReq = fmap (\(_, role) -> Req.SetRole role) syncDataEvt

  _ <- requestGame joinReq
  _ <- requestGame roleReq

  let widgetSelector = ffor identityDyn $ \case
        Nothing -> do
          submitEvt <- setupOverlayWidget actorsMapDyn activeClientsDyn
          prerender_ (pure ()) $ do
            performEvent_ $ ffor submitEvt $ \mIdent -> do
              liftIO $ triggerIdentityUpdate mIdent
        Just (_, role) -> do
          let initialActor = case role of
                RolePlayer actorId -> Just actorId
                _ -> Nothing
          uiWidget Nothing initialActor triggerIdentityUpdate identityDyn

  _ <- dyn widgetSelector
  pure ()

-- | Establishes the WebSocket connection and decodes messages into Push/Response events.
connectWebSocket
  :: (MonadWidget t m)
  => T.Text
  -> Event t [T.Text]
  -> m (Event t (), Event t ServerPush, Event t TaggedResponse)
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

  pure (_webSocket_open ws, pushEvt, taggedResps)

-- | Constructs the session state by folding incoming server push events.
makeSessionState
  :: (Reflex t, MonadHold t m, MonadFix m)
  => Event t ServerPush
  -> Dynamic t (Maybe (Text, ClientRole))
  -> m (SessionState t)
makeSessionState pushEvt identityDyn = do
  let gameEvt =
        fmapMaybe
          (\case PushWelcome{game = g} -> Just g; PushUpdate{game = g} -> Just g; _ -> Nothing)
          pushEvt
  actorsMapDyn <- holdDyn Map.empty (fmap (.actors) gameEvt)
  logsDyn <-
    foldDyn
      (flip ++)
      []
      ( leftmost
          [ fmapMaybe (\case PushWelcome{history = h} -> Just h; _ -> Nothing) pushEvt
          , fmapMaybe (\case PushNewLogs l -> Just l; _ -> Nothing) pushEvt
          ]
      )
  phaseDyn <-
    holdDyn
      Planning
      ( leftmost
          [ fmapMaybe (\case PushWelcome{phase = p} -> Just p; _ -> Nothing) pushEvt
          , fmapMaybe (\case PushUpdate{newPhase = Just p} -> Just p; _ -> Nothing) pushEvt
          ]
      )
  mapModeDyn <- holdDyn MapModeGrid (fmap (fromMaybe MapModeGrid . (.mapMode)) gameEvt)
  activeClientsDyn <- holdDyn Map.empty (fmap (.activeClients) gameEvt)
  pure $ SessionState actorsMapDyn logsDyn phaseDyn mapModeDyn activeClientsDyn identityDyn

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
  -> (Maybe (Text, ClientRole) -> IO ())
  -- ^ Trigger callback
  -> Dynamic t (Maybe (Text, ClientRole))
  -- ^ Identity dynamic
  -> m ()
uiWidget mStaging initialActorId triggerIdentityUpdate identityDyn = componentS "app-container" (S.flexCol <> S.hScreen <> S.overflowHidden) $ do
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
              sidebarWidget selectedActorId currentViewModeDyn triggerIdentityUpdate identityDyn
            mapActiveChange <- mainContentWidget mStaging selectedActorId currentViewModeDyn identityDyn

        -- Right Sidebar — now returns Event t DefenseTarget from challenge clicks
        let effectiveSelectedActorIdDyn =
              zipDynWith
                ( \mIdent userSel ->
                    case mIdent of
                      Just (_, RolePlayer claimedActorId) -> Just claimedActorId
                      _ -> userSel
                )
                identityDyn
                selectedActorId
        openDefenseEvt <- sidebarRightWidget effectiveSelectedActorIdDyn identityDyn

        -- Render defense modal overlay and handle defense actions
        defenseModalWidget initialActorId effectiveSelectedActorIdDyn resumeDefenseEvt openDefenseEvt

        return viewModeUserEvt'
  pure ()

setupOverlayWidget
  :: forall t m
   . (GameWidget t m, Prerender t m)
  => Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Map.Map UUID ClientInfo)
  -> m (Event t (Maybe (Text, ClientRole)))
setupOverlayWidget actorsMapDyn activeClientsDyn = componentS
  "setup-overlay"
  ( S.flexCol
      <> S.itemsCenter
      <> S.justifyCenter
      <> S.hScreen
      <> S.wFull
      <> S.css "bg-slate-950" "background-color" "#020617"
  )
  $ do
    divS
      ( S.cls "obsidian-panel"
          <> S.p S.S8
          <> S.roundedS (S.Px 8)
          <> S.border1
          <> S.border S.Yellow 10
          <> S.w (S.Px 450)
          <> S.flexCol
          <> S.gap S.S6
          <> S.css "backdrop-blur-md" "backdrop-filter" "blur(12px)"
          <> S.css "bg-opacity-80" "background-color" "rgba(15, 23, 42, 0.8)"
      )
      $ do
        elS "h1" (S.text2Xl <> S.fontBold <> S.textCenter <> S.cls "fantasy-font" <> textGoldBright) $
          text "CardPG - Enter Scenario"

        divS (S.flexCol <> S.gap S.S2) $ do
          elS "label" (S.textXs <> S.fontBold <> S.text S.Gray 4 <> S.uppercase <> S.trackingWider) $
            text "Display Name"
          nameInput <-
            inputElement $
              def & initialAttributes .~ ("placeholder" =: "Your name..." <> "class" =: classNames inputStyle)
          let nameValDyn = _inputElement_value nameInput

          elS
            "label"
            (S.textXs <> S.fontBold <> S.text S.Gray 4 <> S.uppercase <> S.trackingWider <> S.mt S.S2)
            $ text "Choose Your Identity"

          rec selectedRoleDyn <- holdDyn RoleUnassigned roleSelectEvt
              gmClick <-
                roleCard
                  "Game Master"
                  "Control monsters, advance rounds, and edit scenario."
                  (constDyn RoleGM)
                  selectedRoleDyn
                  (constDyn False)

              elS "div" (S.textXs <> S.text S.Gray 5 <> S.mt S.S2 <> S.cls "fantasy-font") $
                text "Available Characters"

              let pcsDyn = fmap (Map.filter (\as -> as.actorType == "PC")) actorsMapDyn
              pcClicks <- listWithKey pcsDyn $ \aid actorDyn -> do
                let isClaimedDyn = ffor2 activeClientsDyn actorDyn $ \clients actor ->
                      let matches = Map.filter (\c -> c.role == RolePlayer aid) clients
                       in if Map.null matches
                            then Nothing
                            else Just (head (Map.elems matches)).name
                    isDisabledDyn = fmap isJust isClaimedDyn
                    claimTextDyn = ffor isClaimedDyn $ \case
                      Nothing -> "Click to claim character"
                      Just cName -> "Claimed by " <> cName
                nameDyn <- holdUniqDyn $ fmap (.name) actorDyn
                click <- roleCard nameDyn claimTextDyn (constDyn (RolePlayer aid)) selectedRoleDyn isDisabledDyn
                return (RolePlayer aid <$ click)

              let pcClickEvt = switchDyn (leftmost . Map.elems <$> pcClicks)
                  roleSelectEvt = leftmost [RoleGM <$ gmClick, pcClickEvt]

          let isSubmitDisabledDyn = ffor2 nameValDyn selectedRoleDyn $ \name role ->
                T.null (T.strip name) || role == RoleUnassigned

          btnClick <-
            button
              (def :: ButtonConfig t)
                { variant = VariantPrimary
                , fullWidth = True
                , disabled = isSubmitDisabledDyn
                , extraStyle = S.mt S.S4
                }
              $ text "Begin Adventure"

          let submitEvt = current ((,) <$> nameValDyn <*> selectedRoleDyn) <@ btnClick
          return $ Just <$> submitEvt
  where
    inputStyle =
      S.wFull
        <> S.css "bg-slate-900" "background-color" "#0f172a"
        <> S.border1
        <> S.border S.Gray 10
        <> S.rounded
        <> S.px S.S3
        <> S.py S.S2
        <> S.textSm
        <> S.textWhite
        <> S.css "focus:outline-none" "outline" "none"
        <> S.pseudo "focus" (S.border S.Yellow 5)

roleCard
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m)
  => Dynamic t Text
  -> Dynamic t Text
  -> Dynamic t ClientRole
  -> Dynamic t ClientRole
  -> Dynamic t Bool
  -> m (Event t ())
roleCard titleDyn descDyn cardRoleDyn selectedRoleDyn isDisabledDyn = do
  let isSelectedDyn = (==) <$> cardRoleDyn <*> selectedRoleDyn
      cardStyleDyn = ffor3 isSelectedDyn isDisabledDyn cardRoleDyn $ \isSelected isDisabled role ->
        let base =
              S.wFull
                <> S.p S.S3
                <> S.rounded
                <> S.border1
                <> S.flexCol
                <> S.gap S.S1
                <> S.relative

            stateStyle =
              if
                | isDisabled ->
                    S.css "bg-slate-900" "background-color" "#0f172a"
                      <> S.css "border-slate-800" "border-color" "#1e293b"
                      <> S.opacity50
                      <> S.css "cursor-not-allowed" "cursor" "not-allowed"
                | isSelected ->
                    S.css "bg-slate-800" "background-color" "#1e293b"
                      <> S.border S.Yellow 5
                      <> S.css "shadow-yellow" "box-shadow" "0 0 10px rgba(250,204,21,0.2)"
                      <> S.cursorPointer
                | otherwise ->
                    S.css "bg-slate-900" "background-color" "#0f172a"
                      <> S.border S.Gray 10
                      <> S.hover (S.css "bg-slate-800" "background-color" "#1e293b")
                      <> S.cursorPointer
         in base <> stateStyle

  (cardEl, _) <- elDynAttr' "div" (ffor cardStyleDyn $ \s -> "class" =: classNames s) $ do
    elS "div" (S.fontBold <> S.textSm <> S.textWhite) $ dynText titleDyn
    elS "div" (S.fontSize 10 <> S.text S.Gray 5) $ dynText descDyn

  let clickEvt = domEvent Click cardEl
  return $ gate (not <$> current isDisabledDyn) clickEvt

-- | Interactive map board and hand widget feedback loop.
mapWidget
  :: (GameWidgetIO t m)
  => Maybe StagingState
  -> Dynamic t (Maybe ActorId)
  -> m (Event t (Maybe ActorId))
mapWidget mStaging selectedActorId = do
  rec (mapChange, rankMoveClickEvt) <- mapBoardWidget selectedActorId stagingStateDyn rankMoveStagingDyn

      actorsMapDyn <- askActors
      pb <- getPostBuild
      let welcomeArrivalEvt = Control.Monad.void (ffilter (not . Map.null) (updated actorsMapDyn))
          triggerEvt =
            attach (current actorsMapDyn) $
              leftmost
                [ updated selectedActorId
                , current selectedActorId <@ welcomeArrivalEvt
                , current selectedActorId <@ pb
                ]
      handWidgetResDyn <- widgetHold (return (constDyn Nothing, constDyn Nothing)) $ ffor triggerEvt $ \(actorsMap, mId) ->
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
  -> Dynamic t (Maybe (Text, ClientRole))
  -> m (Event t (Maybe ActorId))
mainContentWidget mStaging selectedActorId currentViewModeDyn identityDyn = componentS "main-content" mainContent $ do
  let effectiveSelectedActorIdDyn =
        zipDynWith
          ( \mIdent userSel ->
              case mIdent of
                Just (_, RolePlayer claimedActorId) -> Just claimedActorId
                _ -> userSel
          )
          identityDyn
          selectedActorId
      mapWidgetBranch = mapWidget mStaging effectiveSelectedActorIdDyn
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
