{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Frontend.Game.ExplorationBoard
  ( explorationBoardWidget
  , renderExplorationBoard
  , renderExplorationBoardWithWorld
  ) where

import Control.Monad (forM_, unless, when)
import Control.Monad.Fix (MonadFix)
import Data.Char (toUpper)
import Data.Functor (void)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust, isNothing)
import Data.Text (Text)
import Data.Text qualified as T
import Reflex.Dom.Core hiding (button)

import Api.Request qualified as Req
import Api.Types (ClientRole (..))
import Core.Card.Exploration
  ( ActionScope (..)
  , ChallengeDef (..)
  , ClockDeckId (..)
  , ClockEffect (..)
  , ExitStatus (..)
  , ExplorationAction (..)
  , LocationCard (..)
  , LocationExit (..)
  , LocationId (..)
  , SetExitStatus (..)
  , TravelCard (..)
  , TravelExpedients (..)
  , TravelId (..)
  , TravelRoute (..)
  )
import Core.Keyword (keywordToText)
import Core.NonEmptyText (getRawText)
import Core.Primitives (ActorId)
import Core.RichText ()
import Core.State
  ( ActiveClockEffect (..)
  , ActorState (..)
  , CoreCardState (..)
  , Direction (..)
  , ExplorationFocus (..)
  , ExplorationIntent (..)
  , LocationRuntimeState (..)
  , PlannedAction (..)
  , WorldState (..)
  , isActorPC
  )
import Core.Stats (ResourceType (..))
import Core.Time
  ( Duration (..)
  , ExpeditionTime (..)
  , TimeUnit (..)
  , formatExpeditionTime
  , toMinutes
  )
import Core.Util (tshow)
import Frontend.Game.Class
  ( GameWidget
  , askActors
  , askIdentity
  , askWorldState
  , requestGame
  )
import Frontend.Render.Rules (renderRichText)
import Frontend.Style.Common
  ( Style
  , classNames
  , componentS
  , divS
  , elS
  , textCrimsonLight
  , textEmerald
  , textGoldBright
  , textGoldMuted
  )
import Frontend.Style.DSL qualified as S

--------------------------------------------------------------------------------
-- Styles
--------------------------------------------------------------------------------

boardOuterStyle :: Style
boardOuterStyle =
  S.relative
    <> S.flex1
    <> S.minW0
    <> S.minH0
    <> S.css "overflow-y" "overflow-y" "auto"
    <> S.p S.S6
    <> S.flexCol
    <> S.itemsCenter
    <> S.css "bg-board-outer" "background-color" "#0f172a"
    <> S.selectNone

panelStyle :: Style
panelStyle =
  S.cls "obsidian-panel"
    <> S.wFull
    <> S.css "max-w-4xl" "max-width" "960px"
    <> S.flexCol
    <> S.gap S.S6
    <> S.p S.S6
    <> S.roundedLg
    <> S.border1
    <> S.border S.Gray 9
    <> S.bg S.Gray 12
    <> S.shadowLg

headerStyle :: Style
headerStyle =
  S.flexCol
    <> S.gap S.S2
    <> S.wFull
    <> S.borderB
    <> S.border S.Gray 10
    <> S.pb S.S4

titleStyle :: Style
titleStyle =
  S.text2Xl
    <> S.fontBold
    <> textGoldBright
    <> S.cls "fantasy-font"
    <> S.trackingWider

metaBadgeStyle :: Style
metaBadgeStyle =
  S.px S.S2
    <> S.py S.S1
    <> S.rounded
    <> S.textXs
    <> S.fontBold
    <> S.trackingWider
    <> S.border1

tagBadgeStyle :: Style
tagBadgeStyle =
  S.px S.S2
    <> S.py S.S1
    <> S.rounded
    <> S.textXs
    <> S.bg S.Gray 11
    <> S.border1
    <> S.border S.Gray 9
    <> textGoldMuted

activeEffectBannerStyle :: Style
activeEffectBannerStyle =
  S.flexCol
    <> S.gap S.S1
    <> S.p S.S3
    <> S.rounded
    <> S.border1
    <> S.border S.Red 6
    <> S.bg S.Red 12
    <> S.textSm

sensoryBoxStyle :: Style
sensoryBoxStyle =
  S.p S.S4
    <> S.rounded
    <> S.borderL4
    <> S.border S.Yellow 8
    <> S.bg S.Gray 11
    <> S.css "font-italic" "font-style" "italic"
    <> S.textSm
    <> S.text S.Gray 3
    <> S.leadingRelaxed

sectionHeadingStyle :: Style
sectionHeadingStyle =
  S.textSm
    <> S.fontBold
    <> textGoldMuted
    <> S.trackingWider
    <> S.uppercase

sectionSubtitleStyle :: Style
sectionSubtitleStyle =
  S.textXs
    <> S.text S.Gray 5

actionCardStyle :: Style
actionCardStyle =
  S.flexCol
    <> S.gap S.S3
    <> S.p S.S4
    <> S.rounded
    <> S.border1
    <> S.border S.Gray 9
    <> S.bg S.Gray 11
    <> S.hover (S.border S.Yellow 7)

scopeBadgeStyle :: ActionScope -> Style
scopeBadgeStyle ScopeSolo =
  S.px S.S2 <> S.py S.S1 <> S.rounded <> S.textXs <> S.fontBold <> S.bg S.Gray 9 <> S.text S.Gray 2
scopeBadgeStyle ScopeTeamwork =
  S.px S.S2 <> S.py S.S1 <> S.rounded <> S.textXs <> S.fontBold <> S.bg S.Blue 9 <> S.text S.Blue 2
scopeBadgeStyle ScopeEveryone =
  S.px S.S2
    <> S.py S.S1
    <> S.rounded
    <> S.textXs
    <> S.fontBold
    <> S.bg S.Purple 9
    <> S.text S.Purple 2

resourceColorStyle :: ResourceType -> Style
resourceColorStyle Red = textCrimsonLight <> S.fontBold
resourceColorStyle Yellow = textGoldBright <> S.fontBold
resourceColorStyle Blue = S.text S.Blue 4 <> S.fontBold

exitCardStyle :: Style
exitCardStyle =
  S.flexRow
    <> S.itemsCenter
    <> S.justifyBetween
    <> S.gap S.S4
    <> S.p S.S3
    <> S.rounded
    <> S.border1
    <> S.border S.Gray 9
    <> S.bg S.Gray 11
    <> S.hover (S.border S.Yellow 7)

btnActionStyle :: Bool -> Style
btnActionStyle isPlanned =
  S.px S.S3
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> S.textXs
    <> S.fontBold
    <> S.cursorPointer
    <> if isPlanned
      then S.border S.Amber 5 <> S.bg S.Amber 12 <> textGoldBright
      else
        S.border S.Gray 9 <> S.bg S.Gray 12 <> textGoldMuted <> S.hover (S.bg S.Gray 9 <> textGoldBright)

btnDisabledStyle :: Style
btnDisabledStyle =
  S.px S.S3
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> S.border S.Gray 10
    <> S.bg S.Gray 12
    <> S.textXs
    <> S.text S.Gray 6
    <> S.cursorNotAllowed

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

formatDuration :: Duration -> Text
formatDuration (Duration v Minute) = tshow v <> "m"
formatDuration (Duration v Hour) = tshow v <> "h"
formatDuration (Duration v Day) = tshow v <> "d"

formatTimePerImpact :: Duration -> Text
formatTimePerImpact d = "+" <> formatDuration d <> " / flip"

formatDeckName :: Text -> Text
formatDeckName t =
  case T.uncons t of
    Nothing -> t
    Just (c, rest) -> T.singleton (toUpper c) <> rest

isActionLoud :: ExplorationAction -> Bool
isActionLoud act =
  isJust act.interrupt
    || maybe False (any (\t -> T.toUpper t == "LOUD") . NE.toList) act.tags

findPlanners :: (ExplorationIntent -> Bool) -> Map.Map ActorId ActorState -> [Text]
findPlanners predicate actorsMap =
  [ actor.name
  | actor <- Map.elems actorsMap
  , isActorPC actor
  , case actor.coreState.planned of
      Just (PExploration intent) -> predicate intent
      _ -> False
  ]

renderPlannersList :: (DomBuilder t m, PostBuild t m) => Dynamic t [Text] -> m ()
renderPlannersList plannersDyn = do
  dyn_ $ ffor plannersDyn $ \planners ->
    unless (null planners) $ do
      divS (S.flexRow <> S.flexWrap <> S.itemsCenter <> S.gap S.S2 <> S.mt S.S1) $ do
        elS "span" (S.textXs <> S.text S.Gray 5) $ text "Planning:"
        forM_ planners $ \pName -> do
          divS
            ( S.flexRow
                <> S.itemsCenter
                <> S.gap S.S1
                <> S.px S.S2
                <> S.py (S.Px 2)
                <> S.roundedFull
                <> S.border1
                <> S.border S.Yellow 8
                <> S.bg S.Yellow 12
                <> S.textXs
                <> textGoldBright
            )
            $ do
              elS "span" S.textXs $ text "👤"
              text pName

--------------------------------------------------------------------------------
-- Main Exploration Board Widget
--------------------------------------------------------------------------------

-- | High-level container querying SessionState from MonadGame.
explorationBoardWidget
  :: (GameWidget t m)
  => Dynamic t (Maybe ActorId)
  -> m ()
explorationBoardWidget selectedActorIdDyn = do
  worldStateDyn <- askWorldState
  actorsMapDyn <- askActors
  identityDyn <- askIdentity
  renderExplorationBoard worldStateDyn actorsMapDyn identityDyn selectedActorIdDyn

-- | Top-level render switching on Maybe WorldState.
renderExplorationBoard
  :: forall t m
   . (GameWidget t m)
  => Dynamic t (Maybe WorldState)
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe (Text, ClientRole))
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderExplorationBoard worldStateDyn actorsMapDyn identityDyn selectedActorIdDyn =
  componentS "exploration-board" boardOuterStyle $ do
    initialWs <- sample (current worldStateDyn)
    _ <-
      widgetHold
        (renderBranch initialWs)
        (renderBranch <$> updated worldStateDyn)
    pure ()
  where
    renderBranch Nothing =
      divS (panelStyle <> S.itemsCenter <> S.justifyCenter <> S.py S.S12) $ do
        elAttr
          "div"
          ("data-testid" =: "exploration-empty" <> "class" =: classNames (S.textSm <> S.text S.Gray 5))
          $ text "No active exploration module loaded. Select or enter a scenario."
    renderBranch (Just ws) = do
      let wsDyn = fmap (fromMaybe ws) worldStateDyn
      renderExplorationBoardWithWorld wsDyn actorsMapDyn identityDyn selectedActorIdDyn

-- | Render when WorldState is present, switching on ExplorationFocus.
renderExplorationBoardWithWorld
  :: forall t m
   . (GameWidget t m)
  => Dynamic t WorldState
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe (Text, ClientRole))
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderExplorationBoardWithWorld wsDyn actorsMapDyn identityDyn selectedActorIdDyn = do
  -- Resolve effective acting PC
  let effectiveActorIdDyn =
        zipDynWith
          ( \mIdent userSel ->
              case mIdent of
                Just (_, RolePlayer claimedId) -> Just claimedId
                _ -> userSel
          )
          identityDyn
          selectedActorIdDyn

  let focusDyn = (.focus) <$> wsDyn
  initialFocus <- sample (current focusDyn)
  _ <-
    widgetHold
      (renderFocus initialFocus wsDyn actorsMapDyn effectiveActorIdDyn)
      ( ffor (updated focusDyn) $ \f ->
          renderFocus f wsDyn actorsMapDyn effectiveActorIdDyn
      )
  pure ()
  where
    renderFocus focus wsD actorsD effectiveAidD = case focus of
      AtLocation locId -> renderLocationBoard locId wsD actorsD effectiveAidD
      OnTravel trvId dir -> renderTravelBoard trvId dir wsD actorsD effectiveAidD

--------------------------------------------------------------------------------
-- Location Board Rendering
--------------------------------------------------------------------------------

renderLocationBoard
  :: forall t m
   . (GameWidget t m)
  => LocationId
  -> Dynamic t WorldState
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderLocationBoard locId wsDyn actorsMapDyn effectiveActorIdDyn = do
  initialWs <- sample (current wsDyn)
  case Map.lookup locId initialWs.locations of
    Nothing ->
      divS panelStyle $ do
        elAttr "div" ("data-testid" =: "exploration-empty") $
          text ("Location not found in module manifest: " <> locId.unLocationId)
    Just loc -> divS panelStyle $ do
      -- 1. Header with Title, Deck Origin, Tags, and Active Timed Effects
      renderLocationHeader loc wsDyn

      -- 2. Narrative Sensory Box
      divS (sensoryBoxStyle <> S.wFull) $ do
        elAttr "div" ("data-testid" =: "exploration-sensory-box") $
          renderRichText loc.narrative

      -- 3. Actions Section
      renderLocationActions loc wsDyn actorsMapDyn effectiveActorIdDyn

      -- 4. Exits Section
      renderLocationExits loc wsDyn actorsMapDyn effectiveActorIdDyn

      -- 5. Footer Quick Controls (Pass / Wait)
      renderPassFooter actorsMapDyn effectiveActorIdDyn

renderLocationHeader
  :: forall t m
   . (DomBuilder t m, PostBuild t m, MonadHold t m)
  => LocationCard
  -> Dynamic t WorldState
  -> m ()
renderLocationHeader loc wsDyn = divS (headerStyle <> S.wFull) $ do
  elAttr
    "div"
    ("data-testid" =: "exploration-header" <> "class" =: classNames (S.flexCol <> S.gap S.S2))
    $ do
      -- Badges row
      divS (S.flexRow <> S.itemsCenter <> S.justifyBetween <> S.wFull) $ do
        divS (S.flexRow <> S.itemsCenter <> S.gap S.S2) $ do
          divS (metaBadgeStyle <> S.border S.Green 8 <> S.bg S.Green 12 <> textEmerald) $
            text "LOCATION"
          case loc.governingClock of
            Nothing -> pure ()
            Just cid ->
              divS (metaBadgeStyle <> S.border S.Red 8 <> S.bg S.Red 12 <> S.text S.Red 3) $
                text ("CLOCK: " <> formatDeckName cid.unClockDeckId)

        -- Base Time
        divS (S.flexRow <> S.itemsCenter <> S.gap S.S1 <> S.textXs <> textGoldMuted) $ do
          text ("Base Time: " <> formatDuration loc.baseTime)

      -- Title
      elAttr "h2" ("data-testid" =: "exploration-title" <> "class" =: classNames titleStyle) $
        text (getRawText loc.name)

      -- Environmental & Narrative Tags
      elAttr
        "div"
        ("data-testid" =: "exploration-tags" <> "class" =: classNames (S.flexRow <> S.flexWrap <> S.gap S.S2))
        $ do
          case loc.tags of
            Nothing -> pure ()
            Just tagsList ->
              forM_ (NE.toList tagsList) $ \t ->
                elAttr "span" ("data-testid" =: ("tag-" <> t) <> "class" =: classNames tagBadgeStyle) $
                  text ("#" <> t)

      -- Active Clock Effects Banners
      let activeEffectsDyn = ffor wsDyn $ \ws ->
            let mLocState = Map.lookup loc.id ws.locationStates
             in maybe [] ((.activeEffects)) mLocState
          currentMinuteDyn = ffor wsDyn (\ws -> let ExpeditionTime m = ws.time in m)

      dyn_ $ ffor2 activeEffectsDyn currentMinuteDyn $ \effects curMin ->
        unless (null effects) $ do
          elAttr
            "div"
            ( "data-testid" =: "active-clock-effects"
                <> "class" =: classNames (S.flexCol <> S.gap S.S2 <> S.mt S.S2)
            )
            $ do
              forM_ effects $ \actEff -> do
                let eff = actEff.effect
                    remMin = fmap (\expMin -> max 0 (expMin - curMin)) actEff.expiresAtMinute
                    timeTxt = case remMin of
                      Nothing -> "(Permanent until resolved)"
                      Just m -> "(Expires in " <> tshow m <> "m)"
                divS activeEffectBannerStyle $ do
                  elAttr
                    "div"
                    ( "data-testid" =: ("clock-effect-" <> eff.target)
                        <> "class" =: classNames (S.flexRow <> S.itemsCenter <> S.justifyBetween)
                    )
                    $ do
                      elS "span" (S.fontBold <> S.text S.Red 2) $
                        text ("⚠️ " <> eff.target <> " " <> timeTxt)
                  divS (S.textXs <> S.text S.Gray 3) $
                    renderRichText eff.text

                  -- Warnings
                  when eff.extinguishesLight $
                    elS "span" (S.textXs <> S.fontBold <> S.text S.Amber 4) $
                      text "🔥 Snuffs out unguarded flames!"
                  case eff.setExitStatus of
                    Just (SetExitStatus eId ExitBlocked) ->
                      elS "span" (S.textXs <> S.fontBold <> S.text S.Red 4) $
                        text ("⛔ Passage to " <> eId.unLocationId <> " is blocked!")
                    _ -> pure ()
                  case eff.spawnActors of
                    Just spawns
                      | not (null spawns) ->
                          elS "span" (S.textXs <> S.fontBold <> textCrimsonLight) $
                            text ("⚔️ Hostile threats lurking: " <> T.intercalate ", " spawns)
                    _ -> pure ()

--------------------------------------------------------------------------------
-- Actions Rendering
--------------------------------------------------------------------------------

renderLocationActions
  :: forall t m
   . (GameWidget t m)
  => LocationCard
  -> Dynamic t WorldState
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderLocationActions loc wsDyn actorsMapDyn effectiveActorIdDyn = do
  let actions = fromMaybe [] loc.actions
  divS (S.flexCol <> S.gap S.S3 <> S.wFull) $ do
    divS (S.flexCol <> S.gap S.S1) $ do
      elS "h3" sectionHeadingStyle $ text "Available Actions"
      elS "p" sectionSubtitleStyle $
        text
          "Party members plan intents simultaneously. Challenges measure caloric work, time, and exhaustion."

    elAttr
      "div"
      ( "data-testid" =: "exploration-actions-section"
          <> "class" =: classNames (S.flexCol <> S.gap S.S3 <> S.wFull)
      )
      $ do
        if null actions
          then
            divS (S.p S.S4 <> S.textCenter <> S.text S.Gray 6 <> S.textSm) $ text "No specific actions here."
          else forM_ (zip [0 ..] actions) $ \(idx, act) ->
            renderActionCard idx act wsDyn actorsMapDyn effectiveActorIdDyn

renderActionCard
  :: forall t m
   . (GameWidget t m)
  => Int
  -> ExplorationAction
  -> Dynamic t WorldState
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderActionCard idx act _wsDyn actorsMapDyn effectiveActorIdDyn = do
  elAttr
    "div"
    ("data-testid" =: ("action-card-" <> tshow idx) <> "class" =: classNames actionCardStyle)
    $ do
      -- Row 1: Header (Name + Scope + Challenge + Time + Loud)
      divS (S.flexRow <> S.itemsCenter <> S.justifyBetween <> S.wFull) $ do
        divS (S.flexRow <> S.itemsCenter <> S.gap S.S2) $ do
          elS "span" (S.fontBold <> S.textSm <> textGoldBright) $
            text (getRawText act.name)
          -- Scope badge
          elAttr
            "span"
            ("data-testid" =: "action-scope-badge" <> "class" =: classNames (scopeBadgeStyle act.scope))
            $ text
              (case act.scope of ScopeSolo -> "Solo"; ScopeTeamwork -> "Teamwork"; ScopeEveryone -> "Everyone")

        -- Badges group: Challenge, Time, Loud
        divS (S.flexRow <> S.itemsCenter <> S.gap S.S2) $ do
          case act.challenge of
            Nothing -> pure ()
            Just cDef -> do
              elAttr
                "span"
                ( "data-testid" =: "action-challenge-badge"
                    <> "class"
                      =: classNames
                        ( S.px S.S2
                            <> S.py S.S1
                            <> S.rounded
                            <> S.textXs
                            <> S.bg S.Gray 12
                            <> S.border1
                            <> S.border S.Gray 9
                            <> resourceColorStyle cDef.color
                        )
                )
                $ do
                  text (tshow cDef.color <> " " <> tshow cDef.strength)
                  case cDef.consequences of
                    Just csqs -> text (" (" <> T.intercalate ", " (fmap keywordToText (NE.toList csqs)) <> ")")
                    Nothing -> pure ()

          -- Time badge
          elAttr
            "span"
            ( "data-testid" =: "action-time-badge"
                <> "class"
                  =: classNames
                    ( S.px S.S2
                        <> S.py S.S1
                        <> S.rounded
                        <> S.textXs
                        <> S.bg S.Gray 12
                        <> S.border1
                        <> S.border S.Gray 9
                        <> textGoldMuted
                    )
            )
            $ do
              text ("⏱️ " <> formatDuration act.time)
              case act.timePerImpact of
                Just imp -> text (" " <> formatTimePerImpact imp)
                Nothing -> pure ()

          -- Loud badge
          when (isActionLoud act)
            $ elAttr
              "span"
              ( "data-testid" =: "action-loud-badge"
                  <> "class"
                    =: classNames
                      ( S.px S.S2
                          <> S.py S.S1
                          <> S.rounded
                          <> S.textXs
                          <> S.fontBold
                          <> S.bg S.Amber 12
                          <> S.border1
                          <> S.border S.Amber 7
                          <> S.text S.Amber 3
                      )
              )
            $ text "⚠️ [LOUD]"

      -- Row 2: Narrative if present
      case act.narrative of
        Nothing -> pure ()
        Just nar ->
          divS (S.textXs <> S.text S.Gray 4 <> S.leadingRelaxed) $
            renderRichText nar

      -- Row 3: Planners List and Plan Button
      divS
        ( S.flexRow
            <> S.itemsCenter
            <> S.justifyBetween
            <> S.wFull
            <> S.pt S.S2
            <> S.borderT
            <> S.border S.Gray 10
        )
        $ do
          let plannersDyn = ffor actorsMapDyn $ \actors ->
                findPlanners (\case IntentAction i -> i == idx; _ -> False) actors
          elAttr "div" ("data-testid" =: ("action-planners-" <> tshow idx)) $
            renderPlannersList plannersDyn

          -- Plan / Cancel Button
          let isPlannedByMeDyn = ffor2 actorsMapDyn effectiveActorIdDyn $ \actors mAid ->
                case mAid >>= (`Map.lookup` actors) of
                  Just actor -> case actor.coreState.planned of
                    Just (PExploration (IntentAction i)) -> i == idx
                    _ -> False
                  Nothing -> False

              btnDisabledDyn = isNothing <$> effectiveActorIdDyn
              btnLabelDyn = ffor isPlannedByMeDyn $ \isPlanned ->
                if isPlanned then "Cancel Intent" else "Plan Action"
              btnStyleDyn = ffor2 isPlannedByMeDyn btnDisabledDyn $ \isPlanned isDisabled ->
                if isDisabled then btnDisabledStyle else btnActionStyle isPlanned

          (btnEl, _) <-
            elDynAttr'
              "button"
              ( ffor3 btnStyleDyn btnLabelDyn btnDisabledDyn $ \s _lbl isDisabled ->
                  "class" =: classNames s
                    <> "data-testid" =: ("action-plan-btn-" <> tshow idx)
                    <> (if isDisabled then "disabled" =: "disabled" else Map.empty)
              )
              $ dynText btnLabelDyn

          let clickEvt = domEvent Click btnEl
              planEvt =
                attachWithMaybe
                  ( \(mAid, isPlanned) () -> do
                      aid <- mAid
                      let intent = if isPlanned then IntentPass else IntentAction idx
                      pure (Req.PlanExplorationIntent aid intent)
                  )
                  (current (zipDyn effectiveActorIdDyn isPlannedByMeDyn))
                  clickEvt

          _ <- requestGame planEvt
          pure ()

--------------------------------------------------------------------------------
-- Exits Rendering
--------------------------------------------------------------------------------

renderLocationExits
  :: forall t m
   . (GameWidget t m)
  => LocationCard
  -> Dynamic t WorldState
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderLocationExits loc wsDyn actorsMapDyn effectiveActorIdDyn = do
  let exits = fromMaybe [] loc.exits
  divS (S.flexCol <> S.gap S.S3 <> S.wFull) $ do
    divS (S.flexCol <> S.gap S.S1) $ do
      elS "h3" sectionHeadingStyle $ text "Exits & Passages"
      elS "p" sectionSubtitleStyle $
        text "Traversing open passages advances expedition time and moves the party or begins a travel leg."

    elAttr
      "div"
      ( "data-testid" =: "exploration-exits-section"
          <> "class" =: classNames (S.flexCol <> S.gap S.S3 <> S.wFull)
      )
      $ do
        if null exits
          then divS (S.p S.S4 <> S.textCenter <> S.text S.Gray 6 <> S.textSm) $ text "No obvious exits."
          else forM_ exits $ \exit ->
            renderExitRow loc.id exit wsDyn actorsMapDyn effectiveActorIdDyn

renderExitRow
  :: forall t m
   . (GameWidget t m)
  => LocationId
  -> LocationExit
  -> Dynamic t WorldState
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderExitRow fromLocId exit wsDyn actorsMapDyn effectiveActorIdDyn = do
  let destLocId = exit.to
  elAttr
    "div"
    ("data-testid" =: ("exit-card-" <> destLocId.unLocationId) <> "class" =: classNames exitCardStyle)
    $ do
      -- Destination & Passage Information
      divS (S.flexCol <> S.gap S.S1) $ do
        divS (S.flexRow <> S.itemsCenter <> S.gap S.S2) $ do
          -- Destination Name
          let destNameDyn = ffor wsDyn $ \ws ->
                case Map.lookup destLocId ws.locations of
                  Just destCard -> getRawText destCard.name
                  Nothing -> destLocId.unLocationId
          elS "span" (S.fontBold <> S.textSm <> textGoldBright) $
            dynText destNameDyn

          -- Via Travel badge if route exists
          case exit.viaTravel of
            Nothing -> pure ()
            Just trvId ->
              divS (metaBadgeStyle <> S.border S.Blue 8 <> S.bg S.Blue 12 <> S.text S.Blue 3) $
                text ("via " <> trvId.unTravelId)

          -- Dynamic Status badge (ExitOpen vs ExitBlocked)
          let actualStatusDyn = ffor wsDyn $ \ws ->
                let mLocState = Map.lookup fromLocId ws.locationStates
                 in fromMaybe exit.status (mLocState >>= Map.lookup destLocId . (.exitStatuses))
          dyn_ $ ffor actualStatusDyn $ \case
            ExitOpen ->
              elAttr
                "span"
                ( "data-testid" =: "exit-status-badge"
                    <> "class" =: classNames (metaBadgeStyle <> S.border S.Green 8 <> S.bg S.Green 12 <> textEmerald)
                )
                $ text "🟢 Open"
            ExitBlocked ->
              elAttr
                "span"
                ( "data-testid" =: "exit-status-badge"
                    <> "class" =: classNames (metaBadgeStyle <> S.border S.Red 8 <> S.bg S.Red 12 <> S.text S.Red 3)
                )
                $ text "⛔ Blocked"

        -- Passage sensory note
        case exit.passage of
          Nothing -> pure ()
          Just p ->
            divS (S.textXs <> S.text S.Gray 4 <> S.leadingRelaxed) $
              renderRichText p

        -- Planners list
        let plannersDyn = ffor actorsMapDyn $ \actors ->
              findPlanners (\case IntentTraverseExit dest -> dest == destLocId; _ -> False) actors
        elAttr "div" ("data-testid" =: ("exit-planners-" <> destLocId.unLocationId)) $
          renderPlannersList plannersDyn

      -- Traversal Button
      let actualStatusDyn = ffor wsDyn $ \ws ->
            let mLocState = Map.lookup fromLocId ws.locationStates
             in fromMaybe exit.status (mLocState >>= Map.lookup destLocId . (.exitStatuses))

          isTraversingDyn = ffor2 actorsMapDyn effectiveActorIdDyn $ \actors mAid ->
            case mAid >>= (`Map.lookup` actors) of
              Just actor -> case actor.coreState.planned of
                Just (PExploration (IntentTraverseExit dest)) -> dest == destLocId
                _ -> False
              Nothing -> False

          btnDisabledDyn = ffor2 actualStatusDyn effectiveActorIdDyn $ \status mAid ->
            status == ExitBlocked || isNothing mAid

          btnLabelDyn = ffor2 actualStatusDyn isTraversingDyn $ \status isTrav ->
            if status == ExitBlocked
              then "Passage Blocked"
              else
                if isTrav
                  then "Cancel Traversal"
                  else "Plan Traversal"

          btnStyleDyn = ffor2 isTraversingDyn btnDisabledDyn $ \isTrav isDisabled ->
            if isDisabled then btnDisabledStyle else btnActionStyle isTrav

      (btnEl, _) <-
        elDynAttr'
          "button"
          ( ffor3 btnStyleDyn btnLabelDyn btnDisabledDyn $ \s _lbl isDisabled ->
              "class" =: classNames s
                <> "data-testid" =: ("exit-traverse-btn-" <> destLocId.unLocationId)
                <> (if isDisabled then "disabled" =: "disabled" else Map.empty)
          )
          $ dynText btnLabelDyn

      let clickEvt = domEvent Click btnEl
          traverseEvt =
            attachWithMaybe
              ( \(mAid, isTrav, status) () -> do
                  aid <- mAid
                  if status == ExitBlocked
                    then Nothing
                    else do
                      let intent = if isTrav then IntentPass else IntentTraverseExit destLocId
                      pure (Req.PlanExplorationIntent aid intent)
              )
              (current ((,,) <$> effectiveActorIdDyn <*> isTraversingDyn <*> actualStatusDyn))
              clickEvt

      _ <- requestGame traverseEvt
      pure ()

--------------------------------------------------------------------------------
-- Travel Board Rendering
--------------------------------------------------------------------------------

renderTravelBoard
  :: forall t m
   . (GameWidget t m)
  => TravelId
  -> Direction
  -> Dynamic t WorldState
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderTravelBoard trvId dir wsDyn actorsMapDyn effectiveActorIdDyn = do
  initialWs <- sample (current wsDyn)
  case Map.lookup trvId initialWs.travelCards of
    Nothing ->
      divS panelStyle $ do
        elAttr "div" ("data-testid" =: "exploration-empty") $
          text ("Travel card not found in module manifest: " <> trvId.unTravelId)
    Just trv -> divS panelStyle $ do
      -- 1. Header with Route, Heading, Distance, Tags
      renderTravelHeader trv dir wsDyn

      -- 2. Narrative Sensory Box
      divS (sensoryBoxStyle <> S.wFull) $ do
        elAttr "div" ("data-testid" =: "exploration-sensory-box") $
          renderRichText trv.narrative

      -- 3. Travel Paces
      renderTravelPaces trv wsDyn actorsMapDyn effectiveActorIdDyn

      -- 4. Expedients & Camp Restrictions if present
      forM_ trv.expedients renderTravelExpedients

      -- 5. Footer Quick Controls (Pass / Wait)
      renderPassFooter actorsMapDyn effectiveActorIdDyn

renderTravelHeader
  :: forall t m
   . (DomBuilder t m, PostBuild t m, MonadHold t m)
  => TravelCard
  -> Direction
  -> Dynamic t WorldState
  -> m ()
renderTravelHeader trv dir _wsDyn = divS (headerStyle <> S.wFull) $ do
  elAttr
    "div"
    ("data-testid" =: "exploration-header" <> "class" =: classNames (S.flexCol <> S.gap S.S2))
    $ do
      -- Badges row
      divS (S.flexRow <> S.itemsCenter <> S.justifyBetween <> S.wFull) $ do
        divS (S.flexRow <> S.itemsCenter <> S.gap S.S2) $ do
          divS (metaBadgeStyle <> S.border S.Blue 8 <> S.bg S.Blue 12 <> S.text S.Blue 3) $
            text "TRAVEL ROUTE"
          case trv.governingClock of
            Nothing -> pure ()
            Just cid ->
              divS (metaBadgeStyle <> S.border S.Red 8 <> S.bg S.Red 12 <> S.text S.Red 3) $
                text ("CLOCK: " <> formatDeckName cid.unClockDeckId)

        -- Base Time & Distance
        divS (S.flexRow <> S.itemsCenter <> S.gap S.S2 <> S.textXs <> textGoldMuted) $ do
          case trv.route.distanceLeagues of
            Just d -> text (tshow d <> " leagues • ")
            Nothing -> pure ()
          text ("Base Time: " <> formatDuration trv.route.baseTime)

      -- Title & Heading
      divS (S.flexRow <> S.itemsCenter <> S.gap S.S3) $ do
        elAttr "h2" ("data-testid" =: "exploration-title" <> "class" =: classNames titleStyle) $
          text (getRawText trv.name)
        elS "span" (S.textXs <> S.fontBold <> textGoldMuted) $
          text (trv.route.from.unLocationId <> " ➔ " <> trv.route.to.unLocationId <> " (" <> tshow dir <> ")")

      -- Tags (General + Terrain)
      elAttr
        "div"
        ("data-testid" =: "exploration-tags" <> "class" =: classNames (S.flexRow <> S.flexWrap <> S.gap S.S2))
        $ do
          case trv.tags of
            Nothing -> pure ()
            Just tagsList ->
              forM_ (NE.toList tagsList) $ \t ->
                elAttr "span" ("data-testid" =: ("tag-" <> t) <> "class" =: classNames tagBadgeStyle) $
                  text ("#" <> t)
          case trv.route.terrainTags of
            Nothing -> pure ()
            Just terrTags ->
              forM_ (NE.toList terrTags) $ \t ->
                elAttr
                  "span"
                  ("data-testid" =: ("tag-" <> t) <> "class" =: classNames (tagBadgeStyle <> S.border S.Blue 8))
                  $ text ("🌲 " <> t)

renderTravelPaces
  :: forall t m
   . (GameWidget t m)
  => TravelCard
  -> Dynamic t WorldState
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderTravelPaces trv wsDyn actorsMapDyn effectiveActorIdDyn = do
  let paces = NE.toList trv.paces
  divS (S.flexCol <> S.gap S.S3 <> S.wFull) $ do
    divS (S.flexCol <> S.gap S.S1) $ do
      elS "h3" sectionHeadingStyle $ text "Travel Paces"
      elS "p" sectionSubtitleStyle $
        text "Marching paces determine overland travel speed, caloric work, and exhaustion risks."

    elAttr
      "div"
      ( "data-testid" =: "exploration-actions-section"
          <> "class" =: classNames (S.flexCol <> S.gap S.S3 <> S.wFull)
      )
      $ do
        forM_ (zip [0 ..] paces) $ \(idx, pace) ->
          renderPaceCard idx pace wsDyn actorsMapDyn effectiveActorIdDyn

renderPaceCard
  :: forall t m
   . (GameWidget t m)
  => Int
  -> ExplorationAction
  -> Dynamic t WorldState
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderPaceCard idx pace _wsDyn actorsMapDyn effectiveActorIdDyn = do
  elAttr
    "div"
    ("data-testid" =: ("action-card-" <> tshow idx) <> "class" =: classNames actionCardStyle)
    $ do
      -- Row 1: Header
      divS (S.flexRow <> S.itemsCenter <> S.justifyBetween <> S.wFull) $ do
        divS (S.flexRow <> S.itemsCenter <> S.gap S.S2) $ do
          elS "span" (S.fontBold <> S.textSm <> textGoldBright) $
            text (getRawText pace.name)
          elAttr
            "span"
            ("data-testid" =: "action-scope-badge" <> "class" =: classNames (scopeBadgeStyle pace.scope))
            $ text
              (case pace.scope of ScopeSolo -> "Solo"; ScopeTeamwork -> "Teamwork"; ScopeEveryone -> "Everyone")

        divS (S.flexRow <> S.itemsCenter <> S.gap S.S2) $ do
          case pace.challenge of
            Nothing -> pure ()
            Just cDef -> do
              elAttr
                "span"
                ( "data-testid" =: "action-challenge-badge"
                    <> "class"
                      =: classNames
                        ( S.px S.S2
                            <> S.py S.S1
                            <> S.rounded
                            <> S.textXs
                            <> S.bg S.Gray 12
                            <> S.border1
                            <> S.border S.Gray 9
                            <> resourceColorStyle cDef.color
                        )
                )
                $ do
                  text (tshow cDef.color <> " " <> tshow cDef.strength)
                  case cDef.consequences of
                    Just csqs -> text (" (" <> T.intercalate ", " (fmap keywordToText (NE.toList csqs)) <> ")")
                    Nothing -> pure ()

          -- Time badge
          elAttr
            "span"
            ( "data-testid" =: "action-time-badge"
                <> "class"
                  =: classNames
                    ( S.px S.S2
                        <> S.py S.S1
                        <> S.rounded
                        <> S.textXs
                        <> S.bg S.Gray 12
                        <> S.border1
                        <> S.border S.Gray 9
                        <> textGoldMuted
                    )
            )
            $ do
              text ("⏱️ " <> formatDuration pace.time)
              case pace.timePerImpact of
                Just imp -> text (" " <> formatTimePerImpact imp)
                Nothing -> pure ()

          -- Loud badge
          when (isActionLoud pace)
            $ elAttr
              "span"
              ( "data-testid" =: "action-loud-badge"
                  <> "class"
                    =: classNames
                      ( S.px S.S2
                          <> S.py S.S1
                          <> S.rounded
                          <> S.textXs
                          <> S.fontBold
                          <> S.bg S.Amber 12
                          <> S.border1
                          <> S.border S.Amber 7
                          <> S.text S.Amber 3
                      )
              )
            $ text "⚠️ [LOUD]"

      -- Row 2: Narrative if present
      case pace.narrative of
        Nothing -> pure ()
        Just nar ->
          divS (S.textXs <> S.text S.Gray 4 <> S.leadingRelaxed) $
            renderRichText nar

      -- Row 3: Planners & Plan Button
      divS
        ( S.flexRow
            <> S.itemsCenter
            <> S.justifyBetween
            <> S.wFull
            <> S.pt S.S2
            <> S.borderT
            <> S.border S.Gray 10
        )
        $ do
          let plannersDyn = ffor actorsMapDyn $ \actors ->
                findPlanners (\case IntentPace i -> i == idx; _ -> False) actors
          elAttr "div" ("data-testid" =: ("action-planners-" <> tshow idx)) $
            renderPlannersList plannersDyn

          -- Plan / Cancel Button
          let isPlannedByMeDyn = ffor2 actorsMapDyn effectiveActorIdDyn $ \actors mAid ->
                case mAid >>= (`Map.lookup` actors) of
                  Just actor -> case actor.coreState.planned of
                    Just (PExploration (IntentPace i)) -> i == idx
                    _ -> False
                  Nothing -> False

              btnDisabledDyn = isNothing <$> effectiveActorIdDyn
              btnLabelDyn = ffor isPlannedByMeDyn $ \isPlanned ->
                if isPlanned then "Cancel Pace" else "Plan Pace"
              btnStyleDyn = ffor2 isPlannedByMeDyn btnDisabledDyn $ \isPlanned isDisabled ->
                if isDisabled then btnDisabledStyle else btnActionStyle isPlanned

          (btnEl, _) <-
            elDynAttr'
              "button"
              ( ffor3 btnStyleDyn btnLabelDyn btnDisabledDyn $ \s _lbl isDisabled ->
                  "class" =: classNames s
                    <> "data-testid" =: ("action-plan-btn-" <> tshow idx)
                    <> (if isDisabled then "disabled" =: "disabled" else Map.empty)
              )
              $ dynText btnLabelDyn

          let clickEvt = domEvent Click btnEl
              planEvt =
                attachWithMaybe
                  ( \(mAid, isPlanned) () -> do
                      aid <- mAid
                      let intent = if isPlanned then IntentPass else IntentPace idx
                      pure (Req.PlanExplorationIntent aid intent)
                  )
                  (current (zipDyn effectiveActorIdDyn isPlannedByMeDyn))
                  clickEvt

          _ <- requestGame planEvt
          pure ()

renderTravelExpedients :: (DomBuilder t m) => TravelExpedients -> m ()
renderTravelExpedients expeds = do
  case expeds.campRestriction of
    Nothing -> pure ()
    Just restr ->
      divS
        ( S.p S.S3
            <> S.rounded
            <> S.border1
            <> S.border S.Amber 8
            <> S.bg S.Amber 12
            <> S.textXs
            <> S.text S.Amber 3
        )
        $ text ("⛺ Camp Restriction: " <> restr)

--------------------------------------------------------------------------------
-- Pass / Wait Footer Bar
--------------------------------------------------------------------------------

renderPassFooter
  :: forall t m
   . (GameWidget t m)
  => Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t (Maybe ActorId)
  -> m ()
renderPassFooter actorsMapDyn effectiveActorIdDyn = do
  divS
    ( S.flexRow
        <> S.itemsCenter
        <> S.justifyBetween
        <> S.wFull
        <> S.pt S.S4
        <> S.borderT
        <> S.border S.Gray 10
    )
    $ do
      divS (S.textXs <> S.text S.Gray 5) $
        text "Need to wait while others resolve actions or keep watch? Declare Pass / Wait."

      let isPassingDyn = ffor2 actorsMapDyn effectiveActorIdDyn $ \actors mAid ->
            case mAid >>= (`Map.lookup` actors) of
              Just actor -> case actor.coreState.planned of
                Just (PExploration IntentPass) -> True
                _ -> False
              Nothing -> False

          btnDisabledDyn = isNothing <$> effectiveActorIdDyn
          passBtnLabelDyn = ffor isPassingDyn $ \isPassing ->
            if isPassing then "Waiting / Passing Step (Active)" else "Wait / Pass Step"
          passBtnStyleDyn = ffor2 isPassingDyn btnDisabledDyn $ \isPassing isDisabled ->
            if isDisabled then btnDisabledStyle else btnActionStyle isPassing

      (btnEl, _) <-
        elDynAttr'
          "button"
          ( ffor3 passBtnStyleDyn passBtnLabelDyn btnDisabledDyn $ \s _lbl isDisabled ->
              "class" =: classNames s
                <> "data-testid" =: "exploration-pass-btn"
                <> (if isDisabled then "disabled" =: "disabled" else Map.empty)
          )
          $ dynText passBtnLabelDyn

      let clickEvt = domEvent Click btnEl
          passEvt =
            attachWithMaybe
              (\mAid () -> Req.PlanExplorationIntent <$> mAid <*> pure IntentPass)
              (current effectiveActorIdDyn)
              clickEvt

      _ <- requestGame passEvt
      pure ()
