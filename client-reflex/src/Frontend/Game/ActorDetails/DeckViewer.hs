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
import Frontend.Style (cardPrint)
import Frontend.Style.Common
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
  elClass "div" "fixed top-6 bottom-96 left-80 right-6 z-30" $ do
    -- Container
    elClass
      "div"
      "bg-slate-900 border border-slate-700 rounded-xl shadow-2xl w-full h-full flex flex-col overflow-hidden"
      $ do
        -- Header
        closeClick <- divClass "p-4 border-b border-slate-700 flex justify-between items-center bg-slate-950" $ do
          elClass "h2" "text-xl font-bold text-slate-100 flex items-center gap-2" $ do
            -- Using text for the icon for now as per plan, or maybe I should use an icon.
            -- Plan said "Title bar with 'Deck Viewer (N cards)'".
            text $ deckView.title <> " (" <> tshow (length deckView.cards) <> " cards)"

          button def{variant = constDyn VariantGhost, size = constDyn SizeSmall} $
            elClass "div" "w-8 h-8" iconClose

        let settings = CardSettings CardFull
        divStyle (cardGrid <> [flex1, "overflow-y-auto", "min-h-0", "w-full"]) $
          mapM_ (renderCoreCardWith settings) deckView.cards

        return closeClick
