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

import Data.Either (Either (..))
import Data.List.NonEmpty (NonEmpty (..), toList)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Optics

import CardPG.Core.Card
  ( CoreCard
  , CoreCardT (..)
  , ItemCardT (..)
  , NatureCardT (..)
  , Stats (..)
  , TalentCardT (..)
  )
import CardPG.Core.Logic.Monad (GameM (..))
import CardPG.Core.Primitives (ResourceType (..), StackPower (..))
import CardPG.Core.RichText (RichText)
import CardPG.Core.RuleDefs (AttackDefT (..), RuleT (RuleAttack))
import CardPG.Core.State
  ( ActionStackMaterialized (..)
  , ActorState (..)
  , AssetState (..)
  , CoreCardState (..)
  , NarrativeStackMaterialized (..)
  , PlannedActionMaterialized (..)
  , RealizedAttack (..)
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

stackPower :: ActionStackMaterialized -> StackPower -> Int
stackPower stack power =
  let
    allCards = stack.actionCard : stack.resources
    relevantStat c = case power.source of
      Red -> c.stats.red
      Yellow -> c.stats.yellow
      Blue -> c.stats.blue
    rawTotal = sum (map relevantStat allCards)
   in
    rawTotal + power.modifier

attackAction :: PlannedActionMaterialized -> Either Text RealizedAttack
attackAction matPlan = case matPlan of
  PMStandard stack -> case getAttackRule stack.actionCard of
    Left err -> Left err
    Right attackRule ->
      Right $
        RealizedAttack
          { attackCard = stack.actionCardId
          , attackStrength = stackPower stack attackRule.power
          , defenseColor = attackRule.resistedBy
          }
  PMPass -> Left "pass action"
  PMNarrative (NarrativeStackMaterialized{cards = cs, cardIds = cIds, color = col}) ->
    -- Narrative Action Logic
    let
      -- Helper to get stat based on color
      getStat :: ResourceType -> Stats -> Int
      getStat Red s = s.red
      getStat Yellow s = s.yellow
      getStat Blue s = s.blue

      rawTotal = sum [getStat col c.stats | c <- toList cs]
     in
      Right $
        RealizedAttack
          { attackCard = let (h :| _) = cIds in h -- Safe as narrative stack must have cards
          , attackStrength = rawTotal -- Modifier 0 for now
          , defenseColor = col -- Defense matches Action Color
          }

-- | Helper: get table cards in active states (Equipped, Trait)
getActiveTableCards :: TableState -> [TableCard]
getActiveTableCards tblSt =
  [ card
  | (cid, assetState) <- Map.toList (tblSt ^. #assets)
  , isActive assetState
  , Just card <- [Map.lookup cid (tblSt ^. #registry)]
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

