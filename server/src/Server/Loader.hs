module Server.Loader
  ( loadLibrary
  , loadMasterCatalog
  , loadModule
  , loadModuleComponents
  , parseAsListOrSingle
  ) where

import Control.Monad (foldM, forM)
import Data.Aeson (FromJSON, Result (..), Value (..), fromJSON)
import Data.List (isInfixOf, isPrefixOf)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Data.Yaml (ParseException, decodeFileEither)
import System.Directory (doesDirectoryExist, doesFileExist, listDirectory)
import System.FilePath (splitDirectories, takeBaseName, takeDirectory, takeExtension, (</>))

import Core.Card
  ( ActorDefinition
  , ConsequenceCard
  , CoreCard
  , ItemCard
  , MasterCard (..)
  , NatureCard
  )
import Core.Card.Exploration
  ( ClockEventCard
  , LocationCard
  , ModuleManifest
  , TravelCard
  )
import Core.Logic.Exploration (initWorldState)
import Core.State (WorldState)
import Server.Types (CardLibrary (..))

-- | Recursively find all files in a directory
walkDir :: FilePath -> IO [FilePath]
walkDir dir = do
  isDir <- doesDirectoryExist dir
  if not isDir
    then return []
    else do
      contents <- listDirectory dir
      paths <- forM contents $ \name -> do
        let path = dir </> name
        isSubDir <- doesDirectoryExist path
        if isSubDir
          then walkDir path
          else return [path]
      return (concat paths)

-- | Recursively load all master cards from a directory into a Map Text MasterCard.
loadMasterCatalog :: FilePath -> IO (Map Text MasterCard)
loadMasterCatalog dir = do
  isDir <- doesDirectoryExist dir
  if not isDir
    then pure Map.empty
    else do
      allFiles <- walkDir dir
      let yamlFiles = filter (\f -> takeExtension f `elem` [".yaml", ".yml"]) allFiles
      cardsNested <- forM yamlFiles $ \path -> do
        res <- parseAsListOrSingle path :: IO (Either String [MasterCard])
        case res of
          Right cards -> pure cards
          Left err -> do
            T.putStrLn $ "WARNING: Failed to parse master card file " <> T.pack path <> ": " <> T.pack err
            pure []
      let (mergedMap, duplicates) =
            foldl'
              ( \(curMap, dups) card ->
                  if Map.member card.id curMap
                    then (Map.insert card.id card curMap, card.id : dups)
                    else (Map.insert card.id card curMap, dups)
              )
              (Map.empty, [])
              (concat cardsNested)
      case duplicates of
        [] -> pure mergedMap
        dups -> do
          T.putStrLn $ "WARNING: Duplicate master card IDs overwritten: " <> T.intercalate ", " dups
          pure mergedMap

loadLibrary :: FilePath -> IO CardLibrary
loadLibrary root = do
  allFiles <- walkDir root
  let yamlFiles = filter (\f -> takeExtension f `elem` [".yaml", ".yml"]) allFiles

  (actors, statuses, consequences, items, nature, masterCards, errors) <-
    foldM
      classifyAndParse
      ([], [], [], [], [], Map.empty, [])
      yamlFiles

  if null errors
    then
      T.putStrLn $
        "Loaded "
          <> T.pack (show (length actors))
          <> " actors, "
          <> T.pack (show (length statuses))
          <> " statuses/core, "
          <> T.pack (show (length consequences))
          <> " consequences, "
          <> T.pack (show (length items))
          <> " items, "
          <> T.pack (show (length nature))
          <> " nature, "
          <> T.pack (show (Map.size masterCards))
          <> " master cards."
    else T.putStrLn $ "WARNING: Failed to parse some files:\n" <> T.unlines (map T.pack errors)

  pure $ CardLibrary actors statuses consequences items nature masterCards

classifyAndParse
  :: ( [ActorDefinition]
     , [CoreCard]
     , [ConsequenceCard]
     , [ItemCard]
     , [NatureCard]
     , Map Text MasterCard
     , [String]
     )
  -> FilePath
  -> IO
       ( [ActorDefinition]
       , [CoreCard]
       , [ConsequenceCard]
       , [ItemCard]
       , [NatureCard]
       , Map Text MasterCard
       , [String]
       )
classifyAndParse acc@(a, s, c, i, n, m, errs) path
  | isMasterPath path = do
      res <- parseAsListOrSingle path :: IO (Either String [MasterCard])
      case res of
        Right vals ->
          let updatedMap = foldl' (\curMap card -> Map.insert card.id card curMap) m vals
           in pure (a, s, c, i, n, updatedMap, errs)
        Left e -> pure (a, s, c, i, n, m, (path <> ": " <> e) : errs)
  | "/pc/" `isInfixOf` path || "/monsters/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (vals ++ a, s, c, i, n, m, errs)
        Left e -> pure (a, s, c, i, n, m, (path <> ": " <> e) : errs)
  | "/status/" `isInfixOf` path || "/core/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (a, vals ++ s, c, i, n, m, errs)
        Left e -> pure (a, s, c, i, n, m, (path <> ": " <> e) : errs)
  | "/consequences/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (a, s, vals ++ c, i, n, m, errs)
        Left e -> pure (a, s, c, i, n, m, (path <> ": " <> e) : errs)
  | "/items/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (a, s, c, vals ++ i, n, m, errs)
        Left e -> pure (a, s, c, i, n, m, (path <> ": " <> e) : errs)
  | "/nature/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (a, s, c, i, vals ++ n, m, errs)
        Left e -> pure (a, s, c, i, n, m, (path <> ": " <> e) : errs)
  | "/modules/" `isInfixOf` path = do
      -- Modules are loaded separately per-module by loadModule / Server.Scenario
      pure acc
  | otherwise = do
      -- Ignore manifests or other structural files silently if needed, or warn
      if "_manifest" `isInfixOf` path
        then pure acc
        else
          let msg = "Skipping file in unknown directory category: " ++ path
           in pure (a, s, c, i, n, m, msg : errs)

isMasterPath :: FilePath -> Bool
isMasterPath path =
  "master" `elem` splitDirectories path
    || "/master/" `isInfixOf` path
    || "master/" `isPrefixOf` path
    || takeBaseName path == "master"

parseAsListOrSingle :: (FromJSON a) => FilePath -> IO (Either String [a])
parseAsListOrSingle path = do
  valRes <- decodeFileEither path :: IO (Either ParseException Value)
  case valRes of
    Left e -> pure (Left (show e))
    Right v@(Array _) -> case fromJSON v of
      Success (l :: [a]) -> pure (Right l)
      Error e -> pure (Left ("List parse failed: " ++ e))
    Right v@(Object _) -> case fromJSON v of
      Success (x :: a) -> pure (Right [x])
      Error e -> pure (Left ("Object parse failed: " ++ e))
    Right _ -> pure (Left "Expected YAML Array or Object")

-- | Load all components of an exploration module and initialize its WorldState.
loadModule :: FilePath -> IO (Either String (ModuleManifest, WorldState))
loadModule path = do
  res <- loadModuleComponents path
  case res of
    Left err -> pure (Left err)
    Right (manifest, locs, travels, clocks) ->
      pure (Right (manifest, initWorldState manifest locs travels clocks))

-- | Load the raw YAML components of an exploration module:
-- the manifest, locations, optional travel edges, and optional clock event cards.
loadModuleComponents
  :: FilePath
  -> IO (Either String (ModuleManifest, [LocationCard], [TravelCard], [ClockEventCard]))
loadModuleComponents path = do
  isDir <- doesDirectoryExist path
  let modDir = if isDir then path else takeDirectory path
      manifestPath = if isDir then path </> "module.yaml" else path
      locsPath = modDir </> "locations.yaml"
      travelPath = modDir </> "travel.yaml"
      clocksPath = modDir </> "clocks.yaml"

  manifestRes <- decodeFileEither manifestPath :: IO (Either ParseException ModuleManifest)
  case manifestRes of
    Left err -> pure (Left $ "Failed to parse module manifest " <> manifestPath <> ": " <> show err)
    Right manifest -> do
      locsRes <- parseAsListOrSingle locsPath :: IO (Either String [LocationCard])
      case locsRes of
        Left err -> pure (Left $ "Failed to parse locations in " <> locsPath <> ": " <> err)
        Right locs -> do
          hasTravel <- doesFileExist travelPath
          travelRes <-
            if hasTravel
              then parseAsListOrSingle travelPath :: IO (Either String [TravelCard])
              else pure (Right [])
          case travelRes of
            Left err -> pure (Left $ "Failed to parse travel routes in " <> travelPath <> ": " <> err)
            Right travels -> do
              hasClocks <- doesFileExist clocksPath
              clocksRes <-
                if hasClocks
                  then parseAsListOrSingle clocksPath :: IO (Either String [ClockEventCard])
                  else pure (Right [])
              case clocksRes of
                Left err -> pure (Left $ "Failed to parse clock events in " <> clocksPath <> ": " <> err)
                Right clocks -> pure (Right (manifest, locs, travels, clocks))
