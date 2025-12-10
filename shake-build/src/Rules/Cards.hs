{-# LANGUAGE OverloadedStrings #-}

module Rules.Cards where

import Control.Monad (forM_)


import Data.Aeson (withObject, (.:), (.:?))
import qualified Data.Aeson.KeyMap as KM
import Data.Maybe (mapMaybe)
import qualified Data.Vector as V
import Data.Yaml (FromJSON (..), Value (..), decodeFileThrow, parseMaybe)
import Development.Shake
import Development.Shake.FilePath

data ManifestEntry = ManifestEntry
  { entryId :: String
  , entryType :: Maybe String
  , entryTags :: Maybe [String]
  , entryName :: String
  }
  deriving (Show)

instance FromJSON ManifestEntry where
  parseJSON = withObject "ManifestEntry" $ \v ->
    ManifestEntry
      <$> v .: "id"
      <*> v .:? "type"
      <*> v .:? "tags"
      <*> v .: "name"

-- Helper to extract entries recursively
extractCards :: Value -> [ManifestEntry]
extractCards (Object obj) = concatMap extractFromValue (KM.elems obj)
  where
    extractFromValue :: Value -> [ManifestEntry]
    extractFromValue (Array vec) = mapMaybe parseEntry (V.toList vec)
    extractFromValue (Object o) = extractCards (Object o) -- Recurse into sub-objects
    extractFromValue _ = []

    parseEntry :: Value -> Maybe ManifestEntry
    parseEntry v = case parseMaybe parseJSON v of
      Just e | entryType e == Just "Cards" -> Just e
      _ -> Nothing
extractCards _ = []

-- | Load manifest and return (PC Decks, Monster Decks)
getDecks :: IO ([ManifestEntry], [ManifestEntry])
getDecks = do
  manifestValue <- decodeFileThrow "design/manifest.yaml" :: IO Value
  let entries = extractCards manifestValue
  let pcDecks = filter (maybe False ("type:pc-deck" `elem`) . entryTags) entries
  let monsterDecks = filter (maybe False ("type:monster-deck" `elem`) . entryTags) entries
  return (pcDecks, monsterDecks)

-- | Compile legacy cards (JSON -> YAML)
compileLegacyCards :: Action ()
compileLegacyCards = do
  (pcDecks, monsterDecks) <- liftIO getDecks
  need ["_build/bin/card-compiler"]
  
  forM_ pcDecks $ \deck -> do
    let deckId = entryId deck
    let jsonSrc = "data/cards/raw" </> deckId <.> "json"
    let outDir = "data/cards/pc"
    cmd_ (["_build/bin/card-compiler", jsonSrc, outDir, "pc"] :: [String])

  forM_ monsterDecks $ \deck -> do
    let deckId = entryId deck
    let jsonSrc = "data/cards/raw" </> deckId <.> "json"
    let outDir = "data/cards/monsters"
    cmd_ (["_build/bin/card-compiler", jsonSrc, outDir, "monster"] :: [String])

-- | Compile card data
buildCardData :: Action ()
buildCardData = need ["vtt-react/src/data/generated_cards.json"]

-- | Run the python sync script
runSync :: Action ()
runSync = cmd_ (["python3", "tools/gsheet_sync/sync-cards-gsheet.py", "--all", "true"] :: [String])

-- | Define rule for VTT JSON generation
defineVttRule :: Rules ()
defineVttRule = do
  "vtt-react/src/data/generated_cards.json" %> \out -> do

    -- Now that compilation is done, dynamically find all generated YAML files
    pcYamls <- getDirectoryFiles "data/cards/pc" ["*.yaml"]
    monsterYamls <- getDirectoryFiles "data/cards/monsters" ["*.yaml"]
    statusYamls <- getDirectoryFiles "data/cards/status" ["*.yaml"]
    consequenceYamls <- getDirectoryFiles "data/cards/consequences" ["*.yaml"]

    let allYamls =
          map ("data/cards/pc" </>) pcYamls
            ++ map ("data/cards/monsters" </>) monsterYamls
            ++ map ("data/cards/status" </>) statusYamls
            ++ map ("data/cards/consequences" </>) consequenceYamls

    -- Track content of all YAMLs
    need allYamls

    need ["_build/bin/card-compiler"]
    cmd_ (["_build/bin/card-compiler", "export-vtt", out] ++ allYamls)
