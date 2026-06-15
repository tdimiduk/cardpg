{-# LANGUAGE DataKinds #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE MultilineStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE UndecidableInstances #-}

module Main where

import Control.Exception (SomeException, catch)
import Control.Monad (forM, forM_, unless, when)
import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO)
import Data.Aeson (Result (..), Value (..), fromJSON, toJSON)
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Char (isAlphaNum)
import Data.List qualified as List
import Data.Map qualified as Map
import Data.Pool (withResource)
import Data.Text qualified as T
import Data.Time (getCurrentTime)
import Data.Yaml qualified as Yaml
import Database.Beam
import Database.Beam.Postgres
import Database.PostgreSQL.Simple qualified as Pg
import Options.Applicative qualified as OA
import Reflex.Dom.Core hiding (Error, mergeList, select)
import System.Directory
  ( createDirectoryIfMissing
  , createFileLink
  , doesDirectoryExist
  , doesPathExist
  , getCurrentDirectory
  , listDirectory
  , pathIsSymbolicLink
  , removePathForcibly
  )
import System.FilePath (takeBaseName, takeExtension, (</>))
import System.Process (callProcess)

import Api.Reflex ()
import Api.Types (LogEntry (..), LogId (..), LogPayload (..), LogSender (..), Phase (..))
import Control.Applicative ((<|>))
import Core.Card
  ( ActorDefinition (..)
  , CardInstance
  , ConsequenceCard (..)
  , CoreCard (..)
  , CustomCard (..)
  , EncounterCard (..)
  , ItemCard (..)
  , NatureCard (..)
  , TalentCard (..)
  , customCardCategoryText
  , customCardFingerprint
  , customCardIdText
  , customCardNameText
  )
import Core.NonEmptyText (getRawText)
import Core.Primitives (ActorId, CardInstanceId (..), ChallengeId (..), Identified (..))
import Core.State
  ( ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , ChallengeSource (..)
  , CoreCardState (..)
  , MapMode (..)
  , PlannedAction (..)
  )
import Core.Stats (ResourceType (..))
import Data.Maybe (catMaybes, fromMaybe, listToMaybe)
import Data.Set qualified as Set
import Frontend.App (headWidget, uiWidget)
import Frontend.Card
  ( CardDisplayMode (..)
  , CardSettings (..)
  , renderCoreCardWith
  , renderItemCardWith
  , renderNatureCardWith
  )
import Frontend.Catalog (catalogWidget)
import Frontend.Game.ActorDetails.DeckViewer (DeckViewData (..), deckViewerModal)
import Frontend.Game.Class (SessionState (..), runGameT)
import Frontend.Game.Planning (StagingState (..))
import Server.Config (loadDbConfig)
import Server.DB (CustomCardRecord, CustomCardT (..), cardpgDb, customCards, initDB)
import Server.Types (StorageBackend (..))

import Frontend.Style.Common
import Frontend.Style.Layout
import Server.Game (GameState (..))
import Server.Scenario (loadSavedGame, loadScenario)

-- | CLI Options
data Mode
  = Catalog {noSnapshot :: Bool}
  | Deck {deckPath :: FilePath, noSnapshot :: Bool}
  | Game {scenarioPath :: FilePath, noSnapshot :: Bool}
  | SyncExport
  | SyncImport

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
          <> OA.command
            "sync-export"
            ( OA.info
                (pure SyncExport)
                (OA.progDesc "Export custom cards from the database back to YAML files in data/cards/")
            )
          <> OA.command
            "sync-import"
            ( OA.info
                (pure SyncImport)
                (OA.progDesc "Import card definitions from YAML files in data/cards/ into the database")
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
    SyncExport -> runSyncExport opts
    SyncImport -> runSyncImport opts
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
        let target = ".." </> "client" </> "static" </> name
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
        , "--log-level=3"
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
        , "--log-level=3"
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
  -- Try to load as a saved game (GameState) first, otherwise fall back to loadScenario
  gameState <-
    loadSavedGame path
      `catch` ( \(_ :: SomeException) -> do
                  (gs, _) <- loadScenario path Nothing
                  return gs
              )

  -- Find player actor dynamically
  let mVallhach = List.find (\(_, a) -> a.name == "vallhach" || a.name == "Vallhach") (Map.toList gameState.actors)
      mFirstActor = List.uncons (Map.toList gameState.actors)
      playerActorName = case mVallhach of
        Just (_, a) -> filter isAlphaNum (T.unpack a.name)
        Nothing -> case mFirstActor of
          Just ((_, a), _) -> filter isAlphaNum (T.unpack a.name)
          Nothing -> "player"

  -- Helper to generate snapshot for a specific state
  let gen nameSuffix mActorId phase = do
        let baseName = "game_" <> nameSuffix
            outHtml = opts.outputDir </> baseName <> ".html"
            outPng = opts.outputDir </> baseName <> ".png"

        writeStaticPage
          outHtml
          (mockGameWidget Nothing mActorId gameState phase)

        unless skipSnapshot $ do
          unless opts.quiet $ putStrLn $ "Taking screenshot for " <> nameSuffix <> "..."
          currentDir <- getCurrentDirectory
          let absHtml = currentDir </> outHtml
          takeScreenshot absHtml outPng 1920 1080
          unless opts.quiet $ putStrLn $ "Snapshot saved to " <> outPng

  -- Helper to generate snapshot with a custom widget
  let genWith customWidget nameSuffix = do
        let baseName = "game_" <> nameSuffix
            outHtml = opts.outputDir </> baseName <> ".html"
            outPng = opts.outputDir </> baseName <> ".png"

        writeStaticPage
          outHtml
          customWidget

        unless skipSnapshot $ do
          unless opts.quiet $ putStrLn $ "Taking screenshot for " <> nameSuffix <> "..."
          currentDir <- getCurrentDirectory
          let absHtml = currentDir </> outHtml
          takeScreenshot absHtml outPng 1920 1080
          unless opts.quiet $ putStrLn $ "Snapshot saved to " <> outPng

  -- Extra states for complete interactive UI styling visibility, generated for the main player character dynamically
  unless (null playerActorName) $ do
    genWith (mockGameWidgetWithStaging gameState) (playerActorName <> "_staging")
    genWith (mockGameWidgetWithDeckView gameState) (playerActorName <> "_deckview")
    genWith (mockGameWidgetWithDiscardView gameState) (playerActorName <> "_discardview")
    genWith (mockGameWidgetWithDefense gameState) (playerActorName <> "_defense")

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
  => Maybe StagingState
  -> Maybe ActorId
  -> GameState
  -> Phase
  -> m ()
mockGameWidget mStaging initialActorId gameState phaseSetting = do
  let baseActors = gameState.actors
  actorsDyn <- holdDyn baseActors never
  let logsDyn = constDyn gameState.history
      sessionState = SessionState actorsDyn logsDyn (constDyn phaseSetting) (constDyn MapModeGrid)
  rec (_, _) <-
        runRequesterT
          (runGameT sessionState (uiWidget mStaging initialActorId))
          never
  return ()

-- | Helper to get a card's name bypassing NoFieldSelectors
cardName :: CardInstance CoreCard -> T.Text
cardName (Identified _ (CoreCard nameNE _ _ _ _ _ _)) = getRawText nameNE

-- | Specialized mock widget that natively displays the active staging/planning state
mockGameWidgetWithStaging
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadIO m
     , Prerender t m
     )
  => GameState
  -> m ()
mockGameWidgetWithStaging gameState = do
  let mVallhach = List.find (\(_, a) -> a.name == "vallhach" || a.name == "Vallhach") (Map.toList gameState.actors)
      mFirstActor = List.uncons (Map.toList gameState.actors)
      (actorId, actorState) = case mVallhach of
        Just (aid, a) -> (Just aid, a)
        Nothing -> case mFirstActor of
          Just ((aid, a), _) -> (Just aid, a)
          Nothing -> (Nothing, error "No actors found in game state for staging preview")

  case actorId of
    Nothing -> blank
    Just aid -> do
      let hand = actorState.coreState.hand
          mActionId =
            fmap (.id) (List.find (\c -> cardName c == "Sunburn") hand)
              <|> fmap (.id) (listToMaybe hand)
          mResource1 = fmap (.id) (List.find (\c -> cardName c == "Lightning Dodge") hand)
          mResource2 = fmap (.id) (List.find (\c -> cardName c == "Blinding Sun") hand)
          mockStagingState = case mActionId of
            Nothing -> Nothing
            Just actId ->
              Just $
                StagingState
                  { stagedActionId = actId
                  , stagedResourceIds = Set.fromList (catMaybes [mResource1, mResource2])
                  }
      mockGameWidget mockStagingState (Just aid) gameState Planning

-- | Specialized mock widget that overlays the Deck Viewer modal (Draw Pile)
mockGameWidgetWithDeckView
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadIO m
     , Prerender t m
     )
  => GameState
  -> m ()
mockGameWidgetWithDeckView gameState = do
  let mVallhach = List.find (\(_, a) -> a.name == "vallhach" || a.name == "Vallhach") (Map.toList gameState.actors)
      mFirstActor = List.uncons (Map.toList gameState.actors)
      (actorId, actorState) = case mVallhach of
        Just (aid, a) -> (Just aid, a)
        Nothing -> case mFirstActor of
          Just ((aid, a), _) -> (Just aid, a)
          Nothing -> (Nothing, error "No actors found in game state for deck view preview")

  mockGameWidget Nothing actorId gameState Planning

  do
    pb <- getPostBuild
    let coreState = actorState.coreState :: CoreCardState
        realDeckCards = map (\x -> (x :: CardInstance CoreCard).content) (coreState.deck)
        realHandCards = map (\x -> (x :: CardInstance CoreCard).content) (coreState.hand)
        viewCards = realDeckCards ++ realHandCards
        viewData = DeckViewData "Draw Pile" viewCards
    deckViewerModal (Just viewData <$ pb)
    return ()

-- | Specialized mock widget that overlays the Discard Pile modal
mockGameWidgetWithDiscardView
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadIO m
     , Prerender t m
     )
  => GameState
  -> m ()
mockGameWidgetWithDiscardView gameState = do
  let mVallhach = List.find (\(_, a) -> a.name == "vallhach" || a.name == "Vallhach") (Map.toList gameState.actors)
      mFirstActor = List.uncons (Map.toList gameState.actors)
      (actorId, actorState) = case mVallhach of
        Just (aid, a) -> (Just aid, a)
        Nothing -> case mFirstActor of
          Just ((aid, a), _) -> (Just aid, a)
          Nothing -> (Nothing, error "No actors found in game state for discard view preview")

  mockGameWidget Nothing actorId gameState Planning

  do
    pb <- getPostBuild
    let coreState = actorState.coreState :: CoreCardState
        realDeckCards = map (\x -> (x :: CardInstance CoreCard).content) (coreState.deck)
        realHandCards = map (\x -> (x :: CardInstance CoreCard).content) (coreState.hand)
        viewCards = realDeckCards ++ realHandCards
        viewData = DeckViewData "Discard" viewCards
    deckViewerModal (Just viewData <$ pb)
    return ()

-- | Specialized mock widget that sets up an active defense resolution overlay
mockGameWidgetWithDefense
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadIO m
     , Prerender t m
     )
  => GameState
  -> m ()
mockGameWidgetWithDefense gameState = do
  let mVallhach = List.find (\(_, a) -> a.name == "vallhach" || a.name == "Vallhach") (Map.toList gameState.actors)
      mFirstActor = List.uncons (Map.toList gameState.actors)
      (actorId, actorState) = case mVallhach of
        Just (aid, a) -> (Just aid, a)
        Nothing -> case mFirstActor of
          Just ((aid, a), _) -> (Just aid, a)
          Nothing -> (Nothing, error "No actors found in game state for defense preview")

  case actorId of
    Nothing -> blank
    Just aid -> do
      let challengeId = ChallengeId (read "00000000-0000-0000-0000-000000000099")
          challenge =
            ActiveChallenge
              { id = challengeId
              , source = CSAdHoc "Fierce Attack" Nothing
              , challengeStrength = 4
              , challengeColor = Red
              }
          -- Use first card in deck as flipped card
          coreState = actorState.coreState :: CoreCardState
          defCards = take 1 coreState.deck
          activeDefense =
            ActiveDefense
              { activeChallenge = challenge
              , cards = defCards
              }
          actorState' = actorState{coreState = coreState{defending = Just activeDefense}}
          actors' = Map.insert aid actorState' gameState.actors

          -- Insert challenge log entry
          logId = LogId (read "00000000-0000-0000-0000-000000000099")
          logPayload = LogChallenge challenge PPass
          logEntry = LogEntry logId SenderGM logPayload
          history' = logEntry : gameState.history

          gameState' = gameState{actors = actors', history = history'}

      mockGameWidget Nothing (Just aid) gameState' Resolution

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

--------------------------------------------------------------------------------
-- CLI Sync Implementation
--------------------------------------------------------------------------------

runSyncExport :: Options -> IO ()
runSyncExport _ = do
  dbCfg <- loadDbConfig
  backend <- initDB dbCfg
  case backend of
    InMemoryBackend _ -> putStrLn "Error: Cannot export from InMemory DB backend."
    PostgresBackend pool -> do
      withResource pool $ \conn -> do
        records <-
          runBeamPostgres conn $
            runSelectReturningList $
              select $
                all_ (customCards cardpgDb)
        putStrLn $ "Found " ++ show (length records) ++ " custom cards in DB."

        -- Group by sourceFile
        let grouped = Map.fromListWith (++) [(c.customCardSourceFile, [c]) | c <- records]

        forM_ (Map.toList grouped) $ \(sourceFile, cardRecords) -> do
          let relPath = T.unpack sourceFile
              fullPath = "data" </> "cards" </> relPath
          putStrLn $ "Syncing changes to " ++ fullPath
          fileExists <- doesPathExist fullPath
          if not fileExists
            then do
              putStrLn $ "Creating new file " ++ fullPath
              createDirectoryIfMissing True (takeBaseName fullPath) -- wait, takeDirectory is correct, but takeBaseName of fullPath has directory structure if we extract path directory
              -- Let's extract directory using takeDirectory or just write file directly.
              -- Actually, createDirectoryIfMissing is handled. Let's make sure directory exists:
              let dirName = takeDirectory' fullPath
              createDirectoryIfMissing True dirName
              let cards = catMaybes [decodeCard r | r <- cardRecords]
              Yaml.encodeFile fullPath cards
            else classifyAndExport fullPath cardRecords

takeDirectory' :: FilePath -> FilePath
takeDirectory' fp =
  let parts = T.splitOn "/" (T.pack fp)
   in if null parts
        then "."
        else T.unpack $ T.intercalate "/" (init parts)

classifyAndExport :: FilePath -> [CustomCardRecord] -> IO ()
classifyAndExport path records
  | "/pc/" `List.isInfixOf` path || "/monsters/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (actorDef :: ActorDefinition) -> do
          let updated = updateActorDef actorDef records
          Yaml.encodeFile path updated
          putStrLn $ "Successfully exported to ActorDefinition: " ++ path
        Left err -> putStrLn $ "Error parsing ActorDefinition " ++ path ++ ": " ++ show err
  | "/consequences/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (cards :: [ConsequenceCard]) -> do
          let updated = updateConsequenceList cards records
          Yaml.encodeFile path updated
          putStrLn $ "Successfully exported to [ConsequenceCard]: " ++ path
        Left err -> putStrLn $ "Error parsing ConsequenceCards " ++ path ++ ": " ++ show err
  | "/items/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (cards :: [ItemCard]) -> do
          let updated = updateItemList cards records
          Yaml.encodeFile path updated
          putStrLn $ "Successfully exported to [ItemCard]: " ++ path
        Left err -> putStrLn $ "Error parsing ItemCards " ++ path ++ ": " ++ show err
  | "/nature/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (cards :: [NatureCard]) -> do
          let updated = updateNatureList cards records
          Yaml.encodeFile path updated
          putStrLn $ "Successfully exported to [NatureCard]: " ++ path
        Left err -> putStrLn $ "Error parsing NatureCards " ++ path ++ ": " ++ show err
  | "/core/" `List.isInfixOf` path || "/status/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (cards :: [CoreCard]) -> do
          let updated = updateCoreList cards records
          Yaml.encodeFile path updated
          putStrLn $ "Successfully exported to [CoreCard]: " ++ path
        Left err -> putStrLn $ "Error parsing CoreCards " ++ path ++ ": " ++ show err
  | otherwise = putStrLn $ "Unknown path category for export: " ++ path

coreCardKey :: CoreCard -> T.Text
coreCardKey c = getRawText c.name <> "-" <> customCardFingerprint (CustomCore c)

itemCardKey :: ItemCard -> T.Text
itemCardKey c = getRawText c.name <> "-" <> customCardFingerprint (CustomItem c)

natureCardKey :: NatureCard -> T.Text
natureCardKey c = getRawText c.name <> "-" <> customCardFingerprint (CustomNature c)

consequenceCardKey :: ConsequenceCard -> T.Text
consequenceCardKey c = getRawText c.name <> "-" <> customCardFingerprint (CustomConsequence c)

updateActorDef :: ActorDefinition -> [CustomCardRecord] -> ActorDefinition
updateActorDef actorDef records =
  let (cores, items, natures) = partitionRecords records
      updatedDeck = mergeList actorDef.deck cores coreCardKey
      updatedItems = mergeList actorDef.items items itemCardKey
      updatedNature = mergeList actorDef.nature natures natureCardKey
   in actorDef
        { deck = updatedDeck
        , items = updatedItems
        , nature = updatedNature
        }
  where
    partitionRecords :: [CustomCardRecord] -> ([CoreCard], [ItemCard], [NatureCard])
    partitionRecords [] = ([], [], [])
    partitionRecords (r : rs) =
      let (c, i, n) = partitionRecords rs
       in case decodeCard r of
            Just (CustomCore cc) -> (cc : c, i, n)
            Just (CustomItem ic) -> (c, ic : i, n)
            Just (CustomNature nc) -> (c, i, nc : n)
            _ -> (c, i, n)

mergeList :: [a] -> [a] -> (a -> T.Text) -> [a]
mergeList existing new getName =
  let newMap = Map.fromList [(getName n, n) | n <- new]
      mergedExisting = map (\e -> fromMaybe e (Map.lookup (getName e) newMap)) existing
      existingNames = Set.fromList (map getName existing)
      addedNew = filter (\n -> not (Set.member (getName n) existingNames)) new
   in mergedExisting ++ addedNew

updateConsequenceList :: [ConsequenceCard] -> [CustomCardRecord] -> [ConsequenceCard]
updateConsequenceList existing records =
  let newConsequences =
        catMaybes [case decodeCard r of Just (CustomConsequence cc) -> Just cc; _ -> Nothing | r <- records]
   in mergeList existing newConsequences consequenceCardKey

updateItemList :: [ItemCard] -> [CustomCardRecord] -> [ItemCard]
updateItemList existing records =
  let newItems = catMaybes [case decodeCard r of Just (CustomItem ic) -> Just ic; _ -> Nothing | r <- records]
   in mergeList existing newItems itemCardKey

updateNatureList :: [NatureCard] -> [CustomCardRecord] -> [NatureCard]
updateNatureList existing records =
  let newNatures = catMaybes [case decodeCard r of Just (CustomNature nc) -> Just nc; _ -> Nothing | r <- records]
   in mergeList existing newNatures natureCardKey

updateCoreList :: [CoreCard] -> [CustomCardRecord] -> [CoreCard]
updateCoreList existing records =
  let newCores = catMaybes [case decodeCard r of Just (CustomCore cc) -> Just cc; _ -> Nothing | r <- records]
   in mergeList existing newCores coreCardKey

decodeCard :: CustomCardRecord -> Maybe CustomCard
decodeCard r =
  let (PgJSONB val) = r.customCardData
   in case fromJSON val of
        Success card -> Just card
        Error _ -> Nothing

runSyncImport :: Options -> IO ()
runSyncImport _ = do
  dbCfg <- loadDbConfig
  backend <- initDB dbCfg
  case backend of
    InMemoryBackend _ -> putStrLn "Error: Cannot import to InMemory DB backend."
    PostgresBackend pool -> do
      putStrLn "Scanning YAML files in data/cards/ ..."
      allFiles <- walkDir' "data/cards"
      let files = filter (\f -> takeExtension f `elem` [".yaml", ".yml"]) allFiles
      putStrLn $ "Found " ++ show (length files) ++ " YAML files."

      withResource pool $ \conn -> do
        forM_ files $ \path -> do
          cards <- classifyAndParseImport path
          unless (null cards) $ do
            putStrLn $ "Importing " ++ show (length cards) ++ " cards from " ++ path
            forM_ cards $ \card -> do
              now <- getCurrentTime
              let cId = customCardIdText card
                  category = customCardCategoryText card
                  name = customCardNameText card
                  relPath = makeRelative' "data/cards" path
                  dbRecord = CustomCard cId category name (PgJSONB (toJSON card)) (T.pack relPath) "SyncImport" now
              upsertCustomCardRecord conn dbRecord
        putStrLn "Import complete."

walkDir' :: FilePath -> IO [FilePath]
walkDir' dir = do
  isDir <- doesDirectoryExist dir
  if not isDir
    then return []
    else do
      contents <- listDirectory dir
      paths <- forM contents $ \name -> do
        let path = dir </> name
        isSubDir <- doesDirectoryExist path
        if isSubDir
          then walkDir' path
          else return [path]
      return (concat paths)

makeRelative' :: FilePath -> FilePath -> FilePath
makeRelative' prefix path =
  let pStr = T.pack path
      prefStr = T.pack prefix
   in if prefStr `T.isPrefixOf` pStr
        then T.unpack $ T.drop (T.length prefStr + 1) pStr
        else path

classifyAndParseImport :: FilePath -> IO [CustomCard]
classifyAndParseImport path
  | "/pc/" `List.isInfixOf` path || "/monsters/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (actorDef :: ActorDefinition) -> do
          let cores = map CustomCore actorDef.deck
              items = map CustomItem actorDef.items
              natures = map CustomNature actorDef.nature
          return $ cores ++ items ++ natures
        Left _ -> return []
  | "/consequences/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (cards :: [ConsequenceCard]) -> return $ map CustomConsequence cards
        Left _ -> return []
  | "/items/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (cards :: [ItemCard]) -> return $ map CustomItem cards
        Left _ -> return []
  | "/nature/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (cards :: [NatureCard]) -> return $ map CustomNature cards
        Left _ -> return []
  | "/core/" `List.isInfixOf` path || "/status/" `List.isInfixOf` path = do
      fileContent <- BS.readFile path
      case Yaml.decodeEither' fileContent of
        Right (cards :: [CoreCard]) -> return $ map CustomCore cards
        Left _ -> return []
  | otherwise = return []

upsertCustomCardRecord :: Pg.Connection -> CustomCardRecord -> IO ()
upsertCustomCardRecord conn dbRecord = do
  runBeamPostgres conn $ do
    existing <-
      runSelectReturningOne $
        select $
          filter_ (\c -> customCardId c ==. val_ (customCardId dbRecord)) (all_ (customCards cardpgDb))
    case existing of
      Just _ ->
        runUpdate $
          update
            (customCards cardpgDb)
            ( \c ->
                mconcat
                  [ customCardCategory c <-. val_ (customCardCategory dbRecord)
                  , customCardName c <-. val_ (customCardName dbRecord)
                  , customCardData c <-. val_ (customCardData dbRecord)
                  , customCardSourceFile c <-. val_ (customCardSourceFile dbRecord)
                  , customCardAuthor c <-. val_ (customCardAuthor dbRecord)
                  , customCardUpdatedAt c <-. val_ (customCardUpdatedAt dbRecord)
                  ]
            )
            (\c -> customCardId c ==. val_ (customCardId dbRecord))
      Nothing -> runInsert $ insert (customCards cardpgDb) (insertValues [dbRecord])
