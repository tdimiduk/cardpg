{-# LANGUAGE OverloadedStrings #-}

module CardPG.Core.Language where

import Data.Text (Text)

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

-- Separators
sepArrow :: Text
sepArrow = "->"

sepColon :: Text
sepColon = ":"

sepSpace :: Text
sepSpace = " "
