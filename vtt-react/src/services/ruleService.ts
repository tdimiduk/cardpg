import { Card, ConsequenceCard } from '../types';


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
