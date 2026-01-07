module Frontend.Game.Sidebar where

import Data.Map qualified as Map
import Reflex.Dom.Core

import Core.Primitives (ActorId)
import Core.State (ActorState (..))
import Core.Util (tshow)
import Frontend.Style hiding (classes)
import Frontend.Style qualified as Style

sidebarWidget ::
  (MonadWidget t m) =>
  Dynamic t (Maybe ActorId) -> Dynamic t (Map.Map ActorId ActorState) -> m (Event t (Maybe ActorId))
sidebarWidget selectedActorId actorsMapDyn = do
  divStyle
    ["w-72", "bg-slate-950", borderR, "border-slate-800", flex, flexCol, hFull, "z-20", shadowXl]
    $ do
      -- Sidebar Header (Static for now)
      divStyle ["p-6", borderB, "border-slate-800"] $ do
        elStyle "h1" ["text-xl", fontBold, textSlate100] $ text "CardPG"

      -- Actor List or Active Actor Details
      dyn_ $ ffor selectedActorId $ \case
        Nothing ->
          divClass (Style.classes ["p-4", "text-center", "text-slate-500", "italic", textSm]) $
            text "Select an actor"
        Just aid -> do
          -- Active Actor Header (Mini)
          divStyle
            ["p-4", borderB, "border-slate-800", bgSlate900, flex, itemsCenter, "gap-3"]
            $ do
              divStyle
                [ "w-10"
                , "h-10"
                , "rounded-full"
                , border2
                , borderSlate600
                , bgSlate800
                , flex
                , itemsCenter
                , justifyCenter
                , "shrink-0"
                ]
                $ text "A" -- Placeholder Avatar
              divStyle ["flex-1", overflowHidden] $ do
                -- We need to look up the name from the map, but for now just show ID
                elStyle "div" [fontBold, textSlate100, truncateText] $ text $ tshow aid
                elStyle "div" [textXs, "text-slate-500", "uppercase"] $ text "Player"

      -- Actor List (Always visible in this simple version, or switchable)
      divStyle ["flex-1", "overflow-y-auto", "p-4", "space-y-2"] $ do
        selectClick <- listWithKey actorsMapDyn $ \aid actorDyn -> do
          (e, _) <- elClass'
            "button"
            ( Style.classes
                [ wFull
                , "text-left"
                , "px-4"
                , "py-2"
                , bgSlate800
                , "hover:bg-slate-700"
                , rounded
                , "transition-colors"
                , "group"
                ]
            )
            $ do
              dyn_ $ ffor actorDyn $ \actor -> do
                text $ actor.name
          return (aid <$ domEvent Click e)

        -- Aggregate clicks
        return $ fmap Just $ switchDyn $ fmap (leftmost . Map.elems) selectClick
