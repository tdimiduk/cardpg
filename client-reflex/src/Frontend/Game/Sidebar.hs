module Frontend.Game.Sidebar where

import Data.Map qualified as Map
import Reflex.Dom.Core

import Core.Primitives (ActorId)
import Core.State (ActorState (..))
import Core.Util (tshow)

sidebarWidget ::
  (MonadWidget t m) =>
  Dynamic t (Maybe ActorId) -> Dynamic t (Map.Map ActorId ActorState) -> m (Event t (Maybe ActorId))
sidebarWidget selectedActorId actorsMapDyn = do
  divClass "w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl" $ do
    -- Sidebar Header (Static for now)
    divClass "p-6 border-b border-slate-800" $ do
      elClass "h1" "text-xl font-bold text-slate-100" $ text "CardPG"

    -- Actor List or Active Actor Details
    dyn_ $ ffor selectedActorId $ \case
      Nothing -> divClass "p-4 text-center text-slate-500 italic text-sm" $ text "Select an actor"
      Just aid -> do
        -- Active Actor Header (Mini)
        divClass "p-4 border-b border-slate-800 bg-slate-900 flex items-center gap-3" $ do
          divClass
            "w-10 h-10 rounded-full border-2 border-slate-600 bg-slate-800 flex items-center justify-center shrink-0"
            $ text "A" -- Placeholder Avatar
          divClass "flex-1 overflow-hidden" $ do
            -- We need to look up the name from the map, but for now just show ID
            elClass "div" "font-bold text-slate-100 truncate" $ text $ tshow aid
            elClass "div" "text-xs text-slate-500 uppercase" $ text "Player"

    -- Actor List (Always visible in this simple version, or switchable)
    divClass "flex-1 overflow-y-auto p-4 space-y-2" $ do
      selectClick <- listWithKey actorsMapDyn $ \aid actorDyn -> do
        (e, _) <- elClass'
          "button"
          "w-full text-left px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded transition-colors group"
          $ do
            dyn_ $ ffor actorDyn $ \actor -> do
              text $ actor.name
        return (aid <$ domEvent Click e)

      -- Aggregate clicks
      return $ fmap Just $ switchDyn $ fmap (leftmost . Map.elems) selectClick
