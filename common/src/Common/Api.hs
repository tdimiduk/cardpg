{-# Language TemplateHaskell #-}
module Common.Api where

import Data.Text (Text)
import           Data.Vector (Vector)

import Data.Aeson (ToJSON, FromJSON)

import Common.Card
import Common.Card.Common

newtype ConsequencesDeck = ConsequencesDeck Text
  deriving newtype (ToJSON, FromJSON)

data Api a where
  Api_ConsequencesDeck :: ConsequencesDeck -> Api (Vector ConsequenceCard)
  Api_RefreshDeck :: Text -> Api (Either Text Int)
  Api_AddDeck :: CardType -> Text -> Text -> Text -> Api (Either Text ())

class (ToJSON req, FromJSON req) => IsDeckRequest req where
  type Card req :: *

instance IsDeckRequest ConsequencesDeck where
  type Card ConsequencesDeck = ConsequenceCard
