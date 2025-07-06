module Frontend.Deck where

import Data.Text (Text)

import Reflex.Dom.Core

import Common.Api

import qualified Frontend.Card.Consequence as Consequence

prerenderSwitchover :: (Prerender t m, Monad m) => m (Event t ())
prerenderSwitchover = switchPromptlyDyn <$> prerender (pure never) getPostBuild

consequencesDeck ::
  ( DomBuilder t m
  , Requester t m
  , MonadHold t m
  , Response m ~ Either Text
  , Request m ~ Api
  , Prerender t m
  )
  => ConsequencesDeck
  -> m ()
consequencesDeck deck = do
  el "h1" $ text "Consequences"
  ps <- prerenderSwitchover
  (err, fetched) <- fanEither <$> requesting (Api_ConsequencesDeck deck <$ ps)
  widgetHold_ blank (text <$> err)
  widgetHold_ blank (divClass "cards" . mapM_ Consequence.card <$> fetched)
  pure ()
