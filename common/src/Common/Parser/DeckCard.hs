{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE RecordWildCards #-}

module Common.Parser.DeckCard
  ( deckCard
  )
  where

import Control.Applicative (liftA2)
import Control.Monad (void)
import Data.Either.Combinators
import Data.List.NonEmpty (NonEmpty(..))
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import Text.Megaparsec hiding (some, sepBy1)
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Data.Void
import Witherable

import Common.DeckCard 
import Common.Parser.Common
import Common.RichText

deckCard :: Parser DeckCard
deckCard = do
  _actor <- label "actor" $ tsvField textTillTab
  _name <- label "name" $ tsvField textTillTab
  _stats <- stats
  _keywordProvide <- label "keywords provided" $ tsvField $ optional textTillTab
  _cost <- label "cost" $ tsvField $ optional L.decimal
  _keywordCost <- label "required keywords" $ tsvField $ optional $ textTillTab
  -- _rules <- rules
  label "trailing whitespace for card" hspace
  let
    _id = _actor <> "-" <> _name
    _tags = ["from-sheet"]
    _flavor = Nothing
  pure DeckCard{..}

stats :: Parser Stats
stats = do
  _red <- label "red" $ tsvField L.decimal
  _yellow <- label "yellow" $ tsvField L.decimal
  _blue <- label "blue" $ tsvField L.decimal
  pure Stats {..}

-- rules :: Parser [Rule] 
-- rules = do
--   _action <- tsvField $ optional action
--   _effect <- label "effect" $ tsvField $ optional richString
--   _details <- label "details" $ tsvField $ optional richString
--   pure $ catMaybes [_action, _effect, _details]

action :: Parser Action
action = label "action"
  (   DoAttack <$> attack
  <|> DoDefend <$> defend
  <|> DoInstall <$> install
  <|> DoGeneral <$> general
  <|> DoNarrative <$> richString
  )

attack :: Parser AttackDef
attack = label "attack" $ do
  _ <- string' "attack "
  _resistedBy <- resourceSymbol
  _power <- stackPower
  pure AttackDef {..}
  
stackPower :: Parser StackPower
stackPower = label "stack power" $ do
  _ <- ots $ string ":"
  _ <- optional $ do
    _ <- ots $ string' "strength"
    ots $ optional $ string "="
  _source <- ots $ resourceSymbol
  _modifier <- ots $ plusModifier
  _ <- optional semicolin
  pure StackPower {..}

richString :: Parser RichString
richString = undefined

general :: Parser GeneralDef
general = undefined

install :: Parser InstallDef
install = undefined

defend :: Parser DefendDef
defend = undefined

