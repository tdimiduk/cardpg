{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Applicative (optional, some, (<**>))
import Control.Monad (forM_)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Design.Bundle
  ( BundleConfig (..)
  , BundleSummary (..)
  , FileBundleEntry (..)
  , authorityTierTitle
  , createBundle
  )
import Options.Applicative
  ( Parser
  , argument
  , execParser
  , fullDesc
  , header
  , help
  , helper
  , info
  , long
  , metavar
  , progDesc
  , short
  , showDefault
  , str
  , strOption
  , value
  )
import System.Directory (doesDirectoryExist, doesFileExist, getCurrentDirectory)
import System.Exit (exitFailure, exitSuccess)
import System.FilePath (normalise, takeDirectory, (</>))
import System.IO (hPutStrLn, stderr)

data CliArgs = CliArgs
  { topic :: String
  , framing :: Maybe String
  , framingFile :: Maybe FilePath
  , output :: FilePath
  , inputFiles :: [FilePath]
  }
  deriving stock (Show, Eq)

cliParser :: Parser CliArgs
cliParser =
  CliArgs
    <$> strOption
      ( long "topic"
          <> metavar "TEXT"
          <> help "Human-readable title of the design/rules topic"
      )
    <*> optional
      ( strOption
          ( long "framing"
              <> metavar "TEXT"
              <> help "Framing questions, core tensions, and goals for the Web UI session"
          )
      )
    <*> optional
      ( strOption
          ( long "framing-file"
              <> metavar "FILEPATH"
              <> help "Path to file containing framing markdown text, or '-' to read from stdin"
          )
      )
    <*> strOption
      ( long "output"
          <> short 'o'
          <> metavar "FILEPATH"
          <> value "export/topic_bundle.md"
          <> showDefault
          <> help "Output bundle file path relative to repo root"
      )
    <*> some
      ( argument
          str
          ( metavar "FILES..."
              <> help "Repository-relative file paths to include in the bundle"
          )
      )

-- | Locate repository root by walking up towards cabal.project or .git
findRepoRoot :: IO FilePath
findRepoRoot = do
  cwd <- getCurrentDirectory
  let isRoot d = do
        hasGit <- doesDirectoryExist (d </> ".git")
        hasCabal <- doesFileExist (d </> "cabal.project")
        pure (hasGit || hasCabal)
      walk d = do
        found <- isRoot d
        if found
          then pure d
          else do
            let parent = takeDirectory d
            if parent == d then pure cwd else walk parent
  walk cwd

main :: IO ()
main = do
  args <-
    execParser
      ( info
          (cliParser <**> helper)
          ( fullDesc
              <> progDesc "Assemble a self-contained markdown topic bundle for web discussion."
              <> header "bundle-topic - CardPG topic context bundler"
          )
      )

  repoRoot <- findRepoRoot

  -- Resolve framing text
  framingText <- case args.framingFile of
    Just "-" -> Just <$> TIO.getContents
    Just fp -> do
      let fullFp = if normalise fp == fp && not ("/" `T.isPrefixOf` T.pack fp) then repoRoot </> fp else fp
      exists <- doesFileExist fullFp
      if not exists
        then do
          hPutStrLn stderr $ "Error: Framing file does not exist: " ++ fp
          exitFailure
        else Just <$> TIO.readFile fullFp
    Nothing -> pure (fmap T.pack args.framing)

  let cfg =
        BundleConfig
          { topic = T.pack args.topic
          , framing = framingText
          , output = args.output
          , inputFiles = args.inputFiles
          , timestamp = Nothing
          }

  result <- createBundle repoRoot cfg
  case result of
    Left missing -> do
      hPutStrLn stderr "Error: The following input file(s) do not exist:"
      forM_ missing $ \f -> hPutStrLn stderr ("  - " ++ f)
      exitFailure
    Right summary -> do
      putStrLn $ "Bundle successfully generated: " ++ summary.outputPath
      putStrLn $ "Topic: " ++ args.topic
      putStrLn $ "Included Files (" ++ show summary.totalFiles ++ "):"
      forM_ summary.entries $ \e ->
        putStrLn $
          "  - "
            ++ e.relPath
            ++ " ("
            ++ T.unpack (authorityTierTitle e.authorityTier)
            ++ ", "
            ++ show e.lineCount
            ++ " lines)"
      putStrLn $
        "Total Size: "
          ++ show summary.totalFiles
          ++ " files | "
          ++ show summary.totalLines
          ++ " lines | ~"
          ++ show summary.totalEstimatedTokens
          ++ " tokens"
      exitSuccess
