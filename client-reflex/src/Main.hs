{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE MultilineStrings #-}
{-# LANGUAGE RankNTypes #-}

module Main where

import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text qualified as T
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
import Frontend.Style qualified as Style

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
  el "script" $
    text
      """
      const init = () => {
        const ro = new ResizeObserver(entries => {
          for (const entry of entries) {
            const container = entry.target;
            const content = container.querySelector('.scaler-target');
            if (!content) continue;
            const nativeW = parseFloat(container.dataset.nativeW);
            const currentW = entry.contentRect.width;
            if (nativeW && currentW) {
              const scale = currentW / (nativeW * 3.7795275591);
              content.style.transform = `scale(${scale})`;
            }
          }
        });

        const mo = new MutationObserver(mutations => {
          for (const m of mutations) {
            for (const node of m.addedNodes) {
              if (node.nodeType === 1) {
                if (node.classList.contains('scaler-container')) ro.observe(node);
                node.querySelectorAll('.scaler-container').forEach(c => ro.observe(c));
              }
            }
          }
        });
        mo.observe(document.body, { childList: true, subtree: true });

        // Find existing ones
        document.querySelectorAll('.scaler-container').forEach(c => ro.observe(c));
      };

      if (document.readyState === 'loading') {
        window.addEventListener('DOMContentLoaded', init);
      } else {
        init();
      }
      """

deckWidget :: (DomBuilder t m) => ActorDefinition -> m ()
deckWidget actor = do
  let printSettings = CardSettings{displayMode = CardPrint}
  Style.divStyle Style.deckGrid $ do
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
