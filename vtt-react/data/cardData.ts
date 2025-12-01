import { Inline, ResourceType } from '../types';

// --- Helpers for Generated Files ---

export const T = (content: string): Inline => ({ type: 'textRun', content });
export const I = (color: ResourceType): Inline => ({ type: 'colorValue', value: { source: color, modifier: 0, conditional: null } });



// --- Exports ---


