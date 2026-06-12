{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (forM, forM_, unless, when)
import Data.Aeson
import Data.Aeson.Types (parseEither)
import Data.Char (toUpper)
import Data.List (intercalate, isPrefixOf, isSuffixOf)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.IO qualified as Text
import Data.Yaml (ParseException, decodeFileEither)
import System.Directory (doesFileExist)
import System.Exit (exitFailure)
import System.FilePath (takeFileName, (</>))
import Text.Read (readMaybe)

-- Data structures
data Consequence = Consequence
  { name :: Text
  , tags :: [Text]
  , triggers :: Text
  , verisimilitude :: Text
  , description :: Text
  , onsetImpact :: Int
  , terminalImpact :: Maybe Int
  , healing :: Text
  , recoveryDifficulty :: Int
  , citations :: Text
  , file :: FilePath
  , lineNum :: Int
  }
  deriving (Show)

data LintError = LintError
  { file :: FilePath
  , lineNum :: Int
  , errorType :: String
  , errorMessage :: String
  }
  deriving (Show)

-- Main entry point
main :: IO ()
main = do
  let indexYamlPath = "design/research/index.yaml"
      hubPath = "design/research/synthesis/consequence-database.md"

  -- 1. Discover consequence files
  indexExists <- doesFileExist indexYamlPath
  unless indexExists $ do
    putStrLn $
      "[ERROR] "
        ++ indexYamlPath
        ++ " does not exist. Make sure you run the script from the repository root."
    exitFailure

  yamlResult <- decodeFileEither indexYamlPath :: IO (Either ParseException Value)
  paths <- case yamlResult of
    Left err -> do
      putStrLn $ "[ERROR] Failed to parse index.yaml: " ++ show err
      exitFailure
    Right val -> case extractConsequencePaths val of
      Left err -> do
        putStrLn $ "[ERROR] Failed to extract consequence paths from index.yaml: " ++ err
        exitFailure
      Right ps -> return ps

  -- 2. Extract canonical tags from the database hub
  hubExists <- doesFileExist hubPath
  unless hubExists $ do
    putStrLn $ "[ERROR] Consequence database hub file " ++ hubPath ++ " does not exist."
    exitFailure

  hubContent <- Text.readFile hubPath
  let canonicalTags = extractCanonicalTags hubContent
  putStrLn $ "Loaded " ++ show (Set.size canonicalTags) ++ " canonical tags from taxonomy."

  -- 3. Parse and lint each file
  results <- forM paths $ \relPath -> do
    let fullPath = "design" </> relPath
    exists <- doesFileExist fullPath
    if not exists
      then
        return
          (Left [LintError fullPath 0 "FileMissing" "Consequence file listed in index.yaml not found on disk."])
      else do
        fileContent <- Text.readFile fullPath
        return $ parseConsequenceFile fullPath fileContent canonicalTags

  let (errorsList, consequencesList) = partitionResults results
      allErrors = concat errorsList
      allConsequences = concat consequencesList

  -- 4. Print results & warnings
  if not (null allErrors)
    then do
      putStrLn $ "\n--- LINT ERRORS FOUND (" ++ show (length allErrors) ++ ") ---"
      forM_ allErrors $ \err ->
        putStrLn $ err.file ++ ":" ++ show err.lineNum ++ " [" ++ err.errorType ++ "] " ++ err.errorMessage
      putStrLn "\nVerification failed due to critical errors."
      exitFailure
    else do
      putStrLn $
        "\n[OK] All " ++ show (length allConsequences) ++ " consequences successfully parsed and verified."

      -- Check density and log warnings
      checkDensity allConsequences

      -- Generate and inject the density table
      let activeDomains = map getDomainName paths
          densityTable = generateDensityTable activeDomains allConsequences
      injectionResult <- injectTable hubPath densityTable
      case injectionResult of
        Left err -> do
          putStrLn $ "[ERROR] Failed to inject density table into hub: " ++ err
          exitFailure
        Right () -> do
          putStrLn $ "[OK] Live decade-density summary table successfully updated in " ++ hubPath

-- Helpers
extractConsequencePaths :: Value -> Either String [FilePath]
extractConsequencePaths = parseEither parseIndex
  where
    parseIndex = withObject "root" $ \obj -> do
      dp <- obj .: "design_process_and_research"
      rs <- dp .: "research_synthesis"
      paths <- mapM parseItem rs
      return $ filter isConsequencesFile paths

    parseItem = withObject "item" $ \item -> do
      pathText <- item .: "path"
      return $ Text.unpack pathText

    isConsequencesFile path =
      let filename = takeFileName path
       in "consequences-" `isPrefixOf` filename && ".md" `isSuffixOf` filename

extractCanonicalTags :: Text -> Set Text
extractCanonicalTags content =
  let allLines = Text.lines content
      taxonomyLines = getTaxonomyLines allLines False
      allTags = concatMap extractBacktickedWords taxonomyLines
   in Set.fromList allTags
  where
    getTaxonomyLines :: [Text] -> Bool -> [Text]
    getTaxonomyLines [] _ = []
    getTaxonomyLines (l : ls) active
      | "## Canonical Tag Taxonomy" `Text.isPrefixOf` l = getTaxonomyLines ls True
      | active && "## " `Text.isPrefixOf` l = []
      | active = l : getTaxonomyLines ls True
      | otherwise = getTaxonomyLines ls False

    extractBacktickedWords :: Text -> [Text]
    extractBacktickedWords txt =
      let parts = Text.splitOn "`" txt
          odds [] = []
          odds [_] = []
          odds (_ : x : xs) = x : odds xs
       in map Text.strip (odds parts)

isTableRow :: Text -> Bool
isTableRow t =
  let s = Text.strip t
   in Text.length s > 1 && Text.head s == '|' && Text.last s == '|'

stripMarkdownBold :: Text -> Text
stripMarkdownBold t =
  let s = Text.strip t
   in if "**" `Text.isPrefixOf` s && "**" `Text.isSuffixOf` s && Text.length s >= 4
        then Text.drop 2 (Text.dropEnd 2 s)
        else s

parseConsequenceFile :: FilePath -> Text -> Set Text -> Either [LintError] [Consequence]
parseConsequenceFile filePath content canonicalTags =
  let linesWithNums = zip [1 ..] (Text.lines content)
      tableRows = filter (\(_, l) -> isTableRow l) linesWithNums
   in if length tableRows < 2
        then Left [LintError filePath 0 "Format" "No markdown table found or table is too short."]
        else
          -- Skip the header (first row) and divider (second row)
          let dataRows = drop 2 tableRows
              results = map (\(ln, line) -> parseRow filePath ln line canonicalTags) dataRows
              (errors, consequences) = partitionEithers results
           in if not (null errors)
                then Left errors
                else Right consequences

parseRow :: FilePath -> Int -> Text -> Set Text -> Either LintError Consequence
parseRow filePath ln line canonicalTags =
  let cells = map Text.strip $ safeInit $ safeTail $ Text.splitOn "|" line
   in if length cells /= 10
        then
          Left $
            LintError
              filePath
              ln
              "Schema"
              ("Expected exactly 10 columns, but found " ++ show (length cells) ++ " columns.")
        else do
          let nameVal = fromMaybe "" (listToMaybe cells)
              tagsVal = cells !! 1
              triggersVal = cells !! 2
              verisimilitudeVal = cells !! 3
              descriptionVal = cells !! 4
              onsetVal = cells !! 5
              terminalVal = cells !! 6
              healingVal = cells !! 7
              recoveryVal = cells !! 8
              citationsVal = cells !! 9
              cleanName = stripMarkdownBold nameVal

          when (Text.null cleanName) $
            Left $
              LintError filePath ln "Validation" "Consequence Name cannot be empty."

          onset <- case readMaybe (Text.unpack onsetVal) of
            Just n | n >= 1 && n <= 100 -> Right n
            _ ->
              Left $
                LintError
                  filePath
                  ln
                  "Validation"
                  ("Onset Impact must be an integer between 1 and 100, got: '" ++ Text.unpack onsetVal ++ "'")

          terminal <-
            if terminalVal == "-"
              then Right Nothing
              else case readMaybe (Text.unpack terminalVal) of
                Just n | n >= 1 && n <= 100 -> Right (Just n)
                _ ->
                  Left $
                    LintError
                      filePath
                      ln
                      "Validation"
                      ( "Terminal Impact must be an integer between 1 and 100 or '-', got: '"
                          ++ Text.unpack terminalVal
                          ++ "'"
                      )

          recovery <- case readMaybe (Text.unpack recoveryVal) of
            Just n | n >= 1 && n <= 100 -> Right n
            _ ->
              Left $
                LintError
                  filePath
                  ln
                  "Validation"
                  ("Recovery Difficulty must be an integer between 1 and 100, got: '" ++ Text.unpack recoveryVal ++ "'")

          let rawTags = map Text.strip $ Text.splitOn "," tagsVal
              tags = filter (not . Text.null) rawTags
              invalidTags = filter (\t -> not (Set.member t canonicalTags)) tags

          if not (null invalidTags)
            then
              Left $
                LintError
                  filePath
                  ln
                  "Taxonomy"
                  ( "Invalid tag(s): "
                      ++ intercalate ", " (map (show . Text.unpack) invalidTags)
                      ++ ". Must match Canonical Tag Taxonomy."
                  )
            else
              Right
                Consequence
                  { name = cleanName
                  , tags = tags
                  , triggers = triggersVal
                  , verisimilitude = verisimilitudeVal
                  , description = descriptionVal
                  , onsetImpact = onset
                  , terminalImpact = terminal
                  , healing = healingVal
                  , recoveryDifficulty = recovery
                  , citations = citationsVal
                  , file = filePath
                  , lineNum = ln
                  }
  where
    safeTail [] = []
    safeTail (_ : xs) = xs
    safeInit [] = []
    safeInit xs = init xs

partitionResults :: [Either a b] -> ([a], [b])
partitionResults = foldr select ([], [])
  where
    select (Left x) (ls, rs) = (x : ls, rs)
    select (Right x) (ls, rs) = (ls, x : rs)

partitionEithers :: [Either a b] -> ([a], [b])
partitionEithers = partitionResults

getDecadeLabel :: Int -> Text
getDecadeLabel n
  | n >= 1 && n <= 10 = "1–10"
  | n >= 11 && n <= 20 = "11–20"
  | n >= 21 && n <= 30 = "21–30"
  | n >= 31 && n <= 40 = "31–40"
  | n >= 41 && n <= 50 = "41–50"
  | n >= 51 && n <= 60 = "51–60"
  | n >= 61 && n <= 70 = "61–70"
  | n >= 71 && n <= 80 = "71–80"
  | n >= 81 && n <= 90 = "81–90"
  | n >= 91 && n <= 100 = "91–100"
  | otherwise = "Invalid"

getDomainName :: FilePath -> Text
getDomainName fp =
  let base = takeFileName fp
   in case base of
        "consequences-combat.md" -> "Combat"
        "consequences-exploration.md" -> "Exploration"
        "consequences-social.md" -> "Social"
        "consequences-crafting.md" -> "Crafting"
        "consequences-arcane.md" -> "Arcane"
        "consequences-logistics.md" -> "Logistics"
        _ ->
          let t = Text.pack base
              stripped = fromMaybe t $ Text.stripPrefix "consequences-" t
              stripped' = fromMaybe stripped $ Text.stripSuffix ".md" stripped
           in capitalize stripped'

capitalize :: Text -> Text
capitalize t =
  if Text.null t
    then t
    else Text.singleton (toUpper (Text.head t)) <> Text.tail t

checkDensity :: [Consequence] -> IO ()
checkDensity consequences = do
  let decadeLabels = ["1–10", "11–20", "21–30", "31–40", "41–50", "51–60", "61–70", "71–80", "81–90", "91–100"]
  forM_ decadeLabels $ \dec -> do
    let decCons = filter (\c -> getDecadeLabel c.onsetImpact == dec) consequences
        total = length decCons
    if
      | total == 0 ->
          putStrLn $ "[WARNING] Decade " ++ Text.unpack dec ++ " has 0 entries aggregated across all files."
      | total < 2 ->
          putStrLn $
            "[WARNING] Decade "
              ++ Text.unpack dec
              ++ " has fewer than 2 entries aggregated across all files (low density: "
              ++ show total
              ++ ")."
      | otherwise -> return ()

generateDensityTable :: [Text] -> [Consequence] -> Text
generateDensityTable activeDomains consequences =
  let decadeLabels = ["1–10", "11–20", "21–30", "31–40", "41–50", "51–60", "61–70", "71–80", "81–90", "91–100"]
      counts = [(dec, getCountsForDecade dec) | dec <- decadeLabels]
      header = "| Decade | " ++ Text.unpack (Text.intercalate " | " activeDomains) ++ " | Total |"
      divider = "| :--- | " ++ intercalate " | " (map (const ":---:") activeDomains) ++ " | :---: |"
      rows = map makeRow counts
   in Text.unlines $
        [ "<!-- START_DENSITY_TABLE -->"
        , "<!-- prettier-ignore -->"
        , Text.pack header
        , Text.pack divider
        ]
          ++ rows
          ++ ["<!-- END_DENSITY_TABLE -->"]
  where
    getCountsForDecade :: Text -> (Map Text Int, Int)
    getCountsForDecade dec =
      let decCons = filter (\c -> getDecadeLabel c.onsetImpact == dec) consequences
          domainCounts = foldl' (\m c -> Map.insertWith (+) (getDomainName c.file) 1 m) Map.empty decCons
          total = length decCons
       in (domainCounts, total)

    makeRow :: (Text, (Map Text Int, Int)) -> Text
    makeRow (dec, (domCounts, total)) =
      let getVal dom = show (Map.findWithDefault 0 dom domCounts)
          domVals = map getVal activeDomains
          totalVal = "**" ++ show total ++ "**"
          decCell = "**" ++ Text.unpack dec ++ "**"
       in Text.pack $ "| " ++ intercalate " | " (decCell : domVals ++ [totalVal]) ++ " |"

injectTable :: FilePath -> Text -> IO (Either String ())
injectTable hubPath newTable = do
  content <- Text.readFile hubPath
  let startMarker = "<!-- START_DENSITY_TABLE -->"
      endMarker = "<!-- END_DENSITY_TABLE -->"
  case Text.breakOn startMarker content of
    (before, rest) | not (Text.null rest) ->
      case Text.breakOn endMarker (Text.drop (Text.length startMarker) rest) of
        (_, after) | not (Text.null after) -> do
          let cleanAfter = Text.drop (Text.length endMarker) after
              newContent = before <> newTable <> cleanAfter
          Text.writeFile hubPath newContent
          return $ Right ()
        _ -> return $ Left "Could not find <!-- END_DENSITY_TABLE --> comment marker."
    _ -> return $ Left "Could not find <!-- START_DENSITY_TABLE --> comment marker."
