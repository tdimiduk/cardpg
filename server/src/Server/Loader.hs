module Server.Loader (loadLibrary) where

import Control.Monad (filterM, foldM, forM)
import Data.Aeson (FromJSON, Result (..), Value (..), fromJSON)
import Data.Either (lefts, rights)
import Data.List (isInfixOf, isSuffixOf)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Data.Yaml (ParseException, decodeFileEither)
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath (takeExtension, (</>))

import Core.Card (ActorDefinition, ConsequenceCard, CoreCard, ItemCard, NatureCard)
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

loadLibrary :: FilePath -> IO CardLibrary
loadLibrary root = do
  allFiles <- walkDir root
  let yamlFiles = filter (\f -> takeExtension f `elem` [".yaml", ".yml"]) allFiles

  (actors, statuses, consequences, items, nature, errors) <-
    foldM
      classifyAndParse
      ([], [], [], [], [], [])
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
          <> " nature."
    else T.putStrLn $ "WARNING: Failed to parse some files:\n" <> T.unlines (map T.pack errors)

  pure $ CardLibrary actors statuses consequences items nature

classifyAndParse
  :: ( [ActorDefinition]
     , [CoreCard]
     , [ConsequenceCard]
     , [ItemCard]
     , [NatureCard]
     , [String]
     )
  -> FilePath
  -> IO
       ( [ActorDefinition]
       , [CoreCard]
       , [ConsequenceCard]
       , [ItemCard]
       , [NatureCard]
       , [String]
       )
classifyAndParse acc@(a, s, c, i, n, errs) path
  | "/pc/" `isInfixOf` path || "/monsters/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (vals ++ a, s, c, i, n, errs)
        Left e -> pure (a, s, c, i, n, (path <> ": " <> e) : errs)
  | "/status/" `isInfixOf` path || "/core/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (a, vals ++ s, c, i, n, errs)
        Left e -> pure (a, s, c, i, n, (path <> ": " <> e) : errs)
  | "/consequences/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (a, s, vals ++ c, i, n, errs)
        Left e -> pure (a, s, c, i, n, (path <> ": " <> e) : errs)
  | "/items/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (a, s, c, vals ++ i, n, errs)
        Left e -> pure (a, s, c, i, n, (path <> ": " <> e) : errs)
  | "/nature/" `isInfixOf` path = do
      res <- parseAsListOrSingle path
      case res of
        Right vals -> pure (a, s, c, i, vals ++ n, errs)
        Left e -> pure (a, s, c, i, n, (path <> ": " <> e) : errs)
  | otherwise = do
      -- Ignore manifests or other structural files silently if needed, or warn
      if "_manifest" `isInfixOf` path
        then pure acc
        else
          let msg = "Skipping file in unknown directory category: " ++ path
           in pure (a, s, c, i, n, msg : errs)

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
