{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Design.Audit
  ( AuditOptions (..)
  , AuditResult (..)
  , runAudit
  , getRepoFiles
  ) where

import Control.Exception (SomeException, try)
import Control.Monad (forM, unless)
import Data.List (isPrefixOf, isSuffixOf, sort)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (catMaybes)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Design.Frontmatter
  ( extractFirstParagraph
  , extractFrontmatterText
  , parseFrontmatter
  , scaffoldFrontmatter
  , validateFrontmatterSchema
  )
import Design.Index
  ( IndexData (..)
  , insertEntryIntoIndex
  , loadAllIndexData
  , resolveIndexTarget
  , syncAggregatedTags
  )
import Design.TOC
  ( generateArchiveToc
  , generateIterationToc
  , generateResearchToc
  , generateRootToc
  , updateOrVerifyReadmeToc
  )
import Design.Types
import System.Directory
  ( doesDirectoryExist
  , doesFileExist
  , listDirectory
  )
import System.Exit (ExitCode (ExitSuccess), exitFailure)
import System.FilePath
  ( makeRelative
  , takeDirectory
  , (</>)
  )
import System.Process (CreateProcess (..), proc, readCreateProcessWithExitCode)

data AuditOptions = AuditOptions
  { strict :: Bool
  , fix :: Bool
  , repoRoot :: FilePath
  , designRoot :: FilePath
  }
  deriving stock (Show, Eq)

data AuditResult = AuditResult
  { hasFatalError :: Bool
  , missingFromDisk :: Set FilePath
  , untrackedInGit :: Set FilePath
  , unindexedInRepo :: Set FilePath
  , schemaErrors :: Map FilePath [String]
  , alignmentErrors :: Map FilePath [String]
  , deadLinkErrors :: Map FilePath [String]
  , missingFrontmatter :: [FilePath]
  , tagErrors :: [String]
  , tocErrors :: Map FilePath String
  , frontmatterChecked :: Int
  }
  deriving stock (Show, Eq)

-- | Run git ls-files on design root or fallback to recursive filesystem walk
getRepoFiles :: FilePath -> IO (Set FilePath, Bool)
getRepoFiles designRoot = do
  let gitProc = (proc "git" ["ls-files", "."]){cwd = Just designRoot}
  gitResult <-
    try (readCreateProcessWithExitCode gitProc "")
      :: IO (Either SomeException (ExitCode, String, String))
  case gitResult of
    Right (ExitSuccess, stdoutStr, _) -> do
      let rawLines = lines stdoutStr
          normFiles =
            [ norm
            | line <- rawLines
            , let norm = normaliseRel line
            , not (null norm)
            , norm /= "index.yaml"
            , not ("/index.yaml" `isSuffixOf` norm)
            ]
      existingFiles <- forM normFiles $ \f -> do
        exists <- doesFileExist (designRoot </> f)
        pure [f | exists]
      pure (Set.fromList (concat existingFiles), True)
    _ -> do
      files <- walkDir designRoot ""
      pure (Set.fromList files, False)
  where
    walkDir base relDir = do
      let currentDir = base </> relDir
      entries <- listDirectory currentDir
      let skipDirs = [".git", ".gemini", "node_modules", "__pycache__", "sources"]
      paths <- forM entries $ \e -> do
        if e `elem` skipDirs
          then pure []
          else do
            let full = currentDir </> e
                rel = if null relDir then e else relDir </> e
            isDir <- doesDirectoryExist full
            if isDir
              then walkDir base rel
              else do
                let norm = normaliseRel rel
                if norm == "index.yaml" || "/index.yaml" `isSuffixOf` norm
                  then pure []
                  else pure [norm]
      pure (concat paths)

    normaliseRel = map (\c -> if c == '\\' then '/' else c)

-- | Core audit runner
runAudit :: AuditOptions -> IO AuditResult
runAudit opts = do
  let rootIndexAbs = opts.designRoot </> "index.yaml"
  indexExists <- doesFileExist rootIndexAbs
  unless indexExists $ do
    putStrLn $ "Error: index.yaml not found at " ++ rootIndexAbs
    exitFailure

  initIdxData <- loadAllIndexData opts.designRoot rootIndexAbs
  (initRepoFiles, isGit) <- getRepoFiles opts.designRoot

  let getMissingFromDisk idxFiles missingIdxs =
        let fromIdx = Set.toList idxFiles
         in do
              missingFiles <- forM fromIdx $ \f -> do
                exists <- doesFileExist (opts.designRoot </> f)
                pure [f | not exists]
              let relMissingIdxs = map (normaliseRel . makeRelative opts.designRoot) missingIdxs
              pure $ Set.fromList (concat missingFiles ++ relMissingIdxs)

      getIndexFilesInDesign =
        Set.filter
          ( \f ->
              not (".." `isPrefixOf` f)
                && not ("/" `isPrefixOf` f)
                && not ("index.yaml" `isSuffixOf` f)
                && not ("http://" `isPrefixOf` f)
                && not ("https://" `isPrefixOf` f)
          )

  initMissingFromDisk <- getMissingFromDisk initIdxData.allFiles initIdxData.missingIndexes
  let initIndexInDesign = getIndexFilesInDesign initIdxData.allFiles
      initUnindexed = Set.difference initRepoFiles initIndexInDesign

  -- 1. If fix is requested, auto-index unindexed files
  (idxData, repoFiles, indexInDesign, unindexedInRepo, missingFromDisk) <-
    if opts.fix && not (Set.null initUnindexed)
      then do
        putStrLn $ "--- Auto-indexing " ++ show (Set.size initUnindexed) ++ " unindexed file(s) ---\n"
        fixedCount <- autoIndexFiles opts.designRoot (Set.toList initUnindexed)
        if fixedCount > 0
          then do
            reloaded <- loadAllIndexData opts.designRoot rootIndexAbs
            (reloadedRepo, _) <- getRepoFiles opts.designRoot
            reMissing <- getMissingFromDisk reloaded.allFiles reloaded.missingIndexes
            let reIndexInDesign = getIndexFilesInDesign reloaded.allFiles
                reUnindexed = Set.difference reloadedRepo reIndexInDesign
            pure (reloaded, reloadedRepo, reIndexInDesign, reUnindexed, reMissing)
          else pure (initIdxData, initRepoFiles, initIndexInDesign, initUnindexed, initMissingFromDisk)
      else pure (initIdxData, initRepoFiles, initIndexInDesign, initUnindexed, initMissingFromDisk)

  let untrackedInGit =
        if isGit
          then Set.difference (Set.difference indexInDesign repoFiles) missingFromDisk
          else Set.empty

  -- 2. Audit frontmatter across all repo markdown files
  let mdFiles = [f | f <- Set.toList repoFiles, ".md" `isSuffixOf` f]
  (fmChecked, schemaErrs, alignErrs, deadLinkErrs, missingFm) <-
    auditMarkdownFiles opts.repoRoot opts.designRoot idxData.entriesByPath mdFiles

  -- 3. Audit and optionally sync aggregated tags
  (tagErrs, _) <- syncAggregatedTags opts.designRoot rootIndexAbs opts.fix

  -- 4. Audit and optionally update README tables of contents
  let tocGenerators =
        [ ("README.md", generateRootToc)
        , ("iteration/README.md", generateIterationToc)
        , ("research/README.md", generateResearchToc)
        , ("archive/README.md", generateArchiveToc)
        ]
  tocResults <- forM tocGenerators $ \(relReadme, genFn) -> do
    let readmeAbs = opts.designRoot </> relReadme
    body <- genFn opts.designRoot
    (verifyRes, _) <- updateOrVerifyReadmeToc readmeAbs body opts.fix
    case verifyRes of
      Left err -> pure (Just (relReadme, err))
      Right () -> pure Nothing
  let tocErrs = Map.fromList (catMaybes tocResults)

  let hasFatal =
        not (Set.null missingFromDisk)
          || not (Set.null untrackedInGit)
          || not (Set.null unindexedInRepo)
          || not (Map.null schemaErrs)
          || not (Map.null alignErrs)
          || not (Map.null deadLinkErrs)
          || (opts.strict && not (null missingFm))
          || not (null tagErrs)
          || not (Map.null tocErrs)

  pure
    AuditResult
      { hasFatalError = hasFatal
      , missingFromDisk = missingFromDisk
      , untrackedInGit = untrackedInGit
      , unindexedInRepo = unindexedInRepo
      , schemaErrors = schemaErrs
      , alignmentErrors = alignErrs
      , deadLinkErrors = deadLinkErrs
      , missingFrontmatter = missingFm
      , tagErrors = tagErrs
      , tocErrors = tocErrs
      , frontmatterChecked = fmChecked
      }
  where
    normaliseRel = map (\c -> if c == '\\' then '/' else c)

-- | Auto-index list of unindexed files
autoIndexFiles :: FilePath -> [FilePath] -> IO Int
autoIndexFiles designRoot unindexed = do
  results <- forM (sort unindexed) $ \relPath -> do
    if not (".md" `isSuffixOf` relPath)
      then do
        putStrLn $
          "[SKIP] Cannot auto-index non-markdown file '" ++ relPath ++ "'. Manual indexing required."
        pure False
      else do
        let absPath = designRoot </> relPath
        content <- TIO.readFile absPath
        (fm, fmErrors) <- case extractFrontmatterText content of
          Left err -> do
            putStrLn $ "[SKIP] Cannot auto-index '" ++ relPath ++ "': frontmatter error: " ++ err
            pure (Nothing, [err])
          Right Nothing -> do
            let (scaffolded, newContent) = scaffoldFrontmatter relPath content
            TIO.writeFile absPath newContent
            putStrLn $ "[FIX] Scaffolding epistemic frontmatter in '" ++ relPath ++ "'"
            pure (Just scaffolded, [])
          Right (Just (fmLang, _)) -> do
            case parseFrontmatter fmLang of
              Left err -> do
                putStrLn $ "[SKIP] Cannot auto-index '" ++ relPath ++ "': YAML error: " ++ err
                pure (Nothing, [err])
              Right (parsed, errs) -> pure (Just parsed, errs)

        case fm of
          Nothing -> pure False
          Just f -> do
            let schemaErrs = fmErrors ++ validateFrontmatterSchema f
            if not (null schemaErrs)
              then do
                putStrLn $ "[SKIP] Frontmatter schema errors in '" ++ relPath ++ "': " ++ show schemaErrs
                pure False
              else do
                let docType = f.docType
                    (targetIdxRel, sectionKeys) = resolveIndexTarget relPath docType
                    targetIdxAbs = designRoot </> targetIdxRel

                -- Purpose from frontmatter or first paragraph
                let purposeText = case f.purpose of
                      Just p | not (T.null p) -> p
                      _ -> case f.description of
                        Just d | not (T.null d) -> d
                        _ ->
                          let p = extractFirstParagraph content
                           in if not (T.null p)
                                then p
                                else "Documentation and design specifications for " <> f.title <> "."

                -- Tags derivation
                let isModule = "rules/modules/" `isPrefixOf` relPath || docType == "module"
                    dtTag = if isModule then "doc-type:module" else docTypeCanonicalTag docType
                    audienceTag =
                      if "rules/" `isPrefixOf` relPath
                        then "audience:player-facing"
                        else "audience:designer-facing"
                    extraGmTag =
                      [ "audience:gm-facing"
                      | "rules/" `isPrefixOf` relPath
                      , "rules/modules/" `isPrefixOf` relPath
                          || "gamemaster" `isPrefixOf` relPath
                          || "gm" `isPrefixOf` relPath
                      ]
                    allTags = [dtTag, audienceTag] ++ extraGmTag ++ f.tags

                let entry =
                      IndexItem
                        { path = Just relPath
                        , name = Nothing
                        , purpose = Just purposeText
                        , tags = allTags
                        , sourceType = Nothing
                        , itemType = Nothing
                        , aggregatedTags = Nothing
                        , components = Nothing
                        , sheets = Nothing
                        , rawFields = Map.empty
                        }

                insRes <- insertEntryIntoIndex targetIdxAbs sectionKeys entry
                case insRes of
                  Left err -> do
                    putStrLn $ "[ERROR] Failed to insert '" ++ relPath ++ "' into " ++ targetIdxRel ++ ": " ++ err
                    pure False
                  Right () -> do
                    putStrLn $
                      "[FIX] Auto-indexed '"
                        ++ relPath
                        ++ "' -> "
                        ++ targetIdxRel
                        ++ " ["
                        ++ T.unpack (T.intercalate "." sectionKeys)
                        ++ "]"
                    pure True
  pure $ length (filter id results)

-- | Validate markdown frontmatter, schema, alignment, and links
auditMarkdownFiles
  :: FilePath
  -> FilePath
  -> Map FilePath IndexItem
  -> [FilePath]
  -> IO (Int, Map FilePath [String], Map FilePath [String], Map FilePath [String], [FilePath])
auditMarkdownFiles repoRoot designRoot entriesByPath mdFiles = do
  results <- forM (sort mdFiles) $ \relPath -> do
    let absPath = designRoot </> relPath
        isReqDir = any (`isPrefixOf` relPath) frontmatterRequiredDirs
    content <- TIO.readFile absPath
    case extractFrontmatterText content of
      Left err -> pure (0, Just (relPath, [err]), Nothing, Nothing, [])
      Right Nothing ->
        pure (0, Nothing, Nothing, Nothing, [relPath | isReqDir])
      Right (Just (fmLang, _)) -> do
        case parseFrontmatter fmLang of
          Left parseErr ->
            pure (1, Just (relPath, [parseErr]), Nothing, Nothing, [])
          Right (fm, errs) -> do
            let schemaErrs = errs ++ validateFrontmatterSchema fm
                mEntry = Map.lookup relPath entriesByPath
                alignErrs = validateMetadataAlignment fm mEntry
            deadLinks <- validateRelatedFiles repoRoot designRoot absPath fm
            pure
              ( 1
              , if null schemaErrs then Nothing else Just (relPath, schemaErrs)
              , if null alignErrs then Nothing else Just (relPath, alignErrs)
              , if null deadLinks then Nothing else Just (relPath, deadLinks)
              , []
              )

  let totalChecked = sum [c | (c, _, _, _, _) <- results]
      sErrs = Map.fromList [item | (_, Just item, _, _, _) <- results]
      aErrs = Map.fromList [item | (_, _, Just item, _, _) <- results]
      dErrs = Map.fromList [item | (_, _, _, Just item, _) <- results]
      missingFm = concat [m | (_, _, _, _, m) <- results]

  pure (totalChecked, sErrs, aErrs, dErrs, missingFm)

-- | Validate title and doc_type against index entry
validateMetadataAlignment :: Frontmatter -> Maybe IndexItem -> [String]
validateMetadataAlignment fm mEntry = case mEntry of
  Nothing -> []
  Just entry ->
    let fmTitle = T.toLower (T.strip fm.title)
        entryName = maybe "" (T.toLower . T.strip) entry.name
        titleMismatch =
          [ "Title mismatch: frontmatter '"
              ++ T.unpack fm.title
              ++ "' != index entry name '"
              ++ maybe "" T.unpack entry.name
              ++ "'"
          | not (T.null fmTitle) && not (T.null entryName) && fmTitle /= entryName
          ]
        docTypeMismatch =
          if T.null fm.docType
            then []
            else
              let dtStr = T.toLower (T.strip fm.docType)
                  entryType = maybe "" (T.toLower . T.strip) entry.itemType
                  entryTags = map (T.toLower . T.strip) entry.tags
                  allowed = docTypeCompatibility dtStr
                  matched =
                    (not (T.null entryType) && entryType `Set.member` allowed)
                      || any (`Set.member` allowed) entryTags
               in [ "Document type mismatch: frontmatter doc_type '"
                      ++ T.unpack fm.docType
                      ++ "' does not align with index tags '"
                      ++ show entry.tags
                      ++ "'"
                  | not matched
                  ]
     in titleMismatch ++ docTypeMismatch

-- | Validate paths declared in related_files
validateRelatedFiles :: FilePath -> FilePath -> FilePath -> Frontmatter -> IO [String]
validateRelatedFiles repoRoot designRoot absFilePath fm =
  case fm.relatedFiles of
    Nothing -> pure []
    Just links -> do
      errs <- forM links $ \relLink -> do
        let candidates =
              [ repoRoot </> relLink
              , designRoot </> relLink
              , takeDirectory absFilePath </> relLink
              ]
        existsList <- mapM doesFileExist candidates
        dirList <- mapM doesDirectoryExist candidates
        if or (existsList ++ dirList)
          then pure Nothing
          else pure $ Just $ "Dead link in related_files: '" ++ relLink ++ "' not found on disk"
      pure (catMaybes errs)
