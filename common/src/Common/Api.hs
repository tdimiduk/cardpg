{-# Language TemplateHaskell #-}
module Common.Api where

import Data.Text (Text)
import           Data.Vector (Vector)

import Data.Aeson (ToJSON, FromJSON)

import Common.Card

newtype ConsequencesDeck = ConsequencesDeck Text
  deriving newtype (ToJSON, FromJSON)

data Api a where
  Api_ConsequencesDeck :: ConsequencesDeck -> Api (Vector ConsequenceCard)
  Api_RefreshConsequencesDeck :: ConsequencesDeck -> Api (Either Text Int)
  Api_AddConsequencesDeck :: ConsequencesDeck -> Text -> Text -> Api (Either Text ())
