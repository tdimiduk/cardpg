import { z } from 'zod';
import * as Gen from './generated/types';
import * as GenSchemas from './generated/schemas';

// --- Core Enums ---
export const ResourceTypeSchema = GenSchemas.resourceTypeSchema;
export type ResourceType = Gen.ResourceType;

export const StackPowerSchema = GenSchemas.stackPowerSchema;
export type StackPower = Gen.StackPower;

// --- Rich Text ---
export const TextStyleSchema = GenSchemas.textStyleSchema;
export type TextStyle = Gen.TextStyle;

export const InlineSchema = GenSchemas.inlineSchema;
export type Inline = Gen.Inline;

export const RichStringSchema = GenSchemas.richStringSchema;
export type RichString = Gen.RichString;

// --- Rules ---
export type Rule = Gen.Rule;
export const RuleSchema = GenSchemas.ruleSchema;

// --- Card ---
export const StatsSchema = GenSchemas.statsSchema;
export type Stats = Gen.Stats;

// Extend generated schemas to include the discriminator 'type'
export const CoreCardSchema = GenSchemas.coreCardSchema.and(
  z.object({
    type: z.literal('core'),
    id: z.string(),
  }),
);
export type CoreCard = Gen.CoreCard & { type: 'core'; id: string };

export const ItemCardSchema = GenSchemas.itemCardSchema.and(
  z.object({
    type: z.literal('item'),
    id: z.string(),
  }),
);
export type ItemCard = Gen.ItemCard & { type: 'item'; id: string };

export const CardSchema = z.union([CoreCardSchema, ItemCardSchema]);
export type Card = CoreCard | ItemCard;

// --- Legacy / Game State Types ---

export enum TokenType {
  PC = 'PC',
  NPC = 'NPC',
  MONSTER = 'MONSTER',
}

// Frontend Actor State
export interface Actor {
  id: string;
  name: string;
  type: TokenType;
  color: string;
  deck: PlayerDeckState;
}

// Generated Actor Data (renamed to avoid conflict)
export type ActorData = Gen.Actor;
export const ActorDataSchema = GenSchemas.actorSchema;

export const TokenSchema = z.object({
  id: z.string(),
  actorId: z.string(),
  x: z.number(),
  y: z.number(),
  size: z.number(),
});
export type Token = z.infer<typeof TokenSchema>;

export interface LogEntry {
  id: string;
  timestamp: number;
  sender: 'System' | 'GM' | 'Player' | 'AI';
  content: string;
  type: 'chat' | 'action' | 'info';
  actionResult?: {
    total: number;
    color: ResourceType;
    targetColor?: ResourceType;
    label: string;
  };
}

export interface GameState {
  actors: Record<string, Actor>;
  tokens: Token[];
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
  consequences: CoreCard[];
}

export type GamePhase = 'planning' | 'resolution';

export interface PlannedAction {
  actorId: string;
  actorName: string;
  cards: CoreCard[];
  strengthColor: ResourceType;
  modifier: number;
  targetDefense?: ResourceType;
  actionName?: string;
  move?: {
    x: number;
    y: number;
  };
}
