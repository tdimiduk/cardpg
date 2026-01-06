{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Monad (void)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map
import Data.Text qualified as T
import Data.Text.Encoding (encodeUtf8)
import Data.UUID (UUID)
import Data.UUID.V4 qualified as UUID
import Data.Yaml qualified as Yaml
import Language.Javascript.JSaddle.WebSockets (jsaddleApp, jsaddleOr)
import Network.Wai.Handler.Warp (run)
import Network.WebSockets (defaultConnectionOptions)
import Reflex.Dom.Core
import System.Environment (getArgs, lookupEnv)
import System.FilePath (takeBaseName)

import CardPG.Api.Reflex (ReflexServerMessage (..))
import CardPG.Api.Types qualified as Api
import CardPG.Core.Card (ActorDefinition (..), CardInstance, CoreCard)
import CardPG.Core.State (ActorState (..), CoreCardState (..))
import CardPG.Core.Util (tshow)

import Frontend.Card ()
import Frontend.Catalog (catalogWidget)
import Frontend.Html (Render (..))

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--static"] -> do
      putStrLn "Generating static catalog.html..."
      (_, body) <- renderStatic catalogWidget
      let html =
            "<!DOCTYPE html><html><head><meta charset='utf-8'><title>CardPG Catalog</title><link rel='stylesheet' href='cardpg-client-reflex/static/output.css'></head><body>"
              <> BL.fromStrict body
              <> "</body></html>"
      BL.writeFile "catalog.html" html
      BL.writeFile "catalog.html" html
      putStrLn "Done."
    ["--deck", deckPath] -> do
      putStrLn $ "Generating deck for " <> deckPath
      -- Read the YAML file
      yamlContent <- BS.readFile deckPath
      case Yaml.decodeEither' yamlContent of
        Left err -> putStrLn $ "Error decoding YAML: " <> show err
        Right (actorDef :: ActorDefinition) -> do
          let baseName = takeBaseName deckPath
              outName = baseName <> ".html"
          putStrLn $ "Rendering to " <> outName

          (_, body) <- renderStatic (deckWidget actorDef)
          let html =
                "<!DOCTYPE html><html><head><meta charset='utf-8'><title>"
                  <> BL.fromStrict (encodeUtf8 $ actorDef.name)
                  <> "</title><link rel='stylesheet' href='cardpg-client-reflex/static/output.css'></head><body>"
                  <> BL.fromStrict body
                  <> "</body></html>"
          BL.writeFile outName html
          putStrLn "Done."
    _ -> do
      putStrLn "Starting CardPG Reflex Client..."
      clientId <- UUID.nextRandom
      port <- maybe 3003 read <$> lookupEnv "JSADDLE_WARP_PORT"
      putStrLn $ "Running jsaddle-warp server on port " <> show port

      -- Build the jsaddle application with websocket support
      jsaddleApplication <-
        jsaddleOr
          defaultConnectionOptions
          (mainWidgetWithHead headWidget (appWidget clientId))
          jsaddleApp

      run port jsaddleApplication

headWidget :: (DomBuilder t m) => m ()
headWidget = do
  el "title" $ text "CardPG Reflex Client"
  elAttr "meta" ("charset" =: "utf-8") blank
  elAttr "link" ("rel" =: "stylesheet" <> "href" =: "/output.css") blank

bodyWidget :: (MonadWidget t m) => UUID -> m ()
bodyWidget clientId = do
  clickEvt <- button "Toggle Catalog Mode"
  isCatalog <- toggle False clickEvt
  el "hr" blank
  dyn_ $ ffor isCatalog $ \case
    True -> catalogWidget
    False -> appWidget clientId

appWidget :: (MonadWidget t m) => UUID -> m ()
appWidget clientId = do
  let
    wsUrl = "ws://localhost:3004/api?clientId=" <> T.pack (show clientId) <> "&name=ReflexReflex"

  rec let
        -- Send Join message immediately on open using Api types for compatibility with input parser
        joinMsg = Api.Join "ReflexReflex" Nothing
        sendEvt = fmap (const [BL.toStrict $ encode joinMsg]) (_webSocket_open ws)

        wsConfig = def{_webSocketConfig_send = sendEvt}

      ws <- webSocket wsUrl wsConfig

      let serverMsgEvt = fmap (eitherDecode . BL.fromStrict) (_webSocket_recv ws)

      let
        updateActors (Right (ReflexWelcome _ a)) _ = a
        updateActors (Right (ReflexUpdate a)) _ = a
        updateActors _ old = old

      actorsMapDyn <- foldDyn updateActors Map.empty serverMsgEvt

      -- Actor Selection State
      rec selectedActorId <- holdDyn Nothing (fmap Just selectEvt)

          -- Layout: Sidebar + Main Content
          selectEvt <- divClass "flex flex-row h-screen bg-slate-950 text-slate-100 overflow-hidden" $ do
            -- Sidebar (Left)
            selectEvt' <- divClass "w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl" $ do
              -- Sidebar Header (Static for now)
              divClass "p-6 border-b border-slate-800" $ do
                elClass "h1" "text-xl font-bold text-slate-100" $ text "CardPG"

              -- Actor List or Active Actor Details
              dyn_ $ ffor selectedActorId $ \case
                Nothing -> divClass "p-4 text-center text-slate-500 italic text-sm" $ text "Select an actor"
                Just aid -> do
                  -- Active Actor Header (Mini)
                  divClass "p-4 border-b border-slate-800 bg-slate-900 flex items-center gap-3" $ do
                    divClass
                      "w-10 h-10 rounded-full border-2 border-slate-600 bg-slate-800 flex items-center justify-center shrink-0"
                      $ text "A" -- Placeholder Avatar
                    divClass "flex-1 overflow-hidden" $ do
                      -- We need to look up the name from the map, but for now just show ID
                      elClass "div" "font-bold text-slate-100 truncate" $ text $ tshow aid
                      elClass "div" "text-xs text-slate-500 uppercase" $ text "Player"

              -- Actor List (Always visible in this simple version, or switchable)
              divClass "flex-1 overflow-y-auto p-4 space-y-2" $ do
                selectClick <- listWithKey actorsMapDyn $ \aid actorDyn -> do
                  (e, _) <- elClass'
                    "button"
                    "w-full text-left px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded transition-colors group"
                    $ do
                      dyn_ $ ffor actorDyn $ \actor -> do
                        text $ actor.name
                  return (aid <$ domEvent Click e)

                -- Aggregate clicks
                return $ switchDyn $ fmap (leftmost . Map.elems) selectClick

            -- Main Content Area (Right)
            divClass "flex-1 relative bg-slate-900 overflow-hidden flex flex-col" $ do
              -- Top Bar / Game Board Area (Placeholder)
              divClass "flex-1 flex items-center justify-center text-slate-700" $
                text "Game Board Area"

              -- Player Hand Area (Bottom Overlay)
              dyn_ $ ffor selectedActorId $ \case
                Nothing -> blank
                Just aid -> do
                  let handDyn =
                        fmap (maybe [] (\a -> a.coreState.hand) . Map.lookup aid) actorsMapDyn
                  renderHand handDyn

            return selectEvt'

  return ()

renderHand :: (MonadWidget t m) => Dynamic t [CardInstance CoreCard] -> m ()
renderHand handDyn = do
  divClass "absolute bottom-0 left-0 right-0 flex justify-center items-end pb-4 pointer-events-none" $ do
    divClass "pointer-events-auto flex items-end justify-center px-8" $ do
      -- We need to render the list with standard Reflex list function
      -- Note: simpleList is efficient for dynamic lists
      void $ simpleList handDyn $ \cardDyn -> do
        divClass "pointer-events-auto relative group w-64 shrink-0" $ do
          divClass
            "transition-transform duration-200 ease-out origin-bottom hover:-translate-y-8 hover:z-50 cursor-pointer"
            $ do
              dyn_ $ ffor cardDyn render

deckWidget :: (DomBuilder t m) => ActorDefinition -> m ()
deckWidget actor = do
  divClass "print-deck-grid" $ do
    mapM_ render actor.nature
    mapM_ render actor.items
    mapM_ render actor.deck
