{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}

module Core.Logic.Combat
  ( attackAction
  , getAttackRule
  , stackPower
  , calculateResilience
  , computeDefense
  , computeResilience
  , computeNextSeverity
  , computeDefenseDetails
  , getActiveTableCards
  ) where

import Control.Lens
import Data.Generics.Labels ()
import Data.List.NonEmpty (NonEmpty (..), toList)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)

import Core.Card
  ( CoreCard (..)
  , Identified (..)
  , ItemCard (..)
  , NatureCard (..)
  , TalentCard (..)
  )
import Core.Logic.Monad (GameM (..))
import Core.Primitives (ChallengeId)
import Core.Rules (AttackDef (..))
import Core.State
  ( ActionStack (..)
  , ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , AssetState (..)
  , ChallengeSource (..)
  , CoreCardState (..)
  , DefenseDetails (..)
  , NarrativeStack (..)
  , PlannedAction (..)
  , TableCard (..)
  , TableState (..)
  )
import Core.Stats (ResourceType (..), StackPower (..), Stats (..), getStat)

getAttackRule :: CoreCard -> Either Text AttackDef
getAttackRule card = case card.attack of
  Nothing -> Left "no attack rule"
  Just attack -> Right attack

stackPower :: ActionStack -> StackPower -> Int
stackPower stack power =
  let
    allCards = stack.actionCard : stack.resources
    relevantStat c = getStat power.source c.content.stats
    rawTotal = sum (map relevantStat allCards)
   in
    rawTotal + power.modifier

attackAction :: ChallengeId -> PlannedAction -> Either Text ActiveChallenge
attackAction cid matPlan = case matPlan of
  PStandard stack -> case getAttackRule stack.actionCard.content of
    Left err -> Left err
    Right attackRule ->
      Right $
        ActiveChallenge
          { id = cid
          , source = CSCard stack.actionCard.id
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
          { id = cid
          , source = CSCard (let (h :| _) = cs in h.id) -- Safe as narrative stack must have cards
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
      maxDef = maximum (0 : map (fromMaybe 0 . (.defense)) activeCards)
   in max 1 maxDef

-- | Pure function to compute resilience from table state
computeResilience :: TableState -> Int
computeResilience tblSt =
  let activeCards = getActiveTableCards tblSt
      maxRes = maximum (0 : map (fromMaybe 0 . (.resilience)) activeCards)
   in max 1 maxRes

-- | Pure function to compute next consequence severity from table state
computeNextSeverity :: TableState -> Int
computeNextSeverity tblSt =
  let res = computeResilience tblSt
      currentCons = length tblSt.consequences
   in if res > 0
        then (currentCons `div` res) + 1
        else currentCons + 1

-- | Monadic version for use in GameM context (backwards compatibility)
calculateResilience :: GameM g Int
calculateResilience = do
  tblSt <- use #tableState
  return $ computeResilience tblSt

computeDefenseDetails :: ActorState -> DefenseDetails
computeDefenseDetails ActorState{coreState, tableState} =
  let
    CoreCardState{defending} = coreState
    TableState{consequences} = tableState

    defStat = computeDefense tableState
    resStat = computeResilience tableState

    defendingCards = case defending of
      Nothing -> []
      Just (ActiveDefense _ cards) -> cards

    defRed = sum [getStat Red content.stats | Identified _ content <- defendingCards]
    defYellow = sum [getStat Yellow content.stats | Identified _ content <- defendingCards]
    defBlue = sum [getStat Blue content.stats | Identified _ content <- defendingCards]

    impactVal = length defendingCards
    consequencesVal = if defStat > 0 then impactVal `div` defStat else impactVal
    currentConsequences = length consequences
    nextSeverityVal =
      if resStat > 0
        then ((currentConsequences + consequencesVal) `div` resStat) + 1
        else currentConsequences + consequencesVal + 1
   in
    DefenseDetails
      { values = Stats{red = defRed, yellow = defYellow, blue = defBlue}
      , impact = impactVal
      , consequencesFromDefense = consequencesVal
      , nextSeverity = nextSeverityVal
      }
