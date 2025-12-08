import { z } from 'zod';
import { CoreCard, ItemCard } from './generated/types';

// Export all generated types and schemas
export * from './generated/types';
export * from './generated/types.zod';

import { coreCardSchema, itemCardSchema } from './generated/types.zod';

// --- Card Union ---
export const CardSchema = z.union([coreCardSchema, itemCardSchema]);
export type Card = CoreCard | ItemCard;

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
  consequences: import('./generated/types').ConsequenceCard[];
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
