{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ManageCards.Export
  ( exportMasterCatalog
  , cardGroupToMasterCard
  ) where

import Control.Monad (forM, unless)
import Data.ByteString qualified as BS
import Data.List (sortOn)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Yaml (encode)
import System.Directory (createDirectoryIfMissing)
import System.FilePath (takeDirectory, (</>))

import Core.Card (CoreCard (..), MasterCard (..))
import ManageCards.Types
  ( CardCategory (..)
  , CardGroup (..)
  , categoryFilePath
  )

-- | Convert a CardGroup into a canonical MasterCard ready for database export.
cardGroupToMasterCard :: CardGroup -> MasterCard
cardGroupToMasterCard grp =
  let CoreCard
        { name = cName
        , tags = cTags
        , stats = cStats
        , cost = cCost
        , attack = cAttack
        , rules = cRules
        , flavor = cFlavor
        } = grp.baseCard
      finalTags = case cTags of
        Just ts -> Just ts
        Nothing -> Just (NE.singleton (categoryTag grp.category))
   in MasterCard
        { id = grp.canonicalSlug
        , name = cName
        , tags = finalTags
        , stats = cStats
        , cost = cCost
        , attack = cAttack
        , rules = cRules
        , flavor = cFlavor
        , rulesStatus = Just grp.rulesStatus
        , legacyNotes = grp.legacyNotes
        , milestones = Nothing
        }
  where
    categoryTag CategoryCore = "Core"
    categoryTag CategoryMartial = "Martial"
    categoryTag CategoryArcane = "Arcane"
    categoryTag CategoryBeasts = "Beast"
    categoryTag CategoryHumanoids = "Monster"

-- | Export categorized master cards to YAML files under the given target directory.
exportMasterCatalog :: FilePath -> [CardGroup] -> Bool -> IO [(FilePath, Int)]
exportMasterCatalog outDir groups dryRun = do
  let byCategory =
        Map.fromListWith
          (++)
          [(grp.category, [grp]) | grp <- groups]
      categories =
        [ CategoryCore
        , CategoryMartial
        , CategoryArcane
        , CategoryBeasts
        , CategoryHumanoids
        ]
  results <- forM categories $ \cat -> do
    let catGroups = sortOn (\g -> g.canonicalSlug) (Map.findWithDefault [] cat byCategory)
        masterCards = map cardGroupToMasterCard catGroups
        relPath = categoryFilePath cat
        fullPath = outDir </> relPath
    if null masterCards
      then pure (relPath, 0)
      else do
        let encoded = encode masterCards
        unless dryRun $ do
          createDirectoryIfMissing True (takeDirectory fullPath)
          BS.writeFile fullPath encoded
        pure (relPath, length masterCards)
  pure (filter (\(_, n) -> n > 0) results)
