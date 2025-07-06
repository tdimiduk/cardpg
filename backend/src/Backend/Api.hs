module Backend.Api where

import qualified Control.Exception as E
import Control.Lens
import Data.Generics.Labels ()

import Database.Beam
import Database.Beam.Postgres (Connection, runBeamPostgres,  PgJSONB(..))

import Common.Api
import qualified Common.Card as Api

import Backend.Database.Schema
import Backend.Database.Types

consequenceCardFromDb :: ConsequenceCardT Identity -> Api.ConsequenceCard
consequenceCardFromDb ConsequenceCard{ _name=name, _severity=severity, _effect = PgJSONB effect } =
  Api.ConsequenceCard name severity effect

handle :: Connection -> Api a -> IO a
handle conn api = E.handle (\(E.SomeException e) -> do print e; E.throwIO e) $ case api of
  Api_ConsequencesDeck (ConsequencesDeck deck) -> do
    d <- runBeamPostgres conn $ runSelectReturningList $ select $ do
        relatedBy_ (_tableConsequenceCard db) ((val_ deck ==.) . _deck)
    pure $ consequenceCardFromDb <$> d
