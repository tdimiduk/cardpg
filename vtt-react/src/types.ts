import { z } from 'zod';
import {
  CoreCard as GenCoreCard,
  ItemCard as GenItemCard,
  NatureCard as GenNatureCard,
  TalentCard as GenTalentCard,
  ConsequenceCard as GenConsequenceCard,
  ActorDefinition as GenActorDefinition,
} from './generated/types';

export type CoreCard = GenCoreCard & { id: string };
export type ItemCard = GenItemCard & { id: string };
export type NatureCard = GenNatureCard & { id: string };
export type TalentCard = GenTalentCard & { id: string };
export type ConsequenceCard = GenConsequenceCard & { id: string };
export type ActorDefinition = GenActorDefinition & { id: string };

// Export all generated types and schemas
export * from './generated/types';
export * from './generated/types.zod';

import {
  coreCardSchema,
  itemCardSchema,
  natureCardSchema,
  talentCardSchema,
} from './generated/types.zod';

// --- Card Union ---
export const TableCardSchema = z.union([itemCardSchema, natureCardSchema, talentCardSchema]);
export type TableCard = ItemCard | NatureCard | TalentCard;

export const CardSchema = z.union([coreCardSchema, TableCardSchema]);
export type Card = CoreCard | TableCard;

// --- Legacy / Game State Types ---

export enum TokenType {
  PC = 'PC',
  NPC = 'NPC',
  MONSTER = 'MONSTER',
}

// Frontend Actor State
export interface ActorState {
  id: string;
  name: string;
  type: TokenType;
  color: string;
  deck: PlayerDeckState;
  plannedMove?: { x: number; y: number };
}

export interface LogEntry {
  id: string;
  timestamp: number;
  sender: 'System' | 'GM' | 'Player' | 'AI';
  content: string;
  type: 'chat' | 'action' | 'info';
  actionResult?: {
    total: number;
    color: import('./generated/types').ResourceType;
    targetColor?: import('./generated/types').ResourceType;
    label: string;
  };
}

export interface GameState {
  actors: Record<string, ActorState>;
  tokens: import('./generated/types').Token[];
  logs: LogEntry[];
  gridSize: number;
  activeTokenId: string | null;
}

export interface PlayerDeckState {
  drawPile: CoreCard[];
  hand: CoreCard[];
  discardPile: CoreCard[];
  flippedPile: CoreCard[];
  equipped: Card[];
  consequences: ConsequenceCard[];
}

export type GamePhase = 'planning' | 'resolution';

export interface PlannedAction {
  actorId: string;
  actorName: string;
  cards: CoreCard[];
  strengthColor: import('./generated/types').ResourceType;
  modifier: number;
  targetDefense?: import('./generated/types').ResourceType;
  actionName?: string;
  move?: {
    x: number;
    y: number;
  };
}
