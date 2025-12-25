{-# LANGUAGE FlexibleInstances #-}
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

import CardPG.Core.Card
  ( ActorDefinitionT (..)
  , ConsequenceCardT (..)
  , CoreCardT (..)
  , EncounterCardT (..)
  , EncounterMechanics
  , GeneralActionDef
  , Identified (..)
  , ItemCardT (..)
  , NatureCardT (..)
  , TalentCardT (..)
  )
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
import CardPG.Server.Types
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
import CardPG.Server.Types.Frontend qualified as Frontend
import DeriveSpecialized
  ( deriveSpecializedInstance
  , makeBridgeInstance
  , makeProxyInstance
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

-- Helper for creating splices
-- Using runIO or just simple do block
-- We separate Data Generation (Specialize) from Instance Generation

$(deriveTypeScript cardpgJsonDef ''Phase)

-- 1. Data Generation Scope
$( do
     d_attack <- specializeType ''AttackDefT [ConT ''RichText] "AttackDef"
     d_general <- specializeType ''GeneralDefT [ConT ''RichText] "GeneralDef"
     d_task <- specializeType ''TaskDefT [ConT ''RichText] "TaskDef"
     d_trigger <- specializeType ''TriggerDefT [ConT ''RichText] "TriggerDef"
     d_ongoing <- specializeType ''OngoingDefT [ConT ''RichText] "OngoingDef"
     d_rule <- specializeType ''RuleT [ConT ''RichText] "Rule"

     d_core <-
       specializeType
         ''CoreCardT
         [ConT ''CC.Rule, ConT ''RichText]
         "CoreCard"
     d_actor <-
       specializeType
         ''ActorDefinitionT
         [ConT ''CC.Rule, ConT ''RichText]
         "ActorDefinition"

     d_item <- specializeType ''ItemCardT [ConT ''RichText] "ItemCard"
     d_nature <- specializeType ''NatureCardT [ConT ''RichText] "NatureCard"
     d_talent <- specializeType ''TalentCardT [ConT ''RichText] "TalentCard"
     d_encounter <-
       specializeType ''EncounterCardT [ConT ''RichText] "EncounterCard"
     d_consequence <-
       specializeType ''ConsequenceCardT [ConT ''CC.Rule] "ConsequenceCard"

     d_stats <- specializeType ''P.Stats [ConT ''Int] "Stats"
     d_specDef <- specializeType ''P.Stats [ConT ''P.ResourceType] "SpecialDefend"

     return
       ( d_attack
           ++ d_general
           ++ d_task
           ++ d_trigger
           ++ d_ongoing
           ++ d_rule
           ++ d_core
           ++ d_actor
           ++ d_item
           ++ d_nature
           ++ d_talent
           ++ d_encounter
           ++ d_consequence
           ++ d_stats
           ++ d_specDef
       )
 )

-- 1.5 Base Card Instances
$( do
     let inline = ConT ''RichText

     -- Rules & Bridges
     i_attack <- deriveSpecializedInstance (cardpgJsonOptions "Rule") ''AttackDef ''AttackDefT [inline]
     i_general <-
       deriveSpecializedInstance (cardpgJsonOptions "Rule") ''GeneralDef ''GeneralDefT [inline]
     i_task <- deriveSpecializedInstance (cardpgJsonOptions "Rule") ''TaskDef ''TaskDefT [inline]
     i_trigger <-
       deriveSpecializedInstance (cardpgJsonOptions "Rule") ''TriggerDef ''TriggerDefT [inline]
     i_ongoing <-
       deriveSpecializedInstance (cardpgJsonOptions "Rule") ''OngoingDef ''OngoingDefT [inline]

     -- Rule (Machine)
     i_rule <- deriveSpecializedInstance (cardpgJsonOptions "RuleRule") ''Rule ''RuleT [inline]

     -- Def Helpers
     i_passive <- deriveTypeScript (cardpgJsonOptions "Rule") ''PassiveDef

     i_stats <- deriveSpecializedInstance cardpgJsonDef ''Stats ''P.Stats [ConT ''Int]
     i_specDef <-
       deriveSpecializedInstance cardpgJsonDef ''SpecialDefend ''P.Stats [ConT ''P.ResourceType]

     -- Helpers (GenAction, EncMech)
     i_genAction <- deriveTypeScript cardpgJsonDef ''GeneralActionDef
     i_encMech <- deriveTypeScript cardpgJsonDef ''EncounterMechanics

     -- Core Cards
     i_core <-
       deriveSpecializedInstance
         (cardpgTaggedOptions "")
         ''CoreCard
         ''CoreCardT
         [ConT ''CC.Rule, inline]
     i_actor <-
       deriveSpecializedInstance
         cardpgJsonDef
         ''ActorDefinition
         ''ActorDefinitionT
         [ConT ''CC.Rule, inline]
     i_item <- deriveSpecializedInstance (cardpgTaggedOptions "") ''ItemCard ''ItemCardT [inline]
     i_nature <- deriveSpecializedInstance (cardpgTaggedOptions "") ''NatureCard ''NatureCardT [inline]
     i_talent <- deriveSpecializedInstance (cardpgTaggedOptions "") ''TalentCard ''TalentCardT [inline]
     i_encounter <-
       deriveSpecializedInstance (cardpgTaggedOptions "") ''EncounterCard ''EncounterCardT [inline]
     i_consequence <-
       deriveSpecializedInstance
         (cardpgTaggedOptions "")
         ''ConsequenceCard
         ''ConsequenceCardT
         [ConT ''CC.Rule]

     -- Proxy Instances (Bridge original types to local specialized types)
     let inline = AppT ListT (ConT ''Inline)
     let richStr = ConT ''RichString
     let richTxt = ConT ''RichText
     let text = ConT ''Text
     let maybeText = AppT (ConT ''Maybe) (ConT ''Text)
     let dslRule = ConT ''DSLRule
     let rule = ConT ''Rule

     -- CoreCard
     -- p_core1 handled by d_core implicit instance
     p_core2 <- makeProxyInstance [t|CoreCardT DSLRule RichString|] ''CoreCard "CoreCard"

     -- ActorDefinition
     p_actor <-
       makeProxyInstance [t|ActorDefinitionT DSLRule RichString|] ''ActorDefinition "ActorDefinition"

     -- ItemCard

     p_item3 <- makeProxyInstance [t|ItemCardT RichString|] ''ItemCard "ItemCard"

     -- NatureCard

     p_nature3 <- makeProxyInstance [t|NatureCardT RichString|] ''NatureCard "NatureCard"

     -- TalentCard

     p_talent3 <- makeProxyInstance [t|TalentCardT RichString|] ''TalentCard "TalentCard"

     -- EncounterCard

     p_encounter3 <- makeProxyInstance [t|EncounterCardT RichString|] ''EncounterCard "EncounterCard"

     -- ConsequenceCard
     p_consequence2 <-
       makeProxyInstance [t|ConsequenceCardT DSLRule|] ''ConsequenceCard "ConsequenceCard"

     i_coreInstT <- deriveTypeScript cardpgJsonDef ''Frontend.CoreCardInstance
     i_consInstT <- deriveTypeScript cardpgJsonDef ''Frontend.ConsequenceCardInstance

     return
       ( i_attack
           ++ i_general
           ++ i_task
           ++ i_trigger
           ++ i_ongoing
           ++ i_rule
           ++ i_passive
           ++ i_genAction
           ++ i_encMech
           ++ i_core
           ++ i_actor
           ++ i_item
           ++ i_nature
           ++ i_talent
           ++ i_encounter
           ++ i_consequence
           ++ p_core2
           ++ p_actor
           ++ p_item3
           ++ p_nature3
           ++ p_talent3
           ++ p_encounter3
           ++ p_consequence2
           ++ i_coreInstT
           ++ i_consInstT
           ++ i_stats
           ++ i_specDef
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

     i_tableCard <- deriveTypeScript cardpgJsonDef ''TableCard
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

-- 4. TableCardInstance Instance (Must see TableCard instance and TableCardInstance data)
$( do
     deriveTypeScript cardpgJsonDef ''Frontend.TableCardInstance
 )

-- 5. Dependent State (Must see TableCardInstance proxy)
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
