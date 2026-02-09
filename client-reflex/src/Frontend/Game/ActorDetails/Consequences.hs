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
import Frontend.Style.Class (MonadStyle)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout
import Frontend.UI.Button

consequencesWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadStyle m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => ActorId
  -> Dynamic t ActorState
  -> m ()
consequencesWidget actorId actorState = do
  colWith (S.gap2 . S.p2 . S.bgSlate800 . S.rounded . S.textSlate100 . S.mt2) $ do
    rowWith (S.justifyBetween . S.itemsCenter) $ do
      elT "h2" (S.textSm . S.fontBold . S.uppercase . S.textSlate400) $ text "Consequences"

      -- Next Severity
      divT (S.textXs . S.textSlate500) $ do
        text "Next Severity: "
        dynText $ fmap tshow (actorNextSeverity actorState)

    -- List Consequences
    let consequencesDyn = fmap (\as -> as.tableState.consequences) actorState

    removeEvents <- simpleList consequencesDyn $ \consequenceDyn -> do
      rowWith (S.justifyBetween . S.itemsCenter . S.bgSlate700 . S.p1 . S.rounded . S.mb1) $ do
        let nameDyn = fmap (\(Identified _ c) -> getRawText c.name) consequenceDyn

        divT (S.textXs . S.px1) $ dynText nameDyn

        btnClick <-
          button
            def
              { variant = constDyn VariantGhost
              , size = constDyn SizeSmall
              , extraStyle = S.px1 . S.textRed400 . S.hover S.textRed300
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
          , extraStyle = S.mt2
          }
        $ text "+ Add Consequence"

    let addReq = Req.AddConsequence actorId Nothing <$ addClick

    requesting_ $ leftmost [addReq, switchDyn $ fmap leftmost removeEvents]
