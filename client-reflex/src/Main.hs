{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE RankNTypes #-}

module Main where

import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
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
import Frontend.Card (CardDisplayMode (..), CardSettings (..))
import Frontend.Catalog (catalogWidget)
import Frontend.Html (Render (..))

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--static"] -> do
      writeStaticPage "catalog.html" "CardPG Catalog" catalogWidget
    ["--deck", deckPath] -> do
      putStrLn $ "Generating deck for " <> deckPath
      -- Read the YAML file
      yamlContent <- BS.readFile deckPath
      case Yaml.decodeEither' yamlContent of
        Left err -> putStrLn $ "Error decoding YAML: " <> show err
        Right (actorDef :: ActorDefinition) -> do
          let baseName = takeBaseName deckPath
              outName = baseName <> ".html"
          writeStaticPage outName actorDef.name (deckWidget actorDef)
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
  let printSettings = CardSettings{displayMode = CardPrint}
  divClass "grid gap-[3mm] justify-start grid-cols-[repeat(3,56mm)]" $ do
    mapM_ (renderWith printSettings) actor.nature
    mapM_ (renderWith printSettings) actor.items
    mapM_ (renderWith printSettings) actor.deck

wrapHtml :: Text -> BS.ByteString -> BL.ByteString
wrapHtml title body =
  "<!DOCTYPE html><html><head><meta charset='utf-8'><title>"
    <> BL.fromStrict (encodeUtf8 title)
    <> "</title><link rel='stylesheet' href='client-reflex/static/output.css'></head><body>"
    <> BL.fromStrict body
    <> "</body></html>"

writeStaticPage :: FilePath -> Text -> (forall x. StaticWidget x ()) -> IO ()
writeStaticPage outPath title widget = do
  putStrLn $ "Rendering to " <> outPath
  (_, body) <- renderStatic widget
  let html = wrapHtml title body
  BL.writeFile outPath html
  putStrLn "Done."
