import { Inline, ResourceType } from '../types';
import { STARTER_DECK_DATA, ITEM_DATA, MONSTER_DECK_DATA, CardDefinition, LegacyActionDefinition } from './cardDefinitions';

// --- Helpers for Generated Files ---

export const T = (content: string): Inline => ({ type: 'textRun', content });
export const I = (color: ResourceType): Inline => ({ type: 'colorValue', value: { source: color, modifier: 0, conditional: null } });

export const createCardTemplate = (
    name: string,
    red: number | undefined,
    yellow: number | undefined,
    blue: number | undefined,
    text: Inline[],
    playCount: number | undefined,
    actionDefinition: LegacyActionDefinition | undefined,
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
