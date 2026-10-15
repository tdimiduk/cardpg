{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Design.Bundle
  ( AuthorityTier (..)
  , authorityTierTitle
  , classifyAuthority
  , FileBundleEntry (..)
  , LandscapeEntry (..)
  , BundleConfig (..)
  , BundleSummary (..)
  , computeDynamicFence
  , maxConsecutiveBackticks
  , extensionToLang
  , buildFileBundleEntry
  , extractLandscapeEntries
  , renderBundle
  , createBundle
  ) where

import Control.Applicative ((<|>))
import Data.Aeson (Value (..))
import Data.List (isPrefixOf, isSuffixOf, sort, stripPrefix)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Data.Time (defaultTimeLocale, formatTime, getCurrentTime)
import Design.Frontmatter (extractFrontmatterText, parseFrontmatter)
import Design.Index (IndexData (..), loadAllIndexData)
import Design.Types (Frontmatter (..), IndexItem (..))
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.FilePath (normalise, takeDirectory, takeExtension, (</>))

-- | Authority Tier for CardPG repository documents
data AuthorityTier
  = CanonicalRule
  | DesignPhilosophy
  | SystemDesignStandard
  | CanonicalMathBaseline
  | ActiveIteration
  | EmpiricalResearchSynthesis
  | EmpiricalResearchReport
  | CanonicalCardYaml
  | EngineHaskellAst
  | ArchivedDeprecated
  | ProjectDocument
  deriving stock (Show, Eq, Ord)

-- | Human-readable authority tier title
authorityTierTitle :: AuthorityTier -> Text
authorityTierTitle CanonicalRule = "CANONICAL RULE (Live System Law)"
authorityTierTitle DesignPhilosophy = "DESIGN PHILOSOPHY & PRECEPTS (Foundational Constraints)"
authorityTierTitle SystemDesignStandard = "SYSTEM DESIGN STANDARD (Engine Architecture & Ludology Rules)"
authorityTierTitle CanonicalMathBaseline = "CANONICAL MATH BASELINE (Target Numbers & Probabilities)"
authorityTierTitle ActiveIteration = "ACTIVE ITERATION / PROPOSAL (Unmerged / Exploratory — Not Yet Law)"
authorityTierTitle EmpiricalResearchSynthesis = "EMPIRICAL RESEARCH SYNTHESIS (Distilled Domain Reference)"
authorityTierTitle EmpiricalResearchReport = "EMPIRICAL RESEARCH REPORT (Deep Domain Data)"
authorityTierTitle CanonicalCardYaml = "CANONICAL CARD / CONSEQUENCE YAML (Schema & Balance Grounding)"
authorityTierTitle EngineHaskellAst = "ENGINE AST / HASKELL TYPES (Implementation Grounding)"
authorityTierTitle ArchivedDeprecated = "ARCHIVED / DEPRECATED (Historical Reference Only)"
authorityTierTitle ProjectDocument = "PROJECT DOCUMENT"

-- | Clean and normalize path separators to forward slashes
cleanPath :: FilePath -> FilePath
cleanPath p =
  let norm = map (\c -> if c == '\\' then '/' else c) (normalise p)
   in case norm of
        '.' : '/' : rest -> rest
        '/' : rest -> rest
        other -> other

-- | Classify a document's Authority Tier based on its relative path
classifyAuthority :: FilePath -> AuthorityTier
classifyAuthority rawPath =
  let p = cleanPath rawPath
   in if
        | ".outdated" `isSuffixOf` p
            || "design/archive/" `isPrefixOf` p
            || "archive/" `isPrefixOf` p ->
            ArchivedDeprecated
        | "design/rules/" `isPrefixOf` p || "rules/" `isPrefixOf` p ->
            CanonicalRule
        | "design/philosophy/" `isPrefixOf` p || "philosophy/" `isPrefixOf` p ->
            DesignPhilosophy
        | ".agent/standards/" `isPrefixOf` p || "standards/" `isPrefixOf` p ->
            SystemDesignStandard
        | p == "data/math-baseline.md" || p == "math-baseline.md" ->
            CanonicalMathBaseline
        | "design/iteration/" `isPrefixOf` p || "iteration/" `isPrefixOf` p ->
            ActiveIteration
        | "design/research/synthesis/" `isPrefixOf` p || "research/synthesis/" `isPrefixOf` p ->
            EmpiricalResearchSynthesis
        | "design/research/reports/" `isPrefixOf` p || "research/reports/" `isPrefixOf` p ->
            EmpiricalResearchReport
        | "data/cards/" `isPrefixOf` p || "cards/" `isPrefixOf` p ->
            CanonicalCardYaml
        | "core/src/" `isPrefixOf` p || "core/" `isPrefixOf` p ->
            EngineHaskellAst
        | otherwise ->
            ProjectDocument

-- | Find maximum consecutive backtick count in document text
maxConsecutiveBackticks :: Text -> Int
maxConsecutiveBackticks txt =
  let runs = filter (\g -> not (T.null g) && T.head g == '`') (T.group txt)
   in if null runs then 0 else maximum (map T.length runs)

-- | Compute a dynamic backtick fence safely exceeding any nested fences
computeDynamicFence :: Text -> Text
computeDynamicFence content =
  let n = max 5 (maxConsecutiveBackticks content + 1)
   in T.replicate n "`"

-- | Map file extension to markdown code fence syntax tag
extensionToLang :: FilePath -> Text
extensionToLang p =
  case takeExtension p of
    ".md" -> "markdown"
    ".markdown" -> "markdown"
    ".yaml" -> "yaml"
    ".yml" -> "yaml"
    ".hs" -> "haskell"
    ".json" -> "json"
    ".toml" -> "toml"
    ".sh" -> "bash"
    ".bash" -> "bash"
    _ -> ""

-- | Extracted metadata and contents for an individual bundled file
data FileBundleEntry = FileBundleEntry
  { relPath :: FilePath
  , authorityTier :: AuthorityTier
  , description :: Text
  , content :: Text
  , lineCount :: Int
  , charCount :: Int
  , estimatedTokens :: Int
  , fence :: Text
  , langTag :: Text
  }
  deriving stock (Show, Eq)

-- | Canonical document in the repository landscape available on request
data LandscapeEntry = LandscapeEntry
  { relPath :: FilePath
  , authorityTier :: AuthorityTier
  , description :: Text
  }
  deriving stock (Show, Eq, Ord)

-- | Configuration parameters for creating a bundle
data BundleConfig = BundleConfig
  { topic :: Text
  , framing :: Maybe Text
  , output :: FilePath
  , inputFiles :: [FilePath]
  , timestamp :: Maybe Text
  }
  deriving stock (Show, Eq)

-- | Aggregate summary metrics for a generated bundle
data BundleSummary = BundleSummary
  { totalFiles :: Int
  , totalLines :: Int
  , totalChars :: Int
  , totalEstimatedTokens :: Int
  , outputPath :: FilePath
  , entries :: [FileBundleEntry]
  , landscapeEntries :: [LandscapeEntry]
  }
  deriving stock (Show, Eq)

-- | Look up index or frontmatter description for a file
lookupFileMetadata :: FilePath -> Text -> IndexData -> Text
lookupFileMetadata relP fileContent idxData =
  let norm = cleanPath relP
      strippedDesign = fromMaybe norm (stripPrefix "design/" norm)
      -- 1. Try index lookup under both full and design-stripped paths
      mIndexItem =
        Map.lookup norm idxData.entriesByPath
          <|> Map.lookup strippedDesign idxData.entriesByPath
   in case mIndexItem of
        Just item
          | Just p <- item.purpose
          , not (T.null (T.strip p)) ->
              T.strip p
          | Just n <- item.name
          , not (T.null (T.strip n)) ->
              T.strip n
        _ ->
          -- 2. Fall back to frontmatter if Markdown
          case extractFrontmatterText fileContent of
            Right (Just (fmRaw, _)) ->
              case parseFrontmatter fmRaw of
                Right (fm, _) ->
                  fromMaybe
                    "(No description in index or frontmatter)"
                    (extractFrontmatterSummary fm)
                Left _ -> "(Frontmatter parse error)"
            _ ->
              -- 3. Fall back to first non-empty comment or default
              fromMaybe
                "(No description provided)"
                (extractLeadingComment fileContent)
  where
    extractFrontmatterSummary :: Frontmatter -> Maybe Text
    extractFrontmatterSummary fm =
      fm.purpose
        <|> fm.description
        <|> ( case Map.lookup ("summary" :: Text) fm.rawMap of
                Just (String s) | not (T.null (T.strip s)) -> Just (T.strip s)
                _ -> Nothing
            )
        <|> (if not (T.null (T.strip fm.title)) then Just (T.strip fm.title) else Nothing)

    extractLeadingComment :: Text -> Maybe Text
    extractLeadingComment txt =
      let ls = filter (not . T.null . T.strip) (T.lines txt)
       in case ls of
            (firstLine : _)
              | "# " `T.isPrefixOf` T.stripStart firstLine ->
                  Just (T.strip (T.drop 2 (T.stripStart firstLine)))
              | "-- |" `T.isPrefixOf` T.stripStart firstLine ->
                  Just (T.strip (T.drop 4 (T.stripStart firstLine)))
            _ -> Nothing

-- | Build a FileBundleEntry from disk content and repository index
buildFileBundleEntry :: FilePath -> Text -> IndexData -> FileBundleEntry
buildFileBundleEntry rawP fileContent idxData =
  let p = cleanPath rawP
      tier = classifyAuthority p
      desc = lookupFileMetadata p fileContent idxData
      lCount = length (T.lines fileContent)
      cCount = T.length fileContent
      tokens = cCount `div` 4
      f = computeDynamicFence fileContent
      lang = extensionToLang p
   in FileBundleEntry
        { relPath = p
        , authorityTier = tier
        , description = desc
        , content = fileContent
        , lineCount = lCount
        , charCount = cCount
        , estimatedTokens = tokens
        , fence = f
        , langTag = lang
        }

-- | Extract canonical landscape documents that are NOT in the bundled files
extractLandscapeEntries :: [FilePath] -> IndexData -> [LandscapeEntry]
extractLandscapeEntries inputFiles idxData =
  let bundled = Set.fromList (map cleanPath inputFiles)
      toRepo p =
        let norm = cleanPath p
         in if
              | "../" `isPrefixOf` norm -> drop 3 norm
              | "design/" `isPrefixOf` norm -> norm
              | "data/" `isPrefixOf` norm -> norm
              | "core/" `isPrefixOf` norm -> norm
              | ".agent/" `isPrefixOf` norm -> norm
              | otherwise -> "design/" </> norm
      isEligibleTier t =
        t
          `elem` [ CanonicalRule
                 , DesignPhilosophy
                 , SystemDesignStandard
                 , CanonicalMathBaseline
                 , EmpiricalResearchSynthesis
                 , CanonicalCardYaml
                 ]
      isIgnoredPath p =
        "index.yaml" `isSuffixOf` p
          || "README.md" `isSuffixOf` p
          || "http://" `isPrefixOf` p
          || "https://" `isPrefixOf` p
      rawEntries =
        [ LandscapeEntry
            { relPath = repoP
            , authorityTier = tier
            , description = T.strip desc
            }
        | (idxP, item) <- Map.toList idxData.entriesByPath
        , let repoP = toRepo idxP
        , not (isIgnoredPath repoP)
        , not (cleanPath repoP `Set.member` bundled)
        , let tier = classifyAuthority repoP
        , isEligibleTier tier
        , let desc = fromMaybe "" (item.purpose <|> item.name)
        , not (T.null (T.strip desc))
        ]
      nubByPath = Map.elems (Map.fromList [(e.relPath, e) | e <- rawEntries])
   in sort nubByPath

-- | Render the full markdown bundle text from configuration, entries, and landscape
renderBundle :: BundleConfig -> Text -> [FileBundleEntry] -> [LandscapeEntry] -> Text
renderBundle cfg timeStr fileEntries landscapeEntries =
  let totFiles = length fileEntries
      totLines = sum [e.lineCount | e <- fileEntries]
      totTokens = sum [e.estimatedTokens | e <- fileEntries]
      framingText = case cfg.framing of
        Just f | not (T.null (T.strip f)) -> T.strip f
        _ ->
          "(No specific framing provided. Analyze the included proposals and mechanical questions against the canonical rules and math baseline.)"
      directiveSection =
        T.unlines
          [ "## 1. Directive for AI (Lead Systems Designer)"
          , "You are acting as the **Lead Systems Designer** for CardPG."
          , "Analyze the core tensions framed in Section 2 using the documents provided in Section 6."
          , ""
          , "### Operating Rules:"
          , "1. **Respect Authority Tiers**:"
          , "   - `CANONICAL RULE` and `CANONICAL MATH BASELINE`: Binding laws and hard constraints. Must not be broken without explicit justification."
          , "   - `SYSTEM DESIGN STANDARD`: Mandatory design patterns (Defender-Centric Resolution, Deck as Life, Simultaneity of Action, Table Constraints)."
          , "   - `ACTIVE ITERATION / PROPOSAL`: Unmerged, exploratory ideas under evaluation."
          , "   - `EMPIRICAL RESEARCH SYNTHESIS`: Factual domain reference grounding physical reality."
          , "2. **Repository Context & Boundary Awareness**:"
          , "   - This bundle is a curated slice extracted from the larger CardPG repository, focused on this topic."
          , "   - Do NOT assume concepts referenced but not fully defined here are missing from the game."
          , "   - If a core dependency or subsystem is needed to resolve this topic, consult Section 5 (Broader Repository Landscape) and ask the user for that document rather than inventing substitute systems."
          , "3. **Prioritize Tabletop Ergonomics**: Cards must be physically playable on a standard table. Track status via card states, not excessive tokens. Avoid rigid initiative stacks."
          , "4. **Follow the Wrap-Up Protocol** (Section 3) when concluding."
          ]
      framingSection =
        T.unlines
          [ "## 2. Discussion Framing & Open Questions"
          , framingText
          ]
      wrapUpSection =
        T.unlines
          [ "## 3. Wrap-Up & Return Protocol"
          , "When the user indicates they are ready to finalize, wrap up, or synthesize this session (e.g., saying *\"Wrap this up into the final proposal block\"*), output your final synthesis in a **SINGLE self-contained markdown code block** using this template:"
          , ""
          , "```markdown"
          , "# [Topic Title] Proposal & Resolution"
          , "- **Status**: Iteration Proposal / Ready for Review"
          , "- **Summary**: (2-3 sentences explaining the core mechanical resolution)"
          , "- **Resolved Tensions**: (Bullet points addressing each question from Section 2)"
          , ""
          , "## Mechanical Changes & Drafts"
          , "### Target: `path/to/canonical-or-iteration-file.md`"
          , "[Exact text, section replacement, or new subsection to insert]"
          , ""
          , "### Target: `data/cards/...` (if applicable)"
          , "[YAML card/consequence definitions or schema updates]"
          , ""
          , "## Mathematical & Systems Verification"
          , "[Sanity check against data/math-baseline.md, hand economy, or table constraints]"
          , ""
          , "## Next Steps for Antigravity"
          , "[List of exact files to touch, index entries to update, and tests to run]"
          , "```"
          ]
      manifestLines =
        [ "- `"
            <> T.pack e.relPath
            <> "` (**"
            <> authorityTierTitle e.authorityTier
            <> "**, "
            <> T.pack (show e.lineCount)
            <> " lines) — *"
            <> e.description
            <> "*"
        | e <- fileEntries
        ]
      manifestSection =
        T.unlines
          ( [ "## 4. Included File Manifest & Authority Tiers"
            ]
              ++ manifestLines
              ++ [ ""
                 , "**Total Bundle Size**: "
                     <> T.pack (show totFiles)
                     <> " files | "
                     <> T.pack (show totLines)
                     <> " lines | ~"
                     <> T.pack (show totTokens)
                     <> " tokens"
                 ]
          )
      landscapeLines =
        if null landscapeEntries
          then ["*(All relevant canonical documents are included in this bundle.)*"]
          else
            [ "- `"
                <> T.pack e.relPath
                <> "` (**"
                <> authorityTierTitle e.authorityTier
                <> "**) — *"
                <> e.description
                <> "*"
            | e <- landscapeEntries
            ]
      landscapeSection =
        T.unlines
          ( [ "## 5. Broader Repository Landscape (Available on Request)"
            , "*The following canonical documents exist in the repository but are not bundled above. If relevant to resolving the topic questions, ask the user to provide them:*"
            , ""
            ]
              ++ landscapeLines
          )
      verbatimEntries =
        [ T.unlines
            [ "### FILE: `" <> T.pack e.relPath <> "`"
            , "- **Authority / Role**: " <> authorityTierTitle e.authorityTier
            , "- **Metadata**: " <> e.description
            , ""
            , e.fence <> e.langTag
            , e.content
            , e.fence
            ]
        | e <- fileEntries
        ]
      sourceSection =
        T.unlines
          ( [ "## 6. Verbatim Source Documents"
            , ""
            ]
              ++ verbatimEntries
          )
   in T.unlines
        [ "# CARDPG DESIGN BUNDLE: " <> cfg.topic
        , "Generated: " <> timeStr
        , ""
        , "---"
        , ""
        , directiveSection
        , "---"
        , ""
        , framingSection
        , "---"
        , ""
        , wrapUpSection
        , "---"
        , ""
        , manifestSection
        , "---"
        , ""
        , landscapeSection
        , "---"
        , ""
        , sourceSection
        ]

-- | Assemble bundle, write output file, and return summary metrics
createBundle :: FilePath -> BundleConfig -> IO (Either [FilePath] BundleSummary)
createBundle repoRoot cfg = do
  -- 1. Validate existence of all input files
  checks <- mapM (\p -> (p,) <$> doesFileExist (repoRoot </> p)) cfg.inputFiles
  let missingFiles = [p | (p, False) <- checks]

  if not (null missingFiles)
    then pure (Left missingFiles)
    else do
      -- 2. Load indexes from design/
      let designDir = repoRoot </> "design"
          rootIdx = designDir </> "index.yaml"
      idxData <- loadAllIndexData designDir rootIdx

      -- 3. Read file contents and build entries
      entries <-
        mapM
          ( \p -> do
              txt <- TIO.readFile (repoRoot </> p)
              pure $ buildFileBundleEntry p txt idxData
          )
          cfg.inputFiles

      -- 4. Extract unbundled canonical landscape entries
      let landscape = extractLandscapeEntries cfg.inputFiles idxData

      -- 5. Determine timestamp
      timeStr <- case cfg.timestamp of
        Just t -> pure t
        Nothing ->
          T.pack . formatTime defaultTimeLocale "%Y-%m-%d %H:%M"
            <$> getCurrentTime

      -- 6. Render markdown content
      let rendered = renderBundle cfg timeStr entries landscape
          outPath = repoRoot </> cfg.output

      -- 7. Write to disk
      createDirectoryIfMissing True (takeDirectory outPath)
      TIO.writeFile outPath rendered

      -- 8. Calculate summary metrics
      let summary =
            BundleSummary
              { totalFiles = length entries
              , totalLines = sum [e.lineCount | e <- entries]
              , totalChars = sum [e.charCount | e <- entries]
              , totalEstimatedTokens = sum [e.estimatedTokens | e <- entries]
              , outputPath = cfg.output
              , entries = entries
              , landscapeEntries = landscape
              }
      pure (Right summary)
