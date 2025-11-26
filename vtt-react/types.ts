
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
    color: 'red' | 'yellow' | 'blue'; // The Strength Color
    targetColor?: 'red' | 'yellow' | 'blue'; // The Defense Color
    label: string;
  };
}

export interface GameState {
  tokens: Token[];
  logs: LogEntry[];
  gridSize: number;
  activeTokenId: string | null;
}

// --- Card System Types ---

export type CardColor = 'red' | 'yellow' | 'blue';

export type CardTextPart = 
  | { type: 'text'; content: string }
  | { type: 'icon'; color: CardColor };

export interface ActionDefinition {
  type: 'attack' | 'utility';
  strengthColor: CardColor;      // The attacker's attribute used (e.g., Blue for magic)
  targetDefenseColor?: CardColor; // The defender's attribute targeted (e.g., Red for fortitude)
  modifier: number;
}

export interface Card {
  id: string;
  name: string;
  // Stats are optional. undefined means the card has no stats (Item/Character).
  // 0 means it has 0 stats (Status/Injury).
  red?: number;
  yellow?: number;
  blue?: number;
  
  // Defensive Stats (derived from Items/Armor)
  def?: number; // Defense: How much Impact prevents a consequence
  res?: number; // Resilience: How many consequences before severity increases

  text: CardTextPart[];
  type: 'ability' | 'item' | 'fatigue' | 'wound';
  playCount?: number; // The number in top right (cards to play in stack). undefined = not an action.
  actionDefinition?: ActionDefinition; // Structured data for rules
}

export interface PlayerDeckState {
  drawPile: Card[];
  hand: Card[];
  discardPile: Card[];
  flippedPile: Card[]; // Cards flipped for defense
  equipped: Card[];    // Cards on the table (Items/Characters)
  consequences: Card[]; // Condition cards on the table (Wounds/Injuries)
}

// --- Phase & Planning ---

export type GamePhase = 'planning' | 'resolution';

export interface PlannedAction {
  actorId: string;
  actorName: string;
  cards: Card[];
  strengthColor: CardColor;
  modifier: number;
  targetDefense?: CardColor;
  actionName?: string;
  move?: {
      x: number;
      y: number;
  };
}
