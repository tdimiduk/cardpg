{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Applicative ((<**>))
import Data.List (isSuffixOf)
import Options.Applicative
  ( Parser
  , command
  , customExecParser
  , fullDesc
  , header
  , help
  , helper
  , hsubparser
  , info
  , long
  , metavar
  , optional
  , prefs
  , progDesc
  , short
  , showDefault
  , showHelpOnEmpty
  , strOption
  , switch
  , value
  )
import System.Directory (doesDirectoryExist, listDirectory)
import System.Exit (exitFailure)
import System.FilePath ((</>))

import ManageCards
  ( runAuditCli
  , runExportCli
  , runRewriteCli
  )

data Command
  = CmdAudit AuditOptions
  | CmdExport ExportOptions
  | CmdRewrite RewriteOptions
  deriving stock (Show)

data AuditOptions = AuditOptions
  { pcDir :: FilePath
  , monstersDir :: FilePath
  , verbose :: Bool
  }
  deriving stock (Show)

data ExportOptions = ExportOptions
  { pcDir :: FilePath
  , monstersDir :: FilePath
  , outDir :: FilePath
  , dryRun :: Bool
  }
  deriving stock (Show)

data RewriteOptions = RewriteOptions
  { actorFile :: Maybe FilePath
  , allActors :: Bool
  , pcDir :: FilePath
  , monstersDir :: FilePath
  , catalogDir :: FilePath
  , dryRun :: Bool
  }
  deriving stock (Show)

auditParser :: Parser AuditOptions
auditParser =
  AuditOptions
    <$> strOption
      ( long "pc-dir"
          <> value "data/cards/pc"
          <> showDefault
          <> help "Directory containing player character cards"
      )
    <*> strOption
      ( long "monsters-dir"
          <> value "data/cards/monsters"
          <> showDefault
          <> help "Directory containing monster cards"
      )
    <*> switch
      ( long "verbose"
          <> short 'v'
          <> help "Print detailed list of candidate master cards"
      )

exportParser :: Parser ExportOptions
exportParser =
  ExportOptions
    <$> strOption
      ( long "pc-dir"
          <> value "data/cards/pc"
          <> showDefault
          <> help "Directory containing player character cards"
      )
    <*> strOption
      ( long "monsters-dir"
          <> value "data/cards/monsters"
          <> showDefault
          <> help "Directory containing monster cards"
      )
    <*> strOption
      ( long "out-dir"
          <> value "data/cards/master"
          <> showDefault
          <> help "Target output directory for master database YAML files"
      )
    <*> switch
      ( long "dry-run"
          <> help "Simulate export without writing files to disk"
      )

rewriteParser :: Parser RewriteOptions
rewriteParser =
  RewriteOptions
    <$> optional
      ( strOption
          ( long "actor"
              <> metavar "FILE"
              <> help "Path to specific actor YAML file to rewrite"
          )
      )
    <*> switch
      ( long "all"
          <> help "Rewrite all actor files in pc-dir and monsters-dir"
      )
    <*> strOption
      ( long "pc-dir"
          <> value "data/cards/pc"
          <> showDefault
          <> help "Directory containing player character cards"
      )
    <*> strOption
      ( long "monsters-dir"
          <> value "data/cards/monsters"
          <> showDefault
          <> help "Directory containing monster cards"
      )
    <*> strOption
      ( long "catalog"
          <> value "data/cards/master"
          <> showDefault
          <> help "Directory containing master card database YAML files"
      )
    <*> switch
      ( long "dry-run"
          <> help "Preview rewrites without modifying files on disk"
      )

commandParser :: Parser Command
commandParser =
  hsubparser
    ( command
        "audit"
        ( info
            (CmdAudit <$> auditParser)
            (progDesc "Scan decks, deduplicate inline cards, and check legacy rules")
        )
        <> command
          "export"
          ( info
              (CmdExport <$> exportParser)
              (progDesc "Export categorized master card database YAML files")
          )
        <> command
          "rewrite"
          ( info
              (CmdRewrite <$> rewriteParser)
              (progDesc "Rewrite actor deck(s) to use master card references")
          )
    )

findYamlFiles :: FilePath -> IO [FilePath]
findYamlFiles dir = do
  exists <- doesDirectoryExist dir
  if not exists
    then pure []
    else do
      entries <- listDirectory dir
      let valid =
            filter
              ( \f ->
                  (".yaml" `isSuffixOf` f || ".yml" `isSuffixOf` f)
                    && not (".reformatted" `isSuffixOf` f)
                    && not (".outdated" `isSuffixOf` f)
              )
              entries
      pure (map (dir </>) valid)

main :: IO ()
main = do
  cmd <-
    customExecParser
      (prefs showHelpOnEmpty)
      ( info
          (commandParser <**> helper)
          ( fullDesc
              <> progDesc "CardPG Master Card Database Management & Migration Tool"
              <> header "manage-cards - Card database audit, export, and reference rewriter"
          )
      )
  case cmd of
    CmdAudit opts ->
      runAuditCli [opts.pcDir, opts.monstersDir] opts.verbose
    CmdExport opts ->
      runExportCli [opts.pcDir, opts.monstersDir] opts.outDir opts.dryRun
    CmdRewrite opts -> do
      targets <-
        if opts.allActors
          then do
            pcFiles <- findYamlFiles opts.pcDir
            monFiles <- findYamlFiles opts.monstersDir
            pure (pcFiles ++ monFiles)
          else case opts.actorFile of
            Just f -> pure [f]
            Nothing -> do
              putStrLn "Error: Please specify either --actor <file> or --all to rewrite."
              exitFailure
      runRewriteCli opts.catalogDir targets opts.dryRun
