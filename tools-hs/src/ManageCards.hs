{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ManageCards
  ( module ManageCards.Types
  , module ManageCards.Classifier
  , module ManageCards.Deduplicate
  , module ManageCards.Export
  , module ManageCards.Rewrite
  , module ManageCards.Audit
  , runAuditCli
  , runExportCli
  , runRewriteCli
  , verifyCatalogIntegrity
  ) where

import Control.Monad (forM_)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import System.Exit (exitFailure)

import Core.Card (ActorDefinition (..), CardReference (..), DeckEntry (..), MasterCard)
import ManageCards.Audit
import ManageCards.Classifier
import ManageCards.Deduplicate
import ManageCards.Export
import ManageCards.Rewrite
import ManageCards.Types

-- | CLI runner for 'manage-cards audit'
runAuditCli :: [FilePath] -> Bool -> IO ()
runAuditCli dirs verbose = do
  report <- runAudit dirs
  printAuditReport report verbose

-- | CLI runner for 'manage-cards export'
runExportCli :: [FilePath] -> FilePath -> Bool -> IO ()
runExportCli dirs outDir dryRun = do
  putStrLn $ "Scanning actor files from: " ++ unwords dirs
  (pairs, _) <- scanActorFiles dirs
  putStrLn $ "Found " ++ show (length pairs) ++ " inline cards."
  let groups = groupCards pairs
  putStrLn $ "Deduplicated into " ++ show (length groups) ++ " master cards."
  exported <- exportMasterCatalog outDir groups dryRun
  putStrLn $
    "\nMaster cards catalog export summary (" ++ (if dryRun then "DRY RUN" else outDir) ++ "):"
  forM_ exported $ \(relPath, count) ->
    putStrLn $ "  - " ++ relPath ++ ": " ++ show count ++ " cards"
  putStrLn "Done."

-- | CLI runner for 'manage-cards rewrite'
runRewriteCli :: FilePath -> [FilePath] -> Bool -> IO ()
runRewriteCli catalogDir actorFiles dryRun = do
  eCat <- loadCatalog catalogDir
  case eCat of
    Left err -> do
      putStrLn $ "Error: " ++ err
      exitFailure
    Right catalog -> do
      putStrLn $ "Loaded catalog with " ++ show (Map.size catalog) ++ " master cards."
      putStrLn $
        "Rewriting "
          ++ show (length actorFiles)
          ++ " actor file(s)"
          ++ (if dryRun then " (dry-run):" else ":")
      forM_ actorFiles $ \f -> do
        res <- rewriteActorFile catalog f dryRun
        case res of
          Left err -> putStrLn $ "  [FAIL] " ++ f ++ ": " ++ err
          Right r ->
            if r.modified
              then
                putStrLn $
                  "  [REWRITTEN] "
                    ++ f
                    ++ " ("
                    ++ show r.replacedEntries
                    ++ " cards -> references, "
                    ++ show r.retainedInlineEntries
                    ++ " kept inline)"
              else putStrLn $ "  [UNCHANGED] " ++ f

-- | Verify that all CardReference entries across a set of actors resolve against the catalog.
verifyCatalogIntegrity :: Map Text MasterCard -> [ActorDefinition] -> [String]
verifyCatalogIntegrity catalog actors =
  [ "Actor '" ++ T.unpack actor.name ++ "' references missing card ID '" ++ T.unpack refCard ++ "'"
  | actor <- actors
  , EntryRef CardReference{card = refCard} <- actor.deck
  , not (Map.member refCard catalog)
  ]
