module Frontend.Deck
  ( consequencesDeck

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
import Common.Card (ConsequenceCard(..))

import qualified Frontend.Card.Consequence as Consequence

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
    widgetHold_ blank (consequencesDeckWidget gen <$> state)
  pure ()

data DeckState = DeckState
  { _inPlay :: Vector ConsequenceCard
  , _deck :: Vector ConsequenceCard
  }

allCards :: DeckState -> Vector ConsequenceCard
allCards s = _inPlay s <> _deck s

consequencesDeckWidget
  :: ( DomBuilder t m
     , MonadFix m
     , MonadHold t m
     , Prerender t m
     , PostBuild t m
     , StatefulGen g IO
     )
  => g
  -> DeckState
  -> m ()
consequencesDeckWidget gen initialState = do
  action <- divClass "flex" $ do
    draw <- button "draw"
    reshuffle <- button "reshuffle"
    pure $ leftmost [Left <$> draw, Right <$> reshuffle]
  let (draw, reshuffle) = fanEither action
  rec
    let ePureUpdate = attachWith (\s _ -> handleDraw s) (current state) draw
    stateUpdate <- prerender (pure never) $ performEvent (liftIO . reshuffleDeck gen <$> tag (current state) reshuffle)
    state <- holdDyn initialState $ leftmost [ePureUpdate, switchDyn stateUpdate]
  divClass "cards" $ dyn_ $ (mapM_ Consequence.card . _inPlay) <$> state

handleDraw :: DeckState -> DeckState
handleDraw state =
  case V.uncons (_deck state) of
    Nothing       -> DeckState (_inPlay state) mempty
    Just (c, d)   -> DeckState (V.cons c (_inPlay state)) d

reshuffleDeck :: (PrimMonad m, StatefulGen g m) => g -> DeckState -> m DeckState
reshuffleDeck g s = do
  shuffled <- uniformShuffle (allCards s) g
  pure $ DeckState mempty shuffled
