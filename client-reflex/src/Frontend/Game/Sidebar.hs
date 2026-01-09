module Frontend.Game.Sidebar where

import Data.Map qualified as Map
import Reflex.Dom.Core

import Core.Primitives (ActorId)
import Core.State (ActorState (..))
import Core.Util (tshow)
import Frontend.Style hiding (classes)
import Frontend.Style qualified as Style

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

-- | Actor list button styling
actorButton :: [CssClass]
actorButton =
  [ "w-full"
  , "text-left"
  , "px-4"
  , "py-2"
  , "bg-slate-800"
  , "hover:bg-slate-700"
  , rounded
  , "transition-colors"
  , group
  ]

-- | Actor list container
actorListContainer :: [CssClass]
actorListContainer = ["flex-1", "overflow-y-auto", "p-4", "space-y-2"]

sidebarWidget
  :: (MonadWidget t m)
  => Dynamic t (Maybe ActorId) -> Dynamic t (Map.Map ActorId ActorState) -> m (Event t (Maybe ActorId))
sidebarWidget selectedActorId actorsMapDyn = do
  divStyle sidebarContainer $ do
    -- Sidebar Header
    divStyle sidebarHeader $ do
      elStyle "h1" ["text-xl", fontBold, "text-slate-100"] $ text "CardPG"

    -- Actor List or Active Actor Details
    dyn_ $ ffor selectedActorId $ \case
      Nothing ->
        divStyle ["p-4", "text-center", "text-slate-500", "italic", textSm] $
          text "Select an actor"
      Just aid -> do
        -- Active Actor Header (Mini)
        rowWith ("gap-3" : activeActorHeader) $ do
          divStyle avatar $ text "A" -- Placeholder Avatar
          divStyle ["flex-1", "overflow-hidden"] $ do
            elStyle "div" [fontBold, "text-slate-100", truncateText] $ text $ tshow aid
            elStyle "div" [textXs, "text-slate-500", "uppercase"] $ text "Player"

    -- Actor List
    divStyle actorListContainer $ do
      selectClick <- listWithKey actorsMapDyn $ \aid actorDyn -> do
        (e, _) <- elAttr' "button" ("class" =: Style.classes actorButton) $ do
          dyn_ $ ffor actorDyn $ \actor -> text actor.name
        return (aid <$ domEvent Click e)

      -- Aggregate clicks
      return $ fmap Just $ switchDyn $ fmap (leftmost . Map.elems) selectClick
