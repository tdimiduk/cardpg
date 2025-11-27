{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DuplicateRecordFields #-}
module Main where

import Data.Aeson (encode)
import qualified Data.ByteString.Lazy as B
import Data.Text (Text)
import qualified Data.Text as T
import Data.List.NonEmpty (NonEmpty(..))

import CardPG.Core.Card
import CardPG.Core.Types
import CardPG.Core.RichText

main :: IO ()
main = do
  let cards = [strikeCard, defendCard, stanceCard]
  B.writeFile "reference_cards.json" (encode cards)
  putStrLn "Generated reference_cards.json"

-- Sample Cards

strikeCard :: DeckCard
strikeCard = DeckCard
  { _id = "card_strike"
  , _name = "Strike"
  , _tags = ["Melee", "Attack"]
  , _stats = Stats 3 2 2
  , _cost = Just 1
  , _rules = 
      [ RuleAttack $ AttackDef
          { _power = StackPower Red 2
          , _resistedBy = Red
          , _effect = Nothing
          }
      ]
  , _flavor = Just [TextRun (TextRunDef Nothing "A simple thrust.")]
  }

defendCard :: DeckCard
defendCard = DeckCard
  { _id = "card_block"
  , _name = "Block"
  , _tags = ["Melee", "Defense"]
  , _stats = Stats 0 0 0
  , _cost = Just 1
  , _rules = 
      [ RuleDefend $ DefendDef
          { _power = StackPower Blue 2
          , _resists = Red :| [Yellow]
          , _effect = Nothing
          }
      ]
  , _flavor = Nothing
  }

stanceCard :: DeckCard
stanceCard = DeckCard
  { _id = "card_stance"
  , _name = "Iron Stance"
  , _tags = ["Stance"]
  , _stats = Stats 0 0 0
  , _cost = Just 2
  , _rules = 
      [ RuleStance $ StanceDef
          { _duration = "Until end of encounter"
          }
      , RulePassive $ PassiveDef
          { _bonus = StackPower Red 1
          , _condition = Just "While active"
          }
      ]
  , _flavor = Just [TextRun (TextRunDef Nothing "Unmovable.")]
  }
