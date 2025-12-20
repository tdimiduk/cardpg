{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module CardPG.Server.Session where

import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Pool (Pool)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Database.PostgreSQL.Simple qualified as Pg
import System.Random (StdGen, newStdGen)

import CardPG.Core.Card (ConsequenceCard, ConsequenceCardT (..), CoreCard, CoreCardT (..))
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.State (GameEnv (..))
import CardPG.Server.Config (Config (..))
import CardPG.Server.DB (loadGame, saveGame)
import CardPG.Server.Scenario (loadScenario)
import CardPG.Server.Types (CardLibrary (..), GameState (..), StorageBackend)

-- | Initialize a game session, either by loading from DB or creating a new one from scenario.
-- If `forceReset` is True, it will ignore DB state and load from scenario.
initGame :: StorageBackend -> Config -> CardLibrary -> Bool -> IO (GameState, StdGen)
initGame backend config lib forceReset = do
  let defaultGameId = "default-game"

  maybeLoaded <-
    if forceReset
      then return Nothing
      else loadGame backend defaultGameId

  let hydrate gs =
        let env = gs.env
            statusMap = Map.fromList [(getRawText c.name, c) | c <- lib.statuses]
            consequenceMap = Map.fromList [(getRawText c.name, c) | c <- lib.consequences]
            newEnv = env{statusCardTemplates = statusMap, consequenceCardTemplates = consequenceMap}
         in gs{env = newEnv}

  case maybeLoaded of
    Just loadedGs -> do
      T.putStrLn "Loaded persisted game state."
      rng <- newStdGen
      return (hydrate loadedGs, rng)
    Nothing -> do
      T.putStrLn $ "Loading starter scenario from " <> T.pack config.scenarioFile <> "..."
      (initialGs, rng) <- loadScenario config.scenarioFile

      let newGs = hydrate initialGs

      -- Persist key initial state
      saveGame backend defaultGameId newGs
      return (newGs, rng)
