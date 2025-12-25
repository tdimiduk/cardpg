{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE ScopedTypeVariables #-}
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
import CardPG.Core.RichText (Block, Inline, RichString, RichText, TextStyle)

import CardPG.Core.Primitives qualified as P
import CardPG.Core.RuleDefs hiding
  ( AttackDef
  , GeneralDef
  , OngoingDef
  , Rule
  , TaskDef
  , TriggerDef
  )
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
import CardPG.Api.Frontend qualified as Frontend
import DeriveSpecialized
  ( deriveSpecializedInstance
  , specializeType
  )

instance TypeScript DSLRule where
  getTypeScriptType _ = "string"

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
$(deriveTypeScript (cardpgJsonDef{unwrapUnaryRecords = True}) ''RichString)
$(deriveTypeScript cardpgJsonDef ''Block)

-- Stats

$(deriveTypeScript cardpgJsonDef ''SpatialState)

$(deriveTypeScript cardpgJsonDef ''Phase)

-- 1. Specialized Types for Rules and Stats
-- These create concrete Haskell types from parameterized ones for TypeScript generation.
-- Card types (CoreCard, ItemCard, etc.) are handled by Frontend.* types instead.
$( do
     d_attack <- specializeType ''AttackDefT [ConT ''RichText] "AttackDef"
     d_general <- specializeType ''GeneralDefT [ConT ''RichText] "GeneralDef"
     d_task <- specializeType ''TaskDefT [ConT ''RichText] "TaskDef"
     d_trigger <- specializeType ''TriggerDefT [ConT ''RichText] "TriggerDef"
     d_ongoing <- specializeType ''OngoingDefT [ConT ''RichText] "OngoingDef"
     d_rule <- specializeType ''RuleT [ConT ''RichText] "Rule"
     d_stats <- specializeType ''P.Stats [ConT ''Int] "Stats"
     d_specDef <- specializeType ''P.Stats [ConT ''P.ResourceType] "SpecialDefend"

     return
       ( d_attack
           ++ d_general
           ++ d_task
           ++ d_trigger
           ++ d_ongoing
           ++ d_rule
           ++ d_stats
           ++ d_specDef
       )
 )

-- 2. TypeScript Instances
$( do
     let inline = ConT ''RichText

     -- Rule Variants (needed for Rule union type)
     i_attack <- deriveSpecializedInstance (cardpgJsonOptions "Rule") ''AttackDef ''AttackDefT [inline]
     i_general <-
       deriveSpecializedInstance (cardpgJsonOptions "Rule") ''GeneralDef ''GeneralDefT [inline]
     i_task <- deriveSpecializedInstance (cardpgJsonOptions "Rule") ''TaskDef ''TaskDefT [inline]
     i_trigger <-
       deriveSpecializedInstance (cardpgJsonOptions "Rule") ''TriggerDef ''TriggerDefT [inline]
     i_ongoing <-
       deriveSpecializedInstance (cardpgJsonOptions "Rule") ''OngoingDef ''OngoingDefT [inline]
     i_rule <- deriveSpecializedInstance (cardpgJsonOptions "RuleRule") ''Rule ''RuleT [inline]
     i_passive <- deriveTypeScript (cardpgJsonOptions "Rule") ''PassiveDef

     -- Stats
     i_stats <- deriveSpecializedInstance cardpgJsonDef ''Stats ''P.Stats [ConT ''Int]
     i_specDef <-
       deriveSpecializedInstance cardpgJsonDef ''SpecialDefend ''P.Stats [ConT ''P.ResourceType]

     -- Frontend Card Types
     i_core <- deriveTypeScript cardpgJsonDef ''Frontend.CoreCard
     i_item <- deriveTypeScript cardpgJsonDef ''Frontend.ItemCard
     i_nature <- deriveTypeScript cardpgJsonDef ''Frontend.NatureCard
     i_talent <- deriveTypeScript cardpgJsonDef ''Frontend.TalentCard
     i_consequence <- deriveTypeScript cardpgJsonDef ''Frontend.ConsequenceCard

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
     i_challengeSource <- deriveTypeScript cardpgJsonDef ''ChallengeSource
     i_activeChallenge <- deriveTypeScript cardpgJsonDef ''ActiveChallenge
     i_revealedEffect <- deriveTypeScript cardpgJsonDef ''RevealedEffect

     i_logPayload <- deriveTypeScript cardpgJsonDef ''LogPayload
     i_logEntry <- deriveTypeScript cardpgJsonDef ''LogEntry

     -- Frontend.TableCard
     i_tableCard <- deriveTypeScript (cardpgTaggedOptions "TC") ''Frontend.TableCard
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
           ++ i_revealedEffect
           ++ i_logPayload
           ++ i_logEntry
           ++ i_tableCard
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
     i_defenseDetails <- deriveTypeScript cardpgJsonDef ''Frontend.DefenseDetails
     i_stateUpdate <- deriveTypeScript cardpgJsonDef ''StateUpdate
     i_serverMsg <- deriveTypeScript cardpgJsonDef ''ServerMessage

     return
       ( i_corePlay
           ++ i_coreState
           ++ i_tableState
           ++ i_assetState
           ++ i_actorState
           ++ i_defenseDetails
           ++ i_stateUpdate
           ++ i_serverMsg
       )
 )
