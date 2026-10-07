{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ManageCards.Audit
  ( scanActorFiles
  , runAudit
  , printAuditReport
  , AuditReport (..)
  ) where

import Control.Monad (forM, forM_, when)
import Data.List (isSuffixOf, sortOn)
import Data.Ord (Down (..))
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Data.Yaml (ParseException, decodeFileEither)
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath ((</>))

import Core.Card (ActorDefinition, CoreCard (..), RulesStatus (..), Stats (..), actorDeckCards)
import Core.DSL (toText)
import Core.NonEmptyText (getRawText)
import Data.List.NonEmpty qualified as NE
import ManageCards.Classifier
  ( checkLegacyArmor
  , checkLegacyDefense
  , checkLegacyWounds
  , checkObsoleteTiers
  , checkShorthandColor
  , extractCardTexts
  )
import ManageCards.Deduplicate (groupCards)
import ManageCards.Types (CardGroup (..))

data AuditReport = AuditReport
  { filesScanned :: [FilePath]
  , totalInlineCards :: Int
  , uniqueExactCards :: Int
  , candidateMasterCards :: Int
  , cardGroups :: [CardGroup]
  , topReusedCards :: [(Text, Int)]
  , legacyCardsCount :: Int
  , currentCardsCount :: Int
  , legacyBreakdown :: [(Text, Int)]
  }
  deriving stock (Show)

-- | Scan directory and return all valid YAML files (skipping reformatted/temporary files).
findYamlFiles :: FilePath -> IO [FilePath]
findYamlFiles dir = do
  exists <- doesDirectoryExist dir
  if not exists
    then pure []
    else do
      entries <- listDirectory dir
      let validFiles =
            filter
              ( \f ->
                  (".yaml" `isSuffixOf` f || ".yml" `isSuffixOf` f)
                    && not (".reformatted" `isSuffixOf` f)
                    && not (".outdated" `isSuffixOf` f)
              )
              entries
      pure (map (dir </>) validFiles)

-- | Scan actor directories, extracting all inline cards and scanned file list.
scanActorFiles :: [FilePath] -> IO ([(FilePath, CoreCard)], [FilePath])
scanActorFiles dirs = do
  allFilesNested <- mapM findYamlFiles dirs
  let allFiles = concat allFilesNested
  pairsNested <- forM allFiles $ \path -> do
    res <- decodeFileEither path :: IO (Either ParseException ActorDefinition)
    case res of
      Right actor -> pure [(path, c) | c <- actorDeckCards actor]
      Left _ -> pure []
  pure (concat pairsNested, allFiles)

type ExactCardKey =
  (Text, Maybe Text, Maybe [Text], Maybe Int, (Int, Int, Int), Maybe Text)

-- | Run full audit and deduplication analysis across actor directories.
runAudit :: [FilePath] -> IO AuditReport
runAudit dirs = do
  (rawPairs, scanned) <- scanActorFiles dirs
  let groups = groupCards rawPairs
      exactCount =
        Set.size
          ( Set.fromList
              [ ( getRawText cName
                , fmap toText cAttack
                , fmap (map toText . NE.toList) cRules
                , cCost
                , (r, y, b)
                , fmap toText cFlavor
                )
              | ( _
                  , CoreCard
                      { name = cName
                      , attack = cAttack
                      , rules = cRules
                      , cost = cCost
                      , stats = Stats r y b
                      , flavor = cFlavor
                      }
                  ) <-
                  rawPairs
              ]
              :: Set.Set ExactCardKey
          )
      reused =
        sortOn
          (\(_, cnt) -> Down cnt)
          [ (grp.canonicalSlug, length grp.occurrences)
          | grp <- groups
          , length grp.occurrences > 1
          ]

      legacyCards = filter (\g -> g.rulesStatus == RulesOutdated) groups
      currentCards = filter (\g -> g.rulesStatus == RulesCurrent) groups

      colorCount = countMatches checkShorthandColor groups
      armorCount = countMatches checkLegacyArmor groups
      defendCount = countMatches checkLegacyDefense groups
      tierCount = countMatches checkObsoleteTiers groups
      woundCount = countMatches checkLegacyWounds groups

      breakdown =
        [ ("Shorthand color syntax (|[xyzb]|)", colorCount)
        , ("Legacy armor syntax (ignore armor / no armor)", armorCount)
        , ("Legacy defense wording (defend from anywhere)", defendCount)
        , ("Obsolete consequence tiers (Minor/Major/Critical)", tierCount)
        , ("Legacy wound phrasing (basic wound)", woundCount)
        ]

  pure
    AuditReport
      { filesScanned = scanned
      , totalInlineCards = length rawPairs
      , uniqueExactCards = exactCount
      , candidateMasterCards = length groups
      , cardGroups = groups
      , topReusedCards = take 15 reused
      , legacyCardsCount = length legacyCards
      , currentCardsCount = length currentCards
      , legacyBreakdown = breakdown
      }
  where
    countMatches predicate grps =
      length
        [ g
        | g <- grps
        , any predicate (extractCardTexts g.baseCard)
        ]

-- | Print a formatted audit report to stdout.
printAuditReport :: AuditReport -> Bool -> IO ()
printAuditReport report verbose = do
  T.putStrLn "=========================================================="
  T.putStrLn "              CARD DATABASE AUDIT REPORT                  "
  T.putStrLn "=========================================================="
  putStrLn $ "Actor Files Scanned:           " ++ show (length report.filesScanned)
  putStrLn $ "Total Inline Deck Entries:     " ++ show report.totalInlineCards
  putStrLn $ "Unique Exact Cards:            " ++ show report.uniqueExactCards
  putStrLn $ "Candidate Master Cards:        " ++ show report.candidateMasterCards
  putStrLn $ "Rules Status: Current:         " ++ show report.currentCardsCount
  putStrLn $ "Rules Status: Outdated:        " ++ show report.legacyCardsCount
  T.putStrLn "----------------------------------------------------------"
  T.putStrLn "Legacy Rules Breakdown (in Candidate Master Cards):"
  forM_ report.legacyBreakdown $ \(desc, cnt) ->
    putStrLn $ "  - " ++ T.unpack desc ++ ": " ++ show cnt
  T.putStrLn "----------------------------------------------------------"
  T.putStrLn "Top Reused Candidate Master Cards:"
  forM_ report.topReusedCards $ \(slug, cnt) ->
    putStrLn $ "  - " ++ T.unpack slug ++ ": " ++ show cnt ++ " occurrences"
  when verbose $ do
    T.putStrLn "----------------------------------------------------------"
    T.putStrLn "All Candidate Master Cards:"
    forM_ report.cardGroups $ \grp -> do
      let statusStr = case grp.rulesStatus of
            RulesCurrent -> "[CURRENT]"
            RulesOutdated -> "[OUTDATED]"
            RulesExperimental -> "[EXPERIMENTAL]"
          noteStr = maybe "" (\n -> " (" ++ T.unpack n ++ ")") grp.legacyNotes
      putStrLn $
        "  "
          ++ statusStr
          ++ " "
          ++ T.unpack grp.canonicalSlug
          ++ " ("
          ++ show (length grp.occurrences)
          ++ "x)"
          ++ noteStr
  T.putStrLn "=========================================================="
