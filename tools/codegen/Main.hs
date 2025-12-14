module Main where

import Data.Aeson.TypeScript.TH
import Data.List (intercalate)
import Data.Proxy
import Data.Text (pack, replace, unpack)
import System.Environment (getArgs)
import System.IO (writeFile)
import TypeScriptInstances
  ( ActorDefinition
  , AttackDef
  , ChannelDef
  , ConsequenceCard
  , CoreCard
  , EncounterCard
  , GeneralDef
  , ItemCard
  , NatureCard
  , PrimeDef
  , Rule
  , StanceDef
  , TalentCard
  , TaskDef
  , TriggerDef
  )

import CardPG.Core.Card (EncounterMechanics, GeneralActionDef, SpecialDefend, Stats)
import CardPG.Core.NonEmptyText (NonEmptyText)
import CardPG.Core.Primitives (ActorId, Difficulty, EquipSlot, ResourceType, StackPower)
import CardPG.Core.RichText (Block, Inline, RichString, RichText, TextStyle)
import CardPG.Core.RuleDefs (PassiveDef)
import CardPG.Core.State
  ( ActionStack
  , ActorState
  , AssetState
  , CoreCardState
  , CorePlayState
  , NarrativeStack
  , PlannedAction
  , RealizedAttack
  , SpatialState
  , TableCard
  , TableState
  )
import CardPG.Server.Types
  ( BroadcastAction
  , ClientMessage
  , Command
  , Phase
  , ServerMessage
  , StateUpdate
  , Token
  )

main :: IO ()
main = do
  args <- getArgs
  let outputFile = case args of
        (x : _) -> x
        [] -> "types.ts"

  let declarations =
        formatTSDeclarations
          ( getTypeScriptDeclarations (Proxy :: Proxy ResourceType)
              <> getTypeScriptDeclarations (Proxy :: Proxy StackPower)
              <> getTypeScriptDeclarations (Proxy :: Proxy Difficulty)
              <> getTypeScriptDeclarations (Proxy :: Proxy ActorId)
              <> getTypeScriptDeclarations (Proxy :: Proxy NonEmptyText)
              <> getTypeScriptDeclarations (Proxy :: Proxy TextStyle)
              <> getTypeScriptDeclarations (Proxy :: Proxy Inline)
              <> getTypeScriptDeclarations (Proxy :: Proxy RichText)
              <> getTypeScriptDeclarations (Proxy :: Proxy RichString)
              <> getTypeScriptDeclarations (Proxy :: Proxy Block)
              <> getTypeScriptDeclarations (Proxy :: Proxy PassiveDef)
              <> getTypeScriptDeclarations (Proxy :: Proxy AttackDef)
              <> getTypeScriptDeclarations (Proxy :: Proxy GeneralDef)
              <> getTypeScriptDeclarations (Proxy :: Proxy StanceDef)
              <> getTypeScriptDeclarations (Proxy :: Proxy ChannelDef)
              <> getTypeScriptDeclarations (Proxy :: Proxy PrimeDef)
              <> getTypeScriptDeclarations (Proxy :: Proxy TaskDef)
              <> getTypeScriptDeclarations (Proxy :: Proxy TriggerDef)
              <> getTypeScriptDeclarations (Proxy :: Proxy Rule)
              <> getTypeScriptDeclarations (Proxy :: Proxy Stats)
              <> getTypeScriptDeclarations (Proxy :: Proxy SpecialDefend)
              <> getTypeScriptDeclarations (Proxy :: Proxy CoreCard)
              <> getTypeScriptDeclarations (Proxy :: Proxy ItemCard)
              <> getTypeScriptDeclarations (Proxy :: Proxy NatureCard)
              <> getTypeScriptDeclarations (Proxy :: Proxy TalentCard)
              <> getTypeScriptDeclarations (Proxy :: Proxy GeneralActionDef)
              <> getTypeScriptDeclarations (Proxy :: Proxy EncounterMechanics)
              <> getTypeScriptDeclarations (Proxy :: Proxy EncounterCard)
              <> getTypeScriptDeclarations (Proxy :: Proxy ConsequenceCard)
              <> getTypeScriptDeclarations (Proxy :: Proxy ActorDefinition)
              <> getTypeScriptDeclarations (Proxy :: Proxy ActorState)
              <> getTypeScriptDeclarations (Proxy :: Proxy AssetState)
              <> getTypeScriptDeclarations (Proxy :: Proxy CoreCardState)
              <> getTypeScriptDeclarations (Proxy :: Proxy CorePlayState)
              <> getTypeScriptDeclarations (Proxy :: Proxy EquipSlot)
              <> getTypeScriptDeclarations (Proxy :: Proxy TableState)
              <> getTypeScriptDeclarations (Proxy :: Proxy TableCard)
              <> getTypeScriptDeclarations (Proxy :: Proxy Token)
              <> getTypeScriptDeclarations (Proxy :: Proxy BroadcastAction)
              <> getTypeScriptDeclarations (Proxy :: Proxy Command)
              <> getTypeScriptDeclarations (Proxy :: Proxy ClientMessage)
              <> getTypeScriptDeclarations (Proxy :: Proxy ServerMessage)
              <> getTypeScriptDeclarations (Proxy :: Proxy StateUpdate)
              <> getTypeScriptDeclarations (Proxy :: Proxy SpatialState)
              <> getTypeScriptDeclarations (Proxy :: Proxy ActionStack)
              <> getTypeScriptDeclarations (Proxy :: Proxy NarrativeStack)
              <> getTypeScriptDeclarations (Proxy :: Proxy PlannedAction)
              <> getTypeScriptDeclarations (Proxy :: Proxy RealizedAttack)
              <> getTypeScriptDeclarations (Proxy :: Proxy Phase)
          )

  let exportedDeclarations =
        unpack $
          replace "interface " "export interface " $
            replace "type " "export type " $
              pack declarations

  writeFile outputFile $
    "// Generated by cardpg-codegen. DO NOT EDIT.\n\n" ++ exportedDeclarations
