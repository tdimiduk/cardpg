{-# LANGUAGE OverloadedStrings #-}

module Design.Prettier
  ( runPrettier
  ) where

import System.Directory (findExecutable)
import System.Process (readProcessWithExitCode)

-- | Run prettier --write on given files if available (direct binary or via pre-commit fallback)
runPrettier :: [FilePath] -> IO ()
runPrettier [] = pure ()
runPrettier files = do
  mPrettier <- findExecutable "prettier"
  case mPrettier of
    Just bin -> do
      _ <- readProcessWithExitCode bin ("--write" : files) ""
      pure ()
    Nothing -> do
      mPreCommit <- findExecutable "pre-commit"
      case mPreCommit of
        Just bin -> do
          _ <- readProcessWithExitCode bin (["run", "prettier", "--files"] ++ files) ""
          pure ()
        Nothing -> pure ()
