{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module TypeScriptInstances where

import Data.Aeson (Options (..))
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
  , ItemCardT (..)
  , NatureCardT (..)
  , SpecialDefend
  , Stats
  , TalentCardT (..)
  )
import CardPG.Core.Card qualified as CC
import CardPG.Core.Json (cardpgJsonDef, cardpgJsonOptions, cardpgTaggedOptions)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.Primitives
  ( CardInstanceId
  , Difficulty
  , EquipSlot (..)
  , ResourceType (..)
  , StackPower
  , TargetId
  )
import CardPG.Core.RichText (Block, Inline, RichString, RichText, TextStyle)
import CardPG.Core.RuleDefs hiding
  ( AttackDef
  , ChannelDef
  , GeneralDef
  , PrimeDef
  , Rule
  , StanceDef
  , TaskDef
  , TriggerDef
  )
import CardPG.Core.State
  ( ActorState (..)
  , AssetState (..)
  , CoreCardState (..)
  , CorePlayState (..)
  , GameEvent (..)
  , PlannedAction (..)
  , SpatialState (..)
  , TableCard (..)
  , TableState (..)
  )
import CardPG.Server.Types
  ( BroadcastAction (..)
  , ClientMessage
  , Command (..)
  , ServerMessage
  , StateUpdate (..)
  , Token
  )
import DeriveSpecialized
  ( deriveSpecializedInstance
  , makeBridgeInstance
  , makeProxyInstance
  , specializeType
  )

instance TypeScript DSLRule where
  getTypeScriptType _ = "string"

-- Basic Types
$(deriveTypeScript cardpgJsonDef ''ResourceType)
$(deriveTypeScript cardpgJsonDef ''StackPower)

$(deriveTypeScript cardpgJsonDef ''Difficulty)
$(deriveTypeScript cardpgJsonDef ''EquipSlot)

instance TypeScript CardInstanceId where
  getTypeScriptType _ = "string"

instance TypeScript TargetId where
  getTypeScriptType _ = "string"

-- NonEmptyText
instance TypeScript NonEmptyText where
  getTypeScriptType _ = "string"

-- RichText
$(deriveTypeScript cardpgJsonDef ''TextStyle)
$(deriveTypeScript cardpgJsonDef ''Inline)
$(deriveTypeScript (cardpgJsonDef{unwrapUnaryRecords = True}) ''RichText)
$(deriveTypeScript (cardpgJsonDef{unwrapUnaryRecords = True}) ''RichString)
$(deriveTypeScript cardpgJsonDef ''Block)

-- Stats
$(deriveTypeScript cardpgJsonDef ''Stats)
$(deriveTypeScript cardpgJsonDef ''SpecialDefend)

$(deriveTypeScript cardpgJsonDef ''SpatialState)
$(deriveTypeScript cardpgJsonDef ''PlannedAction)

-- Helper for creating splices
-- Using runIO or just simple do block
-- We separate Data Generation (Specialize) from Instance Generation

-- 1. Data Generation Scope
$( do
     d_attack <- specializeType ''AttackDefT [AppT ListT (ConT ''Inline)] "AttackDef"
     d_general <- specializeType ''GeneralDefT [AppT ListT (ConT ''Inline)] "GeneralDef"
     d_task <- specializeType ''TaskDefT [AppT ListT (ConT ''Inline)] "TaskDef"
     d_trigger <- specializeType ''TriggerDefT [AppT ListT (ConT ''Inline)] "TriggerDef"
     d_stance <- specializeType ''StanceDefT [AppT ListT (ConT ''Inline)] "StanceDef"
     d_channel <- specializeType ''ChannelDefT [AppT ListT (ConT ''Inline)] "ChannelDef"
     d_prime <- specializeType ''PrimeDefT [AppT ListT (ConT ''Inline)] "PrimeDef"
     d_rule <- specializeType ''RuleT [AppT ListT (ConT ''Inline)] "Rule"

     d_core <-
       specializeType
         ''CoreCardT
         [ConT (mkName "Rule"), AppT ListT (ConT ''Inline)]
         "CoreCard"
     d_actor <-
       specializeType
         ''ActorDefinitionT
         [ConT (mkName "Rule"), AppT ListT (ConT ''Inline)]
         "ActorDefinition"

     d_item <- specializeType ''ItemCardT [AppT ListT (ConT ''Inline)] "ItemCard"
     d_nature <- specializeType ''NatureCardT [AppT ListT (ConT ''Inline)] "NatureCard"
     d_talent <- specializeType ''TalentCardT [AppT ListT (ConT ''Inline)] "TalentCard"
     d_encounter <-
       specializeType ''EncounterCardT [AppT ListT (ConT ''Inline)] "EncounterCard"
     d_consequence <-
       specializeType ''ConsequenceCardT [ConT (mkName "Rule")] "ConsequenceCard"

     return
       ( d_attack
           ++ d_general
           ++ d_task
           ++ d_trigger
           ++ d_stance
           ++ d_channel
           ++ d_prime
           ++ d_rule
           ++ d_core
           ++ d_actor
           ++ d_item
           ++ d_nature
           ++ d_talent
           ++ d_encounter
           ++ d_consequence
       )
 )

-- 1.5 Base Card Instances
$( do
     let inline = AppT ListT (ConT ''Inline)

     -- Rules & Bridges
     i_attack <- deriveSpecializedInstance (cardpgJsonOptions "Rule") ''AttackDef ''AttackDefT [inline]
     i_general <-
       deriveSpecializedInstance (cardpgJsonOptions "Rule") ''GeneralDef ''GeneralDefT [inline]
     i_task <- deriveSpecializedInstance (cardpgJsonOptions "Rule") ''TaskDef ''TaskDefT [inline]
     i_trigger <-
       deriveSpecializedInstance (cardpgJsonOptions "Rule") ''TriggerDef ''TriggerDefT [inline]
     i_stance <- deriveSpecializedInstance (cardpgJsonOptions "Rule") ''StanceDef ''StanceDefT [inline]
     i_channel <-
       deriveSpecializedInstance (cardpgJsonOptions "Rule") ''ChannelDef ''ChannelDefT [inline]
     i_prime <- deriveSpecializedInstance (cardpgJsonOptions "Rule") ''PrimeDef ''PrimeDefT [inline]

     -- Rule (Machine)
     i_rule <- deriveSpecializedInstance (cardpgJsonOptions "RuleRule") ''Rule ''RuleT [inline]

     -- Def Helpers
     i_passive <- deriveTypeScript (cardpgJsonOptions "Rule") ''PassiveDef

     -- Helpers (GenAction, EncMech)
     i_genAction <- deriveTypeScript cardpgJsonDef ''GeneralActionDef
     i_encMech <- deriveTypeScript cardpgJsonDef ''EncounterMechanics

     -- Core Cards
     i_core <-
       deriveSpecializedInstance
         (cardpgTaggedOptions "")
         ''CoreCard
         ''CoreCardT
         [ConT (mkName "Rule"), inline]
     i_actor <-
       deriveSpecializedInstance
         cardpgJsonDef
         ''ActorDefinition
         ''ActorDefinitionT
         [ConT (mkName "Rule"), inline]
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
         [ConT (mkName "Rule")]

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
     p_item2 <- makeProxyInstance [t|ItemCardT RichText|] ''ItemCard "ItemCard"
     p_item3 <- makeProxyInstance [t|ItemCardT RichString|] ''ItemCard "ItemCard"

     -- NatureCard
     p_nature2 <- makeProxyInstance [t|NatureCardT RichText|] ''NatureCard "NatureCard"
     p_nature3 <- makeProxyInstance [t|NatureCardT RichString|] ''NatureCard "NatureCard"

     -- TalentCard
     p_talent2 <- makeProxyInstance [t|TalentCardT RichText|] ''TalentCard "TalentCard"
     p_talent3 <- makeProxyInstance [t|TalentCardT RichString|] ''TalentCard "TalentCard"

     -- EncounterCard
     p_encounter2 <- makeProxyInstance [t|EncounterCardT RichText|] ''EncounterCard "EncounterCard"
     p_encounter3 <- makeProxyInstance [t|EncounterCardT RichString|] ''EncounterCard "EncounterCard"

     -- ConsequenceCard
     p_consequence2 <-
       makeProxyInstance [t|ConsequenceCardT DSLRule|] ''ConsequenceCard "ConsequenceCard"

     return
       ( i_attack
           ++ i_general
           ++ i_task
           ++ i_trigger
           ++ i_stance
           ++ i_channel
           ++ i_prime
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
           ++ p_item2
           ++ p_item3
           ++ p_nature2
           ++ p_nature3
           ++ p_talent2
           ++ p_talent3
           ++ p_encounter2
           ++ p_encounter3
           ++ p_consequence2
       )
 )

-- 3. Dependent Types (Must see ItemCard instance etc)
$( do
     -- State Types
     i_token <- deriveTypeScript cardpgJsonDef ''Token
     i_command <- deriveTypeScript cardpgJsonDef ''Command
     i_broadcast <- deriveTypeScript cardpgJsonDef ''BroadcastAction
     i_clientMsg <- deriveTypeScript cardpgJsonDef ''ClientMessage

     i_tableCard <- deriveTypeScript cardpgJsonDef ''TableCard
     i_corePlay <- deriveTypeScript cardpgJsonDef ''CorePlayState
     i_coreState <- deriveTypeScript cardpgJsonDef ''CoreCardState
     i_tableState <- deriveTypeScript cardpgJsonDef ''TableState
     i_assetState <- deriveTypeScript cardpgJsonDef ''AssetState
     i_actorState <- deriveTypeScript cardpgJsonDef ''ActorState
     i_gameEvent <- deriveTypeScript cardpgJsonDef ''GameEvent
     i_stateUpdate <- deriveTypeScript cardpgJsonDef ''StateUpdate
     i_serverMsg <- deriveTypeScript cardpgJsonDef ''ServerMessage

     return
       ( i_token
           ++ i_command
           ++ i_broadcast
           ++ i_clientMsg
           ++ i_serverMsg
           ++ i_tableCard
           ++ i_corePlay
           ++ i_coreState
           ++ i_tableState
           ++ i_assetState
           ++ i_actorState
           ++ i_gameEvent
           ++ i_stateUpdate
       )
 )
