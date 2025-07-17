module Frontend.Deck
  ( consequencesDeck
  , printConsequencesDeck
  )
where

import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class
import Control.Monad.Primitive
import qualified System.Random.MWC as MWC
import System.Random.MWC.Distributions (uniformShuffle)
import System.Random.Stateful
import           Data.Vector (Vector)
import qualified Data.Vector as V
import Data.Text (Text)

import Reflex.Dom.Core

import Common.Api

import Frontend.Card ()
import Frontend.Html

consequencesDeck
  :: ( DomBuilder t m
     , Response (Client m) ~ Either Text
     , Request (Client m) ~ Api
     , Requester t (Client m)
     , Prerender t m
     )
  => ConsequencesDeck
  -> m ()
consequencesDeck deck = do
  el "h1" $ text "Consequences"
  prerender_ blank $ do
    gen <- liftIO MWC.createSystemRandom
    ps <- getPostBuild
    (err, fetched) <- fanEither <$> requesting (Api_ConsequencesDeck deck <$ ps)
    state <- performEvent (liftIO . reshuffleDeck gen . DeckState mempty <$> fetched)
    widgetHold_ blank (text <$> err)
    widgetHold_ blank (deckInnerWidget gen <$> state)
  pure ()

data DeckState a = DeckState
  { _inPlay :: Vector a
  , _deck :: Vector a
  }

printConsequencesDeck
  :: ( DomBuilder t m
     , Response (Client m) ~ Either Text
     , Request (Client m) ~ Api
     , Requester t (Client m)
     , Prerender t m
     )
  => ConsequencesDeck
  -> m ()
printConsequencesDeck deck = prerender_ blank $ divClass "cards" $ do
  ps <- getPostBuild
  (err, fetched) <- fanEither <$> requesting (Api_ConsequencesDeck deck <$ ps)
  widgetHold_ blank (text <$> err)
  widgetHold_ blank (mapM_ render <$> fetched)


allCards :: DeckState a -> Vector a
allCards s = _inPlay s <> _deck s

deckInnerWidget
  :: ( DomBuilder t m
     , MonadFix m
     , MonadHold t m
     , Prerender t m
     , PostBuild t m
     , StatefulGen g IO
     , Render a m
     )
  => g
  -> DeckState a
  -> m ()
deckInnerWidget gen initialState = do
  action <- divClass "flex" $ do
    draw <- button "draw"
    reshuffle <- button "reshuffle"
    pure $ leftmost [Left <$> draw, Right <$> reshuffle]
  let (draw, reshuffle) = fanEither action
  rec
    let ePureUpdate = attachWith (\s _ -> handleDraw s) (current state) draw
    stateUpdate <- prerender (pure never) $ performEvent (liftIO . reshuffleDeck gen <$> tag (current state) reshuffle)
    state <- holdDyn initialState $ leftmost [ePureUpdate, switchDyn stateUpdate]
  divClass "cards" $ dyn_ $ (mapM_ render . _inPlay) <$> state

handleDraw :: DeckState a -> DeckState a
handleDraw state =
  case V.uncons (_deck state) of
    Nothing       -> DeckState (_inPlay state) mempty
    Just (c, d)   -> DeckState (V.cons c (_inPlay state)) d

reshuffleDeck :: (PrimMonad m, StatefulGen g m) => g -> DeckState a -> m (DeckState a)
reshuffleDeck g s = do
  shuffled <- uniformShuffle (allCards s) g
  pure $ DeckState mempty shuffled
