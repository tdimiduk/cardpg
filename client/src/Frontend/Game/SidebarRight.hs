{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.SidebarRight where

import Control.Monad.Fix (MonadFix)

import Data.List (find)
import Data.Map qualified as Map
import Data.Text qualified as T
import Reflex.Dom.Core

import Api.Request (ApiRequest (..))
import Api.Types
  ( LogEntry (..)
  , LogPayload (..)
  , LogSender (..)
  )
import Core.Card (CoreCard (..), Identified (..))
import Core.NonEmptyText (getRawText)
import Core.Primitives (ActorId)
import Core.State
import Core.Stats (Stats (..))
import Core.Util (tshow)
import Frontend.Game.Class
import Frontend.Game.Defense (DefenseTarget (..))
import Frontend.Game.PhaseDisplay (phaseDisplayWidget)
import Frontend.Render.Common (IconMode (..), renderResourceType)
import Frontend.Style.Common (Style, classNames, divS, elS, testId, textGoldBright)
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout

-- | Sidebar container (Right)
sidebarRightContainer :: Style
sidebarRightContainer =
  S.shrink0
    <> S.flexCol
    <> S.w (S.Rem 20)
    <> S.cls "obsidian-panel"
    <> S.borderL
    <> S.border S.Gray 10
    <> S.hFull
    <> S.z 20

-- | Sidebar header section
sidebarHeader :: Style
sidebarHeader =
  S.p S.S4
    <> S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    <> S.borderB
    <> S.border S.Gray 10
    <> S.shrink0

-- | Log Area
logArea :: Style
logArea =
  S.flex1
    <> S.overflowYAuto
    <> S.p S.S4
    <> S.spaceY2
    <> S.css "custom-scrollbar" "scrollbar-width" "thin"

-- | Chat Input Area
chatArea :: Style
chatArea =
  S.p S.S3
    <> S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    <> S.borderT
    <> S.border S.Gray 10
    <> S.shrink0
    <> S.flex
    <> S.gap S.S2

-- | Main sidebar widget. Now returns an Event t DefenseTarget for when
-- the user clicks a challenge log entry to open the defense panel.
sidebarRightWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadGame t m
     )
  => Dynamic t (Maybe ActorId)
  -> m (Event t DefenseTarget)
sidebarRightWidget selectedActorId = do
  logsDyn <- askLogs
  actorsMapDyn <- askActors
  divS sidebarRightContainer $ do
    -- Phase Display
    phaseDisplayWidget

    -- Header
    divS sidebarHeader $ do
      row $ do
        elS "h2" (S.textXs <> S.fontBold <> S.text S.Gray 5 <> S.uppercase <> S.trackingWider) $
          text "Game Log"
        spacer
        -- Count
        elS
          "div"
          ( S.fontSize 10
              <> S.text S.Gray 6
              <> S.fontMono
          )
          $ dynText
          $ fmap (T.pack . show . length) logsDyn

    -- Logs — filter out LogDefense entries (shown inline under their challenge)
    let logAreaCls = classNames logArea
        -- Group logs: challenge entries absorb their defense logs;
        -- filter defense logs from the main list.
        groupedLogsDyn = fmap filterDefenseLogs logsDyn

    openDefenseEvt <- elAttr "div" ("class" =: logAreaCls <> testId "game-log") $ do
      -- Render each log entry, collecting any "open defense" events.
      openEvtsDyn <- simpleList groupedLogsDyn $ \logEntryDyn ->
        renderLogEntry logsDyn actorsMapDyn logEntryDyn
      return $ switchDyn (fmap leftmost openEvtsDyn)

    divS chatArea $ chatInputRequesting selectedActorId
    return openDefenseEvt

-- | Filter LogDefense entries from the main log list.
-- They are rendered inline inside their parent LogChallenge entries.
filterDefenseLogs :: [LogEntry] -> [LogEntry]
filterDefenseLogs = filter (not . isDefenseLog)
  where
    isDefenseLog entry = case entry.payload of
      LogDefense{} -> True
      _ -> False

-- | Find the most recent LogDefense entry for a given challenge ID.
findLatestDefenseLog :: [LogEntry] -> T.Text -> Maybe LogEntry
findLatestDefenseLog logs challengeIdText =
  case filter matchesChallenge logs of
    [] -> Nothing
    (latest : _) -> Just latest
  where
    matchesChallenge entry = case entry.payload of
      LogDefense{challengeId} -> tshow challengeId == challengeIdText
      _ -> False

-- | Render a single log entry. Challenge entries are clickable and return
-- an Event t DefenseTarget for opening the defense panel.
renderLogEntry
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     )
  => Dynamic t [LogEntry]
  -- ^ All logs (for finding defense logs related to challenges)
  -> Dynamic t (Map.Map ActorId ActorState)
  -- ^ Actor map (for resolving attacker names and card stacks)
  -> Dynamic t LogEntry
  -> m (Event t DefenseTarget)
renderLogEntry allLogsDyn actorsMapDyn logDyn =
  dyn (ffor (zipDyn logDyn (zipDyn allLogsDyn actorsMapDyn)) renderOneEntry)
    >>= switchHold never
  where
    renderOneEntry (logEntry, (allLogs, actorsMap)) = case logEntry.payload of
      -- Challenge entries: clickable, return DefenseTarget
      LogChallenge challenge plannedAction -> do
        let actorId = senderActorId logEntry.sender
            attackerName = senderName logEntry.sender
            -- Resolve the actual card stack from the attacker's state
            attackStack = case actorId >>= \aid -> Map.lookup aid actorsMap of
              Just _ -> plannedActionCards plannedAction
              Nothing -> []
            defenseTarget =
              DefenseTarget
                { challenge = challenge
                , attackStack = attackStack
                , attackerName = attackerName
                }
            -- Look up associated defense log for inline display
            mDefenseLog = findLatestDefenseLog allLogs (tshow challenge.id)

        challengeLogItem defenseTarget mDefenseLog

      -- Defense entries: rendered inline, skip here
      LogDefense{} ->
        return never
      -- Info entries
      LogInfo c -> do
        divS
          ( S.textXs
              <> S.text S.Gray 5
              <> S.italic
              <> S.p S.S2
              <> S.borderB
              <> S.border S.Gray 10
          )
          $ text c
        return never

      -- Chat entries
      LogChat c -> do
        let chatStyle =
              S.bgAlpha S.Gray 10 50
                <> S.rounded
                <> S.p S.S2
                <> S.css "animate-fade-in" "animation" "fadeIn 0.2s"
                <> S.flex
                <> S.gap S.S2
        let chatCls = classNames chatStyle
        elAttr
          "div"
          ( "class" =: chatCls
              <> testId "log-entry-chat"
          )
          $ do
            elS
              "div"
              ( S.w S.S6
                  <> S.h S.S6
                  <> S.roundedFull
                  <> S.bg S.Gray 9
                  <> S.flex
                  <> S.itemsCenter
                  <> S.justifyCenter
                  <> S.shrink0
              )
              $ text "Bot"
            divS S.flex1 $ do
              elS
                "div"
                ( S.fontSize 10
                    <> S.fontBold
                    <> S.text S.Gray 5
                    <> S.mb S.S0
                )
                $ text (renderSender logEntry.sender)
              let msgCls = classNames (S.textSm <> S.text S.Gray 2)
              elAttr "div" ("class" =: msgCls <> testId "log-entry-message") $
                text c
        return never

      -- Error entries
      LogError c -> do
        divS
          ( S.textXs
              <> S.textWhite
              <> S.bgAlpha S.Red 11 50
              <> S.fontBold
              <> S.p S.S2
              <> S.borderB
              <> S.border S.Red 10
          )
          $ text c
        return never

-- | Render a clickable challenge log entry.
-- Shows the attack details and any associated defense summary inline.
-- Returns Event that fires with DefenseTarget when clicked.
challengeLogItem
  :: (DomBuilder t m, PostBuild t m)
  => DefenseTarget
  -> Maybe LogEntry
  -> m (Event t DefenseTarget)
challengeLogItem defenseTarget mDefenseLog = do
  let challenge = defenseTarget.challenge

  -- Challenge container — clickable, styled as a red-accented dark stone slab
  let challengeStyle =
        S.bgAlpha S.Red 12 30
          <> S.border1
          <> S.borderAlpha S.Red 9 50
          <> S.rounded
          <> S.p S.S3
          <> S.mb S.S2
          <> S.css "animate-fade-in" "animation" "fadeIn 0.2s"
          <> S.cursorPointer
          <> S.hover (S.bgAlpha S.Red 12 50)
          <> S.css "transition-colors" "transition-property" "background-color"
          <> S.relative

  (container, _) <- elAttr' "div" ("class" =: classNames challengeStyle <> testId "challenge-log-item") $ do
    -- Header
    divS (S.flex <> S.justifyBetween <> S.itemsCenter <> S.mb S.S1) $ do
      divS (S.textXs <> S.fontBold <> S.text S.Red 3 <> S.flex <> S.itemsCenter <> S.gap S.S1) $ do
        divS
          ( S.w S.S3
              <> S.h S.S3
              <> S.bg S.Red 6
              <> S.roundedFull
          )
          blank
        text "Challenge Action"

    -- Power + color
    divS
      ( S.flex
          <> S.itemsCenter
          <> S.gap S.S2
          <> S.textSm
          <> S.bgAlpha S.Black 12 40
          <> S.rounded
          <> S.p S.S1
          <> S.mb S.S1
      )
      $ do
        elS "span" (S.fontBold <> S.text S.Red 5) $
          text ("Power: " <> tshow challenge.challengeStrength)
        renderResourceType IconInline challenge.challengeColor Nothing

    -- Attacker name
    divS (S.textXs <> S.text S.Gray 4 <> S.mb S.S1) $
      text ("By: " <> defenseTarget.attackerName)

    -- Inline defense summary (if there is one)
    maybe blank renderInlineDefenseSummary mDefenseLog

    -- Hover hint
    divS
      ( S.textXs
          <> S.text S.Gray 6
          <> S.css "text-right" "text-align" "right"
          <> S.opacity50
          <> S.hover S.opacity75
      )
      $ text "Click to Defend"

  return (defenseTarget <$ domEvent Click container)

-- | Inline defense summary shown inside a challenge log entry.
renderInlineDefenseSummary
  :: (DomBuilder t m, PostBuild t m)
  => LogEntry
  -> m ()
renderInlineDefenseSummary defLog = case defLog.payload of
  LogDefense{details = mDetails, cards = mCards, ended} -> do
    let defenseLineStyle =
          S.mt S.S2
            <> S.pt S.S2
            <> S.borderT
            <> S.borderAlpha S.Red 9 30

    divS defenseLineStyle $ do
      divS (S.flex <> S.justifyBetween <> S.itemsCenter <> S.mb S.S1) $ do
        divS (S.textXs <> S.fontBold <> S.text S.Blue 3 <> S.flex <> S.itemsCenter <> S.gap S.S1) $
          text (if ended then "Defense Result" else "Defending...")
        -- Color totals
        case mDetails of
          Just details ->
            divS
              ( S.flex
                  <> S.gap S.S2
                  <> S.fontMono
                  <> S.fontSize 10
              )
              $ do
                elS "span" (S.text S.Red 4) $ text ("R:" <> tshow details.values.red)
                elS "span" (S.text S.Yellow 4) $ text ("Y:" <> tshow details.values.yellow)
                elS "span" (S.text S.Blue 4) $ text ("B:" <> tshow details.values.blue)
          Nothing -> blank

      -- Defense card chips
      case mCards of
        Just cards
          | not (null cards) ->
              divS (S.flex <> S.flexWrap <> S.gap S.S1 <> S.mt S.S1) $
                mapM_
                  ( \(Identified _ cardContent) ->
                      elS
                        "span"
                        ( S.textXs
                            <> S.bgAlpha S.Blue 12 50
                            <> S.text S.Blue 2
                            <> S.px S.S1
                            <> S.py S.S0_5
                            <> S.rounded
                            <> S.borderAlpha S.Blue 9 30
                        )
                        $ text (getRawText cardContent.name)
                  )
                  cards
        _ -> blank

      -- Impact summary (when ended)
      case (ended, mDetails) of
        (True, Just details) ->
          divS
            (S.flex <> S.gap S.S3 <> S.mt S.S2 <> S.textXs <> S.bgAlpha S.Black 12 20 <> S.p S.S1 <> S.rounded)
            $ do
              divS (S.text S.Gray 3) $ do
                text "Impact: "
                elS "span" (S.textWhite <> S.fontBold) $ text (tshow details.impact)
              divS (S.text S.Gray 3) $ do
                text "Cons: "
                elS "span" (S.textWhite <> S.fontBold) $ text (tshow details.consequencesFromDefense)
        _ -> blank
  _ -> blank

chatInputRequesting
  :: (DomBuilder t m, PostBuild t m, MonadFix m, MonadHold t m, MonadGame t m)
  => Dynamic t (Maybe ActorId) -> m ()
chatInputRequesting selectedActorId = do
  let classListCls = classNames classList
  rec input <-
        inputElement $
          def
            & initialAttributes
            .~ mconcat
              [ "placeholder" =: "Type a message..."
              , "class" =: classListCls
              , Map.mapKeys (AttributeName Nothing) (testId "chat-input")
              ]
            & inputElementConfig_setValue
            .~ ("" <$ success)

      let submit = keypress Enter input
      let send = current (value input) <@ submit

      -- Send Button
      let btnCls = classNames btnStyle
      (btn, _) <-
        elAttr'
          "button"
          ( "class" =: btnCls
              <> testId "chat-send"
          )
          $ text ">"

      let clickSend = current (value input) <@ domEvent Click btn

      let msgEvt = leftmost [send, clickSend]
      r <- requestGame $ attachWith SendChat (current selectedActorId) msgEvt
      let (err, success) = fanEither r
  widgetHold_ blank $ text . tshow <$> err
  pure ()
  where
    classList =
      S.flex1
        <> S.css "bg-stone-med" "background-color" "var(--color-stone-med)"
        <> S.border1
        <> S.border S.Gray 10
        <> S.rounded
        <> S.px S.S3
        <> S.p S.S2
        <> S.textXs
        <> S.textWhite
        <> S.css "focus:outline-none" "outline" "none"
        <> S.pseudo "focus" (S.border S.Yellow 5)

    btnStyle =
      S.bg S.Yellow 5
        <> S.hover (S.bg S.Yellow 4)
        <> S.textBlack
        <> S.p S.S2
        <> S.rounded
        <> S.fontBold
        <> S.cls "fantasy-font"

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

senderActorId :: LogSender -> Maybe ActorId
senderActorId (SenderActor aid _) = Just aid
senderActorId _ = Nothing

senderName :: LogSender -> T.Text
senderName = renderSender

renderSender :: LogSender -> T.Text
renderSender SenderSystem = "System"
renderSender SenderGame = "Game"
renderSender SenderGM = "GM"
renderSender SenderEnvironment = "Environment"
renderSender (SenderActor _ name) = name

-- | Reconstruct the active defense target from the actor state and logs history.
reconstructDefenseTarget
  :: [LogEntry] -> Map.Map ActorId ActorState -> ActorState -> Maybe DefenseTarget
reconstructDefenseTarget history actorsMap actorState = do
  activeDef <- actorState.coreState.defending
  let challengeId = activeDef.activeChallenge.id
      -- Find the challenge log entry in history
      mLogEntry =
        find
          ( \le -> case le.payload of
              LogChallenge chal _ -> chal.id == challengeId
              _ -> False
          )
          history
  case mLogEntry of
    Just (LogEntry{sender = sender, payload = LogChallenge challenge plannedAction}) ->
      let actorId = senderActorId sender
          attackerName = senderName sender
          attackStack = case actorId >>= \aid -> Map.lookup aid actorsMap of
            Just _ -> plannedActionCards plannedAction
            Nothing -> []
       in Just
            DefenseTarget
              { challenge = challenge
              , attackStack = attackStack
              , attackerName = attackerName
              }
    _ ->
      -- Fallback if log not found in history yet (e.g., edge case or state sync)
      Just
        DefenseTarget
          { challenge = activeDef.activeChallenge
          , attackStack = []
          , attackerName = "Unknown Attacker"
          }

-- | Helper to get the active defense target for a given actor ID, actors map, and logs history.
getActiveDefenseTarget
  :: Maybe ActorId -> Map.Map ActorId ActorState -> [LogEntry] -> Maybe DefenseTarget
getActiveDefenseTarget mActorId actorsMap history = do
  actorId <- mActorId
  actorState <- Map.lookup actorId actorsMap
  reconstructDefenseTarget history actorsMap actorState
