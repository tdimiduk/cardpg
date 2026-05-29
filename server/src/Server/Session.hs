{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Server.Session where

import Data.Map qualified as Map
import Data.Text qualified as T
import Data.Text.IO qualified as T
import System.Random (StdGen, mkStdGen, newStdGen)

import Core.Card (ConsequenceCard (..), CoreCard (..))
import Core.NonEmptyText (getRawText)
import Core.State (GameEnv (..))
import Server.Config (Config (..))
import Server.DB (loadGame, saveGame)
import Server.Scenario (loadSavedGame, loadScenario)
import Server.Types (CardLibrary (..), GameState (..), StorageBackend)

-- | Initialize a game session, either by loading from DB or creating a new one from scenario.
-- If `forceReset` is True, it will ignore DB state and load from scenario/saved-game.
initGame :: StorageBackend -> Config -> CardLibrary -> Bool -> IO (GameState, StdGen)
initGame backend config lib forceReset = do
  let defaultGameId = "default-game"

  maybeLoaded <-
    if forceReset
      then return Nothing
      else loadGame backend defaultGameId

  let hydrate gs =
        let env = gs.env
            statusMap = Map.fromList [(getRawText name, c) | c@CoreCard{name} <- lib.statuses]
            consequenceMap = Map.fromList [(getRawText name, c) | c@ConsequenceCard{name} <- lib.consequences]
            newEnv = env{statusCardTemplates = statusMap, consequenceCardTemplates = consequenceMap}
         in gs{env = newEnv}

  case maybeLoaded of
    Just loadedGs -> do
      T.putStrLn "Loaded persisted game state."
      rng <- case config.seed of
        Just s -> return $ mkStdGen s
        Nothing -> newStdGen
      return (hydrate loadedGs, rng)
    Nothing -> do
      (initialGs, rng) <- case config.savedGameFile of
        Just file -> do
          T.putStrLn $ "Loading saved game state from " <> T.pack file <> "..."
          gs <- loadSavedGame file
          r <- case config.seed of
            Just s -> return $ mkStdGen s
            Nothing -> newStdGen
          return (gs, r)
        Nothing -> do
          T.putStrLn $ "Loading starter scenario from " <> T.pack config.scenarioFile <> "..."
          loadScenario config.scenarioFile config.seed

      let newGs = hydrate initialGs

      -- Persist key initial state
      saveGame backend defaultGameId newGs
      return (newGs, rng)
