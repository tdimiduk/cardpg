{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module TypeScriptInstances where

import Data.Aeson.TypeScript.TH
import Language.Haskell.TH (Type(ConT, AppT, ListT), mkName)

import GHC.Generics (Generic)
import Data.Proxy (Proxy(..))
import Data.Text (Text)
import Data.List.NonEmpty (NonEmpty)

import DeriveSpecialized (specializeType, specializeType2, makeBridgeInstance)
import CardPG.Core.Json (cardpgJsonDef, cardpgTaggedOptions, cardpgJsonOptions)
import CardPG.Core.Types (ResourceType(..), StackPower, Difficulty)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.RichText (TextStyle, Inline, RichString, RichText, Block)
import CardPG.Core.RuleDefs hiding (Rule, AttackDef, GeneralDef, TaskDef, TriggerDef, StanceDef, ChannelDef, PrimeDef) 
import CardPG.Core.Card (Stats, ItemCardT(..), NatureCardT(..), TalentCardT(..), GeneralActionDef, EncounterMechanics, EncounterCardT(..), ConsequenceCardT(..), ActorT(..), CoreCardT(..))
import CardPG.Server.Types (ClientMessage, ServerMessage)

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

-- Helper for creating splices
-- Using runIO or just simple do block
-- We separate Data Generation (Specialize) from Instance Generation

-- 1. Data Generation Scope
$(do
  d_attack <- specializeType ''AttackDefT (AppT ListT (ConT ''Inline)) "AttackDef"
  d_general <- specializeType ''GeneralDefT (AppT ListT (ConT ''Inline)) "GeneralDef"
  d_task <- specializeType ''TaskDefT (AppT ListT (ConT ''Inline)) "TaskDef"
  d_trigger <- specializeType ''TriggerDefT (AppT ListT (ConT ''Inline)) "TriggerDef"
  d_stance <- specializeType ''StanceDefT (AppT ListT (ConT ''Inline)) "StanceDef"
  d_channel <- specializeType ''ChannelDefT (AppT ListT (ConT ''Inline)) "ChannelDef"
  d_prime <- specializeType ''PrimeDefT (AppT ListT (ConT ''Inline)) "PrimeDef"
  d_rule <- specializeType ''RuleT (AppT ListT (ConT ''Inline)) "Rule"
  
  d_core <- specializeType2 ''CoreCardT (ConT (mkName "Rule")) (AppT ListT (ConT ''Inline)) "CoreCard"
  d_actor <- specializeType2 ''ActorT (ConT (mkName "Rule")) (AppT ListT (ConT ''Inline)) "Actor"
  
  d_item <- specializeType ''ItemCardT (AppT ListT (ConT ''Inline)) "ItemCard"
  d_nature <- specializeType ''NatureCardT (AppT ListT (ConT ''Inline)) "NatureCard"
  d_talent <- specializeType ''TalentCardT (AppT ListT (ConT ''Inline)) "TalentCard"
  d_encounter <- specializeType ''EncounterCardT (AppT ListT (ConT ''Inline)) "EncounterCard"
  d_consequence <- specializeType ''ConsequenceCardT (ConT (mkName "Rule")) "ConsequenceCard"
  
  return (d_attack ++ d_general ++ d_task ++ d_trigger ++ d_stance 
          ++ d_channel ++ d_prime ++ d_rule ++ d_core ++ d_actor 
          ++ d_item ++ d_nature ++ d_talent ++ d_encounter ++ d_consequence)
 )

-- 2. Instance Generation Scope (Mutually Recursive)
$(do
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
  b_item <- makeBridgeInstance ''ItemCardT (AppT ListT (ConT ''Inline)) "ItemCard"
  
  i_nature <- deriveTypeScript cardpgJsonDef ''NatureCard
  b_nature <- makeBridgeInstance ''NatureCardT (AppT ListT (ConT ''Inline)) "NatureCard"
  
  i_talent <- deriveTypeScript cardpgJsonDef ''TalentCard
  b_talent <- makeBridgeInstance ''TalentCardT (AppT ListT (ConT ''Inline)) "TalentCard"
  
  i_encounter <- deriveTypeScript cardpgJsonDef ''EncounterCard
  b_encounter <- makeBridgeInstance ''EncounterCardT (AppT ListT (ConT ''Inline)) "EncounterCard"

  i_consequence <- deriveTypeScript (cardpgTaggedOptions "") ''ConsequenceCard
  b_consequence <- makeBridgeInstance ''ConsequenceCardT (ConT (mkName "Rule")) "ConsequenceCard"
  
  i_actor <- deriveTypeScript cardpgJsonDef ''Actor
  
  -- Helpers
  i_genAction <- deriveTypeScript cardpgJsonDef ''GeneralActionDef
  i_encMech <- deriveTypeScript cardpgJsonDef ''EncounterMechanics
  
  return (i_attack ++ b_attack ++ i_general ++ b_general ++ i_task ++ b_task 
          ++ i_trigger ++ b_trigger ++ i_stance ++ b_stance ++ i_channel ++ b_channel 
          ++ i_prime ++ b_prime ++ i_rule ++ b_rule ++ i_passive 
          ++ i_core ++ i_item ++ b_item ++ i_nature ++ b_nature ++ i_talent 
          ++ b_talent ++ i_encounter ++ b_encounter ++ i_consequence ++ b_consequence 
          ++ i_actor ++ i_genAction ++ i_encMech)
 )

instance TypeScript (CoreCardT Rule [Inline]) where
  getTypeScriptType _ = "CoreCard"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy CoreCard)]

instance TypeScript (CoreCardT DSLRule RichString) where
  getTypeScriptType _ = "CoreCard"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy CoreCard)]

instance TypeScript (ActorT DSLRule RichString) where
  getTypeScriptType _ = "Actor"
  getTypeScriptDeclarations _ = []
  getParentTypes _ = [TSType (Proxy :: Proxy Actor)]
