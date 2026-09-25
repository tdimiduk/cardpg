{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Design.TOC
  ( getItemTitle
  , cleanDesc
  , makeMarkdownTable
  , generateRootToc
  , generateIterationToc
  , generateResearchToc
  , generateArchiveToc
  , normalizeMarkdownBlock
  , updateOrVerifyReadmeToc
  ) where

import Data.Aeson
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KM
import Data.Char (toUpper)
import Data.List (isPrefixOf, isSuffixOf)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Data.Vector qualified as V
import Design.Frontmatter (extractFrontmatterText, parseFrontmatter)
import Design.Index (loadIndexValue)
import Design.Types
import System.Directory (doesFileExist)
import System.FilePath (takeBaseName, takeDirectory, (</>))

-- | Clean and truncate descriptions for tables
cleanDesc :: Text -> Int -> Text
cleanDesc text maxLen =
  let s = T.strip (T.replace "\n" " " text)
   in if T.length s > maxLen
        then
          let searchSpan = T.drop 40 (T.take maxLen s)
           in case T.breakOn ". " searchSpan of
                (beforeDot, afterDot)
                  | not (T.null afterDot) ->
                      T.take 40 s <> beforeDot <> "."
                _ -> T.take (maxLen - 3) s <> "..."
        else s

-- | Format a markdown table with headers and rows
makeMarkdownTable :: [Text] -> [[Text]] -> Text
makeMarkdownTable headers rows =
  let sep = "| " <> T.intercalate " | " (replicate (length headers) ":---") <> " |"
      headerRow = "| " <> T.intercalate " | " headers <> " |"
      dataRows = ["| " <> T.intercalate " | " row <> " |" | row <- rows]
   in T.intercalate "\n" ([headerRow, sep] ++ dataRows)

-- | Look up or derive human title for an item in index
getItemTitle :: FilePath -> IndexItem -> IO Text
getItemTitle designRoot item = do
  case item.name of
    Just n | not (T.null n) -> pure n
    _ -> do
      let mPath = item.path
      case mPath of
        Just p
          | "http://" `isPrefixOf` p || "https://" `isPrefixOf` p ->
              pure $ fromMaybe (T.pack p) item.name
          | otherwise -> do
              let absPath = designRoot </> p
              exists <- doesFileExist absPath
              if exists
                then do
                  content <- TIO.readFile absPath
                  case extractFrontmatterText content of
                    Right (Just (fmLang, _)) ->
                      case parseFrontmatter fmLang of
                        Right (fm, _) | not (T.null fm.title) -> pure fm.title
                        _ -> checkReadmeOrFallback p absPath
                    _ -> checkReadmeOrFallback p absPath
                else pure $ deriveTitleFromPath p
        Nothing ->
          case item.components of
            Just compMap ->
              case Map.lookup "report_file" compMap of
                Just repF ->
                  let repDir = takeBaseName (takeDirectory repF)
                   in pure $ case repDir of
                        "dynamics-of-the-duel" -> "Dynamics of the Duel"
                        "pre-modern_battlefield_injury" -> "Pre-Modern Battlefield Injury"
                        other -> humanize (T.pack other)
                Nothing -> pure "Untitled"
            Nothing -> pure "Untitled"
  where
    checkReadmeOrFallback p absPath =
      if "index.yaml" `isSuffixOf` p
        then do
          let readmePath = takeDirectory absPath </> "README.md"
          rExists <- doesFileExist readmePath
          if rExists
            then do
              rContent <- TIO.readFile readmePath
              case extractFrontmatterText rContent of
                Right (Just (fmLang, _)) ->
                  case parseFrontmatter fmLang of
                    Right (fm, _) | not (T.null fm.title) -> pure fm.title
                    _ -> pure $ deriveTitleFromPath p
                _ -> pure $ deriveTitleFromPath p
            else pure $ deriveTitleFromPath p
        else pure $ deriveTitleFromPath p

    deriveTitleFromPath p =
      let stem = takeBaseName p
          parent = takeBaseName (takeDirectory p)
          special s = case s of
            "AGENTS" -> Just "Agent Design Rules"
            "players-guide" -> Just "Player's Guide"
            "gamemaster-guide" -> Just "Gamemaster's Guide"
            "players-guide-patch" -> Just "Player's Guide Patch"
            "gamemaster-guide-patch" -> Just "Gamemaster's Guide Patch"
            "resolution-exploration" -> Just "Resolution Mechanic Exploration"
            "fatigue-change-proposal" -> Just "Fatigue Change Proposal"
            "defense-action" -> Just "Defense Action Iteration"
            "design-sketchbook" -> Just "Design Sketchbook"
            "resolution-design-constraints" -> Just "Resolution System Design Constraints"
            "resolution-pitfalls" -> Just "Resolution System Pitfalls & Anti-Patterns"
            "consequence-pool-tag-escalation" -> Just "Consequence Pool & Tag Escalation Engine"
            "exploration-is-logistics" -> Just "Literature Note: How OSR Teaches Us That Exploration Is Logistics"
            "calibrating-your-expectations" -> Just "Literature Note: Calibrating Your Expectations"
            _ -> Nothing
       in case special stem of
            Just s -> s
            Nothing
              | stem `elem` ["README", "index"] ->
                  case special parent of
                    Just s -> s
                    Nothing
                      | parent `elem` ["iteration", "research", "archive", ""] ->
                          if stem == "README" then "Root Readme" else "Root Index"
                      | otherwise -> humanize (T.pack parent)
              | otherwise -> humanize (T.pack stem)

    humanize t =
      let replaced = map (\c -> if c == '-' || c == '_' then ' ' else c) (T.unpack t)
          ws = words replaced
          cap (c : cs) = toUpper c : cs
          cap [] = []
       in T.pack (unwords (map cap ws))

-- | Generate TOC body for root README.md
generateRootToc :: FilePath -> IO Text
generateRootToc designRoot = do
  res <- loadIndexValue (designRoot </> "index.yaml")
  case res of
    Left err -> pure $ "Error loading index.yaml: " <> T.pack err
    Right (_, Object rootObj) -> do
      let projFound = case KM.lookup "project_foundation" rootObj of
            Just (Object o) -> o
            _ -> KM.empty
          gameSys = case KM.lookup "game_system_and_rules" rootObj of
            Just (Object o) -> o
            _ -> KM.empty

      let getItemsFrom :: Text -> KM.KeyMap Value -> [IndexItem]
          getItemsFrom key obj = case KM.lookup (Key.fromText key) obj of
            Just (Array arr) -> [item | Success item <- map fromJSON (V.toList arr)]
            _ -> []

      -- Foundations & Philosophy
      let philItems =
            getItemsFrom "philosophy" projFound
              ++ getItemsFrom "design_patterns" projFound
              ++ getItemsFrom "methodology" projFound
          introItems =
            [ item
            | item <- getItemsFrom "introductory_materials" rootObj
            , item.path `elem` [Just "AGENTS.md", Just "introduction.md"]
            ]
      foundationsRows <- mapM (formatRow designRoot) (philItems ++ introItems)

      -- Rules & Mechanics
      let rulesItems =
            getItemsFrom "core_rules_and_guides" gameSys
              ++ getItemsFrom "lexicons" gameSys
              ++ getItemsFrom "modules" gameSys
      rulesRows <- mapM (formatRow designRoot) rulesItems

      -- Domain Catalogs
      let subIdxItems = getItemsFrom "sub_indexes" rootObj
      domainRows <- mapM (formatDomainRow designRoot) subIdxItems

      let blocks =
            [ "## Directory Catalog"
            , ""
            , "### Foundations & Philosophy"
            , makeMarkdownTable ["Document", "Summary"] foundationsRows
            , ""
            , "### Rules & Mechanics"
            , makeMarkdownTable ["Document", "Summary"] rulesRows
            , ""
            , "### Domain Catalogs"
            , makeMarkdownTable ["Domain", "Directory / Sub-Index", "Focus & Scope"] domainRows
            , ""
            , "_Last synced from `design/index.yaml` via `tools/audit_index.py`._"
            ]
      pure $ T.intercalate "\n" blocks
    _ -> pure "Invalid root index.yaml format"
  where
    formatRow root item = do
      title <- getItemTitle root item
      let pathStr = fromMaybe "" item.path
          desc = cleanDesc (fromMaybe "" item.purpose) 160
      pure ["[" <> title <> "](" <> T.pack pathStr <> ")", desc]

    formatDomainRow _ item = do
      let p = fromMaybe "" item.path
          dirName = T.pack (takeWhile (/= '/') p)
          domainName = case T.uncons dirName of
            Just (c, rest) -> T.cons (toUpper c) rest
            Nothing -> dirName
          subIndexLink =
            "[" <> dirName <> "/](" <> dirName <> "/README.md) ([Index](" <> T.pack p <> "))"
          desc = cleanDesc (fromMaybe "" item.purpose) 160
      pure ["**" <> domainName <> "**", subIndexLink, desc]

-- | Generate TOC body for iteration/README.md
generateIterationToc :: FilePath -> IO Text
generateIterationToc designRoot = do
  res <- loadIndexValue (designRoot </> "iteration/index.yaml")
  case res of
    Left err -> pure $ "Error loading iteration/index.yaml: " <> T.pack err
    Right (_, Object iterObj) -> do
      let activeExpl = case KM.lookup "active_design_exploration" iterObj of
            Just (Object o) -> o
            _ -> KM.empty
          getItemsFrom :: Text -> [IndexItem]
          getItemsFrom key = case KM.lookup (Key.fromText key) activeExpl of
            Just (Array arr) -> [item | Success item <- map fromJSON (V.toList arr)]
            _ -> []

      constraintsRows <- mapM (formatRelRow "iteration/") (getItemsFrom "mechanical_constraints")
      let proposalItems =
            getItemsFrom "resolution_and_combat_proposals"
              ++ getItemsFrom "mechanics_and_resource_proposals"
      proposalsRows <- mapM (formatProposalRow "iteration/") proposalItems
      sketchesRows <- mapM (formatRelRow "iteration/") (getItemsFrom "ideation_and_sketches")
      macroRows <- mapM (formatProposalRow "iteration/") (getItemsFrom "macro_structure_and_traces")

      let blocks =
            [ "## Active Iteration Catalog"
            , ""
            , "### Mechanical Constraints & Frameworks"
            , makeMarkdownTable ["Document", "Summary"] constraintsRows
            , ""
            , "### Active Proposals & Mechanics"
            , makeMarkdownTable ["Document", "Summary"] proposalsRows
            , ""
            , "### Ideation Sketches"
            , makeMarkdownTable ["Document", "Summary"] sketchesRows
            , ""
            ]
              ++ ( if null macroRows
                     then []
                     else
                       [ "### Macro Structure & Gameplay Traces"
                       , makeMarkdownTable ["Document", "Summary"] macroRows
                       , ""
                       ]
                 )
              ++ ["_Last synced from `iteration/index.yaml` via `tools/audit_index.py`._"]
      pure $ T.intercalate "\n" blocks
    _ -> pure "Invalid iteration/index.yaml format"
  where
    formatRelRow prefix item = do
      title <- getItemTitle designRoot item
      let p = fromMaybe "" item.path
          relP = stripPrefixStr prefix p
          desc = cleanDesc (fromMaybe "" item.purpose) 160
      pure ["[" <> title <> "](" <> T.pack relP <> ")", desc]

    formatProposalRow prefix item = do
      title <- getItemTitle designRoot item
      let p = fromMaybe "" item.path
          relP = stripPrefixStr prefix p
          finalP =
            if "index.yaml" `isSuffixOf` relP
              then take (length relP - length ("index.yaml" :: String)) relP ++ "README.md"
              else relP
          desc = cleanDesc (fromMaybe "" item.purpose) 160
      pure ["[" <> title <> "](" <> T.pack finalP <> ")", desc]

    stripPrefixStr pfx s
      | pfx `isPrefixOf` s = drop (length pfx) s
      | otherwise = s

-- | Generate TOC body for research/README.md
generateResearchToc :: FilePath -> IO Text
generateResearchToc designRoot = do
  res <- loadIndexValue (designRoot </> "research/index.yaml")
  case res of
    Left err -> pure $ "Error loading research/index.yaml: " <> T.pack err
    Right (_, Object rootObj) -> do
      let resData = case KM.lookup "design_process_and_research" rootObj of
            Just (Object o) -> o
            _ -> KM.empty
          getItemsFrom :: Text -> [IndexItem]
          getItemsFrom key = case KM.lookup (Key.fromText key) resData of
            Just (Array arr) -> [item | Success item <- map fromJSON (V.toList arr)]
            _ -> []

      let bedrockItems =
            getItemsFrom "factual_bedrock"
              ++ getItemsFrom "inspiration_library"
              ++ getItemsFrom "ludology_library"
      bedrockRows <- mapM (formatRelRow "research/") bedrockItems
      synthesisRows <- mapM (formatRelRow "research/") (getItemsFrom "research_synthesis")
      reportRows <- mapM formatReportRow (getItemsFrom "research_reports")
      theoryRows <- mapM (formatRelRow "research/") (getItemsFrom "design_theory_and_readings")

      let blocks =
            [ "## Research Catalog"
            , ""
            , "### Bibliographies & Bedrock"
            , makeMarkdownTable ["Document", "Summary"] bedrockRows
            , ""
            , "### Living Research Syntheses (`synthesis/`)"
            , makeMarkdownTable ["Document", "Summary"] synthesisRows
            , ""
            , "### Empirical Reports (`reports/`)"
            , makeMarkdownTable ["Report", "Summary"] reportRows
            , ""
            , "### Game Design Theory (`theory/readings/`)"
            , makeMarkdownTable ["Document", "Summary"] theoryRows
            , ""
            , "_Last synced from `research/index.yaml` via `tools/audit_index.py`._"
            ]
      pure $ T.intercalate "\n" blocks
    _ -> pure "Invalid research/index.yaml format"
  where
    formatRelRow prefix item = do
      title <- getItemTitle designRoot item
      let p = fromMaybe "" item.path
          relP = stripPrefixStr prefix p
          desc = cleanDesc (fromMaybe "" item.purpose) 160
      pure ["[" <> title <> "](" <> T.pack relP <> ")", desc]

    formatReportRow item = do
      title <- getItemTitle designRoot item
      let repF = case item.components of
            Just cMap -> fromMaybe "" (Map.lookup "report_file" cMap)
            Nothing -> ""
          relF = stripPrefixStr "research/" repF
          desc = cleanDesc (fromMaybe "" item.purpose) 160
      pure ["[" <> title <> "](" <> T.pack relF <> ")", desc]

    stripPrefixStr pfx s
      | pfx `isPrefixOf` s = drop (length pfx) s
      | otherwise = s

-- | Generate TOC body for archive/README.md
generateArchiveToc :: FilePath -> IO Text
generateArchiveToc designRoot = do
  res <- loadIndexValue (designRoot </> "archive/index.yaml")
  case res of
    Left err -> pure $ "Error loading archive/index.yaml: " <> T.pack err
    Right (_, Object rootObj) -> do
      let archData = case KM.lookup "archive_and_legacy_materials" rootObj of
            Just (Object o) -> o
            _ -> KM.empty
          getItemsFrom :: Text -> [IndexItem]
          getItemsFrom key = case KM.lookup (Key.fromText key) archData of
            Just (Array arr) -> [item | Success item <- map fromJSON (V.toList arr)]
            _ -> []

      itemsRows <- mapM formatItemRow (getItemsFrom "archived_playtest_spreadsheets")
      let blocks =
            [ "## Archived Content Catalog"
            , ""
            , "### Playtest Spreadsheets & Materials"
            , makeMarkdownTable ["Item", "Summary"] itemsRows
            , ""
            , "_Last synced from `archive/index.yaml` via `tools/audit_index.py`._"
            ]
      pure $ T.intercalate "\n" blocks
    _ -> pure "Invalid archive/index.yaml format"
  where
    formatItemRow item = do
      title <- getItemTitle designRoot item
      let p = fromMaybe "" item.path
          desc = cleanDesc (fromMaybe "" item.purpose) 160
      pure ["[" <> title <> "](" <> T.pack p <> ")", desc]

-- | Normalize markdown lines inside TOC block for robust diff comparison
normalizeMarkdownBlock :: Text -> [Text]
normalizeMarkdownBlock txt =
  let rawLines = map T.strip (T.lines (T.strip txt))
      filterLines =
        filter
          ( \l ->
              not (T.null l)
                && l /= "<!-- BEGIN AUTO-TOC -->"
                && l /= "<!-- END AUTO-TOC -->"
          )
          rawLines
   in map normalizeLine filterLines
  where
    normalizeLine l
      | T.isPrefixOf "|" l && T.isSuffixOf "|" l =
          let cells = map T.strip (T.splitOn "|" l)
              isSep c = T.null c || (T.all (\ch -> ch == '-' || ch == ':') c && not (T.null c))
              normCells = map (T.replace "\\*" "*" . T.replace "\\_" "_") cells
           in if all isSep cells
                then "TABLE_SEP"
                else "ROW:" <> T.intercalate "|" normCells
      | isLastSynced l =
          -- Normalize tool name and markers
          "_Last synced_"
      | otherwise = l

    isLastSynced l =
      let s = T.strip l
       in (T.isPrefixOf "*Last synced" s || T.isPrefixOf "_Last synced" s)
            && (T.isSuffixOf "*." s || T.isSuffixOf "_." s || T.isSuffixOf "*" s || T.isSuffixOf "_" s)

-- | Verify or update the AUTO-TOC block in a README file
updateOrVerifyReadmeToc :: FilePath -> Text -> Bool -> IO (Either String (), Bool)
updateOrVerifyReadmeToc readmeAbsPath expectedTocBody fix = do
  exists <- doesFileExist readmeAbsPath
  let expectedBlock = "<!-- BEGIN AUTO-TOC -->\n" <> T.strip expectedTocBody <> "\n<!-- END AUTO-TOC -->"
  if not exists
    then
      if fix
        then do
          TIO.writeFile readmeAbsPath (expectedBlock <> "\n")
          pure (Right (), True)
        else pure (Left $ "README file " ++ readmeAbsPath ++ " does not exist", False)
    else do
      content <- TIO.readFile readmeAbsPath
      let beginTag = "<!-- BEGIN AUTO-TOC -->"
          endTag = "<!-- END AUTO-TOC -->"
      case T.breakOn beginTag content of
        (before, afterBegin)
          | T.null afterBegin ->
              if fix
                then do
                  let newContent = T.stripEnd content <> "\n\n" <> expectedBlock <> "\n"
                  TIO.writeFile readmeAbsPath newContent
                  pure (Right (), True)
                else pure (Left "Missing <!-- BEGIN AUTO-TOC --> block", False)
          | otherwise -> do
              let afterTag = T.drop (T.length beginTag) afterBegin
              case T.breakOn endTag afterTag of
                (innerBlock, afterEnd)
                  | T.null afterEnd ->
                      pure (Left "Unterminated <!-- BEGIN AUTO-TOC --> block (missing closing tag)", False)
                  | otherwise -> do
                      let currentBlock = beginTag <> innerBlock <> endTag
                          normCurrent = normalizeMarkdownBlock currentBlock
                          normExpected = normalizeMarkdownBlock expectedBlock
                      if normCurrent == normExpected
                        then pure (Right (), False)
                        else
                          if fix
                            then do
                              let remainder = T.drop (T.length endTag) afterEnd
                                  newContent = before <> expectedBlock <> remainder
                              TIO.writeFile readmeAbsPath newContent
                              pure (Right (), True)
                            else pure (Left "Table of contents is out of date", False)
