module Backend.GSheets.Fetch
  ( syncCards )
where

import Data.Aeson
import Data.Text (Text)
import GHC.Generics

syncCards :: IO ()
syncCards = undefined

data ConsequenceCard = ConsequenceCard
  { _name :: Text
  , _severity :: Int
  , _effect :: Text
  }
  deriving (Show, Generic, ToJSON, FromJSON)
