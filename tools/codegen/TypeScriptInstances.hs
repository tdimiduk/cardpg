{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
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
import CardPG.Core.Primitives (Difficulty, ResourceType (..), StackPower)
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
import CardPG.Server.Types (BroadcastAction (..), ClientMessage, ServerMessage, Token)
import DeriveSpecialized (makeBridgeInstance, specializeType, specializeType2, specializeType3)

instance TypeScript DSLRule where
  getTypeScriptType _ = "string"

-- Basic Types
$(deriveTypeScript cardpgJsonDef ''ResourceType)
$(deriveTypeScript cardpgJsonDef ''StackPower)
$(deriveTypeScript cardpgJsonDef ''Difficulty)

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
     d_attack <- specializeType ''AttackDefT (AppT ListT (ConT ''Inline)) "AttackDef"
     d_general <- specializeType ''GeneralDefT (AppT ListT (ConT ''Inline)) "GeneralDef"
     d_task <- specializeType ''TaskDefT (AppT ListT (ConT ''Inline)) "TaskDef"
     d_trigger <- specializeType ''TriggerDefT (AppT ListT (ConT ''Inline)) "TriggerDef"
     d_stance <- specializeType ''StanceDefT (AppT ListT (ConT ''Inline)) "StanceDef"
     d_channel <- specializeType ''ChannelDefT (AppT ListT (ConT ''Inline)) "ChannelDef"
     d_prime <- specializeType ''PrimeDefT (AppT ListT (ConT ''Inline)) "PrimeDef"
     d_rule <- specializeType ''RuleT (AppT ListT (ConT ''Inline)) "Rule"

     d_core <-
       specializeType3
         ''CoreCardT
         (ConT ''Text)
         (ConT (mkName "Rule"))
         (AppT ListT (ConT ''Inline))
         "CoreCard"
     d_actor <-
       specializeType3
         ''ActorDefinitionT
         (ConT ''Text)
         (ConT (mkName "Rule"))
         (AppT ListT (ConT ''Inline))
         "ActorDefinition"

     d_item <- specializeType2 ''ItemCardT (ConT ''Text) (AppT ListT (ConT ''Inline)) "ItemCard"
     d_nature <- specializeType2 ''NatureCardT (ConT ''Text) (AppT ListT (ConT ''Inline)) "NatureCard"
     d_talent <- specializeType2 ''TalentCardT (ConT ''Text) (AppT ListT (ConT ''Inline)) "TalentCard"
     d_encounter <-
       specializeType2 ''EncounterCardT (ConT ''Text) (AppT ListT (ConT ''Inline)) "EncounterCard"
     d_consequence <-
       specializeType2 ''ConsequenceCardT (ConT ''Text) (ConT (mkName "Rule")) "ConsequenceCard"

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

-- 2. Instance Generation Scope (Mutually Recursive)
$( do
     -- Defs
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

     -- Cards
     i_core <- deriveTypeScript (cardpgTaggedOptions "") ''CoreCard
     i_item <- deriveTypeScript (cardpgTaggedOptions "") ''ItemCard
     -- b_item moved to manual instance

     i_nature <- deriveTypeScript (cardpgTaggedOptions "") ''NatureCard
     -- b_nature moved to manual instance

     i_talent <- deriveTypeScript (cardpgTaggedOptions "") ''TalentCard
     -- b_talent moved to manual instance

     i_encounter <- deriveTypeScript (cardpgTaggedOptions "") ''EncounterCard
     -- b_encounter moved to manual instance

     i_consequence <- deriveTypeScript (cardpgTaggedOptions "") ''ConsequenceCard
     -- b_consequence moved to manual instance

     i_actor <- deriveTypeScript cardpgJsonDef ''ActorDefinition

     -- Helpers
     i_genAction <- deriveTypeScript cardpgJsonDef ''GeneralActionDef
     i_encMech <- deriveTypeScript cardpgJsonDef ''EncounterMechanics

     -- Server Types
     i_token <- deriveTypeScript cardpgJsonDef ''Token
     i_broadcast <- deriveTypeScript cardpgJsonDef ''BroadcastAction
     i_clientMsg <- deriveTypeScript cardpgJsonDef ''ClientMessage
     i_serverMsg <- deriveTypeScript cardpgJsonDef ''ServerMessage

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
           ++ i_core
           ++ i_item
           ++ i_nature
           ++ i_talent
           ++ i_encounter
           ++ i_consequence
           ++ i_actor
           ++ i_genAction
           ++ i_encMech
           ++ i_token
           ++ i_broadcast
           ++ i_clientMsg
           ++ i_serverMsg
       )
 )

instance TypeScript (CoreCardT Text Rule [Inline]) where
  getTypeScriptType _ = "CoreCard"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy CoreCard)]

instance TypeScript (CoreCardT (Maybe Text) DSLRule RichString) where
  getTypeScriptType _ = "CoreCard"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy CoreCard)]

instance TypeScript (ActorDefinitionT Text Rule [Inline]) where
  getTypeScriptType _ = "ActorDefinition"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy ActorDefinition)]

instance TypeScript (ItemCardT Text [Inline]) where
  getTypeScriptType _ = "ItemCard"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy ItemCard)]

instance TypeScript (NatureCardT Text [Inline]) where
  getTypeScriptType _ = "NatureCard"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy NatureCard)]

instance TypeScript (TalentCardT Text [Inline]) where
  getTypeScriptType _ = "TalentCard"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy TalentCard)]

instance TypeScript (EncounterCardT Text [Inline]) where
  getTypeScriptType _ = "EncounterCard"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy EncounterCard)]

instance TypeScript (ConsequenceCardT Text Rule) where
  getTypeScriptType _ = "ConsequenceCard"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy ConsequenceCard)]
