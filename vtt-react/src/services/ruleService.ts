import { CoreCard, ResourceType, Stats, Card, ConsequenceCard } from '../types';

export const calculateStackStrength = (
  stack: CoreCard[],
  strengthColor: ResourceType,
  modifier: number = 0,
): number => {
  // Rule: Sum of color values in stack + modifier
  const key = strengthColor.toLowerCase() as keyof Stats;
  const base = stack.reduce((sum, card) => sum + (card.stats[key] ?? 0), 0);
  return base + modifier;
};

export const getAttributeValue = (equipped: Card[], stat: 'def' | 'res'): number => {
  let max = 0;
  let found = false;
  equipped.forEach((c) => {
    if (c.type === 'itemCard' || c.type === 'natureCard') {
      const val = stat === 'def' ? c.defense : c.resilience;
      if (val !== undefined && val !== null) {
        max = Math.max(max, val);
        found = true;
      }
    }
  });
  return found ? max : 1; // Default Res 1, Def 1
};

export const calculateSeverity = (consequences: ConsequenceCard[], resilience: number): number => {
  return Math.floor(consequences.length / resilience) + 1;
};
