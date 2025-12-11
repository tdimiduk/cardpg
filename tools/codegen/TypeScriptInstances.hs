{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module TypeScriptInstances where

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
import CardPG.Core.Json (cardpgJsonDef, cardpgJsonOptions, cardpgTaggedOptions)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.Primitives (CardInstanceId, Difficulty, EquipSlot (..), ResourceType (..), StackPower, TargetId)
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
  , TriggerDef
  )
import CardPG.Core.State
  ( ActorState (..)
  , AssetState (..)
  , CoreCardState (..)
  , CorePlayState (..)
  , GameEvent (..)
  , TableCard (..)
  , TableState (..)
  )
import CardPG.Server.Types (BroadcastAction (..), ClientMessage, Command (..), ServerMessage, StateUpdate (..), Token)
import qualified CardPG.Core.Card as CC
import DeriveSpecialized (makeBridgeInstance, makeProxyInstance, specializeType)

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
$(deriveTypeScript cardpgJsonDef ''NonEmptyText)

-- RichText
$(deriveTypeScript cardpgJsonDef ''TextStyle)
$(deriveTypeScript cardpgJsonDef ''Inline)
$(deriveTypeScript cardpgJsonDef ''RichText)
$(deriveTypeScript cardpgJsonDef ''RichString)
$(deriveTypeScript cardpgJsonDef ''Block)

-- Stats
$(deriveTypeScript cardpgJsonDef ''Stats)
$(deriveTypeScript cardpgJsonDef ''SpecialDefend)

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
     -- Rules & Bridges
     i_attack <- deriveTypeScript (cardpgJsonOptions "Rule") ''AttackDef
     b_attack <- makeBridgeInstance ''AttackDefT (AppT ListT (ConT ''Inline)) "AttackDef"

     i_general <- deriveTypeScript (cardpgJsonOptions "Rule") ''GeneralDef
     b_general <- makeBridgeInstance ''GeneralDefT (AppT ListT (ConT ''Inline)) "GeneralDef"

     i_task <- deriveTypeScript (cardpgJsonOptions "Rule") ''TaskDef
     b_task <- makeBridgeInstance ''TaskDefT (AppT ListT (ConT ''Inline)) "TaskDef"

     i_trigger <- deriveTypeScript (cardpgJsonOptions "Rule") ''TriggerDef
     b_trigger <- makeBridgeInstance ''TriggerDefT (AppT ListT (ConT ''Inline)) "TriggerDef"

     i_stance <- deriveTypeScript (cardpgJsonOptions "Rule") ''StanceDef
     b_stance <- makeBridgeInstance ''StanceDefT (AppT ListT (ConT ''Inline)) "StanceDef"

     i_channel <- deriveTypeScript (cardpgJsonOptions "Rule") ''ChannelDef
     b_channel <- makeBridgeInstance ''ChannelDefT (AppT ListT (ConT ''Inline)) "ChannelDef"

     i_prime <- deriveTypeScript (cardpgJsonOptions "Rule") ''PrimeDef
     b_prime <- makeBridgeInstance ''PrimeDefT (AppT ListT (ConT ''Inline)) "PrimeDef"

     -- Rule (Machine)
     i_rule <- deriveTypeScript (cardpgJsonOptions "RuleRule") ''Rule
     b_rule <- makeBridgeInstance ''RuleT (AppT ListT (ConT ''Inline)) "Rule"
     
     -- Def Helpers
     i_passive <- deriveTypeScript (cardpgJsonOptions "Rule") ''PassiveDef
     
     -- Helpers (GenAction, EncMech)
     i_genAction <- deriveTypeScript cardpgJsonDef ''GeneralActionDef
     i_encMech <- deriveTypeScript cardpgJsonDef ''EncounterMechanics

     i_core <- deriveTypeScript (cardpgTaggedOptions "") ''CoreCard
     i_item <- deriveTypeScript (cardpgTaggedOptions "") ''ItemCard
     i_nature <- deriveTypeScript (cardpgTaggedOptions "") ''NatureCard
     i_talent <- deriveTypeScript (cardpgTaggedOptions "") ''TalentCard
     i_encounter <- deriveTypeScript (cardpgTaggedOptions "") ''EncounterCard
     i_consequence <- deriveTypeScript (cardpgTaggedOptions "") ''ConsequenceCard
     i_actor <- deriveTypeScript cardpgJsonDef ''ActorDefinition
     

     -- Proxy Instances (Bridge original types to local specialized types)
     let inline = AppT ListT (ConT ''Inline)
     let richStr = ConT ''RichString
     let richTxt = ConT ''RichText
     let text = ConT ''Text
     let maybeText = AppT (ConT ''Maybe) (ConT ''Text)
     let dslRule = ConT ''DSLRule
     let rule = ConT ''Rule

     -- CoreCard
     p_core1 <- makeProxyInstance [t| CoreCardT Rule [Inline] |] ''CoreCard "CoreCard"
     p_core2 <- makeProxyInstance [t| CoreCardT DSLRule RichString |] ''CoreCard "CoreCard"

     -- ActorDefinition
     p_actor <- makeProxyInstance [t| ActorDefinitionT DSLRule RichString |] ''ActorDefinition "ActorDefinition"
     
     -- ItemCard
     p_item1 <- makeProxyInstance [t| ItemCardT [Inline] |] ''ItemCard "ItemCard"
     p_item2 <- makeProxyInstance [t| ItemCardT RichText |] ''ItemCard "ItemCard"
     p_item3 <- makeProxyInstance [t| ItemCardT RichString |] ''ItemCard "ItemCard"

     -- NatureCard
     p_nature1 <- makeProxyInstance [t| NatureCardT [Inline] |] ''NatureCard "NatureCard"
     p_nature2 <- makeProxyInstance [t| NatureCardT RichText |] ''NatureCard "NatureCard"
     p_nature3 <- makeProxyInstance [t| NatureCardT RichString |] ''NatureCard "NatureCard"

     -- TalentCard
     p_talent1 <- makeProxyInstance [t| TalentCardT [Inline] |] ''TalentCard "TalentCard"
     p_talent2 <- makeProxyInstance [t| TalentCardT RichText |] ''TalentCard "TalentCard"
     p_talent3 <- makeProxyInstance [t| TalentCardT RichString |] ''TalentCard "TalentCard"

     -- EncounterCard
     p_encounter1 <- makeProxyInstance [t| EncounterCardT [Inline] |] ''EncounterCard "EncounterCard"
     p_encounter2 <- makeProxyInstance [t| EncounterCardT RichText |] ''EncounterCard "EncounterCard"
     p_encounter3 <- makeProxyInstance [t| EncounterCardT RichString |] ''EncounterCard "EncounterCard"

     -- ConsequenceCard
     p_consequence1 <- makeProxyInstance [t| ConsequenceCardT Rule |] ''ConsequenceCard "ConsequenceCard"
     p_consequence2 <- makeProxyInstance [t| ConsequenceCardT DSLRule |] ''ConsequenceCard "ConsequenceCard"
      
     return
       ( i_attack
           ++ b_attack
           ++ i_general
           ++ b_general
           ++ i_task
           ++ b_task
           ++ i_trigger
           ++ b_trigger
           ++ i_stance
           ++ b_stance
           ++ i_channel
           ++ b_channel
           ++ i_prime
           ++ b_prime
           ++ i_rule
           ++ b_rule
           ++ i_passive
           
           ++ i_genAction
           ++ i_encMech
           ++ i_core
           ++ i_item
           ++ i_nature
           ++ i_talent
           ++ i_encounter
           ++ i_consequence
           ++ i_actor
           
           ++ p_core1 ++ p_core2
           ++ p_actor
           ++ p_item1 ++ p_item2 ++ p_item3
           ++ p_nature1 ++ p_nature2 ++ p_nature3
           ++ p_talent1 ++ p_talent2 ++ p_talent3
           ++ p_encounter1 ++ p_encounter2 ++ p_encounter3
           ++ p_consequence1 ++ p_consequence2
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


