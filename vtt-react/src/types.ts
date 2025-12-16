export * from './generated/types';

import {
  CoreCard as GenCoreCard,
  ItemCard as GenItemCard,
  NatureCard as GenNatureCard,
  TalentCard as GenTalentCard,
  EncounterCard as GenEncounterCard,
  ConsequenceCard as GenConsequenceCard,
  ActorState as ServerActorState,
  ActorDefinition as GenActorDefinition,
  RevealedEffect,
  PlannedAction,
  ResourceType,
  EquipSlot,
} from './generated/types';

import { z } from 'zod';

// Backward Compatibility Aliases
export type GamePhase = 'planning' | 'resolution';

// UI-Specific Enums
export enum TokenType {
  PC = 'PC',
  MONSTER = 'MONSTER',
  NPC = 'NPC',
}

// Extended Types with IDs for Frontend Use
export interface CoreCard extends GenCoreCard {
  id: string;
}

export interface ItemCard extends GenItemCard {
  id: string;
}

export interface NatureCard extends GenNatureCard {
  id: string;
}

export interface TalentCard extends GenTalentCard {
  id: string;
}

export interface EncounterCard extends GenEncounterCard {
  id: string;
}

export interface ConsequenceCard extends GenConsequenceCard {
  id: string;
}

export interface ActorDefinition extends GenActorDefinition {
  id: string; // Frontend always needs an ID for actors
}

// Union Type for logic that handles any card
// We use the Extended versions here
export type Card = CoreCard | ItemCard | NatureCard | TalentCard | EncounterCard | ConsequenceCard;

// Schemas
export const coreCardSchema = z.any();
export const actorDefinitionSchema = z.any();
export const serverMessageSchema = z.any();

// UI State Definitions

export interface PlayerDeckState {
  drawPile: CoreCard[];
  hand: CoreCard[];
  discardPile: CoreCard[];
  flippedPile: CoreCard[];
  equipped: Card[];
  consequences: ConsequenceCard[];
}

export interface UIPlannedAction {
  actorId: string;
  actorName: string;
  cards: CoreCard[];
  strengthColor: ResourceType;
  modifier: number;
  actionName: string;
  targetDefense?: ResourceType;
}

// Frontend ViewModel ActorState (overrides backend ActorState name collision)
export interface ActorState {
  id: string; // Token/Actor ID
  name: string;
  type: TokenType;
  color: string;

  // Flattened/Hydrated Deck State for UI
  deck: PlayerDeckState;

  // Spatial
  plannedMove?: { x: number; y: number };

  // Registry of expanded cards
  registry: Record<string, CoreCard | Card>;

  // Game State
  revealed?: RevealedEffect;
}
