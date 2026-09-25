{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (forM_)
import Data.List (sort)
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Design.Audit
  ( AuditOptions (..)
  , AuditResult (..)
  , runAudit
  )
import Options.Applicative
  ( Parser
  , execParser
  , fullDesc
  , header
  , help
  , helper
  , info
  , long
  , progDesc
  , switch
  , (<**>)
  )
import System.Directory (getCurrentDirectory)
import System.Exit (exitFailure, exitSuccess)
import System.FilePath (splitDirectories, (</>))

data CliArgs = CliArgs
  { strict :: Bool
  , fix :: Bool
  }
  deriving stock (Show, Eq)

cliParser :: Parser CliArgs
cliParser =
  CliArgs
    <$> switch
      ( long "strict"
          <> help "Treat missing frontmatter in required directories as a fatal error."
      )
    <*> switch
      ( long "fix"
          <> help
            "Automatically scaffold frontmatter and register unindexed markdown files in the appropriate index."
      )

main :: IO ()
main = do
  args <-
    execParser
      ( info
          (cliParser <**> helper)
          ( fullDesc
              <> progDesc "Audit CardPG design index synchronization and frontmatter validation."
              <> header "audit-index - CardPG design registry verification"
          )
      )

  cwd <- getCurrentDirectory
  -- Determine repoRoot and designRoot based on cwd
  let inDesign = "design" `elem` splitDirectories cwd
      repoRoot = if inDesign then take (length cwd - length ("/design" :: String)) cwd else cwd
      designRoot = repoRoot </> "design"

  res <-
    runAudit
      AuditOptions
        { strict = args.strict
        , fix = args.fix
        , repoRoot = repoRoot
        , designRoot = designRoot
        }

  -- Print Audit Results
  putStrLn "--- Design Index & Frontmatter Audit ---\n"

  -- 1. Missing from disk
  if not (Set.null res.missingFromDisk)
    then do
      putStrLn $
        "[MISSING] Files registered in index but missing on disk ("
          ++ show (Set.size res.missingFromDisk)
          ++ "):"
      forM_ (sort (Set.toList res.missingFromDisk)) $ \f ->
        putStrLn $ "  - " ++ f
    else putStrLn "[OK] All index files found on disk."

  -- 2. Untracked in git
  if not (Set.null res.untrackedInGit)
    then do
      putStrLn $
        "[UNTRACKED IN GIT] Files registered in index but not tracked by git ("
          ++ show (Set.size res.untrackedInGit)
          ++ "):"
      forM_ (sort (Set.toList res.untrackedInGit)) $ \f ->
        putStrLn $ "  - " ++ f
      putStrLn "  Run 'git add <file>' to track, or remove from index."
    else putStrLn "[OK] All indexed files are tracked by git."

  -- 3. Unindexed files
  if not (Set.null res.unindexedInRepo)
    then do
      putStrLn $
        "[UNINDEXED] Files in design/ but not registered in index ("
          ++ show (Set.size res.unindexedInRepo)
          ++ "):"
      forM_ (sort (Set.toList res.unindexedInRepo)) $ \f ->
        putStrLn $ "  - " ++ f
    else putStrLn "[OK] All design/ files are indexed."

  -- 4. Schema errors
  if not (Map.null res.schemaErrors)
    then do
      putStrLn $
        "\n[SCHEMA ERRORS] Frontmatter schema violations (" ++ show (Map.size res.schemaErrors) ++ "):"
      forM_ (sort (Map.toList res.schemaErrors)) $ \(f, errs) -> do
        putStrLn $ "  - " ++ f ++ ":"
        forM_ errs $ \e ->
          putStrLn $ "      * " ++ e
    else
      putStrLn $
        "[OK] Frontmatter schema valid across all " ++ show res.frontmatterChecked ++ " documented files."

  -- 5. Alignment errors
  if not (Map.null res.alignmentErrors)
    then do
      putStrLn $
        "\n[ALIGNMENT ERRORS] Frontmatter vs. index mismatches ("
          ++ show (Map.size res.alignmentErrors)
          ++ "):"
      forM_ (sort (Map.toList res.alignmentErrors)) $ \(f, errs) -> do
        putStrLn $ "  - " ++ f ++ ":"
        forM_ errs $ \e ->
          putStrLn $ "      * " ++ e
    else putStrLn "[OK] Metadata alignment verified between frontmatter and index."

  -- 6. Dead links
  if not (Map.null res.deadLinkErrors)
    then do
      putStrLn $
        "\n[DEAD LINKS] Invalid links in related_files (" ++ show (Map.size res.deadLinkErrors) ++ "):"
      forM_ (sort (Map.toList res.deadLinkErrors)) $ \(f, errs) -> do
        putStrLn $ "  - " ++ f ++ ":"
        forM_ errs $ \e ->
          putStrLn $ "      * " ++ e
    else putStrLn "[OK] All related_files references exist on disk."

  -- 7. Missing frontmatter
  if not (null res.missingFrontmatter)
    then do
      if args.strict
        then
          putStrLn $
            "\n[STRICT ERROR] Files missing required frontmatter ("
              ++ show (length res.missingFrontmatter)
              ++ "):"
        else
          putStrLn $
            "\n[PENDING WP2 BACKFILL] Active synthesis files awaiting epistemic frontmatter ("
              ++ show (length res.missingFrontmatter)
              ++ "):"
      forM_ (sort res.missingFrontmatter) $ \f ->
        putStrLn $ "  - " ++ f
    else putStrLn "[OK] All required directories contain epistemic frontmatter."

  -- 8. Tag rollups
  if not (null res.tagErrors)
    then do
      putStrLn $
        "\n[TAG ROLLUP ERRORS] Sub-index aggregated_tags out of date ("
          ++ show (length res.tagErrors)
          ++ "):"
      forM_ res.tagErrors $ \e ->
        putStrLn $ "  - " ++ e
      putStrLn "  Run 'audit-index --fix' to update."
    else putStrLn "[OK] Sub-index aggregated tags verified."

  -- 9. TOC errors
  if not (Map.null res.tocErrors)
    then do
      putStrLn $
        "\n[TOC ERRORS] README tables of contents out of date (" ++ show (Map.size res.tocErrors) ++ "):"
      forM_ (sort (Map.toList res.tocErrors)) $ \(f, e) ->
        putStrLn $ "  - " ++ f ++ ": " ++ e
      putStrLn "  Run 'audit-index --fix' to synchronize README maps."
    else putStrLn "[OK] All directory README tables of contents are up to date."

  putStrLn "\n--- Audit Summary ---"
  if res.hasFatalError
    then do
      putStrLn "FAIL: Discrepancies detected. Please correct the errors above."
      exitFailure
    else do
      putStrLn "PASS: Index and frontmatter synchronization checks passed."
      exitSuccess
