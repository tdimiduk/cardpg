module Backend.GSheets.Fetch
  ( cards
  , SheetConsequenceCard
  , SheetConditionCard
  )
where

import Control.Exception (IOException, try)
import Data.Aeson
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as C
import Data.Either.Combinators (mapRight)
import Data.Int (Int32)
import Data.Text (Text, unpack)
import GHC.Generics (Generic)
import System.Environment (getExecutablePath)
import System.Process.Typed
import System.FilePath ((</>), takeDirectory)

getBundledScriptPath :: IO FilePath
getBundledScriptPath = takeDirectory <$> getExecutablePath

data SheetConsequenceCard = SheetConsequenceCard
  { name :: Text
  , severity :: Int32
  , effect :: Text
  }
  deriving stock Generic
  deriving anyclass (ToJSON, FromJSON)

data SheetConditionCard = SheetConditionCard
  { name :: Text
  , effect :: Text
  , removal :: Text
  }
  deriving stock Generic
  deriving anyclass (ToJSON, FromJSON)

data SyncError = ProcessError IOException | ScriptBuildFailed IOException | ScriptBuildBadOutput | DataError String
  deriving stock Show

cards :: (FromJSON c) => Maybe FilePath -> Text -> Text -> IO (Either SyncError [c])
cards devRun docKey sheetName = do
  let scriptName = "sync-cards-gsheet.py"
  ePath <- case devRun of
    -- In local dev (ob run) we will set this path from config and build the python package each time we run this.
    Just d -> mapRight ((</> "bin") . C.unpack . C.strip . BL.toStrict . fst) <$>
      try (readProcess_ $ proc "/run/current-system/sw/bin/nix-build" [d])
    -- In production the script will be packaged with the backend and we use that
    Nothing -> Right <$> getBundledScriptPath
  case ePath of
    Left err -> pure $ Left $ ScriptBuildFailed err
    Right path -> do
      r <- try (readProcess_ (proc (path </> scriptName) (fmap unpack [docKey, sheetName])))
      case r of
        Left err -> pure $ Left $ ProcessError err
        Right o -> case eitherDecode (fst o) of
          Left err -> pure $ Left $ DataError err
          Right v -> pure $ Right v
