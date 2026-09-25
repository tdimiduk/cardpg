{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Design.Frontmatter
  ( extractFrontmatterText
  , parseFrontmatter
  , validateFrontmatterSchema
  , extractFirstParagraph
  , scaffoldFrontmatter
  ) where

import Data.Aeson
import Data.Aeson.Key qualified as Key
import Data.Aeson.KeyMap qualified as KM
import Data.Char (isSpace, toUpper)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Yaml qualified as Yaml
import Design.Types
import System.FilePath (splitDirectories, takeBaseName)

-- | Extract frontmatter YAML text and the markdown body
extractFrontmatterText :: Text -> Either String (Maybe (Text, Text))
extractFrontmatterText content =
  let allLines = T.lines content
   in case allLines of
        [] -> Right Nothing
        (firstLine : restLines)
          | T.strip firstLine /= "---" -> Right Nothing
          | otherwise ->
              let (fmLines, remaining) = break (\l -> T.strip l == "---") restLines
               in case remaining of
                    [] -> Left "Unterminated frontmatter (missing closing ---)"
                    (_ : bodyLines) ->
                      Right (Just (T.unlines fmLines, T.unlines bodyLines))

-- | Parse frontmatter YAML text into Frontmatter along with any schema errors
parseFrontmatter :: Text -> Either String (Frontmatter, [String])
parseFrontmatter fmLang =
  case Yaml.decodeEither' (TE.encodeUtf8 fmLang) of
    Left parseErr -> Left $ "YAML parse error: " ++ show parseErr
    Right (Object obj) ->
      let raw = Map.fromList [(Key.toText k, v) | (k, v) <- KM.toList obj]
          mTitle = case KM.lookup "title" obj of
            Just (String t) -> Just t
            _ -> Nothing
          mDocType = case KM.lookup "doc_type" obj of
            Just (String dt) -> Just dt
            _ -> Nothing

          mTrackVal = case KM.lookup "track" obj of
            Just (String trk) -> Just trk
            _ -> Nothing
          mTrack = case mTrackVal of
            Just trk -> case parseTrack trk of
              Right t -> Just t
              Left _ -> Nothing
            Nothing -> Nothing

          mOrigin = case KM.lookup "origin" obj of
            Just (String orig) -> Just orig
            _ -> Nothing

          (mEpistemic, hasObsolete, epErrors) = case KM.lookup "epistemic_status" obj of
            Nothing -> (Nothing, False, ["Missing required field: 'epistemic_status'"])
            Just (Object epObj) ->
              let hasObs = KM.member "status" epObj
                  obsErr =
                    [ "Obsolete field 'status' found in 'epistemic_status'. "
                        ++ "The lifecycle status classification has been removed."
                    | hasObs
                    ]
                  confErr = case KM.lookup "confidence" epObj of
                    Nothing -> ["Missing required field 'confidence' in 'epistemic_status'"]
                    Just (String c) ->
                      [ "Invalid 'confidence': '"
                          ++ T.unpack c
                          ++ "' (must be one of: [\"high\", \"medium\", \"medium-low\", \"speculative\"])"
                      | not (c `Set.member` validConfidenceTiers)
                      ]
                    Just _ -> ["Field 'confidence' must be a string"]
                  vettedErr = case KM.lookup "vetted_by_human" epObj of
                    Nothing -> ["Missing required field 'vetted_by_human' in 'epistemic_status'"]
                    Just (Bool _) -> []
                    Just (String s)
                      | not (T.null (T.strip s)) -> []
                      | otherwise -> ["'vetted_by_human' must be a boolean or non-empty string identifier"]
                    Just _ -> ["'vetted_by_human' must be a boolean or non-empty string identifier"]
                  mEp = case (KM.lookup "confidence" epObj, KM.lookup "vetted_by_human" epObj) of
                    (Just (String c), Just (Bool b))
                      | Right conf <- parseConfidence c -> Just (EpistemicStatus conf (VettedBool b))
                    (Just (String c), Just (String v))
                      | Right conf <- parseConfidence c
                      , not (T.null (T.strip v)) ->
                          Just (EpistemicStatus conf (VettedBy (T.strip v)))
                    _ -> Nothing
               in (mEp, hasObs, obsErr ++ confErr ++ vettedErr)
            Just _ -> (Nothing, False, ["Field 'epistemic_status' must be a dictionary"])

          (mRelatedFiles, rfErrors) = case KM.lookup "related_files" obj of
            Nothing -> (Nothing, [])
            Just (Array arr) ->
              let parsePaths [] = ([], [])
                  parsePaths (String p : rest) =
                    let (ps, subErrs) = parsePaths rest in (T.unpack p : ps, subErrs)
                  parsePaths (_ : rest) =
                    let (ps, subErrs) = parsePaths rest
                     in (ps, "'related_files' entries must be string paths" : subErrs)
                  (paths, collectedErrs) = parsePaths (foldr (:) [] arr)
               in (Just paths, collectedErrs)
            Just _ -> (Nothing, ["'related_files' must be a list of paths"])

          mPurpose = case KM.lookup "purpose" obj of
            Just (String p) -> Just p
            _ -> Nothing
          mDescription = case KM.lookup "description" obj of
            Just (String d) -> Just d
            _ -> Nothing

          tagsList = case KM.lookup "tags" obj of
            Just (Array arr) -> [t | String t <- foldr (:) [] arr]
            _ -> []

          titleErrors = case mTitle of
            Nothing -> ["Missing required field: 'title'"]
            Just t | T.null (T.strip t) -> ["Field 'title' cannot be empty"]
            _ -> []

          docTypeErrors = case mDocType of
            Nothing -> ["Missing required field: 'doc_type'"]
            Just dt | T.null (T.strip dt) -> ["Field 'doc_type' cannot be empty"]
            _ -> []

          trackErrors = case mTrackVal of
            Nothing -> ["Missing required field: 'track'"]
            Just trk
              | not (trk `Set.member` validTracks) ->
                  ["Invalid 'track': '" ++ T.unpack trk ++ "' (must be one of: [\"ludology\", \"verisimilitude\"])"]
            _ -> []

          originErrors = case mOrigin of
            Nothing -> ["Missing required field: 'origin'"]
            Just o | T.null (T.strip o) -> ["Field 'origin' cannot be empty"]
            _ -> []

          allErrors =
            titleErrors
              ++ docTypeErrors
              ++ trackErrors
              ++ originErrors
              ++ epErrors
              ++ rfErrors

          fm =
            Frontmatter
              { title = fromMaybe "" mTitle
              , docType = fromMaybe "" mDocType
              , track = mTrack
              , origin = mOrigin
              , epistemicStatus = mEpistemic
              , relatedFiles = mRelatedFiles
              , purpose = mPurpose
              , description = mDescription
              , tags = tagsList
              , hasObsoleteStatus = hasObsolete
              , rawMap = raw
              }
       in Right (fm, allErrors)
    Right _ -> Left "Frontmatter must parse into a YAML mapping / dictionary"

-- | Validate an already constructed Frontmatter record
validateFrontmatterSchema :: Frontmatter -> [String]
validateFrontmatterSchema fm =
  let titleErrors =
        [ "Missing required field: 'title'" | T.null fm.title
        ]
      docTypeErrors =
        [ "Missing required field: 'doc_type'" | T.null fm.docType
        ]
      trackErrors =
        case fm.track of
          Nothing -> ["Missing required field: 'track'"]
          Just _ -> []
      originErrors =
        case fm.origin of
          Nothing -> ["Missing required field: 'origin'"]
          Just o | T.null (T.strip o) -> ["Field 'origin' cannot be empty"]
          Just _ -> []
      epErrors =
        case fm.epistemicStatus of
          Nothing -> ["Missing required field: 'epistemic_status'"]
          Just _ -> []
      obsoleteErrors =
        [ "Obsolete field 'status' found in 'epistemic_status'. "
            ++ "The lifecycle status classification has been removed."
        | fm.hasObsoleteStatus
        ]
   in titleErrors ++ docTypeErrors ++ trackErrors ++ originErrors ++ epErrors ++ obsoleteErrors

-- | Extract first prose paragraph from markdown content
extractFirstParagraph :: Text -> Text
extractFirstParagraph content =
  let body = case extractFrontmatterText content of
        Right (Just (_, b)) -> b
        _ -> content
      linesList = T.lines body
      isSpecialLine l =
        let s = T.strip l
         in T.isPrefixOf "#" s
              || T.isPrefixOf "|" s
              || T.isPrefixOf "```" s
              || T.isPrefixOf ">" s
              || T.isPrefixOf "**Context Date:" s
              || T.isPrefixOf "**Related Design Brief:" s
      gather [] acc = acc
      gather (l : ls) acc
        | T.null (T.strip l) = if null acc then gather ls [] else acc
        | isSpecialLine l = if null acc then gather ls [] else acc
        | otherwise = gather ls (acc ++ [T.strip l])
      para = T.unwords (gather linesList [])
   in if T.null para
        then ""
        else truncateClean para
  where
    truncateClean :: Text -> Text
    truncateClean txt
      | T.length txt <= 200 = txt
      | otherwise =
          let searchSpan = T.drop 60 (T.take 250 txt)
           in case T.breakOn ". " searchSpan of
                (beforeDot, afterDot)
                  | not (T.null afterDot) ->
                      T.take 60 txt <> beforeDot <> "."
                _ -> T.take 197 txt <> "..."

-- | Scaffold default frontmatter for unindexed markdown files
scaffoldFrontmatter :: FilePath -> Text -> (Frontmatter, Text)
scaffoldFrontmatter relPath content =
  let titleFromHeading =
        listToMaybe
          [ T.strip (T.drop 2 l)
          | l <- T.lines content
          , T.isPrefixOf "# " (T.strip l)
          ]
      derivedTitle = case titleFromHeading of
        Just t | not (T.null t) -> t
        _ -> humanizeTitle (takeBaseName relPath)

      dirs = splitDirectories relPath
      (docType, track) = case dirs of
        ("research" : "synthesis" : _) -> ("synthesis", Verisimilitude)
        ("research" : "theory" : "readings" : _) -> ("literature-note", Ludology)
        ("research" : "reports" : _) -> ("report", Verisimilitude)
        ("rules" : _) -> ("rules", Ludology)
        ("iteration" : _) -> ("iteration", Ludology)
        ("philosophy" : _) -> ("meta", Ludology)
        _ -> ("iteration", Ludology)

      fm =
        Frontmatter
          { title = derivedTitle
          , docType = docType
          , track = Just track
          , origin = Just "AI drafted"
          , epistemicStatus = Just (EpistemicStatus Medium (VettedBool False))
          , relatedFiles = Nothing
          , purpose = Nothing
          , description = Nothing
          , tags = []
          , hasObsoleteStatus = False
          , rawMap = Map.empty
          }

      fmYaml =
        T.unlines
          [ "---"
          , "title: \"" <> escapeYaml derivedTitle <> "\""
          , "doc_type: \"" <> docType <> "\""
          , "track: \"" <> trackToText track <> "\""
          , "origin: \"AI drafted\""
          , "epistemic_status:"
          , "  confidence: \"medium\""
          , "  vetted_by_human: false"
          , "---"
          ]
      fullNewContent = fmYaml <> "\n" <> T.dropWhile (\c -> c == '\n' || isSpace c) content
   in (fm, fullNewContent)
  where
    escapeYaml = T.replace "\"" "\\\""
    humanizeTitle s =
      let replaced = map (\c -> if c == '-' || c == '_' then ' ' else c) s
          wordsList = words replaced
          cap (c : cs) = toUpper c : cs
          cap [] = []
       in T.pack (unwords (map cap wordsList))
