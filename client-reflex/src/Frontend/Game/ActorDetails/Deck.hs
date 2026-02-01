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
import Frontend.Style.Common
import Frontend.Style.Layout
import Frontend.UI.Button

deckWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , Prerender t m
     , MonadFix m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => ActorId
  -> Dynamic t ActorState
  -> m ()
deckWidget actorId actorState = do
  colWith ["gap-2", "p-2", "bg-slate-950", rounded, "text-slate-100"] $ do
    -- Header Row
    rowWith [justifyBetween, itemsCenter, "mb-2"] $ do
      divStyle [flex, itemsCenter, "gap-2", textSm, fontBold, uppercase, "text-slate-400", trackingWider] $ do
        elClass "div" "w-5 h-5" iconDeck
        text "Deck"

    let cs = fmap (.coreState) actorState

    -- Cards Row
    (viewDeck, viewDiscard) <- rowGap "gap-2" $ do
      let deckBox =
            [ flex1
            , "relative"
            , "border"
            , "border-slate-800"
            , "bg-slate-900"
            , rounded
            , "p-3"
            , flex
            , flexCol
            , "gap-2"
            ]
      let labelStyle = ["text-slate-400", textXs]
      let countStyle = ["text-2xl", fontBold, "text-white"]

      -- Helper for view button
      let viewButton =
            button
              def
                { variant = constDyn VariantGhost
                , size = constDyn SizeSmall
                , classes = ["absolute", "top-1", "right-1", "text-slate-600", "hover:text-indigo-400"]
                }
              (elClass "div" "w-5 h-5" iconDeck)

      -- Draw Pile Box
      viewDeckClick <- divStyle deckBox $ do
        viewDeckClick' <- viewButton
        row $ do
          divStyle ([flex, flexRow, itemsCenter, "gap-2"] <> labelStyle) $ text "Draw Pile"
        elStyle "div" countStyle $ dynText $ fmap (tshow . length . (.deck)) cs
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
      viewDiscardClick <- divStyle deckBox $ do
        viewDiscardClick' <- viewButton
        row $ do
          divStyle ([flex, flexRow, itemsCenter, "gap-2"] <> labelStyle) $ text "Discard"

        elStyle "div" countStyle $ dynText $ fmap (tshow . length . (.discard)) cs

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

buttonSpacer :: (DomBuilder t m) => m ()
buttonSpacer = elStyle "div" ["h-[26px]"] blank

reshuffleButtonRequesting
  :: (Request m ~ ApiRequest, DomBuilder t m, PostBuild t m, Requester t m) => ActorId -> m ()
reshuffleButtonRequesting actorId = do
  reshuffleClick <-
    button
      def
        { variant = constDyn VariantSecondary
        , size = constDyn SizeSmall
        , classes = ["gap-1"]
        }
      $ do
        elClass "div" "w-4 h-4" iconRefresh
        text "Reshuffle"

  requesting_ $ Req.Reshuffle actorId <$ reshuffleClick
