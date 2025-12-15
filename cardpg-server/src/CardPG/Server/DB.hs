{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE FieldSelectors #-}

module CardPG.Server.DB where

import Data.Text (Text)
import Data.Time (UTCTime, getCurrentTime)
import Database.Beam
import Database.Beam.Postgres
import Database.Beam.Migrate 
import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON, Value(..), toJSON, fromJSON, Result(..))
import Database.Beam.Backend.SQL.SQL92 (IsSql92DataTypeSyntax(..))
import Data.Pool (Pool, withResource)
import qualified Database.PostgreSQL.Simple as Pg
import Data.Text.Encoding (encodeUtf8)

import CardPG.Server.Types (GameState)

-- | The Game Table
data GameT f = Game
  { gameId :: C f Text
  , gameStatus :: C f Text -- "Active", "Finished", etc.
  , gameState :: C f (PgJSONB Value) -- Store full JSON blob for now
  , gameUpdatedAt :: C f UTCTime
  }
  deriving (Generic, Beamable)

type Game = GameT Identity
type GameId = PrimaryKey GameT Identity

instance Table GameT where
  data PrimaryKey GameT f = GameId (C f Text)
    deriving (Generic, Beamable)
  primaryKey (Game gId _ _ _) = GameId gId

-- | The Database
data CardPGDB f = CardPGDB
  { games :: f (TableEntity GameT)
  }
  deriving (Generic, Database be)

cardpgDb :: DatabaseSettings be CardPGDB
cardpgDb = defaultDbSettings

-- | Helper Functions

initDB :: Pool Pg.Connection -> IO ()
initDB pool = do
    withResource pool $ \conn -> do
        _ <- Pg.execute_ conn "CREATE TABLE IF NOT EXISTS games (game_id TEXT PRIMARY KEY, game_status TEXT NOT NULL, game_state JSONB NOT NULL, game_updated_at TIMESTAMP WITH TIME ZONE NOT NULL)"
        return ()

saveGame :: Pool Pg.Connection -> Text -> GameState -> IO ()
saveGame pool gId gs = do
    now <- getCurrentTime
    let game = Game (gId) ("Active") (PgJSONB (toJSON gs)) (now)
    
    withResource pool $ \conn -> do
        -- Explicit Check for Upsert
        existing <- runBeamPostgresDebug putStrLn conn $ runSelectReturningOne $ select $
            filter_ (\g -> gameId g ==. val_ gId) (all_ (games cardpgDb))
        
        case existing of
            Just _ -> do
                runBeamPostgresDebug putStrLn conn $ runUpdate $ update (games cardpgDb)
                    (\g -> mconcat 
                        [ gameState g <-. val_ (PgJSONB (toJSON gs))
                        , gameUpdatedAt g <-. val_ now 
                        ])
                    (\g -> gameId g ==. val_ gId)
            Nothing -> do
                runBeamPostgresDebug putStrLn conn $ runInsert $ insert (games cardpgDb) (insertValues [game])

loadGame :: Pool Pg.Connection -> Text -> IO (Maybe GameState)
loadGame pool gId = do
    withResource pool $ \conn -> do
        res <- runBeamPostgresDebug putStrLn conn $ runSelectReturningOne $ select $
            filter_ (\g -> gameId g ==. val_ gId) (all_ (games cardpgDb))
        case res of
            Nothing -> return Nothing
            Just g -> do
                let (PgJSONB val) = gameState g
                case fromJSON val of
                    Error e -> do
                        putStrLn $ "Failed to decode game state: " ++ e
                        return Nothing
                    Success s -> return (Just s)
