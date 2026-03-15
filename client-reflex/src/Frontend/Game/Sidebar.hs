{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.Sidebar where

import Control.Monad.Fix (MonadFix)
import Core.Primitives (ActorId, Identified (..))
import Core.State (ActorState (..))
import Data.Map qualified as Map
import Data.Text qualified as T
import Reflex.Dom.Core hiding (button)

import Frontend.Style.Common (Style, divS, elS, elS', testId)
import Frontend.Style.DSL qualified as S

import Api.Request (ApiRequest)
import Data.Maybe (fromMaybe)
import Frontend.Game.ActorDetails (actorDetailsWidget)

import Frontend.Icons (iconClose)
import Frontend.UI.Button

-- | Sidebar container styles
sidebarContainer :: Style
sidebarContainer = S.w72 . S.bgSlate950 . S.borderR . S.borderSlate800 . S.hFull . S.z20 . S.shadowXl

-- | Sidebar header section
sidebarHeader :: Style
sidebarHeader = S.p4 . S.px6 . S.borderB . S.borderSlate800

-- Note: original was p-6. DSL2 has p4, px6. p6 doesn't exist. Using p4 px6? Or just p4?
-- Original was "p-6". p6 is huge (1.5rem). p4 is 1rem.
-- I'll use S.p4 for now or define p6 locally.
-- p-6 is 1.5rem. DSL2 has p1_5 which is 0.375rem.
-- I'll stick to S.p4 as compromise or define p6 locally?
-- I'll use S.p4.
sidebarHeader' :: Style
sidebarHeader' = S.css "p-6" "padding" "1.5rem" . S.borderB . S.borderSlate800

-- | Active actor header base
activeActorHeader :: Style
activeActorHeader = S.p4 . S.borderB . S.borderSlate800 . S.bgSlate900 . S.flex . S.itemsCenter

-- | Placeholder avatar styling
avatar :: Style
avatar =
  S.w10
    . S.h10
    . S.roundedFull
    . S.border2
    . S.css "border-slate-600" "border-color" "#475569"
    . S.bgSlate800
    . S.flex
    . S.itemsCenter
    . S.justifyCenter
    . S.shrink0

-- | Actor list container
actorListContainer :: Style
actorListContainer = S.flex1 . S.overflowYAuto . S.p4 . S.css "space-y-2" "margin-top" "> * + *" -- space-y-2 logic is hard.
-- I'll switch to flex col gap 2 in usage.

actorListContainer' :: Style
actorListContainer' = S.flex1 . S.overflowYAuto . S.p4 . S.flexCol . S.gap2

sidebarWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , Requester t m
     , Request m ~ ApiRequest
     , Prerender t m
     )
  => Dynamic t (Maybe (Identified ActorId ActorState))
  -> Dynamic t (Map.Map ActorId ActorState)
  -> m (Event t (Maybe ActorId))
sidebarWidget selectionDyn actorsMapDyn = do
  divS (S.flexCol . sidebarContainer) $ do
    -- Sidebar Header
    divS sidebarHeader' $ do
      elS "h1" (S.textXl . S.fontBold . S.textSlate100) $ text "CardPG"

    -- Dynamic Content: List or Details
    dyContent <- dyn $ ffor selectionDyn $ \case
      Nothing -> do
        -- No selection: Show List
        divS (S.p4 . S.textCenter . S.textSlate500 . S.css "italic" "font-style" "italic" . S.textSm) $
          text "Select an actor"

        divS actorListContainer' $ do
          selectClick <- listWithKey actorsMapDyn $ \aid actorDyn -> do
            e <- button
              def
                { variant = constDyn VariantSecondary
                , fullWidth = True
                , extraStyle = S.justifyStart . S.textLeft
                , attributes = ffor actorDyn $ \a -> testId ("select-actor-" <> a.name)
                }
              $ dyn_
              $ ffor actorDyn
              $ \actor -> text actor.name
            return (aid <$ e)

          return (Just <$> switchDyn (fmap (leftmost . Map.elems) selectClick))
      Just (Identified aid actorState) -> do
        -- Selection: Show Details
        -- Header (Click anywhere to deselect)
        (minHeader, _) <- elS' "div" (S.cursorPointer . S.hover S.bgSlate800 . activeActorHeader) Map.empty $ do
          divS avatar $ text $ T.take 1 actorState.name

          divS (S.flex1 . S.overflowHidden) $ do
            elS "div" (S.fontBold . S.textSlate100 . S.textTruncate) $ text actorState.name
            elS "div" (S.textXs . S.textSlate500 . S.uppercase) $ text "Player"

          -- Close indicator (decorative - header click handles deselection)
          divS
            ( S.roundedFull
                . S.w8
                . S.h8
                . S.css "p-0" "padding" "0"
                . S.flex
                . S.itemsCenter
                . S.justifyCenter
                . S.textSlate400
                . S.hover S.textSlate200
            )
            iconClose

        -- Header click deselects
        let deselectEvent = Nothing <$ domEvent Click minHeader

        -- Details Widget
        -- We re-derive the Dynamic ActorState from the map to ensure it receives updates.
        -- We gracefully fall back to the snapshot 'actorState' if the actor is removed from the map.
        let actorStateDyn = ffor actorsMapDyn $ \m -> fromMaybe actorState (Map.lookup aid m)

        -- Auto-deselect if the actor is removed from the map
        let actorExistsDyn = ffor actorsMapDyn $ \m -> Map.member aid m
        let actorLostEvent = Nothing <$ ffilter not (updated actorExistsDyn)

        divS (S.flex1 . S.overflowYAuto . S.p2) $
          actorDetailsWidget aid actorStateDyn

        return $ leftmost [deselectEvent, actorLostEvent]

    -- Extract events
    contentEvents <- holdDyn never dyContent
    let selectionChange = switchDyn contentEvents

    return selectionChange
