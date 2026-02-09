{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.ActorDetails.Deck
  ( deckWidget
  ) where

import Control.Category ((.))
import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)
import Prelude hiding (filter, id, (.))

import Api.Request (ApiRequest)
import Api.Request qualified as Req
import Core.Primitives (ActorId, Identified (..))
import Core.State (ActorState (..), CoreCardState (..))
import Core.Util (tshow)
import Frontend.Game.ActorDetails.DeckViewer (DeckViewData (..), deckViewerModal)

import Frontend.Icons (iconDeck, iconRefresh)
import Frontend.Style.Class (MonadStyle, StyledDomBuilder)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.UI.Button

deckWidget
  :: ( StyledDomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , Prerender t m
     , MonadFix m
     , MonadStyle m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => ActorId
  -> Dynamic t ActorState
  -> m ()
deckWidget actorId actorState = do
  divT (S.flexCol . S.gap2 . S.p2 . S.bgSlate950 . S.rounded . S.textSlate100) $ do
    let cs = fmap (.coreState) actorState

    -- Cards Row
    (viewDeck, viewDiscard) <- divT (S.flex . S.wFull . S.gap2) $ do
      let deckBox =
            S.flexCol
              . S.flex
              . S.flex1
              . S.relative
              . S.border
              . S.borderSlate800
              . S.bgSlate900
              . S.rounded
              . S.p3
              . S.gap2
      let labelStyle = S.textSlate400 . S.textXs
      let countStyle = S.text2Xl . S.fontBold . S.textWhite

      -- Helper for view button
      let viewButton =
            button
              def
                { variant = constDyn VariantGhost
                , size = constDyn SizeSmall
                , extraStyle = S.absolute . S.top1 . S.right1 . S.textSlate600 . S.hover S.textIndigo400
                }
              (elClass "div" "w-5 h-5" iconDeck)

      -- Draw Pile Box
      viewDeckClick <- divT deckBox $ do
        viewDeckClick' <- viewButton
        divT (S.flex . S.itemsCenter . S.gap2 . labelStyle) $ text "Draw Pile"
        elT "div" countStyle $ dynText $ fmap (tshow . length . (.deck)) cs
        drawClick <-
          button
            def
              { variant = constDyn VariantSecondary
              , size = constDyn SizeSmall
              , fullWidth = True
              }
            $ text "Draw 1"
        requesting_ $ Req.DrawCards actorId <$ drawClick
        pure viewDeckClick'

      -- Discard Box
      viewDiscardClick <- divT deckBox $ do
        viewDiscardClick' <- viewButton
        divT (S.flex . S.itemsCenter . S.gap2 . labelStyle) $ text "Discard"

        elT "div" countStyle $ dynText $ fmap (tshow . length . (.discard)) cs

        widgetHold_ buttonSpacer $ ffor (updated cs) $ \s -> case s.discard of
          [] -> buttonSpacer
          _ -> reshuffleButtonRequesting actorId

        pure viewDiscardClick'

      return (viewDeckClick, viewDiscardClick)

    -- Handle Viewer Events
    let deckCards = fmap (map (\(Identified _ c) -> c) . (.deck)) cs
    let discardCards = fmap (map (\(Identified _ c) -> c) . (.discard)) cs

    let viewDeckReq = attachWith (\cards _ -> Just (DeckViewData "Draw Pile" cards)) (current deckCards) viewDeck
    let viewDiscardReq = attachWith (\cards _ -> Just (DeckViewData "Discard" cards)) (current discardCards) viewDiscard

    deckViewerModal (leftmost [viewDeckReq, viewDiscardReq])

buttonSpacer :: (DomBuilder t m, MonadStyle m) => m ()
buttonSpacer = elT "div" (S.atom "h-[26px]" "height" "26px") blank

reshuffleButtonRequesting
  :: (Request m ~ ApiRequest, DomBuilder t m, PostBuild t m, MonadStyle m, Requester t m)
  => ActorId -> m ()
reshuffleButtonRequesting actorId = do
  reshuffleClick <-
    button
      def
        { variant = constDyn VariantSecondary
        , size = constDyn SizeSmall
        , extraStyle = S.gap1
        }
      $ do
        elClass "div" "w-4 h-4" iconRefresh
        text "Reshuffle"

  requesting_ $ Req.Reshuffle actorId <$ reshuffleClick
