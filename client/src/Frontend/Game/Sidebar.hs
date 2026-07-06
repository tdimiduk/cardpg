{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.Sidebar where

import Control.Monad.Fix (MonadFix)
import Core.Primitives (ActorId)
import Core.State (ActorState (..), MapMode (..))
import Data.Map qualified as Map
import Data.Text qualified as T
import Reflex.Dom.Core hiding (button)

import Frontend.Style.Common (Style, classNames, divS, elS, elS', testId, textGoldBright)
import Frontend.Style.DSL qualified as S

import Data.Maybe (fromMaybe)
import Frontend.Game.ActorDetails (actorDetailsWidget)
import Frontend.Game.Class

import Frontend.Icons (iconClose)
import Frontend.UI.Button

-- | Sidebar container styles
sidebarContainer :: Style
sidebarContainer =
  S.shrink0
    <> S.w (S.Rem 18)
    <> S.cls "obsidian-panel"
    <> S.borderR
    <> S.border S.Gray 10
    <> S.hFull
    <> S.z 20

-- | Sidebar header section
sidebarHeader :: Style
sidebarHeader = S.p S.S6 <> S.borderB <> S.border S.Gray 10

-- | Active actor header base
activeActorHeader :: Style
activeActorHeader =
  S.p S.S4
    <> S.borderB
    <> S.border S.Gray 10
    <> S.css "bg-stone-med" "background-color" "var(--color-stone-med)"
    <> S.flex
    <> S.itemsCenter

-- | Placeholder avatar styling
avatar :: Style
avatar =
  S.w (S.Rem 2.5)
    <> S.h (S.Rem 2.5)
    <> S.roundedFull
    <> S.border2
    <> S.border S.Gray 8
    <> S.bg S.Gray 10
    <> S.flex
    <> S.itemsCenter
    <> S.justifyCenter
    <> S.shrink0

actorListContainer' :: Style
actorListContainer' = S.flex1 <> S.overflowYAuto <> S.p S.S4 <> S.flexCol <> S.gap S.S2

data ViewMode
  = ViewGridMap
  | ViewRanksMode
  | ViewCardEditor
  deriving (Eq, Ord, Show, Read, Enum, Bounded)

-- | Styled view mode dropdown menu
viewModeDropdownStyle :: Style
viewModeDropdownStyle =
  S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    <> S.border1
    <> S.border S.Gray 10
    <> S.rounded
    <> S.px S.S2
    <> S.py S.S1
    <> S.textXs
    <> S.text S.Yellow 5
    <> S.fontBold
    <> S.cls "fantasy-font"
    <> S.cursorPointer
    <> S.css "focus:outline-none" "outline" "none"
    <> S.pseudo "focus" (S.border S.Yellow 7)

mapModeToViewMode :: MapMode -> ViewMode
mapModeToViewMode MapModeGrid = ViewGridMap
mapModeToViewMode MapModeRank = ViewRanksMode

sidebarWidget
  :: (GameWidget t m, Adjustable t m, Prerender t m)
  => Dynamic t (Maybe ActorId)
  -> Dynamic t ViewMode
  -> m (Event t (Maybe ActorId), Event t ActorId, Event t ViewMode)
sidebarWidget selectedActorId currentViewMode = do
  actorsMapDyn <- askActors
  mapModeDyn <- askMapMode
  initialViewMode <- sample (current currentViewMode)
  divS (S.flexCol <> sidebarContainer) $ do
    -- Sidebar Header
    ddChange <- divS (sidebarHeader <> S.flexRow <> S.justifyBetween <> S.itemsCenter) $ do
      elS
        "h1"
        ( S.textXl
            <> S.fontBold
            <> S.cls "fantasy-font"
            <> textGoldBright
        )
        $ text "CardPG"

      let viewModeOptions =
            Map.fromList
              [ (ViewGridMap, "Grid Map")
              , (ViewRanksMode, "Ranks Mode")
              , (ViewCardEditor, "Card Editor")
              ]
      dd <-
        dropdown initialViewMode (constDyn viewModeOptions) $
          def
            & dropdownConfig_setValue
            .~ fmap mapModeToViewMode (updated mapModeDyn)
            & dropdownConfig_attributes
            .~ constDyn
              ( "class" =: classNames viewModeDropdownStyle
                  <> "data-testid" =: "view-mode-select"
              )
      return (_dropdown_change dd)

    -- Links row
    divS
      ( S.px S.S6
          <> S.py S.S2
          <> S.borderB
          <> S.border S.Gray 10
          <> S.flex
          <> S.gap S.S2
          <> S.textXs
          <> S.fontBold
          <> S.trackingWider
          <> S.cls "fantasy-font"
      )
      $ do
        let linkStyle =
              S.text S.Gray 5
                <> S.hover textGoldBright
                <> S.css "transition-colors" "transition-property" "color"
            linkAttrs href =
              "href" =: href
                <> "target" =: "_blank"
                <> "class" =: classNames linkStyle
        elAttr "a" (linkAttrs "rules.html") $ text "Rules"
        elS "span" (S.text S.Gray 8) $ text "|"
        elAttr "a" (linkAttrs "glossary.html") $ text "Glossary"
        elS "span" (S.text S.Gray 8) $ text "|"
        elAttr "a" (linkAttrs "colors.html") $ text "Colors"

    -- Dynamic Content: List or Details
    dyContent <- dyn $ ffor selectedActorId $ \case
      Nothing -> do
        -- No selection: Show List
        divS (S.p S.S4 <> S.textCenter <> S.text S.Gray 5 <> S.italic <> S.textSm) $
          text "Select an actor"

        divS actorListContainer' $ do
          selectClick <- listWithKey actorsMapDyn $ \aid actorDyn -> do
            actorVal <- sample (current actorDyn)
            e <- button
              def
                { variant = VariantSecondary
                , fullWidth = True
                , extraStyle = S.justifyStart <> S.textLeft
                , attributes = testId ("select-actor-" <> actorVal.name)
                }
              $ dyn_
              $ ffor actorDyn
              $ \actor -> text actor.name
            return (aid <$ e)

          return (Just <$> switchDyn (fmap (leftmost . Map.elems) selectClick), never)
      Just aid -> do
        -- Fetch the initial state from current actors map to boot the UI cleanly.
        actorsMap <- sample (current actorsMapDyn)
        case Map.lookup aid actorsMap of
          Nothing -> return (never, never)
          Just initialActorState -> do
            -- Dynamic ActorState from the map to ensure it receives updates.
            let actorStateDyn = ffor actorsMapDyn $ \m -> fromMaybe initialActorState (Map.lookup aid m)

            -- Header (Click anywhere to deselect)
            (minHeader, _) <- elS' "div" (S.cursorPointer <> S.hover (S.bg S.Gray 10) <> activeActorHeader) Map.empty $ do
              let nameDyn = (.name) <$> actorStateDyn
              divS avatar $ dynText $ T.take 1 <$> nameDyn

              divS (S.flex1 <> S.overflowHidden) $ do
                elS "div" (S.fontBold <> S.text S.Gray 1 <> S.textTruncate) $ dynText nameDyn
                elS "div" (S.textXs <> S.text S.Gray 5 <> S.uppercase) $ text "Player"

              -- Close indicator (decorative - header click handles deselection)
              divS
                ( S.roundedFull
                    <> S.w S.S8
                    <> S.h S.S8
                    <> S.p S.S0
                    <> S.flex
                    <> S.itemsCenter
                    <> S.justifyCenter
                    <> S.text S.Gray 4
                    <> S.hover (S.text S.Gray 2)
                )
                iconClose

            -- Header click deselects
            let deselectEvent = Nothing <$ domEvent Click minHeader

            -- Auto-deselect if the actor is removed from the map
            let actorExistsDyn = ffor actorsMapDyn $ \m -> Map.member aid m
            let actorLostEvent = Nothing <$ ffilter not (updated actorExistsDyn)

            resumeEvt <-
              divS (S.flex1 <> S.overflowYAuto <> S.p S.S2) $
                actorDetailsWidget aid actorStateDyn

            return (leftmost [deselectEvent, actorLostEvent], aid <$ resumeEvt)

    -- Extract events
    contentEvents <- holdDyn (never, never) dyContent
    let selectionChange = switchDyn (fmap fst contentEvents)
        resumeDefense = switchDyn (fmap snd contentEvents)

    return (selectionChange, resumeDefense, ddChange)
