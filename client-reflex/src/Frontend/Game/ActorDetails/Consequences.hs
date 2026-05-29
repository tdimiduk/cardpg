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
     , Requester t m
     , Request m ~ ApiRequest
     )
  => ActorId
  -> Dynamic t ActorState
  -> m ()
consequencesWidget actorId actorState = do
  colWith (S.gap S.S2 . S.p S.S2 . S.cls "obsidian-panel" . S.rounded . S.text S.Gray 1 . S.mt S.S2) $ do
    rowWith (S.justifyBetween . S.itemsCenter) $ do
      elS
        "h2"
        ( S.textSm
            . S.fontBold
            . S.uppercase
            . S.cls "fantasy-font"
            . S.css "text-gold-bright" "color" "var(--color-gold-bright)"
        )
        $ text "Consequences"

      -- Next Severity
      divS (S.textXs . S.cls "fantasy-font" . S.css "text-gold-muted" "color" "var(--color-gold-muted)") $ do
        text "Next Severity: "
        dynText $ fmap tshow (actorNextSeverity actorState)

    -- List Consequences
    let consequencesDyn = fmap (\as -> as.tableState.consequences) actorState

    removeEvents <- simpleList consequencesDyn $ \consequenceDyn -> do
      rowWith
        (S.justifyBetween . S.itemsCenter . S.cls "cursed-lava-stone" . S.p S.S1 . S.rounded . S.mb S.S1)
        $ do
          let nameDyn = fmap (\(Identified _ c) -> getRawText c.name) consequenceDyn

          divS (S.textXs . S.px S.S1 . S.css "text-crimson-light" "color" "#fca5a5" . S.fontBold) $
            dynText nameDyn

          btnClick <-
            button
              def
                { variant = constDyn VariantGhost
                , size = constDyn SizeSmall
                , extraStyle = S.px S.S1 . S.text S.Red 5 . S.hover (S.text S.Red 4)
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
          , extraStyle = S.mt S.S2
          }
        $ text "+ Add Consequence"

    let addReq = Req.AddConsequence actorId Nothing <$ addClick

    requesting_ $ leftmost [addReq, switchDyn $ fmap leftmost removeEvents]
