{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}

module Frontend (frontend) where

import Control.Monad (join)
import Control.Monad.Fix (MonadFix)
import Data.ByteString (ByteString)
import Data.Csv (HasHeader(..))
import Data.Either.Combinators
import Data.Functor.Identity
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (decodeUtf8, encodeUtf8)
import qualified Data.Vector as V
import Prelude hiding (filter)

import Obelisk.Configs
import Obelisk.Frontend
import Obelisk.Route
import Obelisk.Route.Frontend
import Obelisk.Generated.Static

import Reflex.Dom.Core
import Reflex.Dom.GadtApi.WebSocket

import Common.Api
import Common.Card
import Common.CardParser
import Common.Route

import Frontend.Admin
import Frontend.Card
import Frontend.Deck
import Frontend.Demo

type ValidEnc = Encoder Identity Identity (R (FullRoute BackendRoute FrontendRoute)) PageName

data DeckType = StandardDeck | AdhocDeck

data Deck = Standard [Card] | Adhoc (V.Vector AdhocCard)

deckFromRoute
  :: ( MonadFix m
     , MonadHold t m
     , Adjustable t m
     )
  => RoutedT t (R FrontendRoute) m (Dynamic t (Maybe (Text, DeckType)))
deckFromRoute = do
  r <- subRoute $ \case
    FrontendRoute_Deck -> do
      md <- askRoute
      pure (fmap (,StandardDeck) <$> md)
    FrontendRoute_Adhoc -> do
      md <- askRoute
      pure (fmap (, AdhocDeck) <$> md)
    _ -> pure $ (constDyn Nothing)
  pure $ join r


-- This runs in a monad that can be run on the client or the server.
-- To run code in a pure client or pure server context, use one of the
-- `prerender` functions.
frontend :: Frontend (R FrontendRoute)
frontend = Frontend htmlHead htmlBody

htmlHead :: ( DomBuilder t m
            , MonadFix m
            , MonadHold t m
            , PostBuild t m
            )
         => RoutedT t (R FrontendRoute) m ()
htmlHead = do
  deck <- deckFromRoute
  el "title" $ dynText $ maybe "CaRdPG" fst <$> deck
  elAttr "link" ("href" =: $(static "main.css") <> "type" =: "text/css" <> "rel" =: "stylesheet") blank

htmlBody
  :: forall t m.
     ( ObeliskWidget t (R FrontendRoute) m)
  => RoutedT t (R FrontendRoute) m ()
htmlBody = do
  let enc :: Either Text ValidEnc = checkEncoder fullRouteEncoder
  maybeR <- getTextConfig "common/route"
  case (enc, maybeR) of
    (Left _, _) -> error "routes are invalid!"
    (_, Nothing) -> error "couldn't load common/route config file"
    (Right validEnc, Just r) -> do
      let apiRoute = T.replace "https://" "wss://" $ T.replace "http://" "ws://" r <>
            renderBackendRoute validEnc (BackendRoute_WebSocket :/ ())
      subRoute_ $ \case
        FrontendRoute_Deck -> do
          md <- askRoute
          dyn_ $ cardsWidget <$> fmap (,StandardDeck) <$> md
        FrontendRoute_Adhoc -> do
          md <- askRoute
          dyn_ $ cardsWidget <$> fmap (,AdhocDeck) <$> md
        FrontendRoute_Main -> cardsWidget Nothing
        FrontendRoute_Demo -> do
          layoutOptions
        FrontendRoute_Consequences -> runRequesting apiRoute $ consequencesDeck $ ConsequencesDeck "general-wound"
        FrontendRoute_Admin -> runRequesting apiRoute admin
        FrontendRoute_Print -> do
          mdeck <- askRoute
          let
            render Nothing = text "update the url to specify a deck name"
            render (Just deck) = runRequesting apiRoute $ printConsequencesDeck $ ConsequencesDeck deck
          dyn_ $ render <$> mdeck

runRequesting
  :: forall t m r.
     ( MonadHold t m
     , MonadFix m
     , PerformEvent t m
     , Prerender t m
     )
  => WebSocketEndpoint
  -> RequesterT t Api (Either Text) m r
  -> m r
runRequesting endpoint requester = do
  rec (result, requests) <- runRequesterT requester responses
      responses <- performWebSocketRequests endpoint requests
  pure result

cardsWidget :: (DomBuilder t m, HasConfigs m, MonadFix m, MonadHold t m) => Maybe (Text, DeckType) -> m ()
cardsWidget Nothing = do
  _ <- workflow (cw Nothing)
  pure ()
  where
    cw Nothing = Workflow $ do
      text "Paste cards and hit render "
      render <- button "Render Standard"
      renderAdhoc <- button "Render Adhoc"
      input <- divClass "cardsInput" $ textAreaElement $ def
      let inputText = (current $ nonEmptyText <$> (_textAreaElement_value input))
          parse =  (leftmost [mapRight Standard . parseCards "pasted input" <$> traceEvent "pasted" (tagMaybe inputText render),
                              mapRight Adhoc . readAdhocCards NoHeader tsv . encodeUtf8 <$> tagMaybe (inputText) renderAdhoc])
          (err, cards) = fanEither parse
      widgetHold_ blank (el "pre" . text . T.pack <$> err)
      pure $ ((), cw . Just <$> cards)
    cw (Just input) = Workflow $ do
      renderDeck input
      pure ((), never)
cardsWidget (Just (deckName, deckType)) = do
  let deckPath = "common/" <> deckName <> ".tsv"
  maybeCards <- getConfig deckPath
  case maybeCards of
    Nothing -> text $ "could not read " <> deckPath
    Just cardLines -> case deckType of
      StandardDeck -> case parseCards (T.unpack deckName) (decodeUtf8 cardLines) of
        Left err -> el "pre" $ text $ T.pack err
        Right deck -> renderDeck $ Standard deck
      AdhocDeck -> renderAdhocCards cardLines

renderDeck :: DomBuilder t m => Deck -> m ()
renderDeck deck = divClass "cards" $ case deck of
  Standard cards -> mapM_ card cards
  Adhoc cards -> V.mapM_ adhocCard cards

renderAdhocCards :: DomBuilder t m => ByteString -> m ()
renderAdhocCards cardLines = case readAdhocCards HasHeader tsv cardLines of
  Left err -> text $ T.pack err
  Right cards -> divClass "cards" $ mapM_ adhocCard cards
