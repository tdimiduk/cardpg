{-# LANGUAGE OverloadedStrings #-}

module CardPG.Server.ChatParser
  ( ChatCommand (..)
  , ChallengeDetails (..)
  , parseChatCommand
  ) where

import Data.Text (Text)
import Data.Text qualified as T
import Data.Void (Void)
import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Char.Lexer qualified as L

import CardPG.Core.Primitives (ResourceType (..))

data ChallengeDetails = ChallengeDetails
  { color :: ResourceType
  , value :: Int
  , name :: Text
  , description :: Maybe Text
  }
  deriving (Show, Eq)

data ChatCommand
  = CmdChallenge ChallengeDetails
  | CmdText Text -- Fallback for normal chat
  deriving (Show, Eq)

type Parser = Parsec Void Text

sc :: Parser ()
sc = L.space space1 empty empty

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

-- | Parser for Resource Type (case insensitive)
pColor :: Parser ResourceType
pColor =
  choice
    [ Red <$ (string' "red" <|> symbol "R")
    , Yellow <$ (string' "yellow" <|> symbol "Y")
    , Blue <$ (string' "blue" <|> symbol "B")
    ]

-- | Parser for Ad-Hoc Challenge Command
-- Patter: /a <color> <value> [rest...]
-- Patter: /check <color> <value> [rest...]
pChallenge :: Parser ChatCommand
pChallenge = do
  _ <- char '/'
  _ <- string' "a" <|> string' "check"
  sc
  c <- lexeme pColor
  v <- lexeme L.decimal

  -- Parse optional name/desc from the rest of the line
  rest <- takeRest
  let (n, d) =
        if T.null rest
          then ("Ad-hoc Challenge", Nothing)
          else (T.strip rest, Nothing) -- Could split by newline for desc if we wanted
  return $ CmdChallenge (ChallengeDetails c v n d)

-- | Main Parser
pChatCommand :: Parser ChatCommand
pChatCommand = try pChallenge <|> (CmdText <$> takeRest)

parseChatCommand :: Text -> ChatCommand
parseChatCommand t =
  case runParser pChatCommand "" t of
    Left _ -> CmdText t -- If parsing fails, treat as normal text
    Right cmd -> cmd
