{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module TypeScriptInstances where

-- Force rebuild
import Data.Aeson (Options (..), Value)
import Data.Aeson.TypeScript.TH
import Data.List.NonEmpty (NonEmpty)
import Data.Proxy (Proxy (..))
import Data.Text (Text)
import GHC.Generics (Generic)
import Language.Haskell.TH (Type (AppT, ConT, ListT), mkName)

import CardPG.Core.Card qualified as CC
import CardPG.Core.Json (cardpgJsonDef, cardpgJsonOptions, cardpgTaggedOptions)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.Primitives
  ( ActorId
  , CardInstanceId
  , CardLocation (..)
  , Difficulty
  , EquipSlot (..)
  , ResourceType (..)
  , StackPower
  , TargetId
  )
import CardPG.Core.RichText (Block, Inline, RichText, TextStyle)

import CardPG.Api.Frontend qualified as Frontend
import CardPG.Api.Types
  ( ActorGameEvent (..)
  , AdminCommand (..)
  , ClientMessage
  , Command (..)
  , LogEntry (..)
  , LogPayload (..)
  , Phase (..)
  , ServerMessage
  , StateUpdate (..)
  , Token
  )
import CardPG.Core.Primitives qualified as P
import CardPG.Core.RuleDefs
import CardPG.Core.State
  ( ActiveChallenge (..)
  , AssetState (..)
  , ChallengeSource (..)
  , CorePlayState (..)
  , NarrativeStack (..)
  , RevealedEffect (..)
  , SpatialState (..)
  , TableCard (..)
  )
import DeriveSpecialized
  ( deriveSpecializedInstance
  , specializeType
  )

import CardPG.Core.State qualified as Core

instance TypeScript Core.ActiveChallenge where
  getTypeScriptType _ = "ActiveChallenge"

instance TypeScript Core.ChallengeSource where
  getTypeScriptType _ = "ChallengeSource"

instance TypeScript CardInstanceId where
  getTypeScriptType _ = "string"

instance TypeScript TargetId where
  getTypeScriptType _ = "string"

instance TypeScript ActorId where
  getTypeScriptType _ = "string"

-- NonEmptyText
instance TypeScript NonEmptyText where
  getTypeScriptType _ = "string"

-- Basic Types
$(deriveTypeScript cardpgJsonDef ''ResourceType)
$(deriveTypeScript cardpgJsonDef ''StackPower)

$(deriveTypeScript (cardpgJsonOptions "Location") ''CardLocation)

$(deriveTypeScript cardpgJsonDef ''Difficulty)
$(deriveTypeScript cardpgJsonDef ''EquipSlot)

-- RichText
$(deriveTypeScript cardpgJsonDef ''TextStyle)
$(deriveTypeScript cardpgJsonDef ''Inline)
$(deriveTypeScript (cardpgJsonDef{unwrapUnaryRecords = True}) ''RichText)

$(deriveTypeScript cardpgJsonDef ''Block)

-- Stats

$(deriveTypeScript cardpgJsonDef ''SpatialState)

$(deriveTypeScript cardpgJsonDef ''Phase)

-- 1. Specialized Types for Rules and Stats
-- These create concrete Haskell types from parameterized ones for TypeScript generation.
-- Card types (CoreCard, ItemCard, etc.) are handled by Frontend.* types instead.
$( do
     d_stats <- specializeType ''P.Stats [ConT ''Int] "Stats"
     d_specDef <- specializeType ''P.Stats [ConT ''P.ResourceType] "SpecialDefend"

     return
       ( d_stats
           ++ d_specDef
       )
 )

-- 2. TypeScript Instances
$( do
     let inline = ConT ''RichText

     -- Rule Variants (needed for Rule union type)
     i_attack <- deriveTypeScript (cardpgJsonOptions "Rule") ''AttackDef
     i_general <- deriveTypeScript (cardpgJsonOptions "Rule") ''GeneralDef
     i_task <- deriveTypeScript (cardpgJsonOptions "Rule") ''TaskDef
     i_trigger <- deriveTypeScript (cardpgJsonOptions "Rule") ''TriggerDef
     i_ongoing <- deriveTypeScript (cardpgJsonOptions "Rule") ''OngoingDef
     i_passive <- deriveTypeScript (cardpgJsonOptions "Rule") ''PassiveDef

     -- Stats
     i_stats <- deriveSpecializedInstance cardpgJsonDef ''Stats ''P.Stats [ConT ''Int]
     i_specDef <-
       deriveSpecializedInstance cardpgJsonDef ''SpecialDefend ''P.Stats [ConT ''P.ResourceType]

     -- Frontend Card Types
     i_rule <- deriveTypeScript (cardpgJsonOptions "Rule") ''Frontend.Rule
     i_core <- deriveTypeScript cardpgJsonDef ''Frontend.CoreCard
     i_item <- deriveTypeScript cardpgJsonDef ''Frontend.ItemCard
     i_nature <- deriveTypeScript cardpgJsonDef ''Frontend.NatureCard
     i_talent <- deriveTypeScript cardpgJsonDef ''Frontend.TalentCard
     i_consequence <- deriveTypeScript cardpgJsonDef ''Frontend.ConsequenceCard
     i_logCard <- deriveTypeScript cardpgJsonDef ''Frontend.LogCard
     i_defenseDetails <- deriveTypeScript cardpgJsonDef ''Frontend.DefenseDetails

     return
       ( i_attack
           ++ i_general
           ++ i_task
           ++ i_trigger
           ++ i_ongoing
           ++ i_rule
           ++ i_passive
           ++ i_stats
           ++ i_specDef
           ++ i_core
           ++ i_item
           ++ i_nature
           ++ i_talent
           ++ i_consequence
           ++ i_logCard
           ++ i_defenseDetails
       )
 )

-- 3. Dependent Types (Must see ItemCard instance etc)
$( do
     -- State Types
     i_token <- deriveTypeScript cardpgJsonDef ''Token
     i_admin <- deriveTypeScript (cardpgTaggedOptions "") ''AdminCommand
     i_command <- deriveTypeScript cardpgJsonDef ''Command
     i_actorGameEvent <- deriveTypeScript cardpgJsonDef ''ActorGameEvent
     i_clientMsg <- deriveTypeScript cardpgJsonDef ''ClientMessage

     i_actionStack <- deriveTypeScript cardpgJsonDef ''Frontend.ActionStack
     i_narrativeStack <- deriveTypeScript cardpgJsonDef ''Frontend.NarrativeStack
     i_plannedAction <- deriveTypeScript cardpgJsonDef ''Frontend.PlannedAction
     i_challengeSource <- deriveTypeScript cardpgJsonDef ''Frontend.ChallengeSource
     i_activeChallenge <- deriveTypeScript cardpgJsonDef ''Frontend.ActiveChallenge
     i_activeDefense <- deriveTypeScript cardpgJsonDef ''Frontend.ActiveDefense
     i_revealedEffect <- deriveTypeScript cardpgJsonDef ''RevealedEffect

     i_logPayload <- deriveTypeScript cardpgJsonDef ''LogPayload
     i_logEntry <- deriveTypeScript cardpgJsonDef ''LogEntry

     -- Frontend.TableCard
     i_tableCard <- deriveTypeScript (cardpgTaggedOptions "TC") ''Frontend.TableCard
     i_illegalDetails <- deriveTypeScript cardpgJsonDef ''Frontend.IllegalActionDetails
     i_gameEvent <- deriveTypeScript cardpgJsonDef ''Frontend.GameEvent

     return
       ( i_token
           ++ i_admin
           ++ i_command
           ++ i_actorGameEvent
           ++ i_clientMsg
           ++ i_actionStack
           ++ i_narrativeStack
           ++ i_plannedAction
           ++ i_challengeSource
           ++ i_activeChallenge
           ++ i_activeDefense
           ++ i_revealedEffect
           ++ i_logPayload
           ++ i_logEntry
           ++ i_tableCard
           ++ i_illegalDetails
           ++ i_gameEvent
       )
 )

-- 4. Dependent State
$( do
     i_corePlay <- deriveTypeScript cardpgJsonDef ''CorePlayState
     i_coreState <- deriveTypeScript cardpgJsonDef ''Frontend.CoreCardState
     i_tableState <- deriveTypeScript cardpgJsonDef ''Frontend.TableState
     i_assetState <- deriveTypeScript cardpgJsonDef ''AssetState
     i_actorState <- deriveTypeScript cardpgJsonDef ''Frontend.ActorState
     i_stateUpdate <- deriveTypeScript cardpgJsonDef ''StateUpdate
     i_serverMsg <- deriveTypeScript cardpgJsonDef ''ServerMessage

     return
       ( i_corePlay
           ++ i_coreState
           ++ i_tableState
           ++ i_assetState
           ++ i_actorState
           ++ i_stateUpdate
           ++ i_serverMsg
       )
 )
