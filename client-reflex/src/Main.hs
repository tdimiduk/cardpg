{-# LANGUAGE MonoLocalBinds #-}

module Main where

import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Text.Encoding (encodeUtf8)
import Data.UUID.V4 qualified as UUID
import Data.Yaml qualified as Yaml
import Language.Javascript.JSaddle.WebSockets (jsaddleApp, jsaddleOr)
import Network.Wai.Handler.Warp (run)
import Network.WebSockets (defaultConnectionOptions)
import Reflex.Dom.Core
import System.Environment (getArgs, lookupEnv)
import System.FilePath (takeBaseName)

import Api.Reflex ()
import Core.Card (ActorDefinition (..))
import Frontend.App (appWidget)
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

deckWidget :: (DomBuilder t m) => ActorDefinition -> m ()
deckWidget actor = do
  divClass "print-deck-grid" $ do
    mapM_ render actor.nature
    mapM_ render actor.items
    mapM_ render actor.deck
