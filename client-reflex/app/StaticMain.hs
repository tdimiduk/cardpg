{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE MultilineStrings #-}
{-# LANGUAGE RankNTypes #-}

module Main where

import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Text (Text)
import Data.Text.Encoding (encodeUtf8)
import Data.Yaml qualified as Yaml
import Reflex.Dom.Core
import System.Environment (getArgs)
import System.FilePath (takeBaseName)

import Api.Reflex ()
import Core.Card (ActorDefinition (..))
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
      putStrLn "Usage:"
      putStrLn "  cardpg-static --static          Generate catalog.html"
      putStrLn "  cardpg-static --deck <path>     Generate deck HTML from YAML"

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
