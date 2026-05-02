{-# LANGUAGE DataKinds #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE MultilineStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE UndecidableInstances #-}

module Main where

import Control.Exception (SomeException, catch)
import Control.Monad (forM_, unless, when)
import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO)
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Char (isAlphaNum)
import Data.Map qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding (encodeUtf8)
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
import System.FilePath (takeBaseName, (</>))
import System.Process (callProcess)

import Api.Reflex ()
import Api.Types (LogEntry, Phase (..))
import Core.Card (ActorDefinition (..))
import Core.Primitives (ActorId)
import Core.State (ActorState (..))
import Frontend.App (headWidget, uiWidget)
import Frontend.Card
  ( CardDisplayMode (..)
  , CardSettings (..)
  , renderCoreCardWith
  , renderItemCardWith
  , renderNatureCardWith
  )
import Frontend.Catalog (catalogWidget)
import Frontend.MockData qualified as Mock

import Frontend.Style.Common
import Frontend.Style.Layout
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

  let linkFile name = do
        let target = ".." </> "client-reflex" </> "static" </> name
            linkPath = outDir </> name
        isSym <- pathIsSymbolicLink linkPath `catch` (\(_ :: SomeException) -> return False)
        exists <- doesPathExist linkPath
        when (isSym || exists) $ removePathForcibly linkPath
        createFileLink target linkPath

  linkFile "base.css"
  linkFile "atomic.css"

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
  writeStaticPage outName catalogWidget
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
      writeStaticPage outName (deckWidget actorDef)

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
  (gameState, _) <- loadScenario path Nothing

  -- Helper to generate snapshot for a specific state
  let gen nameSuffix mActorId phase = do
        let baseName = "game_" <> nameSuffix
            outHtml = opts.outputDir </> baseName <> ".html"
            outPng = opts.outputDir </> baseName <> ".png"

        writeStaticPage
          outHtml
          (mockGameWidget mActorId gameState phase)

        unless skipSnapshot $ do
          unless opts.quiet $ putStrLn $ "Taking screenshot for " <> nameSuffix <> "..."
          currentDir <- getCurrentDirectory
          let absHtml = currentDir </> outHtml
          takeScreenshot absHtml outPng 1920 1080
          unless opts.quiet $ putStrLn $ "Snapshot saved to " <> outPng

  -- 3. Explicitly generate Mock Game state as well (to match GenCss coverage)
  gen "MockHero_planning" (Just Mock.mockActorId) Planning
  gen "MockHero_resolution" (Just Mock.mockActorId) Resolution

  -- 1. No Actor Selected (both phases)
  gen "none_planning" Nothing Planning
  gen "none_resolution" Nothing Resolution

  -- 2. Each Actor Selected
  let actors = Map.toList gameState.actors
  forM_ actors $ \(aid, actorState) -> do
    let rawName = T.unpack actorState.name
        safeName = filter isAlphaNum rawName
    unless (null safeName) $ do
      gen (safeName <> "_planning") (Just aid) Planning
      gen (safeName <> "_resolution") (Just aid) Resolution

-- | Widgets (Copied/Adapted)
mockGameWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadIO m
     , Prerender t m
     )
  => Maybe ActorId
  -> GameState
  -> Phase
  -> m ()
mockGameWidget initialActorId gameState phaseSetting = do
  -- Use mock actors with staged actions if available, otherwise fall back to gameState
  let baseActors = gameState.actors
      -- Merge mock actor data to exercise staging styles
      actorsWithStaging = Map.union Mock.mockActorsMap baseActors
      -- Use whichever map has data
      actorsMap = if Map.null baseActors then actorsWithStaging else baseActors
  actorsDyn <- holdDyn actorsMap never
  let logsDyn = constDyn Mock.mockLogs
  rec (_, _) <-
        runRequesterT
          (uiWidget initialActorId actorsDyn logsDyn (constDyn phaseSetting) (constDyn 1) (constDyn 1))
          never
  return ()

deckWidget :: (DomBuilder t m) => ActorDefinition -> m ()
deckWidget actor = do
  let printSettings = CardSettings{displayMode = CardPrint}
  divS deckGrid $ do
    mapM_ (renderNatureCardWith printSettings) actor.nature
    mapM_ (renderItemCardWith printSettings) actor.items
    mapM_ (renderCoreCardWith printSettings) actor.deck

wrapHtml :: BS.ByteString -> BS.ByteString -> BL.ByteString
wrapHtml headHtml body =
  "<!DOCTYPE html><html><head>"
    <> BL.fromStrict headHtml
    <> "</head><body>"
    <> BL.fromStrict body
    <> "</body></html>"

writeStaticPage :: FilePath -> (forall x. StaticWidget x ()) -> IO ()
writeStaticPage outPath widget = do
  putStrLn $ "Rendering to " <> outPath
  (_, body) <- renderStatic widget
  (_, headHtml) <- renderStatic headWidget
  let html = wrapHtml headHtml body
  BL.writeFile outPath html
  putStrLn "Done."
