import { CardTextPart, ActionDefinition, CardColor } from '../types';
import { STARTER_DECK_DATA, ITEM_DATA, MONSTER_DECK_DATA, CardDefinition } from './cardDefinitions';

// --- Helpers for Generated Files ---

export const T = (content: string): CardTextPart => ({ type: 'text', content });
export const I = (color: CardColor): CardTextPart => ({ type: 'icon', color });

export const createCardTemplate = (
    name: string,
    red: number | undefined,
    yellow: number | undefined,
    blue: number | undefined,
    text: CardTextPart[],
    playCount: number | undefined,
    actionDefinition: ActionDefinition | undefined,
    type: 'ability' | 'item' | 'fatigue' | 'wound',
    stats?: { def?: number, res?: number }
): CardDefinition => ({
    name, 
    red, 
    yellow, 
    blue, 
    text, 
    playCount, 
    actionDefinition, 
    type, 
    def: stats?.def, 
    res: stats?.res
});

// --- Exports ---

export const STARTER_DECK_TEMPLATES = STARTER_DECK_DATA;
export const PERMANENT_CARDS = ITEM_DATA;
export const LIZARD_DECK_TEMPLATES = MONSTER_DECK_DATA;
