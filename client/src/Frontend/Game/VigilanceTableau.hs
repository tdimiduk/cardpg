{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | The Vigilance Tableau panel for Exploration Mode.
--
-- Replaces the combat Hand tray at the bottom of the screen when in
-- ModeExploration. Styled as a Dark Fantasy Obsidian Altar per the design language.
module Frontend.Game.VigilanceTableau
  ( vigilanceTableauWidget
  , renderVigilanceTableau
  ) where

import Control.Monad (forM, forM_)
import Reflex.Dom.Core hiding (button)

import Api.Request qualified as Req
import Core.Card (CardInstance, CoreCard (..), Identified (..))
import Core.Primitives (ActorId)
import Core.State
  ( ActorState (..)
  , CoreCardState (..)
  )
import Core.Util (tshow)

import Frontend.Card (CardDisplayMode (..), CardSettings (..), renderCoreCardWith)
import Frontend.Game.Class
import Frontend.Icons (iconClose, iconDeck, iconDefense)
import Frontend.Style qualified as Style
import Frontend.Style.Common
  ( Style
  , classNames
  , divS
  , elS
  , testId
  , textGoldBright
  )
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout (cardGrid)
import Frontend.UI.Button

-- ---------------------------------------------------------------------------
-- Styles
-- ---------------------------------------------------------------------------

tableauWrapper :: Style
tableauWrapper =
  S.absolute
    <> S.bottom0
    <> S.left0
    <> S.right0
    <> S.pointerEventsNone
    <> S.z 40
    <> S.flex
    <> S.justifyCenter
    <> S.itemsEnd
    <> S.wFull
    <> S.px S.S8
    <> S.pb S.S4

tableauPanel :: Style
tableauPanel =
  S.cls "obsidian-panel"
    <> S.css "bg-obsidian-textbox" "background-color" "rgba(18, 16, 15, 0.92)"
    <> S.border1
    <> S.border S.Gray 9
    <> S.roundedXl
    <> S.shadow2Xl
    <> S.backdropBlurMd
    <> S.p S.S4
    <> S.flex
    <> S.itemsCenter
    <> S.gap S.S6
    <> S.pointerEventsAuto

sectionLabel :: Style
sectionLabel =
  S.textXs
    <> S.uppercase
    <> S.text S.Gray 5
    <> S.fontBold
    <> S.css "tracking" "letter-spacing" "0.05em"

cardBackStyle :: Style
cardBackStyle =
  S.w (S.Rem 4.5)
    <> S.h (S.Rem 6.5)
    <> S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    <> S.border1
    <> S.borderAlpha S.Amber 6 60
    <> S.rounded
    <> S.flexCol
    <> S.itemsCenter
    <> S.justifyCenter
    <> S.gap S.S1
    <> S.shadowLg
    <> S.css "user-select" "user-select" "none"

emptySlotStyle :: Style
emptySlotStyle =
  S.border1
    <> S.css "border-dashed" "border-style" "dashed"
    <> S.border S.Gray 8
    <> S.rounded
    <> S.flexCol
    <> S.itemsCenter
    <> S.justifyCenter
    <> S.gap S.S1
    <> S.p S.S2
    <> S.css "bg-obsidian-textbox" "background-color" "rgba(18, 16, 15, 0.5)"

readiedSlotEmpty :: Style
readiedSlotEmpty =
  emptySlotStyle
    <> S.w (S.Rem 7)
    <> S.h (S.Rem 7)
    <> S.cursorPointer
    <> S.hover (S.border S.Amber 6)

readiedSlotFilled :: Style
readiedSlotFilled =
  S.flexCol
    <> S.itemsCenter
    <> S.gap S.S1

modalBackdrop :: Style
modalBackdrop =
  S.fixed
    <> S.inset0
    <> S.z 50
    <> S.flex
    <> S.itemsCenter
    <> S.justifyCenter
    <> S.css "bg-overlay" "background-color" "rgba(0, 0, 0, 0.75)"
    <> S.backdropBlurMd

modalContainer :: Style
modalContainer =
  S.cls "obsidian-panel"
    <> S.css "bg-obsidian-textbox" "background-color" "rgba(18, 16, 15, 0.98)"
    <> S.border1
    <> S.border S.Gray 9
    <> S.roundedXl
    <> S.shadow2Xl
    <> S.w (S.Rem 56)
    <> S.css "max-h-80vh" "max-height" "80vh"
    <> S.flexCol
    <> S.overflowHidden

-- ---------------------------------------------------------------------------
-- Vigilance Tableau Widget
-- ---------------------------------------------------------------------------

-- | Renders the bottom Vigilance Tableau tray for the active PC.
vigilanceTableauWidget
  :: (GameWidget t m)
  => Dynamic t (Identified ActorId ActorState)
  -> m ()
vigilanceTableauWidget actorDyn = do
  divS tableauWrapper $
    renderVigilanceTableau actorDyn

-- | Inner interactive tableau layout.
renderVigilanceTableau
  :: forall t m
   . (GameWidget t m)
  => Dynamic t (Identified ActorId ActorState)
  -> m ()
renderVigilanceTableau actorDyn = mdo
  let actorIdDyn = fmap (.id) actorDyn
      actorStateDyn = fmap (.content) actorDyn
      dialDyn = fmap (.coreState.vigilanceDial) actorStateDyn
      poolDyn = fmap (.coreState.vigilancePool) actorStateDyn
      readiedDyn = fmap (.coreState.readiedCard) actorStateDyn
      deckDyn = fmap (.coreState.deck) actorStateDyn

  (openPickerEvt, dialReqEvt) <-
    elAttr "div" ("class" =: classNames tableauPanel <> testId "vigilance-tableau") $ do
      -- 1. Vigilance Dial Selector (0 to 4)
      dialReqs <- divS (S.flexCol <> S.gap S.S1) $ do
        divS (S.flex <> S.itemsCenter <> S.gap S.S1) $ do
          divS (S.w S.S4 <> S.h S.S4 <> S.text S.Blue 4) iconDefense
          elS "span" sectionLabel $ text "Vigilance Dial"

        setDialEvts <- divS (S.flex <> S.gap S.S1) $ do
          forM [0 .. 4 :: Int] $ \num -> do
            let isCurrentDyn = fmap (== num) dialDyn
            btnDyn <-
              button
                def
                  { variant = VariantGhost
                  , size = SizeSmall
                  , extraStyle =
                      S.w S.S7
                        <> S.h S.S7
                        <> S.textXs
                        <> S.fontBold
                        <> S.p S.S0
                        <> S.flex
                        <> S.itemsCenter
                        <> S.justifyCenter
                  }
                $ dyn_
                $ ffor isCurrentDyn
                $ \isCurr ->
                  if isCurr
                    then elS "span" (textGoldBright <> S.fontBold) $ text (tshow num)
                    else elS "span" (S.text S.Gray 5) $ text (tshow num)
            return (tagPromptlyDyn (ffor actorIdDyn (`Req.SetVigilanceDial` num)) btnDyn)
        let dialClickEvt = leftmost setDialEvts

        divS (S.textXs <> S.text S.Gray 4) $ do
          dynText $ ffor dialDyn $ \d -> tshow d <> " card target"

        return dialClickEvt

      -- Divider
      divS (S.w S.S0_5 <> S.h (S.Rem 7) <> S.bg S.Gray 10) blank

      -- 2. Face-Down Vigilance Pool
      divS (S.flexCol <> S.gap S.S1) $ do
        divS (S.flex <> S.itemsCenter <> S.gap S.S1) $ do
          divS (S.w S.S4 <> S.h S.S4 <> S.text S.Amber 5) iconDeck
          elS "span" sectionLabel $ text "Vigilance Pool"
          dynText $ ffor poolDyn $ \p -> "(" <> tshow (length p) <> ")"

        divS (S.flex <> S.itemsCenter <> S.gap S.S2 <> S.minH (S.Rem 6.5)) $ do
          dyn_ $ ffor poolDyn $ \cards ->
            if null cards
              then divS (emptySlotStyle <> S.w (S.Rem 4.5) <> S.h (S.Rem 6.5)) $ do
                elS "span" (S.textXs <> S.text S.Gray 4 <> S.italic) $ text "Empty"
              else forM_ (zip [1 :: Int ..] cards) $ \(idx, _) ->
                elAttr "div" ("class" =: classNames cardBackStyle <> testId ("vigilance-card-" <> tshow idx)) $ do
                  divS (S.w S.S4 <> S.h S.S4 <> S.text S.Amber 5) iconDeck
                  elS "span" (S.textXs <> S.fontBold <> textGoldBright <> S.cls "fantasy-font") $
                    text "VIGIL"

      -- Divider
      divS (S.w S.S0_5 <> S.h (S.Rem 7) <> S.bg S.Gray 10) blank

      -- 3. Readied Card Slot
      openSlotClick <- divS (S.flexCol <> S.gap S.S1) $ do
        divS (S.flex <> S.itemsCenter <> S.justifyBetween) $ do
          elS "span" sectionLabel $ text "Readied Card"
          elS "span" (S.textXs <> S.text S.Gray 4) $ text "1-min focus"

        dynSlotEvts <-
          dyn $ ffor readiedDyn $ \case
            Nothing -> do
              (e, _) <-
                elAttr'
                  "button"
                  ( "class" =: classNames readiedSlotEmpty
                      <> "data-testid" =: "ready-card-slot-empty"
                  )
                  $ do
                    divS (S.w S.S4 <> S.h S.S4 <> textGoldBright) iconDeck
                    elS "span" (S.textXs <> textGoldBright <> S.fontBold) $ text "+ Ready Card"
                    elS "span" (S.textXs <> S.text S.Gray 4) $ text "(Focus 1 min)"
              return (domEvent Click e)
            Just (Identified _ cardContent) -> do
              elAttr "div" ("class" =: classNames readiedSlotFilled <> testId "readied-card-slot-filled") $ do
                divS
                  ( S.css "scale-75" "transform" "scale(0.75)"
                      <> S.css "origin-tc" "transform-origin" "top center"
                      <> S.mb (S.Rem (-2.0))
                  )
                  $ renderCoreCardWith (CardSettings CardFull) cardContent
                button
                  def
                    { variant = VariantGhost
                    , size = SizeSmall
                    , extraStyle = S.textXs <> S.text S.Gray 5 <> S.hover (S.text S.Gray 2)
                    }
                  $ text "Swap Card"
        switchHold never dynSlotEvts

      return (openSlotClick, dialReqs)

  -- Send SetVigilanceDial API requests
  _ <- requestGame dialReqEvt

  -- 4. Deck Picker Modal for "Ready a Card"
  rec modalOpenDyn <- holdDyn False $ leftmost [True <$ openPickerEvt, False <$ closePickerEvt]
      closePickerEvt <- renderDeckPickerModal modalOpenDyn actorIdDyn deckDyn
  pure ()

-- | Modal for selecting a card from the deck to ready.
renderDeckPickerModal
  :: forall t m
   . (GameWidget t m)
  => Dynamic t Bool
  -> Dynamic t ActorId
  -> Dynamic t [CardInstance CoreCard]
  -> m (Event t ())
renderDeckPickerModal isOpenDyn actorIdDyn deckDyn = do
  dynEvts <-
    dyn $ ffor isOpenDyn $ \isOpen ->
      if not isOpen
        then return never
        else divS modalBackdrop $ do
          divS modalContainer $ do
            -- Header
            closeBtn <-
              divS
                ( S.p S.S4
                    <> S.borderB
                    <> S.border S.Gray 9
                    <> S.flex
                    <> S.justifyBetween
                    <> S.itemsCenter
                    <> S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
                )
                $ do
                  divS (S.flexCol <> S.gap S.S1) $ do
                    elS "h2" (S.textXl <> S.fontBold <> textGoldBright <> S.cls "fantasy-font") $
                      text "Focus (1 min): Ready a Card"
                    elS "p" (S.textXs <> S.text S.Gray 5) $
                      text "Choose a card from your deck to hold ready for instant reaction."
                  button def{variant = VariantGhost, size = SizeSmall} $
                    divS (S.w S.S6 <> S.h S.S6) iconClose

            -- Cards grid from deck
            cardPickedEvt <- do
              selectCardEvtDyn <-
                divS (cardGrid <> S.flex1 <> S.overflowYAuto <> S.wFull <> S.p S.S4) $ do
                  dyn $ ffor deckDyn $ \deckCards ->
                    if null deckCards
                      then do
                        divS (S.p S.S8 <> S.textCenter <> S.text S.Gray 6 <> S.italic) $
                          text "Your deck has no available cards (resting or reshuffling required)."
                        return never
                      else do
                        evts <- forM deckCards $ \cardInst -> do
                          (e, _) <-
                            elAttr'
                              "div"
                              ( "class" =: classNames (Style.standardCardSize <> S.cursorPointer <> S.hover S.translateYNeg4)
                                  <> "data-testid" =: "deck-card-option"
                              )
                              $ renderCoreCardWith (CardSettings CardFull) cardInst.content
                          let cardClickEvt = domEvent Click e
                              selectReq =
                                attachWith
                                  (\aid _ -> Req.SelectReadiedCard aid cardInst.id)
                                  (current actorIdDyn)
                                  cardClickEvt
                          _ <- requestGame selectReq
                          return cardClickEvt
                        return (leftmost evts)
              switchHold never selectCardEvtDyn

            return (leftmost [closeBtn, cardPickedEvt])

  switchHold never dynEvts
