{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE MultilineStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE UndecidableInstances #-}

module Main where

import Control.Exception (SomeException, catch)
import Control.Monad (unless, when)
import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding (encodeUtf8)
import Data.UUID qualified as UUID
import Data.UUID.V4 qualified as UUIDV4
import Data.Yaml qualified as Yaml
import Options.Applicative qualified as OA
import Reflex.Dom.Core
import System.Directory
  ( createDirectoryIfMissing
  , createFileLink
  , doesPathExist
  , getCurrentDirectory
  , pathIsSymbolicLink
  , removePathForcibly
  )
import System.FilePath (makeRelative, takeBaseName, (</>))
import System.Process (callProcess)
import System.Random (newStdGen)

import Api.Reflex ()
import Core.Card (ActorDefinition (..))
import Core.Primitives (ActorId, Identified (..))
import Frontend.App (uiWidget)
import Frontend.Card (CardDisplayMode (..), CardSettings (..))
import Frontend.Catalog (catalogWidget)
import Frontend.Html (Render (..))
import Frontend.Style qualified as Style
import Server.Game (GameState (..))
import Server.Scenario (loadScenario)

-- | CLI Options
data Mode
  = Catalog {noSnapshot :: Bool}
  | Deck {deckPath :: FilePath, noSnapshot :: Bool}
  | Game {scenarioPath :: FilePath, noSnapshot :: Bool}

data Options = Options
  { outputDir :: FilePath
  , quiet :: Bool
  , mode :: Mode
  }

optionsParser :: OA.Parser Options
optionsParser =
  Options
    <$> OA.strOption
      ( OA.long "output-dir"
          <> OA.metavar "DIR"
          <> OA.help "Output directory for generated files"
          <> OA.value "output"
          <> OA.showDefault
      )
    <*> OA.switch
      ( OA.long "quiet"
          <> OA.help "Suppress output"
      )
    <*> OA.subparser
      ( OA.command
          "catalog"
          ( OA.info
              (Catalog <$> OA.switch (OA.long "no-snapshot" <> OA.help "Skip snapshot generation"))
              (OA.progDesc "Generate catalog snapshot")
          )
          <> OA.command
            "deck"
            ( OA.info
                ( Deck
                    <$> OA.strArgument (OA.metavar "FILE" <> OA.help "Path to actor YAML file")
                    <*> OA.switch (OA.long "no-snapshot" <> OA.help "Skip snapshot generation")
                )
                (OA.progDesc "Generate deck snapshot")
            )
          <> OA.command
            "game"
            ( OA.info
                ( Game
                    <$> OA.strArgument (OA.metavar "SCENARIO" <> OA.help "Path to scenario YAML file")
                    <*> OA.switch (OA.long "no-snapshot" <> OA.help "Skip snapshot generation")
                )
                (OA.progDesc "Generate game snapshot")
            )
      )

main :: IO ()
main = do
  opts <- OA.execParser optsInfo
  setupOutputDir opts.outputDir
  case opts.mode of
    Catalog ns -> generateCatalog opts ns
    Deck path ns -> generateDeck opts path ns
    Game path ns -> generateGame opts path ns
  where
    optsInfo =
      OA.info
        (optionsParser OA.<**> OA.helper)
        ( OA.fullDesc
            <> OA.progDesc "Generate static HTML and snapshots for CardPG"
            <> OA.header "cardpg-static - Static site generator for CardPG"
        )

-- | Directory Setup
setupOutputDir :: FilePath -> IO ()
setupOutputDir outDir = do
  createDirectoryIfMissing True outDir
  let linkName = "client-reflex"
      target = ".." </> "client-reflex"
      linkPath = outDir </> linkName

  -- Check and recreate symlink if needed
  isSym <- pathIsSymbolicLink linkPath `catch` (\(_ :: SomeException) -> return False)
  exists <- doesPathExist linkPath
  when (isSym || exists) $ removePathForcibly linkPath
  createFileLink target linkPath

-- | Snapshot Helpers
takeScreenshot :: FilePath -> FilePath -> Int -> Int -> IO ()
takeScreenshot srcHtml outPng width height = do
  -- Chromium usually wants absolute paths
  let cmd = "chromium"
      args =
        [ "--headless"
        , "--disable-gpu"
        , "--hide-scrollbars"
        , "--window-size=" <> show width <> "," <> show height
        , "--screenshot=" <> outPng
        , "file://" <> srcHtml
        ]

  callProcess cmd args
    `catch` ( \(e :: SomeException) ->
                putStrLn $ "Warning: Failed to take screenshot: " <> show e
            )

printPdf :: FilePath -> FilePath -> IO ()
printPdf srcHtml outPdf = do
  let cmd = "chromium"
      args =
        [ "--headless"
        , "--disable-gpu"
        , "--print-to-pdf=" <> outPdf
        , "--no-pdf-header-footer"
        , "file://" <> srcHtml
        ]
  callProcess cmd args
    `catch` ( \(e :: SomeException) ->
                putStrLn $ "Warning: Failed to generate PDF: " <> show e
            )

-- | Generators
generateCatalog :: Options -> Bool -> IO ()
generateCatalog opts skipSnapshot = do
  let outName = opts.outputDir </> "catalog.html"
  writeStaticPage outName "CardPG Catalog" catalogWidget
  unless skipSnapshot $ do
    unless opts.quiet $ putStrLn "Taking screenshot..."
    currentDir <- getCurrentDirectory
    let absHtml = currentDir </> outName
        outPng = opts.outputDir </> "catalog.png"
    takeScreenshot absHtml outPng 1920 2000
    unless opts.quiet $ putStrLn $ "Snapshot saved to " <> outPng

generateDeck :: Options -> FilePath -> Bool -> IO ()
generateDeck opts path skipSnapshot = do
  unless opts.quiet $ putStrLn $ "Generating deck for " <> path
  yamlContent <- BS.readFile path
  case Yaml.decodeEither' yamlContent of
    Left err -> putStrLn $ "Error decoding YAML: " <> show err
    Right (actorDef :: ActorDefinition) -> do
      let baseName = takeBaseName path
          outName = opts.outputDir </> baseName <> ".html"
      writeStaticPage outName actorDef.name (deckWidget actorDef)

      unless skipSnapshot $ do
        currentDir <- getCurrentDirectory
        let absHtml = currentDir </> outName
            outPng = opts.outputDir </> baseName <> ".png"
            outPdf = opts.outputDir </> baseName <> ".pdf"

        unless opts.quiet $ putStrLn "Generating PDF..."
        printPdf absHtml outPdf
        unless opts.quiet $ putStrLn $ "PDF saved to " <> outPdf

        unless opts.quiet $ putStrLn "Taking screenshot..."
        takeScreenshot absHtml outPng 1920 2000
        unless opts.quiet $ putStrLn $ "PNG saved to " <> outPng

generateGame :: Options -> FilePath -> Bool -> IO ()
generateGame opts path skipSnapshot = do
  unless opts.quiet $ putStrLn $ "Generating game view for " <> path
  (gameState, _) <- loadScenario path
  case Map.toList (gameState.actors) of
    ((aid, _) : _) -> do
      clientId <- UUIDV4.nextRandom
      let outName = opts.outputDir </> "game.html"
      writeStaticPage outName "CardPG Game" (mockGameWidget clientId aid gameState)

      unless skipSnapshot $ do
        unless opts.quiet $ putStrLn "Taking screenshot..."
        currentDir <- getCurrentDirectory
        let absHtml = currentDir </> outName
            outPng = opts.outputDir </> "game.png"
        takeScreenshot absHtml outPng 1920 1080
        unless opts.quiet $ putStrLn $ "Snapshot saved to " <> outPng
    [] -> putStrLn "No actors found in scenario"

-- | Widgets (Copied/Adapted)
mockGameWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadIO m
     )
  => UUID.UUID
  -> ActorId
  -> GameState
  -> m ()
mockGameWidget clientId playerId gameState = do
  let actorsMap = gameState.actors
  actorsDyn <- holdDyn actorsMap never
  rec (_, _) <- runRequesterT (uiWidget clientId actorsDyn) never
  return ()

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
