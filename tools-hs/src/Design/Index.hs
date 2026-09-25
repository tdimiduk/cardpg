{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Design.Index
  ( extractHeaderComments
  , formatYamlWithHeader
  , loadIndexValue
  , saveIndexValue
  , IndexData (..)
  , loadAllIndexData
  , computeSubIndexTags
  , syncAggregatedTags
  , resolveIndexTarget
  , insertEntryIntoIndex
  ) where

import Control.Monad (forM)
import Data.Aeson
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KM
import Data.ByteString (ByteString)
import Data.ByteString qualified as BS
import Data.List (isPrefixOf, isSuffixOf, nub, sort)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Text.IO qualified as TIO
import Data.Vector qualified as V
import Data.Yaml qualified as Yaml
import Design.Types
import System.Directory (doesFileExist)
import System.FilePath (normalise, (</>))

-- | Extract leading comment header from YAML content
extractHeaderComments :: Text -> (Text, Text)
extractHeaderComments txt =
  let allLines = T.lines txt
      isHeader l =
        let s = T.stripStart l
         in "#" `T.isPrefixOf` s || T.null s
      (headerLines, restLines) = span isHeader allLines
   in (T.unlines headerLines, T.unlines restLines)

-- | Format a YAML Value with the given header comment prepended
formatYamlWithHeader :: Text -> Value -> ByteString
formatYamlWithHeader header val =
  let encoded = Yaml.encode val
      headerBytes = TE.encodeUtf8 header
   in if BS.null headerBytes
        then encoded
        else headerBytes <> encoded

-- | Load an index file as a (headerComments, Value) pair
loadIndexValue :: FilePath -> IO (Either String (Text, Value))
loadIndexValue path = do
  exists <- doesFileExist path
  if not exists
    then pure $ Left $ "Index file does not exist: " ++ path
    else do
      content <- TIO.readFile path
      let (header, yamlText) = extractHeaderComments content
      case Yaml.decodeEither' (TE.encodeUtf8 yamlText) of
        Left err -> pure $ Left $ "Failed to parse " ++ path ++ ": " ++ show err
        Right val -> pure $ Right (header, val)

-- | Save an index file preserving the header comments
saveIndexValue :: FilePath -> Text -> Value -> IO (Either String ())
saveIndexValue path header val = do
  let formatted = formatYamlWithHeader header val
  BS.writeFile path formatted
  pure $ Right ()

-- | Aggregate result of recursively traversing all indexes
data IndexData = IndexData
  { allFiles :: Set FilePath
  , entriesByPath :: Map FilePath IndexItem
  , missingIndexes :: [FilePath]
  }
  deriving stock (Show, Eq)

-- | Recursively load index.yaml and all referenced sub-indexes
loadAllIndexData :: FilePath -> FilePath -> IO IndexData
loadAllIndexData designRoot rootIndexPath = do
  (files, entries, missing) <- go Set.empty rootIndexPath
  pure
    IndexData
      { allFiles = files
      , entriesByPath = entries
      , missingIndexes = missing
      }
  where
    go :: Set FilePath -> FilePath -> IO (Set FilePath, Map FilePath IndexItem, [FilePath])
    go visited currentAbs
      | currentAbs `Set.member` visited = pure (Set.empty, Map.empty, [])
      | otherwise = do
          exists <- doesFileExist currentAbs
          if not exists
            then pure (Set.empty, Map.empty, [currentAbs])
            else do
              let visited' = Set.insert currentAbs visited
              res <- loadIndexValue currentAbs
              case res of
                Left _ -> pure (Set.empty, Map.empty, [])
                Right (_, val) -> do
                  let (localFiles, localEntries, subIndexes) = extractFromNode val
                  -- Recursively load referenced sub-indexes
                  recResults <- forM subIndexes $ \subRel -> do
                    let subAbs = designRoot </> subRel
                    go visited' subAbs
                  let allSubFiles = Set.unions [f | (f, _, _) <- recResults]
                      allSubEntries = Map.unions [e | (_, e, _) <- recResults]
                      allSubMissing = concat [m | (_, _, m) <- recResults]
                  pure
                    ( Set.union localFiles allSubFiles
                    , Map.union localEntries allSubEntries
                    , allSubMissing
                    )

    extractFromNode :: Value -> (Set FilePath, Map FilePath IndexItem, [FilePath])
    extractFromNode = walk Nothing
      where
        walk :: Maybe IndexItem -> Value -> (Set FilePath, Map FilePath IndexItem, [FilePath])
        walk parentItem (Object obj) =
          let currentItem = case fromJSON (Object obj) of
                Success item -> Just item
                _ -> parentItem

              (files, entries, subIdxs) = case currentItem of
                Just item ->
                  let pFiles = case item.path of
                        Just p
                          | item.sourceType /= Just "google_sheet" ->
                              let norm = normalisePath p
                                  isSub =
                                    item.itemType == Just "Index"
                                      || "index.yaml" `isSuffixOf` norm
                                      || "doc-type:index" `elem` item.tags
                               in (Set.singleton norm, Map.singleton norm item, [norm | isSub])
                        _ -> (Set.empty, Map.empty, [])
                      cFiles = case item.components of
                        Just compMap ->
                          let paths = [normalisePath cp | (_, cp) <- Map.toList compMap]
                           in ( Set.fromList paths
                              , Map.fromList [(p, item) | p <- paths]
                              , []
                              )
                        Nothing -> (Set.empty, Map.empty, [])
                   in (Set.union (fst3 pFiles) (fst3 cFiles), Map.union (snd3 pFiles) (snd3 cFiles), thd3 pFiles)
                Nothing -> (Set.empty, Map.empty, [])

              -- Recurse into child fields (excluding components)
              childrenResults =
                [ walk currentItem v
                | (k, v) <- KM.toList obj
                , k /= "components"
                ]
              childFiles = Set.unions [f | (f, _, _) <- childrenResults]
              childEntries = Map.unions [e | (_, e, _) <- childrenResults]
              childSubIdxs = concat [s | (_, _, s) <- childrenResults]
           in ( Set.unions [files, childFiles]
              , Map.unions [entries, childEntries]
              , subIdxs ++ childSubIdxs
              )
        walk parentItem (Array arr) =
          let childResults = map (walk parentItem) (V.toList arr)
           in ( Set.unions [f | (f, _, _) <- childResults]
              , Map.unions [e | (_, e, _) <- childResults]
              , concat [s | (_, _, s) <- childResults]
              )
        walk _ _ = (Set.empty, Map.empty, [])

    normalisePath :: FilePath -> FilePath
    normalisePath p = map (\c -> if c == '\\' then '/' else c) (normalise p)

    fst3 (a, _, _) = a
    snd3 (_, b, _) = b
    thd3 (_, _, c) = c

-- | Compute aggregated tags recursively across all entries in a sub-index
computeSubIndexTags :: FilePath -> FilePath -> IO [Text]
computeSubIndexTags designRoot subIndexRel = do
  let subIndexAbs = designRoot </> subIndexRel
  exists <- doesFileExist subIndexAbs
  if not exists
    then pure []
    else do
      res <- loadIndexValue subIndexAbs
      case res of
        Left _ -> pure []
        Right (_, val) -> do
          childTags <- collectTags val
          pure $ sort $ nub childTags
  where
    collectTags :: Value -> IO [Text]
    collectTags (Object obj) = do
      let directTags = case KM.lookup "tags" obj of
            Just (Array arr) -> [t | String t <- V.toList arr]
            _ -> []
          mPath = case KM.lookup "path" obj of
            Just (String p) -> Just (T.unpack p)
            _ -> Nothing
          mType = case KM.lookup "type" obj of
            Just (String t) -> Just (T.unpack t)
            _ -> Nothing
          isSubIndex =
            case mPath of
              Just p ->
                (mType == Just "Index" || "index.yaml" `isSuffixOf` p || "doc-type:index" `elem` directTags)
                  && p /= subIndexRel
              Nothing -> False

      subTags <- case mPath of
        Just p | isSubIndex -> computeSubIndexTags designRoot p
        _ -> pure []

      childrenTags <- forM (KM.toList obj) $ \(k, v) ->
        if k == "tags"
          then pure []
          else collectTags v

      pure $ directTags ++ subTags ++ concat childrenTags
    collectTags (Array arr) = do
      tagsList <- mapM collectTags (V.toList arr)
      pure $ concat tagsList
    collectTags _ = pure []

-- | Audit and optionally update aggregated_tags in root index.yaml
syncAggregatedTags :: FilePath -> FilePath -> Bool -> IO ([String], Bool)
syncAggregatedTags designRoot rootIndexPath fix = do
  res <- loadIndexValue rootIndexPath
  case res of
    Left err -> pure (["Failed to load root index for tag audit: " ++ err], False)
    Right (header, val) -> do
      case val of
        Object rootObj -> do
          case KM.lookup "sub_indexes" rootObj of
            Just (Array subArr) -> do
              updates <- forM (V.toList subArr) $ \itemVal -> do
                case itemVal of
                  Object itemObj -> do
                    case KM.lookup "path" itemObj of
                      Just (String p) -> do
                        let subRel = T.unpack p
                        actualTags <- computeSubIndexTags designRoot subRel
                        let existingTags = case KM.lookup "aggregated_tags" itemObj of
                              Just (Array arr) -> [t | String t <- V.toList arr]
                              _ -> []
                        if actualTags /= existingTags
                          then do
                            let msg = "Aggregated tags for '" ++ subRel ++ "' out of date"
                                updatedObj = KM.insert "aggregated_tags" (toJSON actualTags) itemObj
                            pure (Just (msg, Object updatedObj))
                          else pure Nothing
                      _ -> pure Nothing
                  _ -> pure Nothing

              let errors = [msg | Just (msg, _) <- updates]
                  hasChanges = not (null errors)
              if hasChanges && fix
                then do
                  let updatedSubArr =
                        V.fromList
                          [ case up of
                              Just (_, newObj) -> newObj
                              Nothing -> orig
                          | (orig, up) <- zip (V.toList subArr) updates
                          ]
                      updatedRoot = Object (KM.insert "sub_indexes" (Array updatedSubArr) rootObj)
                  _ <- saveIndexValue rootIndexPath header updatedRoot
                  pure ([], True)
                else pure (errors, False)
            _ -> pure ([], False)
        _ -> pure ([], False)

-- | Resolve which index file and section path an unindexed document should be inserted into
resolveIndexTarget :: FilePath -> Text -> (FilePath, [Text])
resolveIndexTarget relPath _docType =
  let p = normaliseRel relPath
   in if
        | "research/" `isPrefixOf` p ->
            if
              | "research/synthesis/" `isPrefixOf` p ->
                  ("research/index.yaml", ["design_process_and_research", "research_synthesis"])
              | "research/theory/readings/" `isPrefixOf` p ->
                  ("research/index.yaml", ["design_process_and_research", "design_theory_and_readings"])
              | "research/reports/" `isPrefixOf` p ->
                  ("research/index.yaml", ["design_process_and_research", "research_reports"])
              | otherwise ->
                  ("research/index.yaml", ["design_process_and_research", "research_synthesis"])
        | "iteration/" `isPrefixOf` p ->
            ("iteration/index.yaml", ["active_design_exploration", "ideation_and_sketches"])
        | "archive/" `isPrefixOf` p ->
            ("archive/index.yaml", ["archive_and_legacy_materials", "orientation"])
        | "rules/" `isPrefixOf` p ->
            if "rules/modules/" `isPrefixOf` p
              then ("index.yaml", ["game_system_and_rules", "modules"])
              else ("index.yaml", ["game_system_and_rules", "core_rules_and_guides"])
        | "philosophy/" `isPrefixOf` p ->
            ("index.yaml", ["project_foundation", "philosophy"])
        | "methodology/" `isPrefixOf` p ->
            ("index.yaml", ["project_foundation", "methodology"])
        | otherwise ->
            ("index.yaml", ["game_system_and_rules", "core_rules_and_guides"])
  where
    normaliseRel = map (\c -> if c == '\\' then '/' else c)

-- | Insert a new IndexItem into the target index file at the given section path
insertEntryIntoIndex :: FilePath -> [Text] -> IndexItem -> IO (Either String ())
insertEntryIntoIndex targetAbsPath sectionKeys entry = do
  loadRes <- loadIndexValue targetAbsPath
  case loadRes of
    Left err -> pure $ Left err
    Right (header, val) -> do
      case insertIntoValue sectionKeys (toJSON entry) val of
        Left err -> pure $ Left err
        Right updatedVal ->
          saveIndexValue targetAbsPath header updatedVal
  where
    insertIntoValue :: [Text] -> Value -> Value -> Either String Value
    insertIntoValue [] _ _ = Left "Empty section key path"
    insertIntoValue [k] entryVal (Object obj) =
      let currentList = case KM.lookup (Key.fromText k) obj of
            Just (Array arr) -> V.toList arr
            _ -> []
          updatedList = currentList ++ [entryVal]
          updatedObj = KM.insert (Key.fromText k) (Array (V.fromList updatedList)) obj
       in Right (Object updatedObj)
    insertIntoValue (k : ks) entryVal (Object obj) =
      let subNode = fromMaybe (Object KM.empty) (KM.lookup (Key.fromText k) obj)
       in case insertIntoValue ks entryVal subNode of
            Left err -> Left err
            Right updatedSub ->
              Right (Object (KM.insert (Key.fromText k) updatedSub obj))
    insertIntoValue _ _ _ = Left "Target node in index is not a YAML object"
