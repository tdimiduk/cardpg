{-# LANGUAGE OverloadedStrings #-}

module CardPG.Core.Language where

import Data.Aeson.TH (deriveJSON)
import Data.Text (Text)
import GHC.Generics (Generic)

import CardPG.Core.Json (cardpgJsonDef)

data TextStyle
  = Bold
  | Italic
  | -- | For "Resolve:", "Setup:", etc.
    GameKeyword
  deriving stock (Eq, Show, Enum, Bounded, Generic)

$(deriveJSON cardpgJsonDef ''TextStyle)

-- Rule Keywords
cmdAttack :: Text
cmdAttack = "Attack"

cmdAction :: Text
cmdAction = "Action:"

cmdGeneral :: Text
cmdGeneral = "General:"

cmdOngoing :: Text
cmdOngoing = "Ongoing"

cmdPassive :: Text
cmdPassive = "Passive:"

cmdTask :: Text
cmdTask = "Task:"

cmdWhen :: Text
cmdWhen = "When"

kwCheck :: Text
kwCheck = "Check"

kwTime :: Text
kwTime = "Time"

kwCost :: Text
kwCost = "Cost"

kwStrength :: Text
kwStrength = "Strength"

-- Separators
sepArrow :: Text
sepArrow = "->"

sepColon :: Text
sepColon = ":"

sepSpace :: Text
sepSpace = " "

sepOpenParen :: Text
sepOpenParen = "("

sepCloseParen :: Text
sepCloseParen = ")"

sepSemi :: Text
sepSemi = ";"

sepComma :: Text
sepComma = ","

-- Styling
styleDelimiter :: TextStyle -> Text
styleDelimiter Bold = "**"
styleDelimiter Italic = "*"
styleDelimiter GameKeyword = "`"
