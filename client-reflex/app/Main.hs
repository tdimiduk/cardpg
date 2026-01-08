{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE MultilineStrings #-}
{-# LANGUAGE RankNTypes #-}

module Main where

import Data.Text qualified as T
import Data.UUID.V4 qualified as UUID
import Language.Javascript.JSaddle.WebSockets (jsaddleApp, jsaddleOr)
import Network.Wai.Handler.Warp (run)
import Network.WebSockets (defaultConnectionOptions)
import Reflex.Dom.Core
import System.Environment (lookupEnv)

import Api.Reflex ()
import Frontend.App (appWidget)

main :: IO ()
main = do
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
