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
import Frontend.Game.Class

import Frontend.Icons (iconClose)
import Frontend.UI.Button

-- | Sidebar container styles
sidebarContainer :: Style
sidebarContainer = S.w (S.Rem 18) . S.cls "obsidian-panel" . S.borderR . S.border S.Gray 10 . S.hFull . S.z 20

-- | Sidebar header section
sidebarHeader :: Style
sidebarHeader = S.p S.S6 . S.borderB . S.border S.Gray 10

-- | Active actor header base
activeActorHeader :: Style
activeActorHeader =
  S.p S.S4
    . S.borderB
    . S.border S.Gray 10
    . S.css "bg-stone-med" "background-color" "var(--color-stone-med)"
    . S.flex
    . S.itemsCenter

-- | Placeholder avatar styling
avatar :: Style
avatar =
  S.w (S.Rem 2.5)
    . S.h (S.Rem 2.5)
    . S.roundedFull
    . S.border2
    . S.border S.Gray 8
    . S.bg S.Gray 10
    . S.flex
    . S.itemsCenter
    . S.justifyCenter
    . S.shrink0

actorListContainer' :: Style
actorListContainer' = S.flex1 . S.overflowYAuto . S.p S.S4 . S.flexCol . S.gap S.S2

sidebarWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , Prerender t m
     , MonadGame t m
     )
  => Dynamic t (Maybe (Identified ActorId ActorState))
  -> m (Event t (Maybe ActorId))
sidebarWidget selectionDyn = do
  actorsMapDyn <- askActors
  divS (S.flexCol . sidebarContainer) $ do
    -- Sidebar Header
    divS sidebarHeader $ do
      elS
        "h1"
        ( S.textXl
            . S.fontBold
            . S.cls "fantasy-font"
            . S.css "text-gold-bright" "color" "var(--color-gold-bright)"
        )
        $ text "CardPG"

    -- Dynamic Content: List or Details
    dyContent <- dyn $ ffor selectionDyn $ \case
      Nothing -> do
        -- No selection: Show List
        divS (S.p S.S4 . S.textCenter . S.text S.Gray 5 . S.italic . S.textSm) $
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
        (minHeader, _) <- elS' "div" (S.cursorPointer . S.hover (S.bg S.Gray 10) . activeActorHeader) Map.empty $ do
          divS avatar $ text $ T.take 1 actorState.name

          divS (S.flex1 . S.overflowHidden) $ do
            elS "div" (S.fontBold . S.text S.Gray 1 . S.textTruncate) $ text actorState.name
            elS "div" (S.textXs . S.text S.Gray 5 . S.uppercase) $ text "Player"

          -- Close indicator (decorative - header click handles deselection)
          divS
            ( S.roundedFull
                . S.w S.S8
                . S.h S.S8
                . S.p S.S0
                . S.flex
                . S.itemsCenter
                . S.justifyCenter
                . S.text S.Gray 4
                . S.hover (S.text S.Gray 2)
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

        divS (S.flex1 . S.overflowYAuto . S.p S.S2) $
          actorDetailsWidget aid actorStateDyn

        return $ leftmost [deselectEvent, actorLostEvent]

    -- Extract events
    contentEvents <- holdDyn never dyContent
    let selectionChange = switchDyn contentEvents

    return selectionChange
