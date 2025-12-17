import { ConsequenceCard, ItemCard, NatureCard, TalentCard } from '../generated/types';

export type EquipmentCard = ItemCard | NatureCard | TalentCard;

export const getAttributeValue = (equipped: EquipmentCard[], stat: 'def' | 'res'): number => {
  let max = 0;
  let found = false;
  equipped.forEach((c) => {
    // Check if card has the stat
    let val: number | undefined | null;

    if (stat === 'def') {
      if ('defense' in c) val = c.defense;
    } else {
      if ('resilience' in c) val = c.resilience;
    }

    if (val !== undefined && val !== null) {
      max = Math.max(max, val);
      found = true;
    }
  });
  return found ? max : 1; // Default Res 1, Def 1
};

export const calculateSeverity = (consequences: ConsequenceCard[], resilience: number): number => {
  return Math.floor(consequences.length / resilience) + 1;
};
