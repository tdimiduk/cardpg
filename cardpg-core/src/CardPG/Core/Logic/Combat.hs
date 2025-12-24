{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module CardPG.Core.Logic.Combat
  ( attackAction
  , getAttackRule
  , stackPower
  , calculateResilience
  , computeDefense
  , computeResilience
  , getActiveTableCards
  ) where

import Data.List.NonEmpty (NonEmpty (..), toList)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Optics

import CardPG.Core.Card
  ( CoreCard
  , CoreCardT (..)
  , Identified (..)
  , ItemCardT (..)
  , NatureCardT (..)
  , Stats (..)
  , TalentCardT (..)
  )
import CardPG.Core.Logic.Monad (GameM (..))
import CardPG.Core.Primitives (ResourceType (..), StackPower (..), getStat)
import CardPG.Core.RichText (RichText)
import CardPG.Core.RuleDefs (AttackDefT (..), RuleT (RuleAttack))
import CardPG.Core.State
  ( ActionStack (..)
  , ActiveChallenge (..)
  , ActorState (..)
  , AssetState (..)
  , ChallengeSource (..)
  , NarrativeStack (..)
  , PlannedAction (..)
  , TableCard (..)
  , TableState (..)
  )

getAttackRule :: CoreCard -> Either Text (AttackDefT RichText)
getAttackRule card = case card.rules of
  Nothing -> Left "no attack rule"
  Just rules -> case [r | RuleAttack r <- toList rules] of
    [] -> Left "no attack rule"
    [r] -> Right r
    _ -> Left "cards with multiple attack rules are not implemented yet"

stackPower :: ActionStack -> StackPower -> Int
stackPower stack power =
  let
    allCards = stack.actionCard : stack.resources
    relevantStat c = getStat power.source c.content.stats
    rawTotal = sum (map relevantStat allCards)
   in
    rawTotal + power.modifier

attackAction :: PlannedAction -> Either Text ActiveChallenge
attackAction matPlan = case matPlan of
  PStandard stack -> case getAttackRule stack.actionCard.content of
    Left err -> Left err
    Right attackRule ->
      Right $
        ActiveChallenge
          { source = CSCard stack.actionCard.id
          , challengeStrength = stackPower stack attackRule.power
          , challengeColor = attackRule.resistedBy
          }
  PPass -> Left "pass action"
  PNarrative (NarrativeStack{cards = cs, color = col}) ->
    -- Narrative Action Logic
    let
      -- Helper to get stat based on color
      rawTotal = sum [getStat col c.content.stats | c <- toList cs]
     in
      Right $
        ActiveChallenge
          { source = CSCard (let (h :| _) = cs in h.id) -- Safe as narrative stack must have cards
          , challengeStrength = rawTotal -- Modifier 0 for now
          , challengeColor = col -- Defense matches Action Color
          }

-- | Helper: get table cards in active states (Equipped, Trait)
getActiveTableCards :: TableState -> [TableCard]
getActiveTableCards tblSt =
  [ card.content
  | (_, (card, assetState)) <- Map.toList (tblSt ^. #assets)
  , isActive assetState
  ]
  where
    isActive (Equipped _) = True
    isActive Trait = True
    isActive _ = False

-- | Pure function to compute defense from table state
computeDefense :: TableState -> Int
computeDefense tblSt =
  let activeCards = getActiveTableCards tblSt
      getDef (TCItem item) = fromMaybe 0 item.defense
      getDef (TCNature nature) = fromMaybe 0 nature.defense
      getDef (TCTalent talent) = fromMaybe 0 talent.defense
      getDef _ = 0
      maxDef = maximum (0 : map getDef activeCards)
   in max 1 maxDef

-- | Pure function to compute resilience from table state
computeResilience :: TableState -> Int
computeResilience tblSt =
  let activeCards = getActiveTableCards tblSt
      getRes (TCItem item) = fromMaybe 0 item.resilience
      getRes (TCNature nature) = fromMaybe 0 nature.resilience
      getRes _ = 0
      maxRes = maximum (0 : map getRes activeCards)
   in max 1 maxRes

-- | Monadic version for use in GameM context (backwards compatibility)
calculateResilience :: GameM g Int
calculateResilience = do
  tblSt <- use #tableState
  return $ computeResilience tblSt
