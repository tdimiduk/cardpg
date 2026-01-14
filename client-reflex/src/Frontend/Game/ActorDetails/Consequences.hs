{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.ActorDetails.Consequences
  ( consequencesWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Data.Default ()
import Reflex.Dom.Core hiding (button)

import Api.Request (ApiRequest)
import Api.Request qualified as Req
import Core.Card (ConsequenceCard (..), Identified (..))
import Core.NonEmptyText (getRawText)
import Core.Primitives (ActorId)
import Core.State (ActorState (..), TableState (..))
import Core.Util (tshow)
import Frontend.Game.ActorLogic (actorNextSeverity)
import Frontend.Style
import Frontend.UI.Button

consequencesWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => ActorId
  -> Dynamic t ActorState
  -> m ()
consequencesWidget actorId actorState = do
  colWith ["gap-2", "p-2", "bg-slate-800", rounded, "text-slate-100", "mt-2"] $ do
    rowWith [justifyBetween, itemsCenter] $ do
      elStyle "h2" [textSm, fontBold, uppercase, "text-slate-400"] $ text "Consequences"

      -- Next Severity
      divStyle [textXs, "text-slate-500"] $ do
        text "Next Severity: "
        dynText $ fmap tshow (actorNextSeverity actorState)

    -- List Consequences
    let consequencesDyn = fmap (\as -> as.tableState.consequences) actorState

    removeEvents <- simpleList consequencesDyn $ \consequenceDyn -> do
      rowWith [justifyBetween, itemsCenter, "bg-slate-700", "p-1", rounded, "mb-1"] $ do
        let nameDyn = fmap (\(Identified _ c) -> getRawText c.name) consequenceDyn

        divStyle [textXs, "px-1"] $ dynText nameDyn

        btnClick <-
          button
            def
              { variant = constDyn VariantGhost
              , size = constDyn SizeSmall
              , classes = ["px-1", "text-red-400", "hover:text-red-300"]
              }
            $ text "×"

        return $
          fmap (\c -> Req.DestroyConsequence actorId c.id) (current consequenceDyn) <@ btnClick

    -- Add Consequence Button
    addClick <-
      button
        def
          { variant = constDyn VariantDestructive
          , fullWidth = True
          , size = constDyn SizeSmall
          , classes = ["mt-2"]
          }
        $ text "+ Add Consequence"

    let addReq = Req.AddConsequence actorId Nothing <$ addClick

    requesting_ $ leftmost [addReq, switchDyn $ fmap leftmost removeEvents]
