module Backend.GSheets.Fetch
  ( syncCards )
where

import Control.Exception (IOException, try)
import Data.Aeson
import Data.Either.Combinators (mapLeft)
import Data.Text (Text, pack, unpack, strip)
import GHC.Generics
import System.Environment (getExecutablePath)
import System.Process (callProcess, readProcess)
import System.FilePath ((</>), takeDirectory)

getBundledScriptPath :: IO FilePath
getBundledScriptPath = takeDirectory <$> getExecutablePath

data SyncError = ProcessError IOException | ScriptBuildFailed IOException | ScriptBuildBadOutput
  deriving stock Show

syncCards :: Maybe FilePath -> IO ()
syncCards devRun = do
  let scriptName = "sync-cards-gsheet.py"
  result :: (Either SyncError ()) <- case devRun of
    -- In local dev (ob run) we will set this path from config and build the python package each time we run this.
    Just d -> do
      buildOut <- try (readProcess "/run/current-system/sw/bin/nix-build" [d] [])
      case buildOut of
        Left err -> pure $ Left $ ScriptBuildFailed err
        Right path -> mapLeft ProcessError <$> try (callProcess (unpack (strip (pack path)) </> "bin" </> scriptName) [])
    -- In production the script will be packaged with the backend and we use that
    Nothing -> do
      scriptDir <- getBundledScriptPath
      mapLeft ProcessError <$> try (callProcess (scriptDir </> scriptName) [])
  case result of
    Right () -> putStrLn "synced cards from gsheets"
    Left e -> print e

data ConsequenceCard = ConsequenceCard
  { _name :: Text
  , _severity :: Int
  , _effect :: Text
  }
  deriving stock (Show, Generic)
  deriving anyclass (ToJSON, FromJSON)
