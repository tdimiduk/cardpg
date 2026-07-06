module Frontend.Game.ActorDetails.Deck
  ( deckWidget
  ) where

import Control.Category ((.))
import Control.Monad (void)
import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)
import Prelude hiding (filter, id, (.))

import Api.Request qualified as Req
import Core.Primitives (ActorId, Identified (..))
import Core.State (ActorState (..), CoreCardState (..))
import Core.Util (tshow)
import Frontend.Game.ActorDetails.DeckViewer (DeckViewData (..), deckViewerModal)
import Frontend.Game.Class

import Frontend.Icons (iconDeck, iconRefresh)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.UI.Button

deckWidget
  :: (GameWidget t m, Prerender t m)
  => ActorId
  -> Dynamic t ActorState
  -> m ()
deckWidget actorId actorState = do
  divS (S.flexCol <> S.gap S.S2 <> S.p S.S2 <> S.bg S.Gray 12 <> S.rounded <> S.text S.Gray 1) $ do
    let cs = fmap (.coreState) actorState

    -- Cards Row
    (viewDeck, viewDiscard) <- divS (S.flex <> S.wFull <> S.gap S.S2) $ do
      let deckBox =
            S.flexCol
              <> S.flex
              <> S.flex1
              <> S.relative
              <> S.border1
              <> S.border S.Gray 10
              <> S.bg S.Gray 11
              <> S.rounded
              <> S.p S.S3
              <> S.gap S.S2
      let labelStyle = S.text S.Gray 4 <> S.textXs
      let countStyle = S.text2Xl <> S.fontBold <> S.textWhite

      -- Helper for view button
      let viewButton =
            button
              def
                { variant = VariantGhost
                , size = SizeSmall
                , extraStyle =
                    S.absolute <> S.top S.S1 <> S.right S.S1 <> S.text S.Gray 6 <> S.hover (S.text S.Indigo 5)
                }
              (divS (S.w S.S5 <> S.h S.S5) iconDeck)

      -- Draw Pile Box
      viewDeckClick <- divS deckBox $ do
        viewDeckClick' <- viewButton
        divS (S.flex <> S.itemsCenter <> S.gap S.S2 <> labelStyle) $ text "Draw Pile"
        elS "div" countStyle $ dynText $ fmap (tshow . length . (.deck)) cs
        drawClick <-
          button
            def
              { variant = VariantSecondary
              , size = SizeSmall
              , fullWidth = True
              }
            $ text "Draw 1"
        void $ requestGame $ Req.DrawCards actorId <$ drawClick
        pure viewDeckClick'

      -- Discard Box
      viewDiscardClick <- divS deckBox $ do
        viewDiscardClick' <- viewButton
        divS (S.flex <> S.itemsCenter <> S.gap S.S2 <> labelStyle) $ text "Discard"

        elS "div" countStyle $ dynText $ fmap (tshow . length . (.discard)) cs

        hasDiscardsDyn <- holdUniqDyn $ fmap (not . null . (.discard)) cs
        dyn_ $ ffor hasDiscardsDyn $ \case
          False -> buttonSpacer
          True -> reshuffleButtonRequesting actorId

        pure viewDiscardClick'

      return (viewDeckClick, viewDiscardClick)

    -- Handle Viewer Events
    let deckCards = fmap (map (\(Identified _ c) -> c) . (.deck)) cs
    let discardCards = fmap (map (\(Identified _ c) -> c) . (.discard)) cs

    let viewDeckReq = attachWith (\cards _ -> Just (DeckViewData "Draw Pile" cards)) (current deckCards) viewDeck
    let viewDiscardReq = attachWith (\cards _ -> Just (DeckViewData "Discard" cards)) (current discardCards) viewDiscard

    deckViewerModal (leftmost [viewDeckReq, viewDiscardReq])

buttonSpacer :: (DomBuilder t m) => m ()
buttonSpacer = elS "div" (S.css "h-[26px]" "height" "26px") blank

reshuffleButtonRequesting
  :: (DomBuilder t m, PostBuild t m, MonadGame t m)
  => ActorId -> m ()
reshuffleButtonRequesting actorId = do
  reshuffleClick <-
    button
      def
        { variant = VariantSecondary
        , size = SizeSmall
        , extraStyle = S.gap S.S1
        }
      $ do
        divS (S.w S.S4 <> S.h S.S4) iconRefresh
        text "Reshuffle"

  void $ requestGame $ Req.Reshuffle actorId <$ reshuffleClick
