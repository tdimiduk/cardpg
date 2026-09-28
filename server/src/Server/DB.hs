{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FieldSelectors #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Server.DB
  ( module Server.DB.Schema
  , initDB
  , withGargoyleDB
  , initInMemoryDB
  , saveGame
  , loadGame
  , loadGameRecord
  , listGames
  , saveGameEvents
  , loadGameEvents
  , saveCustomCard
  , gameEventTypeName
  ) where

import Control.Monad (unless)
import Data.Aeson (Result (..), Value (..), fromJSON, toJSON)
import Data.IORef (modifyIORef', newIORef, readIORef)
import Data.Int (Int32)
import Data.Map qualified as Map
import Data.Maybe (mapMaybe)
import Data.Pool (defaultPoolConfig, newPool, withResource)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding (encodeUtf8)
import Data.Time (getCurrentTime)
import Data.UUID qualified as UUID
import Database.Beam
import Database.Beam.AutoMigrate qualified as BA
import Database.Beam.Postgres
import Database.Beam.Postgres.Full (conflictingFields, insertOnConflict, onConflictUpdateSet)
import Database.PostgreSQL.Simple qualified as Pg

import Api.Types (ActorGameEvent (..), LogEntry (..), LogPayload (..), LogSender (..))
import Core.Card (CustomCard, customCardCategoryText, customCardIdText, customCardNameText)
import Core.Primitives (ActorId (..))
import Core.State (ActorState (..), GameEvent (..))
import Server.Config (DBConfig (..))
import Server.DB.Schema
import Server.Types (GameState (..), InMemoryStorage (..), StorageBackend (..))

import Gargoyle.PostgreSQL.Connect (withDb)

-- | Helper Functions
initDB :: DBConfig -> IO StorageBackend
initDB cfg = do
  let passStr = if null cfg.dbPass then "" else " password=" <> cfg.dbPass
      connStr =
        "host="
          <> cfg.dbHost
          <> " user="
          <> cfg.dbUser
          <> passStr
          <> " dbname="
          <> cfg.dbName
  pool <- newPool $ defaultPoolConfig (connectPostgreSQL (encodeUtf8 $ T.pack connStr)) close 10 10
  withResource pool $ \conn ->
    Pg.withTransaction conn $
      BA.tryRunMigrationsWithEditUpdate annotatedDb conn
  pure $ PostgresBackend pool

withGargoyleDB :: FilePath -> (StorageBackend -> IO a) -> IO a
withGargoyleDB dbPath f = withDb dbPath $ \pool -> do
  withResource pool $ \conn ->
    Pg.withTransaction conn $
      BA.tryRunMigrationsWithEditUpdate annotatedDb conn
  f $ PostgresBackend pool

initInMemoryDB :: IO StorageBackend
initInMemoryDB = InMemoryBackend <$> newIORef (InMemoryStorage Map.empty Map.empty)

saveGame :: StorageBackend -> Text -> Text -> GameState -> IO ()
saveGame (InMemoryBackend ref) gId scenario gs = do
  now <- getCurrentTime
  let actNames = [a.name | a <- Map.elems gs.actors]
  modifyIORef' ref $ \st ->
    let existingStartedAt = case Map.lookup gId st.inMemoryGames of
          Just (_, g) -> g.gameStartedAt
          Nothing -> now
        gameRecord =
          Game
            { gameId = gId
            , scenarioName = scenario
            , gameStatus = "Active"
            , actorNames = PgJSONB actNames
            , currentRound = fromIntegral gs.roundNumber
            , gameState = PgJSONB (toJSON gs)
            , gameStartedAt = existingStartedAt
            , gameUpdatedAt = now
            }
     in st{inMemoryGames = Map.insert gId (gs, gameRecord) st.inMemoryGames}
saveGame (PostgresBackend pool) gId scenario gs = do
  now <- getCurrentTime
  let actNames = [a.name | a <- Map.elems gs.actors]
      gameRecord =
        Game
          { gameId = gId
          , scenarioName = scenario
          , gameStatus = "Active"
          , actorNames = PgJSONB actNames
          , currentRound = fromIntegral gs.roundNumber
          , gameState = PgJSONB (toJSON gs)
          , gameStartedAt = now
          , gameUpdatedAt = now
          }

  withResource pool $ \conn -> do
    runBeamPostgres conn $
      runInsert $
        insertOnConflict
          (games cardpgDb)
          (insertValues [gameRecord])
          (conflictingFields (\g -> g.gameId))
          ( onConflictUpdateSet $ \fields excluded ->
              mconcat
                [ fields.gameState <-. excluded.gameState
                , fields.gameStatus <-. excluded.gameStatus
                , fields.actorNames <-. excluded.actorNames
                , fields.currentRound <-. excluded.currentRound
                , fields.gameUpdatedAt <-. excluded.gameUpdatedAt
                ]
          )

loadGame :: StorageBackend -> Text -> IO (Maybe GameState)
loadGame (InMemoryBackend ref) gId = do
  st <- readIORef ref
  return $ fmap fst (Map.lookup gId st.inMemoryGames)
loadGame (PostgresBackend pool) gId = do
  withResource pool $ \conn -> do
    res <-
      runBeamPostgres conn $
        runSelectReturningOne $
          select $
            filter_ (\g -> g.gameId ==. val_ gId) (all_ (games cardpgDb))
    case res of
      Nothing -> return Nothing
      Just g -> do
        let (PgJSONB val) = g.gameState
        case fromJSON val of
          Error e -> do
            putStrLn $ "Failed to decode game state: " ++ e
            return Nothing
          Success s -> return (Just s)

loadGameRecord :: StorageBackend -> Text -> IO (Maybe Game)
loadGameRecord (InMemoryBackend ref) gId = do
  st <- readIORef ref
  return $ fmap snd (Map.lookup gId st.inMemoryGames)
loadGameRecord (PostgresBackend pool) gId = do
  withResource pool $ \conn -> do
    runBeamPostgres conn $
      runSelectReturningOne $
        select $
          filter_ (\g -> g.gameId ==. val_ gId) (all_ (games cardpgDb))

listGames :: StorageBackend -> IO [Game]
listGames (InMemoryBackend ref) = do
  st <- readIORef ref
  return $ Map.elems (fmap snd st.inMemoryGames)
listGames (PostgresBackend pool) = do
  withResource pool $ \conn -> do
    runBeamPostgres conn $
      runSelectReturningList $
        select $
          all_ (games cardpgDb)

gameEventTypeName :: GameEvent -> Text
gameEventTypeName = \case
  CardsCreated{} -> "CardsCreated"
  DeckShuffled{} -> "DeckShuffled"
  CardDrawn{} -> "CardDrawn"
  CardDefended{} -> "CardDefended"
  MovePlanned{} -> "MovePlanned"
  ActorMoved{} -> "ActorMoved"
  RankMovePlanned{} -> "RankMovePlanned"
  ActorRankMoved{} -> "ActorRankMoved"
  ActionPlanned{} -> "ActionPlanned"
  PlanCanceled{} -> "PlanCanceled"
  ActionRevealed{} -> "ActionRevealed"
  DefenseEnded{} -> "DefenseEnded"
  IllegalAction{} -> "IllegalAction"
  StatusAdded{} -> "StatusAdded"
  StatusRemoved{} -> "StatusRemoved"
  ConsequenceAdded{} -> "ConsequenceAdded"
  ConsequenceRemoved{} -> "ConsequenceRemoved"
  RoundStarted{} -> "RoundStarted"

logPayloadToEvent :: LogEntry -> Maybe (Maybe Text, Text, Value)
logPayloadToEvent logEntry =
  let mAid = case logEntry.sender of
        SenderActor (ActorId u) _ -> Just (UUID.toText u)
        _ -> Nothing
   in case logEntry.payload of
        LogChallenge{} -> Just (mAid, "LogChallenge", toJSON logEntry.payload)
        LogChat{} -> Just (mAid, "LogChat", toJSON logEntry.payload)
        LogInfo{} -> Just (mAid, "LogInfo", toJSON logEntry.payload)
        LogError{} -> Just (mAid, "LogError", toJSON logEntry.payload)
        _ -> Nothing

saveGameEvents :: StorageBackend -> Text -> Int -> [ActorGameEvent] -> [LogEntry] -> IO ()
saveGameEvents (InMemoryBackend ref) gId rNum events logs = do
  now <- getCurrentTime
  let actorRows =
        [ ( fmap (\(ActorId u) -> UUID.toText u) aid
          , gameEventTypeName evt
          , toJSON evt
          )
        | ActorGameEvent aid evt <- events
        ]
      logRows = mapMaybe logPayloadToEvent logs
      allRows = actorRows ++ logRows

  unless (null allRows) $ do
    let rNum32 = fromIntegral rNum :: Int32
    modifyIORef' ref $ \st ->
      let existing = Map.findWithDefault [] gId st.inMemoryEvents
          startId = fromIntegral (length existing) :: Int32
          newRecords =
            [ GameEventRecord
                (SqlSerial (startId + idx))
                gId
                rNum32
                now
                mAid
                eType
                (PgJSONB val)
            | (idx, (mAid, eType, val)) <- zip [1 ..] allRows
            ]
       in st{inMemoryEvents = Map.insert gId (existing ++ newRecords) st.inMemoryEvents}
saveGameEvents (PostgresBackend pool) gId rNum events logs = do
  now <- getCurrentTime
  let actorRows =
        [ ( fmap (\(ActorId u) -> UUID.toText u) aid
          , gameEventTypeName evt
          , toJSON evt
          )
        | ActorGameEvent aid evt <- events
        ]
      logRows = mapMaybe logPayloadToEvent logs
      allRows = actorRows ++ logRows

  unless (null allRows) $ do
    let rNum32 = fromIntegral rNum :: Int32
    withResource pool $ \conn -> do
      runBeamPostgres conn $
        runInsert $
          insert (gameEvents cardpgDb) $
            insertExpressions
              [ GameEventRecord
                  default_
                  (val_ gId)
                  (val_ rNum32)
                  (val_ now)
                  (val_ mAid)
                  (val_ eType)
                  (val_ (PgJSONB val))
              | (mAid, eType, val) <- allRows
              ]

loadGameEvents :: StorageBackend -> Text -> IO [GameEventRecord]
loadGameEvents (InMemoryBackend ref) gId = do
  st <- readIORef ref
  return $ Map.findWithDefault [] gId st.inMemoryEvents
loadGameEvents (PostgresBackend pool) gId = do
  withResource pool $ \conn -> do
    runBeamPostgres conn $
      runSelectReturningList $
        select $
          orderBy_ (\e -> asc_ e.eventId) $
            filter_ (\e -> e.gameId ==. val_ gId) (all_ (gameEvents cardpgDb))

saveCustomCard :: StorageBackend -> CustomCard -> Text -> Text -> IO (Either Text ())
saveCustomCard (InMemoryBackend _) _ _ _ = do
  return $ Right ()
saveCustomCard (PostgresBackend pool) card sourceFile author = do
  now <- getCurrentTime
  let cId = customCardIdText card
      category = customCardCategoryText card
      name = customCardNameText card
      dbRecord = CustomCard cId category name (PgJSONB (toJSON card)) sourceFile author now

  withResource pool $ \conn -> do
    runBeamPostgres conn $
      runInsert $
        insertOnConflict
          (customCards cardpgDb)
          (insertValues [dbRecord])
          (conflictingFields (\c -> c.customCardId))
          ( onConflictUpdateSet $ \fields excluded ->
              mconcat
                [ fields.customCardCategory <-. excluded.customCardCategory
                , fields.customCardName <-. excluded.customCardName
                , fields.customCardData <-. excluded.customCardData
                , fields.customCardSourceFile <-. excluded.customCardSourceFile
                , fields.customCardAuthor <-. excluded.customCardAuthor
                , fields.customCardUpdatedAt <-. excluded.customCardUpdatedAt
                ]
          )

    return $ Right ()
