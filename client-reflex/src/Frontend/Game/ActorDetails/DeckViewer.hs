{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE RecursiveDo #-}

module Frontend.Game.ActorDetails.DeckViewer
  ( DeckViewData (..)
  , deckViewerModal
  ) where

import Control.Monad.Fix (MonadFix)
import Data.Text (Text)
import Reflex.Dom.Core hiding (button)
import Prelude hiding (filter, id, map)

import Core.Card (CoreCard)
import Core.Util (tshow)
import Frontend.Card (CardDisplayMode (..), CardSettings (..), renderCoreCardWith)
import Frontend.Icons (iconClose)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout (cardGrid)
import Frontend.UI.Button

data DeckViewData = DeckViewData
  { title :: Text
  , cards :: [CoreCard]
  }

deckViewerModal
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     )
  => Event t (Maybe DeckViewData)
  -> m ()
deckViewerModal externalReq = mdo
  let
    -- Close event from within the modal
    closeReq = switchDyn closeEvtDyn

    -- Determine what to show.
    -- If external request comes in, use it.
    -- If close request comes in, switch to Nothing.
    viewState = leftmost [externalReq, Nothing <$ closeReq]

  -- Render the modal or nothing
  closeEvtDyn <- widgetHold (return never) $ ffor viewState $ \case
    Nothing -> return never
    Just d -> renderModal d

  return ()

renderModal
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     )
  => DeckViewData
  -> m (Event t ())
renderModal deckView = do
  -- Overlay background
  -- Non-modal Overlay (Positioned to reveal hand and sidebar)
  let fixedPos = S.fixed . S.z30 . top6 . bottom96 . left80 . right6
      top6 = S.css "top-6" "top" "1.5rem"
      bottom96 = S.css "bottom-96" "bottom" "24rem"
      left80 = S.css "left-80" "left" "20rem"
      right6 = S.css "right-6" "right" "1.5rem"

  divS fixedPos $ do
    -- Container
    divS
      ( S.bgSlate900
          . S.border
          . S.borderSlate700
          . S.roundedXl
          . S.shadow2Xl
          . S.wFull
          . S.hFull
          . S.flexCol
          . S.overflowHidden
      )
      $ do
        -- Header
        closeClick <- divS
          (S.p4 . S.borderB . S.borderSlate700 . S.flex . S.justifyBetween . S.itemsCenter . S.bgSlate950)
          $ do
            elS "h2" (S.textXl . S.fontBold . S.textSlate100 . S.flex . S.itemsCenter . S.gap2) $ do
              -- Using text for the icon for now as per plan, or maybe I should use an icon.
              -- Plan said "Title bar with 'Deck Viewer (N cards)'".
              text $ deckView.title <> " (" <> tshow (length deckView.cards) <> " cards)"

            button def{variant = constDyn VariantGhost, size = constDyn SizeSmall} $
              divS (S.w8 . S.h8) iconClose

        let settings = CardSettings CardFull
        divS (cardGrid . S.flex1 . S.overflowYAuto . minH0 . S.wFull) $
          mapM_ (renderCoreCardWith settings) deckView.cards

        return closeClick
  where
    minH0 = S.css "min-h-0" "min-height" "0"
