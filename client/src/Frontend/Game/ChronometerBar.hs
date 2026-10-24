{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Frontend.Game.ChronometerBar
  ( chronometerBarWidget
  , renderBar
  , clockEventRevealModal
  ) where

import Control.Monad (forM, forM_, unless, when)
import Control.Monad.Fix (MonadFix)
import Data.Char (toUpper)
import Data.Functor (void)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, isJust, listToMaybe)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Reflex.Dom.Core hiding (button)

import Api.Request qualified as Req
import Api.Types (ClientRole (..), PlayMode (..))
import Core.Card.Exploration
  ( ClockDeckId (..)
  , ClockEffect (..)
  , ClockEventCard (..)
  , ClockNarrative (..)
  , ClockUrgency (..)
  , LocationId (..)
  , SetExitStatus (..)
  )
import Core.DSL (toText)
import Core.NonEmptyText (getRawText)
import Core.RichText ()
import Core.State
  ( ClockDeckState (..)
  , LightSourceState (..)
  , WorldState (..)
  )
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
  , askIdentity
  , askPlayMode
  , askWorldState
  , requestGame
  )
import Frontend.Icons (iconClose)
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

barOuterStyle :: Style
barOuterStyle =
  S.wFull
    <> S.cls "obsidian-panel"
    <> S.bg S.Gray 11
    <> S.borderB
    <> S.border S.Gray 10
    <> S.z 20
    <> S.shrink0

barRowStyle :: Style
barRowStyle =
  S.flexRow
    <> S.itemsCenter
    <> S.justifyBetween
    <> S.px S.S4
    <> S.py S.S2
    <> S.gap S.S4
    <> S.wFull

sectionGroupStyle :: Style
sectionGroupStyle =
  S.flexRow
    <> S.itemsCenter
    <> S.gap S.S3

chronoBadgeStyle :: Style
chronoBadgeStyle =
  S.flexRow
    <> S.itemsCenter
    <> S.gap S.S2
    <> S.px S.S3
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> S.border S.Gray 9
    <> S.bg S.Gray 12

chronoLabelStyle :: Style
chronoLabelStyle =
  S.textXs
    <> S.fontBold
    <> textGoldMuted
    <> S.trackingWider

chronoTimeStyle :: Style
chronoTimeStyle =
  S.textSm
    <> S.fontBold
    <> textGoldBright
    <> S.cls "fantasy-font"

lightBadgeStyle :: Bool -> Style
lightBadgeStyle isLow =
  S.flexRow
    <> S.itemsCenter
    <> S.gap S.S1
    <> S.px S.S2
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> (if isLow then S.border S.Amber 5 <> S.bg S.Amber 12 else S.border S.Gray 9 <> S.bg S.Gray 12)
    <> S.textXs

clockPillStyle :: Bool -> Style
clockPillStyle isWarning =
  S.flexRow
    <> S.itemsCenter
    <> S.gap S.S2
    <> S.px S.S3
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> (if isWarning then S.border S.Red 5 <> S.bg S.Red 12 else S.border S.Gray 9 <> S.bg S.Gray 12)
    <> S.cursorPointer
    <> S.hover (S.border S.Yellow 5)

progressTrackStyle :: Style
progressTrackStyle =
  S.w (S.Px 48)
    <> S.h (S.Px 6)
    <> S.bg S.Gray 9
    <> S.rounded
    <> S.overflowHidden

progressBarFillStyle :: Int -> Style
progressBarFillStyle pct =
  S.hFull
    <> (if pct >= 100 then S.bg S.Red 5 else S.bg S.Yellow 5)
    <> S.css ("w-pct-" <> tshow pct) "width" (tshow pct <> "%")

modeBadgeStyle :: PlayMode -> Style
modeBadgeStyle ModeExploration =
  S.px S.S2
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> S.border S.Green 6
    <> S.bg S.Green 12
    <> textEmerald
    <> S.textXs
    <> S.fontBold
    <> S.trackingWider
modeBadgeStyle ModeCrisis =
  S.px S.S2
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> S.border S.Red 6
    <> S.bg S.Red 12
    <> textCrimsonLight
    <> S.textXs
    <> S.fontBold
    <> S.trackingWider

gmDrawerStyle :: Style
gmDrawerStyle =
  S.flexCol
    <> S.gap S.S2
    <> S.px S.S4
    <> S.py S.S3
    <> S.bg S.Gray 12
    <> S.borderT
    <> S.border S.Gray 10

modalOverlayStyle :: Style
modalOverlayStyle =
  S.fixed
    <> S.inset0
    <> S.z 50
    <> S.flex
    <> S.itemsCenter
    <> S.justifyCenter
    <> S.p S.S4
    <> S.css "bg-black-60" "background-color" "rgba(0, 0, 0, 0.75)"
    <> S.css "backdrop-blur-sm" "backdrop-filter" "blur(4px)"

modalPanelStyle :: Style
modalPanelStyle =
  S.relative
    <> S.flexCol
    <> S.wFull
    <> S.css "max-w-xl" "max-width" "36rem"
    <> S.cls "obsidian-panel"
    <> S.bg S.Gray 11
    <> S.border1
    <> S.border S.Yellow 8
    <> S.roundedS (S.Px 8)
    <> S.css "shadow-2xl" "box-shadow" "0 25px 50px -12px rgba(0, 0, 0, 0.8)"
    <> S.overflowHidden

urgencyBadgeStyle :: ClockUrgency -> Style
urgencyBadgeStyle Immediate =
  S.px S.S2
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> S.border S.Red 5
    <> S.bg S.Red 11
    <> S.text S.Red 2
    <> S.fontBold
    <> S.textXs
    <> S.uppercase
    <> S.trackingWider
urgencyBadgeStyle OngoingModifier =
  S.px S.S2
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> S.border S.Amber 5
    <> S.bg S.Amber 11
    <> S.text S.Amber 2
    <> S.fontBold
    <> S.textXs
    <> S.uppercase
    <> S.trackingWider
urgencyBadgeStyle TelegraphedPortent =
  S.px S.S2
    <> S.py S.S1
    <> S.rounded
    <> S.border1
    <> S.border S.Indigo 5
    <> S.bg S.Indigo 11
    <> S.text S.Indigo 2
    <> S.fontBold
    <> S.textXs
    <> S.uppercase
    <> S.trackingWider

--------------------------------------------------------------------------------
-- Main Chronometer Bar Widget
--------------------------------------------------------------------------------

-- | Top banner widget displaying expedition time, active light source fuel,
-- living clock deck progress pills, GM controls, and reactive clock reveal overlay.
chronometerBarWidget
  :: forall t m
   . (GameWidget t m)
  => m ()
chronometerBarWidget = do
  mWorldStateDyn <- askWorldState
  identityDyn <- askIdentity
  playModeDyn <- askPlayMode

  rec -- GM drawer open toggle state
      gmControlsOpenDyn <- foldDyn (\() isOpen -> not isOpen) False gmToggleEvt

      -- Track top discarded cards to trigger dramatic event modal on new draws
      let getTopDiscards (ws :: WorldState) =
            Map.mapMaybe (listToMaybe . (.discardPile)) ws.clockDecks
          topDiscardsDyn :: Dynamic t (Map.Map ClockDeckId ClockEventCard) =
            maybe Map.empty getTopDiscards <$> mWorldStateDyn

      initialDiscards <- sample (current topDiscardsDyn)
      let initialDiscardIds = Set.fromList [c.id | c <- Map.elems initialDiscards]
      seenIdsDyn <-
        foldDyn
          (\newCards seen -> Set.union seen (Set.fromList [c.id | c <- Map.elems newCards]))
          initialDiscardIds
          (updated topDiscardsDyn)

      -- Auto-reveal event when a card is drawn whose ID was not previously seen
      let autoRevealEvt =
            attachWithMaybe
              ( \seen currentMap ->
                  let unseenCards = [c | c <- Map.elems currentMap, not (Set.member c.id seen)]
                   in listToMaybe unseenCards
              )
              (current seenIdsDyn)
              (updated topDiscardsDyn)

      -- Hold currently revealed modal card: auto-reveal, manual pill click, or dismissed
      revealedCardDyn <-
        holdDyn
          Nothing
          ( leftmost
              [ Just <$> autoRevealEvt
              , Just <$> manualInspectEvt
              , Nothing <$ modalDismissEvt
              ]
          )

      -- Render top bar when WorldState is available
      (gmToggleEvt, manualInspectEvt) <- componentS "chronometer-bar" barOuterStyle $ do
        let hasWorldDyn = isJust <$> mWorldStateDyn
            renderBarBranch hasW =
              if not hasW
                then pure (never, never)
                else do
                  let wsDyn = fmap (fromMaybe dummyWorldState) mWorldStateDyn
                  renderBar wsDyn identityDyn playModeDyn gmControlsOpenDyn
        initialHasWorld <- sample (current hasWorldDyn)
        dynRes <- widgetHold (renderBarBranch initialHasWorld) (renderBarBranch <$> updated hasWorldDyn)

        -- Unpack dynamically switching events
        let gmEvt = switchDyn (fst <$> dynRes)
            inspectEvt = switchDyn (snd <$> dynRes)
        pure (gmEvt, inspectEvt)

      -- Render dramatic clock event modal overlay when active
      modalDismissEvt <- renderClockEventModal revealedCardDyn

  pure ()
  where
    dummyWorldState =
      WorldState
        Nothing
        (ExpeditionTime 0)
        (error "dummy focus")
        Map.empty
        Map.empty
        Map.empty
        Map.empty
        (LightSourceState Nothing)
        Nothing
        Map.empty
        Map.empty

--------------------------------------------------------------------------------
-- Bar Rendering
--------------------------------------------------------------------------------

renderBar
  :: forall t m
   . (GameWidget t m)
  => Dynamic t WorldState
  -> Dynamic t (Maybe (Text, ClientRole))
  -> Dynamic t PlayMode
  -> Dynamic t Bool
  -> m (Event t (), Event t ClockEventCard)
renderBar wsDyn identityDyn playModeDyn gmControlsOpenDyn = do
  rec (gmToggleEvt, inspectEvt) <- divS barRowStyle $ do
        -- Left: Expedition Time & Light Source
        divS sectionGroupStyle $ do
          -- Expedition Chronometer
          divS chronoBadgeStyle $ do
            divS chronoLabelStyle $ text "EXPEDITION"
            divS chronoTimeStyle $ dynText (formatExpeditionTime . (.time) <$> wsDyn)

          -- Light Source & Fuel
          renderLightSource (fmap (.lightState) wsDyn)

        -- Center: Clock Deck Progress Pills
        inspectEvt' <- renderClockPills (fmap (.clockDecks) wsDyn)

        -- Right: Play Mode Badge & GM Quick-Controls Trigger
        gmToggleEvt' <- divS sectionGroupStyle $ do
          divS mempty $ do
            dyn_ $ ffor playModeDyn $ \pm ->
              divS (modeBadgeStyle pm) $ text (tshow pm)

          -- GM Controls Button (visible only to RoleGM)
          let isGMDyn = ffor identityDyn $ \case
                Just (_, RoleGM) -> True
                _ -> False
              renderGMBtn isGM =
                if not isGM
                  then pure never
                  else do
                    (btnEl, _) <-
                      elAttr'
                        "button"
                        ( "class"
                            =: classNames
                              ( S.px S.S3
                                  <> S.py S.S1
                                  <> S.rounded
                                  <> S.border1
                                  <> S.border S.Yellow 9
                                  <> S.bg S.Gray 12
                                  <> S.hover (S.bg S.Gray 10)
                                  <> textGoldBright
                                  <> S.textXs
                                  <> S.fontBold
                                  <> S.cls "fantasy-font"
                              )
                            <> "data-testid" =: "gm-time-controls-btn"
                        )
                        $ text "GM Time"
                    pure (domEvent Click btnEl)
          initialIsGM <- sample (current isGMDyn)
          dynGmEvt <- widgetHold (renderGMBtn initialIsGM) (renderGMBtn <$> updated isGMDyn)
          pure (switchDyn dynGmEvt)

        pure (gmToggleEvt', inspectEvt')

      -- GM Quick-Controls Drawer
      dyn_ $ ffor (zipDyn gmControlsOpenDyn wsDyn) $ \(isOpen, ws) ->
        when isOpen $ renderGMControls ws

  pure (gmToggleEvt, inspectEvt)

--------------------------------------------------------------------------------
-- Light Source Sub-Widget
--------------------------------------------------------------------------------

renderLightSource
  :: (DomBuilder t m, PostBuild t m)
  => Dynamic t LightSourceState
  -> m ()
renderLightSource lightDyn = do
  dyn_ $ ffor lightDyn $ \(LightSourceState mLight) ->
    case mLight of
      Just (name, fuel) -> do
        let isLow = fuel <= 15
        divS (lightBadgeStyle isLow) $ do
          divS (if isLow then S.text S.Amber 4 else S.text S.Yellow 4) $ text "🔥"
          elS "span" (S.fontBold <> S.textWhite) $ text name
          elS "span" (if isLow then S.text S.Amber 3 <> S.fontBold else S.text S.Gray 4) $
            text ("(" <> tshow fuel <> "m)")
      Nothing ->
        divS (lightBadgeStyle False) $ do
          elS "span" (S.text S.Gray 5 <> S.italic) $ text "🌑 Unlit"

--------------------------------------------------------------------------------
-- Clock Deck Pills Sub-Widget
--------------------------------------------------------------------------------

renderClockPills
  :: forall t m
   . (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m)
  => Dynamic t (Map.Map ClockDeckId ClockDeckState)
  -> m (Event t ClockEventCard)
renderClockPills clockDecksDyn = do
  divS sectionGroupStyle $ do
    let renderPills decks = do
          pillEvts <- forM (Map.toList decks) $ \(cid, deckSt) -> do
            let totalMins = toMinutes deckSt.tickInterval
                accMins = deckSt.accumulatedMinutes
                pct = if totalMins <= 0 then 0 else min 100 ((accMins * 100) `div` totalMins)
                isWarning = accMins >= totalMins
                mTopDiscard = listToMaybe deckSt.discardPile
                displayName = formatDeckName cid.unClockDeckId

            (pillEl, _) <-
              elAttr'
                "div"
                ( "class" =: classNames (clockPillStyle isWarning)
                    <> "title" =: ("Click to inspect latest " <> displayName <> " event")
                    <> "data-testid" =: ("clock-pill-" <> cid.unClockDeckId)
                )
                $ do
                  -- Deck Name
                  elS "span" (S.textXs <> S.fontBold <> (if isWarning then S.text S.Red 3 else S.text S.Gray 3)) $
                    text displayName

                  -- Progress fraction
                  elS "span" (S.textXs <> S.fontMono <> textGoldMuted) $
                    text (tshow accMins <> "/" <> tshow totalMins <> "m")

                  -- Mini progress bar
                  divS progressTrackStyle $
                    divS (progressBarFillStyle pct) blank

                  -- Remaining cards indicator
                  elS "span" (S.textXs <> S.text S.Gray 4) $
                    text ("(" <> tshow (length deckSt.drawPile) <> ")")

            let clickEvt = domEvent Click pillEl
            pure (fmapMaybe (const mTopDiscard) clickEvt)

          pure (leftmost pillEvts)

    initialDecks <- sample (current clockDecksDyn)
    dynPills <- widgetHold (renderPills initialDecks) (renderPills <$> updated clockDecksDyn)
    pure (switchDyn dynPills)

formatDeckName :: Text -> Text
formatDeckName t =
  case T.uncons t of
    Nothing -> t
    Just (c, rest) -> T.singleton (toUpper c) <> rest

--------------------------------------------------------------------------------
-- GM Quick Controls Drawer
--------------------------------------------------------------------------------

renderGMControls
  :: forall t m
   . (GameWidget t m)
  => WorldState
  -> m ()
renderGMControls ws = divS gmDrawerStyle $ do
  -- Row 1: Advance Expedition Time Buttons
  divS (S.flexRow <> S.itemsCenter <> S.gap S.S2) $ do
    elS "span" (S.textXs <> S.fontBold <> textGoldMuted <> S.trackingWider <> S.w (S.Px 100)) $
      text "ADVANCE TIME:"

    let advanceOptions =
          [ ("+1m", Duration 1 Minute)
          , ("+5m", Duration 5 Minute)
          , ("+10m", Duration 10 Minute)
          , ("+30m", Duration 30 Minute)
          , ("+1h", Duration 1 Hour)
          ]

    forM_ advanceOptions $ \(lbl, dur) -> do
      (btnEl, _) <-
        elAttr'
          "button"
          ( "class"
              =: classNames
                ( S.px S.S2
                    <> S.py S.S1
                    <> S.rounded
                    <> S.border1
                    <> S.border S.Gray 9
                    <> S.bg S.Gray 11
                    <> S.hover (S.bg S.Gray 9 <> S.border S.Yellow 6)
                    <> S.textXs
                    <> textGoldBright
                )
              <> "data-testid" =: ("btn-advance-" <> lbl)
          )
          $ text lbl
      let clickEvt = domEvent Click btnEl
          req = Req.AdvanceTimeManual dur <$ clickEvt
      _ <- requestGame req
      pure ()

  -- Row 2: Trigger Clock Deck Draws
  unless (Map.null ws.clockDecks) $ do
    divS (S.flexRow <> S.itemsCenter <> S.gap S.S2) $ do
      elS "span" (S.textXs <> S.fontBold <> textGoldMuted <> S.trackingWider <> S.w (S.Px 100)) $
        text "DRAW CLOCK:"

      forM_ (Map.keys ws.clockDecks) $ \cid -> do
        let displayName = formatDeckName cid.unClockDeckId
        (btnEl, _) <-
          elAttr'
            "button"
            ( "class"
                =: classNames
                  ( S.px S.S2
                      <> S.py S.S1
                      <> S.rounded
                      <> S.border1
                      <> S.border S.Red 8
                      <> S.bg S.Red 12
                      <> S.hover (S.bg S.Red 10)
                      <> S.textXs
                      <> S.text S.Red 2
                      <> S.fontBold
                  )
                <> "data-testid" =: ("btn-draw-clock-" <> cid.unClockDeckId)
            )
            $ text ("Draw " <> displayName)
        let clickEvt = domEvent Click btnEl
            req = Req.DrawClockManual cid <$ clickEvt
        _ <- requestGame req
        pure ()

--------------------------------------------------------------------------------
-- Clock Event Reveal Modal Overlay
--------------------------------------------------------------------------------

-- | Renders the dramatic Clock Event reveal modal overlay when a card is selected.
renderClockEventModal
  :: forall t m
   . (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m)
  => Dynamic t (Maybe ClockEventCard)
  -> m (Event t ())
renderClockEventModal mCardDyn = do
  dynClose <- widgetHold (pure never) $ ffor (updated mCardDyn) $ \case
    Nothing -> pure never
    Just card -> clockEventRevealModal card
  pure (switchDyn dynClose)

-- | Self-contained Clock Event Card reveal modal dialog.
clockEventRevealModal
  :: forall t m
   . (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m)
  => ClockEventCard
  -> m (Event t ())
clockEventRevealModal card = componentS "clock-event-modal" modalOverlayStyle $ do
  -- Backdrop click dismisses
  (backdropEl, _) <-
    elAttr'
      "div"
      ( "class" =: classNames (S.absolute <> S.inset0)
          <> "data-testid" =: "clock-modal-backdrop"
      )
      blank

  (panelEl, closeBtnClick) <-
    elAttr'
      "div"
      ( "class" =: classNames modalPanelStyle
          <> "tabindex" =: "0"
          <> "data-testid" =: "clock-modal-panel"
      )
      $ do
        -- Header: Urgency badge & Deck name + Close icon
        closeClick <- divS
          ( S.flexRow
              <> S.itemsCenter
              <> S.justifyBetween
              <> S.px S.S6
              <> S.py S.S4
              <> S.borderB
              <> S.border S.Gray 10
              <> S.bg S.Gray 12
          )
          $ do
            divS (S.flexRow <> S.itemsCenter <> S.gap S.S3) $ do
              divS (urgencyBadgeStyle card.urgency) $ text (tshow card.urgency)
              elS "span" (S.textXs <> S.fontBold <> textGoldMuted <> S.uppercase <> S.trackingWider) $
                text ("[" <> card.clockDeck.unClockDeckId <> " CLOCK]")

            (closeEl, _) <-
              elAttr'
                "button"
                ( "class" =: classNames (S.text S.Gray 5 <> S.hover S.textWhite <> S.w S.S5 <> S.h S.S5)
                    <> "data-testid" =: "clock-modal-close-icon"
                )
                iconClose
            pure (domEvent Click closeEl)

        -- Body Content
        divS (S.flexCol <> S.gap S.S4 <> S.p S.S6 <> S.overflowYAuto) $ do
          -- Card Title
          elS "h2" (S.text2Xl <> S.fontBold <> textGoldBright <> S.cls "fantasy-font") $
            text (getRawText card.name)

          -- Optional Tags
          case card.tags of
            Nothing -> blank
            Just ts ->
              divS (S.flexRow <> S.gap S.S2 <> S.itemsCenter) $
                forM_ (NE.toList ts) $ \t ->
                  elS "span" (S.px S.S2 <> S.py (S.Px 2) <> S.rounded <> S.bg S.Gray 9 <> S.text S.Gray 3 <> S.textXs) $
                    text ("#" <> t)

          -- Sensory Cue narrative box
          case card.narrative.sensoryCue of
            Nothing -> blank
            Just cue ->
              divS
                ( S.p S.S3
                    <> S.rounded
                    <> S.borderL
                    <> S.css "border-l-4" "border-left-width" "4px"
                    <> S.border S.Yellow 6
                    <> S.bg S.Gray 12
                    <> S.italic
                    <> S.textSm
                    <> S.text S.Gray 3
                )
                $ text ("“" <> toText cue <> "”")

          -- Main narrative summary
          elS "p" (S.textSm <> S.text S.Gray 2 <> S.cls "leading-relaxed") $
            text (toText card.narrative.summary)

          -- Applied Effects section
          unless (null card.effects) $ do
            divS (S.flexCol <> S.gap S.S2 <> S.pt S.S2 <> S.borderT <> S.border S.Gray 10) $ do
              elS "h4" (S.textXs <> S.fontBold <> textGoldMuted <> S.uppercase <> S.trackingWider) $
                text "Applied World Effects"
              forM_ card.effects $ \eff ->
                divS
                  ( S.flexCol
                      <> S.gap (S.Px 2)
                      <> S.p S.S2
                      <> S.rounded
                      <> S.bg S.Gray 12
                      <> S.border1
                      <> S.border S.Gray 9
                  )
                  $ do
                    divS (S.flexRow <> S.justifyBetween <> S.itemsCenter) $ do
                      elS "span" (S.textXs <> S.fontBold <> S.text S.Yellow 4) $ text ("Target: " <> eff.target)
                      case eff.duration of
                        Nothing -> blank
                        Just d ->
                          elS "span" (S.textXs <> S.text S.Gray 4) $
                            text ("Duration: " <> tshow d.value <> " " <> tshow d.unit)
                    elS "span" (S.textXs <> S.text S.Gray 3) $ text (toText eff.text)
                    when eff.extinguishesLight $
                      elS "span" (S.textXs <> S.fontBold <> S.text S.Red 4) $
                        text "⚠️ Extinguishes active light source!"
                    case eff.spawnActors of
                      Nothing -> blank
                      Just actors ->
                        elS "span" (S.textXs <> S.fontBold <> S.text S.Red 4) $
                          text ("⚔️ Spawns hostile actors: " <> T.intercalate ", " actors)
                    case eff.setExitStatus of
                      Nothing -> blank
                      Just (SetExitStatus exit stat) ->
                        elS "span" (S.textXs <> S.text S.Amber 4) $
                          text ("🚪 Exit " <> exit.unLocationId <> " status changed to " <> tshow stat)

        -- Footer: Acknowledge Button
        ackClick <- divS
          ( S.flexRow
              <> S.css "justify-end" "justify-content" "flex-end"
              <> S.px S.S6
              <> S.py S.S4
              <> S.borderT
              <> S.border S.Gray 10
              <> S.bg S.Gray 12
          )
          $ do
            (btnEl, _) <-
              elAttr'
                "button"
                ( "class"
                    =: classNames
                      ( S.px S.S4
                          <> S.py S.S2
                          <> S.rounded
                          <> S.bg S.Yellow 8
                          <> S.hover (S.bg S.Yellow 7)
                          <> S.text S.Black 12
                          <> S.fontBold
                          <> S.textSm
                          <> S.cls "fantasy-font"
                      )
                    <> "data-testid" =: "clock-modal-ack-btn"
                )
                $ text "Acknowledge"
            pure (domEvent Click btnEl)

        pure (leftmost [closeClick, ackClick])

  -- Escape key press inside modal
  let escEvt = void (ffilter (== 27) (domEvent Keydown panelEl))
      backdropClick = domEvent Click backdropEl

  pure (leftmost [closeBtnClick, escEvt, backdropClick])
