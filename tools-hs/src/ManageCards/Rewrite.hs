{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module ManageCards.Rewrite
  ( rewriteActorFile
  , rewriteActorDefinition
  , computeStatOverrides
  , findMatchingMasterCard
  , loadCatalog
  ) where

import Control.Monad (forM)
import Data.ByteString qualified as BS
import Data.List (find)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Yaml (ParseException, decodeEither', decodeFileEither, encode)
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath (takeExtension, (</>))

import Core.Card
  ( ActorDefinition (..)
  , CardReference (..)
  , CoreCard (..)
  , DeckEntry (..)
  , MasterCard (..)
  , Stats (..)
  )
import Core.NonEmptyText (getRawText)
import ManageCards.Types (RewriteResult (..))

-- | Recursively walk a directory to collect all files.
walkDir :: FilePath -> IO [FilePath]
walkDir dir = do
  isDir <- doesDirectoryExist dir
  if not isDir
    then pure []
    else do
      entries <- listDirectory dir
      paths <- forM entries $ \e -> do
        let p = dir </> e
        d <- doesDirectoryExist p
        if d then walkDir p else pure [p]
      pure (concat paths)

-- | Recursively load a master card catalog from a directory.
loadCatalog :: FilePath -> IO (Either String (Map Text MasterCard))
loadCatalog dir = do
  exists <- doesDirectoryExist dir
  if not exists
    then pure $ Left $ "Catalog directory does not exist: " ++ dir
    else do
      files <- walkDir dir
      let yamlFiles = filter (\f -> takeExtension f `elem` [".yaml", ".yml"]) files
      cardsList <- mapM parseFile yamlFiles
      let allCards = concat cardsList
      if null allCards
        then pure $ Left $ "No master cards found in catalog directory: " ++ dir
        else pure $ Right $ Map.fromList [(c.id, c) | c <- allCards]
  where
    parseFile path = do
      content <- BS.readFile path
      case decodeEither' content of
        Right (list :: [MasterCard]) -> pure list
        Left _ -> case decodeEither' content of
          Right (single :: MasterCard) -> pure [single]
          Left _ -> pure []

-- | Compute partial stat overrides for a CardReference.
computeStatOverrides :: Stats Int -> Stats Int -> Maybe (Stats (Maybe Int))
computeStatOverrides actual base
  | actual == base = Nothing
  | otherwise =
      let diffRed = if actual.red /= base.red then Just actual.red else Nothing
          diffYellow = if actual.yellow /= base.yellow then Just actual.yellow else Nothing
          diffBlue = if actual.blue /= base.blue then Just actual.blue else Nothing
       in Just (Stats diffRed diffYellow diffBlue)

-- | Find a matching MasterCard from catalog for an inline CoreCard.
findMatchingMasterCard :: Map Text MasterCard -> CoreCard -> Maybe MasterCard
findMatchingMasterCard catalog card =
  let CoreCard
        { name = cName
        , attack = cAttack
        , rules = cRules
        , cost = cCost
        , flavor = cFlavor
        , stats = cStats
        } = card
      candidates =
        [ mc
        | mc <- Map.elems catalog
        , getRawText mc.card.name == getRawText cName
        , mc.card.attack == cAttack
        , mc.card.rules == cRules
        , mc.card.cost == cCost
        , mc.card.flavor == cFlavor
        ]
   in case candidates of
        [] -> Nothing
        (firstMatch : _) ->
          -- Prioritize exact stat match to avoid unnecessary overrides
          case find (\m -> m.card.stats == cStats) candidates of
            Just exact -> Just exact
            Nothing -> Just firstMatch

-- | Rewrite an ActorDefinition's deck against a catalog.
rewriteActorDefinition
  :: Map Text MasterCard
  -> ActorDefinition
  -> (ActorDefinition, RewriteResult)
rewriteActorDefinition catalog actor =
  let (newDeck, res) = foldr step ([], RewriteResult 0 0 0 0 False) actor.deck
   in (actor{deck = newDeck}, res)
  where
    step (EntryRef ref) (acc, r) =
      ( EntryRef ref : acc
      , r
          { totalEntries = r.totalEntries + 1
          , preservedRefEntries = r.preservedRefEntries + 1
          }
      )
    step (EntryInline c) (acc, r) =
      case findMatchingMasterCard catalog c of
        Nothing ->
          ( EntryInline c : acc
          , r
              { totalEntries = r.totalEntries + 1
              , retainedInlineEntries = r.retainedInlineEntries + 1
              }
          )
        Just mc ->
          let CoreCard{stats = cStats} = c
              ref =
                CardReference
                  { card = mc.id
                  , stats = computeStatOverrides cStats mc.card.stats
                  , upgrades = Nothing
                  , milestone = Nothing
                  }
           in ( EntryRef ref : acc
              , r
                  { totalEntries = r.totalEntries + 1
                  , replacedEntries = r.replacedEntries + 1
                  , modified = True
                  }
              )

-- | Rewrite a specific actor file on disk.
rewriteActorFile
  :: Map Text MasterCard
  -> FilePath
  -> Bool
  -> IO (Either String RewriteResult)
rewriteActorFile catalog actorPath dryRun = do
  decoded <- decodeFileEither actorPath :: IO (Either ParseException ActorDefinition)
  case decoded of
    Left err -> pure $ Left $ "Failed to parse actor file " ++ actorPath ++ ": " ++ show err
    Right actor -> do
      let (updatedActor, result) = rewriteActorDefinition catalog actor
      if result.modified && not dryRun
        then do
          let encoded = encode updatedActor
          BS.writeFile actorPath encoded
          pure $ Right result
        else pure $ Right result
