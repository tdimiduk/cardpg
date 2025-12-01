import { z } from 'zod';

// --- Core Enums ---

export const ResourceTypeSchema = z.enum(['Red', 'Yellow', 'Blue']);
export type ResourceType = z.infer<typeof ResourceTypeSchema>;

export const StackPowerSchema = z.object({
  source: ResourceTypeSchema,
  modifier: z.number(),
});
export type StackPower = z.infer<typeof StackPowerSchema>;

// --- Rich Text ---

export const TextStyleSchema = z.enum(['Bold', 'Italic', 'GameKeyword']);
export type TextStyle = z.infer<typeof TextStyleSchema>;

export const TextRunSchema = z.object({
  type: z.literal('textRun'),
  content: z.string(),
  style: TextStyleSchema.optional().nullable(),
});

export const IconSchema = z.object({
  type: z.literal('icon'),
  color: ResourceTypeSchema,
});

export const DynamicValSchema = z.object({
  type: z.literal('dynamicVal'),
  value: StackPowerSchema,
});

export const BreakSchema = z.object({
  type: z.literal('break'),
});

export const InlineSchema = z.discriminatedUnion('type', [
  TextRunSchema,
  IconSchema,
  DynamicValSchema,
  BreakSchema,
]);
export type Inline = z.infer<typeof InlineSchema>;

export const RichStringSchema = z.array(InlineSchema);
export type RichString = z.infer<typeof RichStringSchema>;

// --- Rules ---

export const AttackDefSchema = z.object({
  power: StackPowerSchema,
  resistedBy: ResourceTypeSchema,
  effect: RichStringSchema.optional().nullable(),
});

export const DefendDefSchema = z.object({
  power: StackPowerSchema,
  resists: z.array(ResourceTypeSchema),
  effect: RichStringSchema.optional().nullable(),
});

export const GeneralDefSchema = z.object({
  power: StackPowerSchema.optional().nullable(),
  cost: RichStringSchema.optional().nullable(),
  effect: RichStringSchema,
});

export const StanceDefSchema = z.object({
  duration: z.string(),
});

export const ChannelDefSchema = z.object({
  duration: z.string(),
});

// Recursive definition for Prime (reaction is a Rule)
export const PrimeDefSchema = z.object({
  trigger: z.string(),
  reaction: z.lazy(() => RuleSchema),
});

export const PassiveDefSchema = z.object({
  bonus: StackPowerSchema,
  condition: z.string().optional().nullable(),
});

export const RuleSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('attack'), data: AttackDefSchema }),
  z.object({ type: z.literal('defend'), data: DefendDefSchema }),
  z.object({ type: z.literal('general'), data: GeneralDefSchema }),
  z.object({ type: z.literal('stance'), data: StanceDefSchema }),
  z.object({ type: z.literal('channel'), data: ChannelDefSchema }),
  z.object({ type: z.literal('prime'), data: PrimeDefSchema }),
  z.object({ type: z.literal('narrative'), data: RichStringSchema }),
  z.object({ type: z.literal('passive'), data: PassiveDefSchema }),
]);
export type Rule = z.infer<typeof RuleSchema>;

// --- Card ---

export const StatsSchema = z.object({
  red: z.number(),
  yellow: z.number(),
  blue: z.number(),
});
export type Stats = z.infer<typeof StatsSchema>;

export const CoreCardSchema = z.object({
  type: z.literal('core'),
  id: z.string(),
  name: z.string(),
  tags: z.array(z.string()).optional(),
  stats: StatsSchema,
  cost: z.number().optional().nullable(),
  rules: z.array(RuleSchema).optional(),
  flavor: RichStringSchema.optional().nullable(),
});
export type CoreCard = z.infer<typeof CoreCardSchema>;

export const ItemCardSchema = z.object({
  type: z.literal('item'),
  id: z.string(),
  name: z.string(),
  tags: z.array(z.string()).optional(),
  flavor: RichStringSchema.optional().nullable(),
  weight: z.number().optional().nullable(),
  value: z.number().optional().nullable(),
  traits: z.array(z.string()).optional(),
  passive: z.string().optional().nullable(),
  defense: z.number().optional().nullable(),
  resilience: z.number().optional().nullable(),
});
export type ItemCard = z.infer<typeof ItemCardSchema>;

export const CardSchema = z.discriminatedUnion('type', [
  CoreCardSchema,
  ItemCardSchema,
]);
export type Card = z.infer<typeof CardSchema>;

// --- Legacy / Game State Types (Preserved but updated where possible) ---

export enum TokenType {
  PC = 'PC',
  NPC = 'NPC',
  MONSTER = 'MONSTER'
}

export interface Token {
  id: string;
  name: string;
  x: number;
  y: number;
  color: string;
  type: TokenType;
  imageUrl?: string;
  size: number;
}

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
  tokens: Token[];
  logs: LogEntry[];
  gridSize: number;
  activeTokenId: string | null;
}

export interface PlayerDeckState {
  drawPile: CoreCard[];
  hand: CoreCard[];
  discardPile: CoreCard[];
  flippedPile: CoreCard[]; // Cards flipped for defense
  equipped: CoreCard[];    // Cards on the table (Items/Characters)
  consequences: CoreCard[]; // Condition cards on the table (Wounds/Injuries)
}

// --- Phase & Planning ---

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

// Re-export Card as CoreCard for compatibility during refactor, 
// or explicitly use CoreCard in new code.
// Re-export Card as CoreCard for compatibility during refactor, 
// or explicitly use CoreCard in new code.
// export type Card = CoreCard; // Removed, using the discriminated union above
