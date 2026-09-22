{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module KeywordMod
  ( main
  , runExportGlossary
  , runNormalizeAll
  , runNormalizeSingle
  , runRename
  , parseGlossaryText
  , parseGlossaryFile
  , transformContent
  , transformLine
  , renameContent
  , chunkLine
  , Chunk (..)
  ) where

import Control.Monad (forM, unless, when)
import Core.Glossary
  ( Glossary (..)
  , GlossaryEntry (..)
  , allEntries
  , fromList
  , toSlug
  )
import Data.Aeson (toJSON)
import Data.Aeson.Encode.Pretty
  ( Config (..)
  , Indent (..)
  , defConfig
  , encodePretty'
  , keyOrder
  )
import Data.ByteString.Lazy qualified as BL
import Data.Char (isAlphaNum)
import Data.List (sortBy)
import Data.Maybe (catMaybes, fromMaybe)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Options.Applicative qualified as OA
import System.Directory
  ( canonicalizePath
  , createDirectoryIfMissing
  , doesDirectoryExist
  , doesFileExist
  , listDirectory
  )
import System.FilePath
  ( normalise
  , splitDirectories
  , takeDirectory
  , takeExtension
  , takeFileName
  , (</>)
  )

--------------------------------------------------------------------------------
-- CLI Model
--------------------------------------------------------------------------------

data Command
  = CmdExportGlossary ExportOptions
  | CmdNormalizeAll NormalizeOptions
  | CmdNormalize NormalizeSingleOptions
  | CmdRename RenameOptions

data ExportOptions = ExportOptions
  { input :: FilePath
  , output :: FilePath
  }

data NormalizeOptions = NormalizeOptions
  { dryRun :: Bool
  , paths :: [FilePath]
  }

data NormalizeSingleOptions = NormalizeSingleOptions
  { keyword :: Text
  , dryRun :: Bool
  , paths :: [FilePath]
  }

data RenameOptions = RenameOptions
  { oldKeyword :: Text
  , newKeyword :: Text
  , dryRun :: Bool
  , paths :: [FilePath]
  }

commandParser :: OA.Parser Command
commandParser =
  OA.hsubparser
    ( OA.command
        "export-glossary"
        ( OA.info
            (CmdExportGlossary <$> exportParser)
            (OA.progDesc "Compile keyword-glossary.md into export/glossary.json")
        )
        <> OA.command
          "normalize-all"
          ( OA.info
              (CmdNormalizeAll <$> normalizeAllParser)
              (OA.progDesc "Normalize all keywords defined in keyword-glossary.md into [[Wikilinks]]")
          )
        <> OA.command
          "normalize"
          ( OA.info
              (CmdNormalize <$> normalizeSingleParser)
              (OA.progDesc "Normalize a specific keyword and its plural across markdown documentation")
          )
        <> OA.command
          "rename"
          ( OA.info
              (CmdRename <$> renameParser)
              (OA.progDesc "Rename a keyword across markdown documentation")
          )
    )

exportParser :: OA.Parser ExportOptions
exportParser =
  ExportOptions
    <$> OA.strOption
      ( OA.long "input"
          <> OA.short 'i'
          <> OA.value "design/rules/keyword-glossary.md"
          <> OA.showDefault
          <> OA.help "Path to keyword glossary markdown file"
      )
    <*> OA.strOption
      ( OA.long "output"
          <> OA.short 'o'
          <> OA.value "export/glossary.json"
          <> OA.showDefault
          <> OA.help "Destination path for exported JSON glossary"
      )

normalizeAllParser :: OA.Parser NormalizeOptions
normalizeAllParser =
  NormalizeOptions
    <$> OA.switch
      ( OA.long "dry-run"
          <> OA.help "Preview changes without modifying files"
      )
    <*> OA.many
      ( OA.strOption
          ( OA.long "path"
              <> OA.metavar "PATH"
              <> OA.help
                "Specific file or directory to process (can be specified multiple times; defaults to design/rules and design/philosophy)"
          )
      )

normalizeSingleParser :: OA.Parser NormalizeSingleOptions
normalizeSingleParser =
  NormalizeSingleOptions
    <$> OA.strArgument
      ( OA.metavar "KEYWORD"
          <> OA.help "Keyword to normalize"
      )
    <*> OA.switch
      ( OA.long "dry-run"
          <> OA.help "Preview changes without modifying files"
      )
    <*> OA.many
      ( OA.strOption
          ( OA.long "path"
              <> OA.metavar "PATH"
              <> OA.help "Specific file or directory to process"
          )
      )

renameParser :: OA.Parser RenameOptions
renameParser =
  RenameOptions
    <$> OA.strArgument
      ( OA.metavar "OLD"
          <> OA.help "Old keyword name"
      )
    <*> OA.strArgument
      ( OA.metavar "NEW"
          <> OA.help "New keyword name"
      )
    <*> OA.switch
      ( OA.long "dry-run"
          <> OA.help "Preview changes without modifying files"
      )
    <*> OA.many
      ( OA.strOption
          ( OA.long "path"
              <> OA.metavar "PATH"
              <> OA.help "Specific file or directory to process"
          )
      )

--------------------------------------------------------------------------------
-- Main Entry Point
--------------------------------------------------------------------------------

main :: IO ()
main = do
  cmd <-
    OA.execParser $
      OA.info
        (commandParser OA.<**> OA.helper)
        (OA.fullDesc <> OA.progDesc "Keyword normalization and glossary management tool for CardPG")
  case cmd of
    CmdExportGlossary opts -> runExportGlossary opts
    CmdNormalizeAll opts -> runNormalizeAll opts
    CmdNormalize opts -> runNormalizeSingle opts
    CmdRename opts -> runRename opts

--------------------------------------------------------------------------------
-- Glossary Parsing
--------------------------------------------------------------------------------

parseGlossaryFile :: FilePath -> IO Glossary
parseGlossaryFile path = do
  content <- TIO.readFile path
  pure $ parseGlossaryText content

parseGlossaryText :: Text -> Glossary
parseGlossaryText input = fromList (reverse finalEntries)
  where
    initialState = ([], "", Nothing) -- (accEntries, currentCat, currentKw)
    (finalEntries, _, _) = foldl' step initialState (T.lines input ++ ["## END"])

    step (entries, currentCat, mKw) line
      | "## " `T.isPrefixOf` line =
          let flushed = maybe [] (flushKw currentCat) mKw
              newCat = T.strip (T.drop 3 line)
           in (flushed ++ entries, newCat, Nothing)
      | "### " `T.isPrefixOf` line =
          let flushed = maybe [] (flushKw currentCat) mKw
              name = T.strip (T.drop 4 line)
           in (flushed ++ entries, currentCat, Just (name, [], []))
      | "#### " `T.isPrefixOf` line =
          let flushed = maybe [] (flushKw currentCat) mKw
              name = T.strip (T.drop 5 line)
           in (flushed ++ entries, currentCat, Just (name, [], []))
      | Just (name, aliases, summaryLines) <- mKw =
          let stripped = T.strip line
           in if
                | isAliasLine stripped ->
                    let newAliases = extractAliases stripped
                     in (entries, currentCat, Just (name, aliases ++ newAliases, summaryLines))
                | not (T.null stripped) && not ("#" `T.isPrefixOf` stripped) ->
                    (entries, currentCat, Just (name, aliases, summaryLines ++ [stripped]))
                | otherwise ->
                    (entries, currentCat, mKw)
      | otherwise = (entries, currentCat, mKw)

    isAliasLine t =
      ("_Aliases:" `T.isPrefixOf` t || "*Aliases:" `T.isPrefixOf` t)
        && (T.isSuffixOf "_" t || T.isSuffixOf "*" t)

    extractAliases t =
      let inner = T.dropWhile (\c -> c == '_' || c == '*' || c == ' ') t
          afterColon = fromMaybe inner (T.stripPrefix "Aliases:" inner)
          cleaned = T.dropWhileEnd (\c -> c == '_' || c == '*' || c == ' ') afterColon
       in filter (not . T.null) $ map T.strip $ T.splitOn "," cleaned

    flushKw cat (name, aliases, summaryLines) =
      let theme = case T.toLower name of
            "red" -> Just "red"
            "yellow" -> Just "yellow"
            "blue" -> Just "blue"
            _ -> Nothing
          summary = T.unwords (filter (not . T.null) summaryLines)
       in [ GlossaryEntry
              { canonical = name
              , aliases = aliases
              , slug = toSlug name
              , category = cat
              , summary = summary
              , theme = theme
              }
          ]

--------------------------------------------------------------------------------
-- Export Subcommand
--------------------------------------------------------------------------------

runExportGlossary :: ExportOptions -> IO ()
runExportGlossary opts = do
  exists <- doesFileExist opts.input
  if not exists
    then putStrLn $ "Error: Glossary file not found: " ++ opts.input
    else do
      glossary <- parseGlossaryFile opts.input
      let total = length (allEntries glossary)
      putStrLn $ "Parsed " ++ show total ++ " glossary entries from " ++ opts.input

      let prettyConfig =
            defConfig
              { confIndent = Spaces 2
              , confCompare = keyOrder ["canonical", "aliases", "slug", "category", "summary", "theme"]
              }
          jsonBytes = encodePretty' prettyConfig (toJSON glossary)

      createDirectoryIfMissing True (takeDirectory opts.output)
      BL.writeFile opts.output jsonBytes
      putStrLn $ "Successfully exported glossary JSON to " ++ opts.output

--------------------------------------------------------------------------------
-- Normalization & Parsing Engine
--------------------------------------------------------------------------------

data Chunk = Protected Text | Unprotected Text
  deriving stock (Show, Eq)

-- | Chunk a line into protected sections (existing wikilinks, markdown links, code spans)
-- and unprotected text that is eligible for keyword substitution.
chunkLine :: Text -> [Chunk]
chunkLine txt
  | T.null txt = []
  | otherwise =
      case findNextSpan txt of
        Nothing -> [Unprotected txt]
        Just (before, spanText, after) ->
          let beforeChunks = [Unprotected before | not (T.null before)]
              spanChunk = Protected spanText
           in beforeChunks ++ [spanChunk] ++ chunkLine after

-- | Find the earliest occurring protected span in the text.
findNextSpan :: Text -> Maybe (Text, Text, Text)
findNextSpan txt =
  let candidates =
        [ findMultiBacktick txt
        , findWikiLink txt
        , findMarkdownLink txt
        ]
      validCandidates = catMaybes candidates
   in case sortBy (\(b1, _, _) (b2, _, _) -> compare (T.length b1) (T.length b2)) validCandidates of
        [] -> Nothing
        (best : _) -> Just best

findMultiBacktick :: Text -> Maybe (Text, Text, Text)
findMultiBacktick txt = do
  let (before, matchRest) = T.breakOn "``" txt
  if T.null matchRest
    then Nothing
    else do
      let backtickRun = T.takeWhile (== '`') matchRest
          runLen = T.length backtickRun
          contentStart = T.drop runLen matchRest
          (inner, closeRest) = T.breakOn backtickRun contentStart
      if T.null closeRest
        then Nothing
        else do
          let spanText = backtickRun <> inner <> backtickRun
              after = T.drop runLen closeRest
          Just (before, spanText, after)

findWikiLink :: Text -> Maybe (Text, Text, Text)
findWikiLink txt = do
  let (before, matchRest) = T.breakOn "[[" txt
  if T.null matchRest
    then Nothing
    else do
      let (inner, closeRest) = T.breakOn "]]" (T.drop 2 matchRest)
      if T.null closeRest
        then Nothing
        else do
          let spanText = "[[" <> inner <> "]]"
              after = T.drop 2 closeRest
          Just (before, spanText, after)

findMarkdownLink :: Text -> Maybe (Text, Text, Text)
findMarkdownLink txt = scan 0
  where
    len = T.length txt
    scan idx
      | idx >= len = Nothing
      | T.index txt idx == '[' =
          case findClose idx of
            Just (spanText, after) ->
              let before = T.take idx txt
               in Just (before, spanText, after)
            Nothing -> scan (idx + 1)
      | otherwise = scan (idx + 1)

    findClose openBracketIdx = do
      let rest = T.drop (openBracketIdx + 1) txt
          (linkText, afterBracket) = T.breakOn "]" rest
      if T.null afterBracket || not ("(" `T.isPrefixOf` T.drop 1 afterBracket)
        then Nothing
        else do
          let urlRest = T.drop 2 afterBracket
              (url, closeParenRest) = T.breakOn ")" urlRest
          if T.null closeParenRest
            then Nothing
            else do
              let spanText = "[" <> linkText <> "](" <> url <> ")"
                  after = T.drop 1 closeParenRest
              Just (spanText, after)

-- | Transform a single line of Markdown, safeguarding headers, links, and code literals.
transformLine :: [Text] -> [(Text, Text)] -> Text -> Text
transformLine terms pluralPairs line
  -- Do not touch headings
  | "#" `T.isPrefixOf` T.stripStart line = line
  | otherwise =
      let chunks = chunkLine line
          transformed = map processChunk chunks
       in T.concat transformed
  where
    processChunk (Protected p) = p
    processChunk (Unprotected u) =
      let withPlurals = foldl' replacePlural u pluralPairs
          withBackticks = foldl' replaceBackticks withPlurals terms
          withBold = foldl' replaceBold withBackticks terms
       in withBold

    -- `singular`s -> [[plural]]
    replacePlural text (plural, singular) =
      replaceWordBoundary ("`" <> singular <> "`s") ("[[" <> plural <> "]]") text

    -- `Term` -> [[Term]]
    replaceBackticks text term =
      T.replace ("`" <> term <> "`") ("[[" <> term <> "]]") text

    -- \**Term** -> [[Term]]
    replaceBold text term =
      T.replace ("**" <> term <> "**") ("[[" <> term <> "]]") text

-- | Replace target with replacement only if not followed by an alphanumeric character.
replaceWordBoundary :: Text -> Text -> Text -> Text
replaceWordBoundary needle replacement haystack
  | T.null needle = haystack
  | otherwise = go haystack
  where
    nLen = T.length needle
    go txt =
      let (before, matchRest) = T.breakOn needle txt
       in if T.null matchRest
            then txt
            else
              let afterMatch = T.drop nLen matchRest
                  isWordFollow = case T.uncons afterMatch of
                    Just (c, _) -> isAlphaNum c
                    Nothing -> False
               in if isWordFollow
                    then before <> needle <> go afterMatch
                    else before <> replacement <> go afterMatch

-- | Transform content of a file, respecting fenced code blocks.
transformContent :: [Text] -> Text -> (Text, Int)
transformContent terms content =
  let (newLines, changedCount, _) = foldl' processLine ([], 0, False) (T.lines content)
      trailingNewline = if "\n" `T.isSuffixOf` content then "\n" else ""
      result = T.intercalate "\n" (reverse newLines) <> trailingNewline
   in (result, changedCount)
  where
    termSet = Set.fromList terms
    pluralPairs =
      [ (t, T.init t)
      | t <- terms
      , "s" `T.isSuffixOf` t
      , Set.member (T.init t) termSet
      ]

    processLine (acc, count, inCodeBlock) line
      | "```" `T.isPrefixOf` T.stripStart line =
          (line : acc, count, not inCodeBlock)
      | inCodeBlock =
          (line : acc, count, True)
      | otherwise =
          let newLine = transformLine terms pluralPairs line
              isChanged = newLine /= line
           in (newLine : acc, if isChanged then count + 1 else count, False)

-- | Rename a keyword across content.
renameLine :: Text -> Text -> Text -> Text
renameLine oldKw newKw line =
  let chunks = chunkLine line
   in T.concat $ map processChunk chunks
  where
    processChunk (Protected p) =
      -- Even within wikilinks, if it matches exactly [[oldKw]], rename it:
      if p == "[[" <> oldKw <> "]]"
        then "[[" <> newKw <> "]]"
        else p
    processChunk (Unprotected u) =
      let r1 = T.replace ("[[" <> oldKw <> "]]") ("[[" <> newKw <> "]]") u
          r2 = T.replace ("`" <> oldKw <> "`") ("[[" <> newKw <> "]]") r1
          r3 = T.replace ("**" <> oldKw <> "**") ("[[" <> newKw <> "]]") r2
       in r3

renameContent :: Text -> Text -> Text -> (Text, Int)
renameContent oldKw newKw content =
  let (newLines, changedCount, _) = foldl' processLine ([], 0, False) (T.lines content)
      trailingNewline = if "\n" `T.isSuffixOf` content then "\n" else ""
      result = T.intercalate "\n" (reverse newLines) <> trailingNewline
   in (result, changedCount)
  where
    processLine (acc, count, inCodeBlock) line
      | "```" `T.isPrefixOf` T.stripStart line =
          (line : acc, count, not inCodeBlock)
      | inCodeBlock =
          (line : acc, count, True)
      | otherwise =
          let newLine = renameLine oldKw newKw line
              isChanged = newLine /= line
           in (newLine : acc, if isChanged then count + 1 else count, False)

--------------------------------------------------------------------------------
-- File Walking & Normalization Commands
--------------------------------------------------------------------------------

defaultTargetDirs :: [FilePath]
defaultTargetDirs =
  [ "design/rules"
  , "design/philosophy"
  ]

glossaryFile :: FilePath
glossaryFile = "design/rules/keyword-glossary.md"

ignorePath :: FilePath -> Bool
ignorePath path =
  let parts = splitDirectories (normalise path)
      fn = takeFileName path
   in case parts of
        [] -> False
        (firstPart : rest) ->
          firstPart
            `elem` [ "code"
                   , ".git"
                   , "ai"
                   , "export"
                   , "tools"
                   , "tools-hs"
                   , "client"
                   , ".venv"
                   , "scratch"
                   , "dist-newstyle"
                   , "output"
                   , "test-results"
                   ]
            || fn
              `elem` [ "inspiration-sources.yaml"
                     , "verisimilitude-sources.yaml"
                     , "ludology-sources.yaml"
                     ]
            || (firstPart == "design" && case rest of ("research" : _) -> True; _ -> False)

walkMarkdownFiles :: [FilePath] -> IO [FilePath]
walkMarkdownFiles targets = do
  targetList <- if null targets then pure defaultTargetDirs else pure targets
  files <- forM targetList walkTarget
  canonicalGlossary <- canonicalizePath glossaryFile
  let allFiles = concat files
  filterM'
    ( \f -> do
        cF <- canonicalizePath f
        pure (cF /= canonicalGlossary)
    )
    allFiles
  where
    filterM' _ [] = pure []
    filterM' p (x : xs) = do
      keep <- p x
      rest <- filterM' p xs
      pure $ if keep then x : rest else rest

    walkTarget path = do
      isDir <- doesDirectoryExist path
      isFile <- doesFileExist path
      if
        | isFile && takeExtension path == ".md" && not (ignorePath path) ->
            pure [path]
        | isDir && not (ignorePath path) -> do
            entries <- listDirectory path
            subpaths <- forM entries (\e -> walkTarget (path </> e))
            pure (concat subpaths)
        | otherwise -> pure []

extractAllTerms :: Glossary -> [Text]
extractAllTerms g =
  let entriesList = allEntries g
      rawTerms = concat [e.canonical : e.aliases | e <- entriesList]
      termSet = Set.fromList rawTerms
   in sortBy (\a b -> compare (T.length b) (T.length a)) (Set.toList termSet)

runNormalizeAll :: NormalizeOptions -> IO ()
runNormalizeAll opts = do
  glossaryExists <- doesFileExist glossaryFile
  if not glossaryExists
    then putStrLn $ "Error: Glossary file not found at " ++ glossaryFile
    else do
      glossary <- parseGlossaryFile glossaryFile
      let terms = extractAllTerms glossary
      putStrLn $ "Loaded " ++ show (length terms) ++ " terms/aliases from " ++ glossaryFile

      mdFiles <- walkMarkdownFiles opts.paths
      (totalChanges, fileCount) <- runNormalizationPass terms opts.dryRun mdFiles
      let modeStr = if opts.dryRun then "Previewed" else "Completed"
      putStrLn $
        modeStr
          ++ " normalization: "
          ++ show totalChanges
          ++ " line changes across "
          ++ show fileCount
          ++ " files."

runNormalizeSingle :: NormalizeSingleOptions -> IO ()
runNormalizeSingle opts = do
  let kw = opts.keyword
      terms =
        if "s" `T.isSuffixOf` kw
          then [kw]
          else [kw <> "s", kw]
      sortedTerms = sortBy (\a b -> compare (T.length b) (T.length a)) terms

  mdFiles <- walkMarkdownFiles opts.paths
  (totalChanges, _) <- runNormalizationPass sortedTerms opts.dryRun mdFiles
  let modeStr = if opts.dryRun then "Previewed" else "Completed"
  putStrLn $
    modeStr ++ " normalization for '" ++ T.unpack kw ++ "': " ++ show totalChanges ++ " changes."

runNormalizationPass :: [Text] -> Bool -> [FilePath] -> IO (Int, Int)
runNormalizationPass terms dryRun files = do
  results <- forM files $ \filePath -> do
    content <- TIO.readFile filePath
    let (newContent, changes) = transformContent terms content
    when (changes > 0) $ do
      let modeTag = if dryRun then "[DRY RUN] Would update " else "Updated "
      putStrLn $ modeTag ++ show changes ++ " lines in " ++ filePath
      unless dryRun $
        TIO.writeFile filePath newContent
    pure (changes, if changes > 0 then 1 else 0)
  pure (sum (map fst results), sum (map snd results))

runRename :: RenameOptions -> IO ()
runRename opts = do
  mdFiles <- walkMarkdownFiles opts.paths
  results <- forM mdFiles $ \filePath -> do
    content <- TIO.readFile filePath
    let (newContent, changes) = renameContent opts.oldKeyword opts.newKeyword content
    when (changes > 0) $ do
      let modeTag = if opts.dryRun then "[DRY RUN] Would rename " else "Renamed "
      putStrLn $ modeTag ++ show changes ++ " instances in " ++ filePath
      unless opts.dryRun $
        TIO.writeFile filePath newContent
    pure changes
  let totalChanges = sum results
      modeStr = if opts.dryRun then "Previewed" else "Completed"
  putStrLn $
    modeStr
      ++ " rename: "
      ++ show totalChanges
      ++ " instances of '"
      ++ T.unpack opts.oldKeyword
      ++ "' -> '[["
      ++ T.unpack opts.newKeyword
      ++ "]]'."
