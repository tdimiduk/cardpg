module Backend.Api where

import qualified Control.Exception as E
import Control.Lens
import Data.Text (unpack, pack)
import Data.Generics.Labels ()
import qualified Data.Vector as V

import Database.Beam

import Database.Beam.Backend.SQL.BeamExtensions
import Database.Beam.Postgres
import qualified Database.Beam.Postgres.Full as Pg

import Common.Api
import qualified Common.Card as Api

import Backend.Common

import Backend.Database.Schema
import Backend.Database.Types
import Backend.Database.Write

import qualified Backend.GSheets.Fetch as Fetch

consequenceCardFromDb :: ConsequenceCardT Identity -> Api.ConsequenceCard
consequenceCardFromDb ConsequenceCard{ _name=name, _severity=severity, _effect = PgJSONB effect } =
  Api.ConsequenceCard name severity effect

handle :: Connection -> BackendEnv -> Api a -> IO a
handle conn env api = E.handle (\(E.SomeException e) -> do print e; E.throwIO e) $ case api of
  Api_ConsequencesDeck (ConsequencesDeck deck) -> do
    d <- runBeamPostgres conn $ runSelectReturningList $ select $ do
        relatedBy_ (_tableConsequenceCard db) ((val_ deck ==.) . _deck)
    pure $ consequenceCardFromDb <$> V.fromList d
  Api_RefreshConsequencesDeck (ConsequencesDeck deck) -> do
    r <- runBeamPostgres conn $ runSelectReturningList $ select $ do
      d <- relatedBy_ (_tableGSheetsRef db) ((val_ deck ==.) . view #_name)
      pure (_key d, _sheet d)
    case r of
      [] -> pure $ Left $ deck <> " does not exist, please add it first"
      [(docKey, sheetName)] -> do
        fetched <- Fetch.cards (unpack <$> _pythonScriptPath env) docKey sheetName
        print $ "fetched " <> deck <> " from gsheets"
        case fetched of
          Left err -> pure $ Left $ pack $ show err
          Right c -> do
            runBeam conn $ replaceConsequenceCards deck c
            pure $ Right (length fetched)
      _ -> pure $ Left $ "somehow a uniqueness constraint got violated"
  Api_AddConsequencesDeck (ConsequencesDeck deck) key sheet -> do
    r <- runBeamPostgresDebug print conn $ runInsertReturningList $
      Pg.insert
        (_tableGSheetsRef db)
        (insertExpressions
          [ GSheetsReference
              default_
              (val_ deck)
              (val_ key)
              (val_ sheet)
          ]
        )
      $ Pg.onConflict (Pg.conflictingFields (\t -> t ^. #_name))
        (onConflictUpdateInstead (\f -> (_key f, _sheet f)))
    case r of
      [] -> pure $ Left "failed to insert"
      _ -> pure $ Right ()
