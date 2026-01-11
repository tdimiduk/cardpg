module Frontend.Game.Sidebar where

import Control.Monad.Fix (MonadFix)
import Data.Map qualified as Map
import Data.Text qualified as T
import Reflex.Dom.Core hiding (button)

import Core.Primitives (ActorId, Identified (..))
import Core.State (ActorState (..))

import Frontend.Style hiding (classes)

import Api.Request (ApiRequest)
import Data.Maybe (fromMaybe)
import Frontend.Game.ActorDetails (actorDetailsWidget)
import Frontend.UI.Button

-- | Sidebar container styles
sidebarContainer :: [CssClass]
sidebarContainer =
  ["w-72", "bg-slate-950", "border-r", "border-slate-800", flex, flexCol, "h-full", "z-20", shadowXl]

-- | Sidebar header section
sidebarHeader :: [CssClass]
sidebarHeader = ["p-6", "border-b", "border-slate-800"]

-- | Active actor header base
activeActorHeader :: [CssClass]
activeActorHeader = ["p-4", "border-b", "border-slate-800", "bg-slate-900", itemsCenter]

-- | Placeholder avatar styling
avatar :: [CssClass]
avatar =
  [ "w-10"
  , "h-10"
  , "rounded-full"
  , "border-2"
  , "border-slate-600"
  , "bg-slate-800"
  , flex
  , itemsCenter
  , justifyCenter
  , "shrink-0"
  ]

-- | Actor list container
actorListContainer :: [CssClass]
actorListContainer = ["flex-1", "overflow-y-auto", "p-4", "space-y-2"]

sidebarWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => Dynamic t (Maybe (Identified ActorId ActorState))
  -> Dynamic t (Map.Map ActorId ActorState)
  -> m (Event t (Maybe ActorId))
sidebarWidget selectionDyn actorsMapDyn = do
  divStyle sidebarContainer $ do
    -- Sidebar Header
    divStyle sidebarHeader $ do
      elStyle "h1" ["text-xl", fontBold, "text-slate-100"] $ text "CardPG"

    -- Dynamic Content: List or Details
    dyContent <- dyn $ ffor selectionDyn $ \case
      Nothing -> do
        -- No selection: Show List
        divStyle ["p-4", "text-center", "text-slate-500", "italic", textSm] $
          text "Select an actor"

        divStyle actorListContainer $ do
          selectClick <- listWithKey actorsMapDyn $ \aid actorDyn -> do
            e <- button
              def
                { _buttonConfig_variant = constDyn VariantSecondary
                , _buttonConfig_fullWidth = True
                , _buttonConfig_classes = ["justify-start", "text-left"]
                }
              $ dyn_
              $ ffor actorDyn
              $ \actor -> text actor.name
            return (aid <$ e)

          return (Just <$> switchDyn (fmap (leftmost . Map.elems) selectClick))
      Just (Identified aid actorState) -> do
        -- Selection: Show Details
        -- Header (Click anywhere to deselect)
        (minHeader, _) <- elStyle' "div" ("cursor-pointer" : "hover:bg-slate-800" : activeActorHeader) $ do
          divStyle avatar $ text $ T.take 1 actorState.name

          divStyle ["flex-1", "overflow-hidden"] $ do
            elStyle "div" [fontBold, "text-slate-100", truncateText] $ text actorState.name
            elStyle "div" [textXs, "text-slate-500", "uppercase"] $ text "Player"

          -- Close indicator (decorative - header click handles deselection)
          divStyle
            [ "rounded-full"
            , "w-8"
            , "h-8"
            , "p-0"
            , flex
            , itemsCenter
            , justifyCenter
            , "text-slate-400"
            , "hover:text-slate-200"
            ]
            $ text "✕"

        -- Header click deselects
        let deselectEvent = Nothing <$ domEvent Click minHeader

        -- Details Widget
        -- We re-derive the Dynamic ActorState from the map to ensure it receives updates.
        -- We gracefully fall back to the snapshot 'actorState' if the actor is removed from the map.
        let actorStateDyn = ffor actorsMapDyn $ \m -> fromMaybe actorState (Map.lookup aid m)

        -- Auto-deselect if the actor is removed from the map
        let actorExistsDyn = ffor actorsMapDyn $ \m -> Map.member aid m
        let actorLostEvent = Nothing <$ ffilter not (updated actorExistsDyn)

        divStyle ["flex-1", "overflow-y-auto", "p-2"] $
          actorDetailsWidget aid actorStateDyn

        return $ leftmost [deselectEvent, actorLostEvent]

    -- Extract events
    contentEvents <- holdDyn never dyContent
    let selectionChange = switchDyn contentEvents

    return selectionChange
