module Frontend.Game.PlannedAction where

import Control.Monad (forM_)
import Reflex.Dom.Core

import Core.State (ActionStack (..), NarrativeStack (..), PlannedAction (..))
import Core.Util (tshow)
import Frontend.Card ()
import Frontend.Html (Render (..))

plannedActionWidget :: (DomBuilder t m) => PlannedAction -> m ()
plannedActionWidget planned = case planned of
  PStandard (ActionStack action res) -> do
    divClass "flex flex-col items-center gap-2" $ do
      -- Revise Button (Floating above)
      elClass
        "button"
        "text-red-400 hover:text-red-300 text-[10px] font-bold uppercase flex items-center gap-1 bg-slate-900/80 px-3 py-1 rounded-full border border-slate-700/50 backdrop-blur transition-colors"
        $ do
          text "↺ Revise"

      -- Stack
      divClass "relative mt-2 w-[160px] h-[220px]" $ do
        -- Resources (Underneath, shifted left)
        -- We iterate with index to shift them
        forM_ (zip [1 :: Int ..] res) $ \(i, r) -> do
          -- Style for shift: translate(-50px * i) matching React
          -- 50px covers the number strip + padding
          let offset = negate (i * 50)
              styleStr = "transform: translate(" <> tshow offset <> "px, 0px); z-index: " <> tshow (10 - i)
          elAttr "div" ("style" =: styleStr <> "class" =: "absolute top-0 left-0 shadow-xl brightness-75") $
            render r

        -- Action Card (Top)
        divClass "absolute top-0 left-0 z-20 shadow-2xl hover:scale-105 transition-transform" $ do
          render action
          divClass
            "absolute -top-3 left-1/2 -translate-x-1/2 bg-indigo-600 text-white text-[10px] uppercase font-bold px-2 py-0.5 rounded shadow z-50"
            $ text "PLANNED"
  PNarrative (NarrativeStack cards _color) -> do
    divClass "flex flex-col items-center gap-2" $ do
      elClass
        "button"
        "text-red-400 hover:text-red-300 text-[10px] font-bold uppercase flex items-center gap-1 bg-slate-900/80 px-3 py-1 rounded-full border border-slate-700/50 backdrop-blur transition-colors"
        $ do
          text "↺ Revise"

      divClass "flex -space-x-8" $ do
        mapM_
          (divClass "relative z-10 hover:z-20 transform hover:-translate-y-2 transition-transform" . render)
          cards
  PPass -> do
    divClass "flex flex-col items-center gap-2" $ do
      elClass
        "button"
        "text-red-400 hover:text-red-300 text-[10px] font-bold uppercase flex items-center gap-1 bg-slate-900/80 px-3 py-1 rounded-full border border-slate-700/50 backdrop-blur transition-colors"
        $ do
          text "↺ Revise"
      divClass "text-slate-500 italic text-sm" $ text "Passed turn"
