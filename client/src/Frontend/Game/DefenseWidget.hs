{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

-- | The interactive defense resolution panel.
--
-- Rendered as a floating overlay (bottom-right, anchored above the right
-- sidebar) matching the React client's DefenseModal. Styled as a Dark Fantasy
-- Obsidian Altar per the design language.
module Frontend.Game.DefenseWidget
  ( defenseWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Core.Card (CardInstance, CoreCard (..), Identified (..))
import Core.Logic.Combat
  ( computeDefense
  , computeNextSeverity
  , computeResilience
  )
import Core.NonEmptyText (getRawText)
import Core.State
  ( ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , CoreCardState (..)
  , DefenseDetails (..)
  )
import Core.Stats (Stats (..))
import Core.Util (tshow)
import Reflex.Dom.Core hiding (button)

import Frontend.Card (CardDisplayMode (..), CardSettings (..), renderCoreCardWith)
import Frontend.Game.Class
import Frontend.Game.Defense (DefenseAction (..), DefenseTarget (..), defensePreview)
import Frontend.Icons (iconClose, iconDefense, iconResilience)
import Frontend.Render.Common (IconMode (..), renderResourceType)
import Frontend.Style.Common
  ( Style
  , bgCrimsonDim
  , classNames
  , divS
  , elS
  , textCrimsonLight
  , textEmerald
  , textGoldBright
  )
import Frontend.Style.DSL qualified as S
import Frontend.UI.Button

-- ---------------------------------------------------------------------------
-- Styles
-- ---------------------------------------------------------------------------

-- | Outer floating container — positioned bottom-right, above the hand area,
-- stacked on top of the map and hand widgets.
floatingContainer :: Style
floatingContainer =
  S.fixed
    <> S.bottom (S.Rem 5)
    <> S.right (S.Rem 21) -- Right of the right sidebar (~20rem wide)
    <> S.z 50
    <> S.w (S.Rem 26)
    <> S.flexCol
    <> S.gap S.S2
    <> S.pointerEventsNone

-- | Main widget panel — the dark obsidian altar.
widgetPanel :: Style
widgetPanel =
  S.cls "obsidian-panel"
    <> S.flexCol
    <> S.overflowHidden
    <> S.border1
    <> S.border S.Gray 9
    <> S.roundedXl
    <> S.shadow2Xl
    <> S.backdropBlurMd
    <> S.pointerEventsAuto

-- | Header bar of the defense widget.
headerBar :: Style
headerBar =
  S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    <> S.pl (S.Rem 1.5)
    <> S.pr (S.Rem 1.5)
    <> S.pt (S.Rem 1.0)
    <> S.pb (S.Rem 0.5)
    <> S.flex
    <> S.itemsCenter
    <> S.justifyBetween
    <> S.borderB
    <> S.border S.Gray 10
    <> S.shrink0

-- | Challenge context banner (shows the incoming attack).
challengeBanner :: Style
challengeBanner =
  S.css "bg-obsidian-textbox" "background-color" "rgba(18, 16, 15, 0.85)"
    <> S.p S.S3
    <> S.borderB
    <> S.border S.Gray 10
    <> S.relative

-- | Red left-accent line on the challenge banner.
attackAccent :: Style
attackAccent =
  S.absolute
    <> S.left0
    <> S.top S.S0
    <> S.bottom0
    <> S.w S.S1
    <> S.bg S.Red 6

-- | Defense stats panel.
statsPanel :: Style
statsPanel =
  S.p S.S3
    <> S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    <> S.borderB
    <> S.border S.Gray 10
    <> S.flexCol
    <> S.gap S.S2

-- | Inner stats breakdown box.
statsBreakdown :: Style
statsBreakdown =
  S.css "bg-obsidian-textbox" "background-color" "rgba(18, 16, 15, 0.85)"
    <> S.p S.S2
    <> S.rounded
    <> S.border1
    <> S.border S.Gray 10
    <> S.flexCol
    <> S.gap S.S1

-- | Flipped cards area.
cardsArea :: Style
cardsArea =
  S.p S.S3
    <> S.css "bg-stone-med" "background-color" "var(--color-stone-light)"
    <> S.borderB
    <> S.border S.Gray 10
    <> S.overflowYAuto
    <> S.css "max-h-24" "max-height" "6rem"

-- | Action bar at the bottom.
actionBar :: Style
actionBar =
  S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    <> S.p S.S3
    <> S.flex
    <> S.gap S.S2
    <> S.borderT
    <> S.border S.Gray 10

-- | Stat label style.
statLabel :: Style
statLabel =
  S.textXs
    <> S.uppercase
    <> S.text S.Gray 5
    <> S.css "tracking" "letter-spacing" "0.05em"

-- | Large stat number.
statValue :: Style
statValue = S.textXl <> S.fontBold

-- | Consequence severity override mini-button.
severityMiniBtn :: Style
severityMiniBtn =
  S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    <> S.hover (S.bg S.Red 9)
    <> S.textWhite
    <> S.fontSize 8
    <> S.flex
    <> S.itemsCenter
    <> S.justifyCenter
    <> S.border1
    <> S.border S.Gray 9
    <> S.cursorPointer
    <> S.w S.S5
    <> S.h S.S5

-- ---------------------------------------------------------------------------
-- Widget
-- ---------------------------------------------------------------------------

-- | The defense resolution floating panel.
--
-- Takes a Dynamic describing what we're defending against and the current
-- state of the defending actor. Returns events for all user interactions,
-- including requesting API calls and closing the panel.
--
-- The caller (App.hs) is responsible for:
--   - Rendering this widget conditionally (when there is an active DefenseTarget)
--   - Routing DefenseAction events to API requests
defenseWidget
  :: (GameWidget t m)
  => Dynamic t DefenseTarget
  -- ^ The challenge being defended against
  -> Dynamic t ActorState
  -- ^ The defending actor's live state
  -> m (Event t DefenseAction)
defenseWidget targetDyn actorDyn = do
  divS floatingContainer $ do
    divS widgetPanel $ do
      -- 1. Header
      closeEvt <- widgetHeader

      -- 2. Challenge Banner
      divS challengeBanner $ do
        divS attackAccent blank
        challengeBannerContent targetDyn

      -- 3. Defense Stats
      divS statsPanel $
        defenseStatsContent actorDyn

      -- 4. Flipped Cards Strip
      divS cardsArea $
        flippedCardsStrip actorDyn

      -- 5. Action Bar
      actionEvts <-
        divS actionBar $
          defenseActionBar actorDyn

      -- 6. Footer
      endEvt <- defenseFooter

      return $ leftmost [ClosePanel <$ closeEvt, actionEvts, endEvt]

-- | Header with title and close button.
widgetHeader
  :: (GameWidget t m) => m (Event t ())
widgetHeader = divS headerBar $ do
  divS (S.flex <> S.itemsCenter <> S.gap S.S2) $ do
    divS (S.w S.S4 <> S.h S.S4 <> S.text S.Blue 4) iconDefense
    elS
      "span"
      ( S.textSm
          <> S.fontBold
          <> S.cls "fantasy-font"
          <> textGoldBright
      )
      $ text "Defense Resolution"
  button
    def
      { variant = VariantGhost
      , size = SizeSmall
      , extraStyle = S.text S.Gray 5 <> S.hover (S.text S.Gray 2) <> S.p S.S1
      }
    $ divS (S.w S.S4 <> S.h S.S4) iconClose

-- | The challenge banner showing the incoming attack details.
challengeBannerContent
  :: (DomBuilder t m, PostBuild t m)
  => Dynamic t DefenseTarget
  -> m ()
challengeBannerContent targetDyn = do
  divS (S.flex <> S.gap S.S3 <> S.pl S.S2) $ do
    -- Attack card thumbnail (first card in stack, scaled down)
    dyn_ $ ffor targetDyn $ \target -> do
      case target.attackStack of
        [] ->
          divS
            ( S.css "w-12" "width" "3rem"
                <> S.css "h-16" "height" "4rem"
                <> S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
                <> S.flex
                <> S.itemsCenter
                <> S.justifyCenter
                <> S.rounded
                <> S.border1
                <> S.border S.Gray 9
                <> S.text S.Gray 7
                <> S.textSm
            )
            $ text "?"
        (Identified _ cardContent : _) ->
          divS
            ( S.shrink0
                <> S.css "scale-75" "transform" "scale(0.75)"
                <> S.css "origin-tl" "transform-origin" "top left"
                <> S.mb (S.Rem (-2.5))
                <> S.mr (S.Rem (-1.5))
            )
            $ renderCoreCardWith (CardSettings CardFull) cardContent

    -- VS Math: power + color
    divS (S.flex1 <> S.flexCol <> S.gap S.S1) $ do
      elS "span" (S.textXs <> S.uppercase <> S.text S.Gray 5 <> S.fontBold) $ text "Incoming Attack"
      dyn_ $ ffor targetDyn $ \target -> do
        let challenge = target.challenge
        divS (S.flex <> S.itemsEnd <> S.gap S.S1) $ do
          elS
            "span"
            ( S.css "text-3xl" "font-size" "1.875rem"
                <> S.fontBold
                <> textCrimsonLight
            )
            $ text (tshow challenge.challengeStrength)
          renderResourceType IconInline challenge.challengeColor Nothing

      -- Resource count indicator
      dyn_ $ ffor targetDyn $ \target ->
        case drop 1 target.attackStack of
          [] -> blank
          rs ->
            divS
              ( S.flex
                  <> S.itemsCenter
                  <> S.gap S.S1
                  <> S.textXs
                  <> S.text S.Gray 5
                  <> S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
                  <> S.px S.S2
                  <> S.py S.S0_5
                  <> S.rounded
                  <> S.wFit
              )
              $ text ("+" <> tshow (length rs) <> " resource cards")

      -- Attacker name
      divS (S.textXs <> S.text S.Gray 5 <> S.mt S.S1) $ do
        text "By: "
        dynText $ ffor targetDyn $ \t -> t.attackerName

-- | Defense stats breakdown panel, computed client-side from core logic.
defenseStatsContent
  :: (DomBuilder t m, PostBuild t m)
  => Dynamic t ActorState
  -> m ()
defenseStatsContent actorDyn = do
  let detailsDyn = ffor actorDyn defensePreview
      defenseDyn = ffor actorDyn (computeDefense . (.tableState))
      resilienceDyn = ffor actorDyn (computeResilience . (.tableState))

  divS statsBreakdown $ do
    -- Per-color totals row
    divS
      ( S.flex
          <> S.justifyBetween
          <> S.itemsCenter
          <> S.textSm
          <> S.text S.Gray 4
          <> S.pb S.S1
          <> S.borderB
          <> S.border S.Gray 10
      )
      $ do
        divS (S.flex <> S.gap S.S3) $ do
          -- Red
          divS (S.flex <> S.itemsCenter <> S.gap S.S1) $ do
            divS (S.w S.S2 <> S.h S.S2 <> S.rounded <> S.bg S.Red 6) blank
            dynText $ ffor detailsDyn $ \d -> tshow d.values.red
          -- Yellow
          divS (S.flex <> S.itemsCenter <> S.gap S.S1) $ do
            divS
              (S.w S.S2 <> S.h S.S2 <> S.roundedFull <> S.bg S.Yellow 5)
              blank
            dynText $ ffor detailsDyn $ \d -> tshow d.values.yellow
          -- Blue
          divS (S.flex <> S.itemsCenter <> S.gap S.S1) $ do
            divS
              ( S.w S.S2
                  <> S.h S.S2
                  <> S.css "rotate-45" "transform" "rotate(45deg)"
                  <> S.bg S.Blue 5
              )
              blank
            dynText $ ffor detailsDyn $ \d -> tshow d.values.blue
        elS "span" (S.text S.Gray 7 <> S.fontMono) $ text "Totals"

    -- Net stats row: defense, resilience, net impact
    divS (S.flex <> S.justifyBetween <> S.itemsCenter <> S.pt S.S1) $ do
      divS (S.flex <> S.gap S.S4) $ do
        -- Defense
        divS (S.flexCol <> S.itemsCenter) $ do
          divS (S.w S.S5 <> S.h S.S5 <> S.text S.Gray 4) iconDefense
          dynText $ ffor defenseDyn tshow
          elS "span" statLabel $ text "DEF"
        -- Resilience
        divS (S.flexCol <> S.itemsCenter) $ do
          divS (S.w S.S5 <> S.h S.S5 <> textEmerald) iconResilience
          dynText $ ffor resilienceDyn tshow
          elS "span" statLabel $ text "RES"
      -- Net impact + consequence count
      divS (S.flexCol <> S.itemsEnd) $ do
        elS "span" statLabel $ text "Net Impact"
        divS (S.flex <> S.itemsCenter <> S.gap S.S2) $ do
          dyn_ $ ffor detailsDyn $ \d ->
            elS
              "span"
              ( statValue
                  <> if d.impact > 0 then textCrimsonLight else S.text S.Blue 4
              )
              $ text (tshow d.impact)
          dyn_ $ ffor detailsDyn $ \d ->
            if d.consequencesFromDefense > 0
              then
                elS
                  "span"
                  ( S.textXs
                      <> bgCrimsonDim
                      <> textCrimsonLight
                      <> S.px S.S1
                      <> S.rounded
                      <> S.border1
                      <> S.border S.Red 9
                  )
                  $ text ("+" <> tshow d.consequencesFromDefense <> " Conseq")
              else blank

-- | Strip of cards that have been flipped for defense.
flippedCardsStrip
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m)
  => Dynamic t ActorState
  -> m ()
flippedCardsStrip actorDyn = do
  let defendingCardsDyn = ffor actorDyn $ \as ->
        case as.coreState.defending of
          Just (ActiveDefense _ cards) -> cards
          Nothing -> []

  dyn_ $ ffor defendingCardsDyn $ \cards ->
    if null cards
      then
        divS (S.textCenter <> S.textXs <> S.text S.Gray 7 <> S.italic <> S.py S.S2) $
          text "Use your deck to defend..."
      else
        divS (S.flex <> S.flexWrap <> S.gap S.S1) $
          mapM_ renderDefenseCardChip cards

-- | A small chip representing one flipped defense card.
renderDefenseCardChip
  :: (DomBuilder t m, PostBuild t m)
  => CardInstance CoreCard
  -> m ()
renderDefenseCardChip (Identified _ card) =
  elS
    "span"
    ( S.textXs
        <> S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
        <> S.text S.Blue 3
        <> S.px S.S2
        <> S.py S.S0_5
        <> S.rounded
        <> S.border1
        <> S.borderAlpha S.Blue 9 50
    )
    $ text (getRawText card.name)

-- | Two-column action bar: Flip Card + Take Consequence.
defenseActionBar
  :: (GameWidget t m)
  => Dynamic t ActorState
  -> m (Event t DefenseAction)
defenseActionBar _actorDyn = do
  let nextSevDyn = ffor _actorDyn (computeNextSeverity . (.tableState))

  -- Flip Card button (primary defense action)
  flipEvt <-
    button
      def
        { variant = VariantPrimary
        , extraStyle = S.flex1
        , size = SizeSmall
        }
      $ divS (S.flex <> S.itemsCenter <> S.justifyCenter <> S.gap S.S1)
      $ do
        divS (S.w S.S4 <> S.h S.S4 <> S.text S.Blue 3) iconDefense
        text "Flip Card"

  -- Consequence + severity overrides
  conseqEvts <- divS (S.flex <> S.gap S.S1) $ do
    -- Main "Take Consequence" button (auto-severity)
    mainConsEvt <-
      button
        def
          { variant = VariantDestructive
          , extraStyle = S.flex1 <> S.css "rounded-l" "border-radius" "var(--radius-2) 0 0 var(--radius-2)"
          , size = SizeSmall
          }
        $ divS (S.flexCol <> S.itemsCenter)
        $ do
          text "Take Conseq"
          divS (S.textXs <> S.opacity50) $ do
            text "Sev "
            dynText (fmap tshow nextSevDyn)

    -- Severity override mini-buttons [3, 2, 1]
    sevEvts <- divS (S.flexCol <> S.w S.S5) $ do
      evts <-
        mapM
          ( \sev -> do
              (e, _) <-
                elAttr'
                  "button"
                  ("class" =: classNames severityMiniBtn)
                  $ text (tshow sev)
              return (TakeConsequence (Just sev) <$ domEvent Click e)
          )
          [3 :: Int, 2, 1]
      return (leftmost evts)

    return $ leftmost [TakeConsequence Nothing <$ mainConsEvt, sevEvts]

  return $ leftmost [FlipCard <$ flipEvt, conseqEvts]

-- | Footer with "Clear / End" link.
defenseFooter
  :: (GameWidget t m)
  => m (Event t DefenseAction)
defenseFooter = do
  divS
    ( S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
        <> S.pl (S.Rem 1.5)
        <> S.pr (S.Rem 1.5)
        <> S.pt (S.Rem 0.5)
        <> S.pb (S.Rem 1.0)
        <> S.flex
        <> S.justifyBetween
    )
    $ do
      endEvt <-
        button
          def
            { variant = VariantGhost
            , size = SizeSmall
            , extraStyle = S.textXs <> S.text S.Gray 6 <> S.hover (S.text S.Gray 3)
            }
          $ text "Clear / End Defense"
      return (EndDefense <$ endEvt)
