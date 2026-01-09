{-# LANGUAGE OverloadedStrings #-}

module Frontend.Game.Staging where

import Control.Monad.Fix (MonadFix)
import Data.List (find)
import Data.Text (Text)
import Data.Text qualified as Text
import Reflex.Dom.Core

import Core.Card (Identified (..))
import Core.Logic.Planning (PlanValidation (..))
import Core.State (ActorState (..), CoreCardState (..))
import Frontend.Card (CardDisplayMode (..), CardSettings (..), renderWith)
import Frontend.Game.Planning (StagingState (..))
import Frontend.Style

-- | The Staging Widget handles the UI for building a plan (ACTION + RESOURCE + TARGETS)
-- It appears as an overlay when an action card is selected.
stagingWidget
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m)
  => Dynamic t ActorState
  -> Dynamic t StagingState
  -> Dynamic t PlanValidation
  -> m (Event t (), Event t (), Event t ())
stagingWidget actor staging validation = do
  -- Returns: (CancelStaging, CancelResource, CommitStaging)

  -- Staging UI Container
  component
    "action-staging"
    [absolute, bottom0, left0, right0, pointerEventsNone, flex, flexCol, justifyEnd, "pb-64"]
    $ do
      divStyle [flex1, flex, flexCol, itemsCenter, justifyEnd, "pb-8", pointerEventsNone] $ do
        -- Widget Block
        divStyle
          [ pointerEventsAuto
          , "bg-slate-900/90"
          , backdropBlur "md"
          , "border"
          , "border-slate-700"
          , "rounded-3xl"
          , "p-6"
          , shadow "2xl"
          , flex
          , flexCol
          , itemsCenter
          , "gap-6"
          , "min-w-[320px]"
          ]
          $ do
            -- Header / Status
            divStyle [flex, flexCol, itemsCenter, "gap-2"] $ do
              text "Preparing Action"
              dyn_ $ ffor validation $ \case
                PlanIncomplete cost provided ->
                  text $ "Need " <> tshow (cost - provided) <> " more resource(s)"
                PlanValid _ ->
                  text "Ready to Commit"
                _ -> blank

            -- Staged Cards Row
            clickAction <- divStyle [flex, "gap-4", itemsEnd, justifyCenter, "py-2"] $ do
              -- Action Card (Click to Cancel/Unstage)
              let actionCardDyn =
                    zipDynWith
                      (\a s -> find (\(Identified i _) -> Just i == s.stagedActionId) a.coreState.hand)
                      actor
                      staging

              (e, _) <- elAttr' "div" ("class" =: "relative group cursor-pointer origin-bottom w-40") $ do
                dyn_ $ ffor actionCardDyn $ \case
                  Just c -> renderWith (CardSettings CardFull) c
                  Nothing -> blank

              let clickEvt = domEvent Click e

              -- Resources Pile (Placeholder)
              text "Resources Pile (TODO)"

              return clickEvt

            -- Controls
            (cancelClick, commitClick) <- divStyle [flex, "gap-2", "w-full"] $ do
              (e, _) <-
                elAttr'
                  "button"
                  ( "class"
                      =: "flex-1 py-2 rounded-lg border border-slate-600 text-slate-400 font-bold hover:bg-slate-800 transition-colors"
                  )
                  $ text "Cancel"

              -- Commit (disabled if not valid)
              let validDyn = ffor validation $ \case PlanValid _ -> True; _ -> False
                  btnClass = ffor validDyn $ \v ->
                    "flex-1 py-2 rounded-lg font-bold transition-colors "
                      <> ( if v
                             then "bg-indigo-600 text-white hover:bg-indigo-500"
                             else "bg-slate-800 text-slate-600 cursor-not-allowed"
                         )

              (commitEl, _) <- elDynAttr' "button" (fmap ("class" =:) btnClass) $ text "Commit"

              -- Only emit commit if valid
              let commitEvt = gate (current validDyn) (domEvent Click commitEl)
              return (domEvent Click e, commitEvt)

            -- Combine cancels (Clicking the ACTION card also cancels/unstages it)
            return (leftmost [cancelClick, clickAction], never, commitClick)

-- Helper
tshow :: (Show a) => a -> Text
tshow = Text.pack . show
