import { useMemo } from 'react';
import { CoreCard, ConsequenceCard } from '../generated/types';
import { EquipmentCard, getAttributeValue, calculateSeverity } from '../services/ruleService';

export interface ActorStats {
  defenseTotal: {
    red: number;
    yellow: number;
    blue: number;
  };
  defenseStat: number;
  resilienceStat: number;
  impact: number;
  calculatedConsequences: number;
  currentSeverity: number;
}

export const useActorStats = (
  flippedPile: CoreCard[] | undefined,
  equipped: EquipmentCard[] | undefined,
  consequences: ConsequenceCard[] | undefined,
): ActorStats | null => {
  return useMemo(() => {
    if (!flippedPile) return null; // Minimal check

    const defenseTotal = {
      red: flippedPile.reduce((sum, c) => sum + (c.stats.red ?? 0), 0),
      yellow: flippedPile.reduce((sum, c) => sum + (c.stats.yellow ?? 0), 0),
      blue: flippedPile.reduce((sum, c) => sum + (c.stats.blue ?? 0), 0),
    };

    const defenseStat = equipped ? getAttributeValue(equipped, 'def') : 1;
    const resilienceStat = equipped ? getAttributeValue(equipped, 'res') : 1;

    const impact = flippedPile.length;
    const calculatedConsequences = Math.floor(impact / defenseStat);
    const currentSeverity = consequences ? calculateSeverity(consequences, resilienceStat) : 0;

    return {
      defenseTotal,
      defenseStat,
      resilienceStat,
      impact,
      calculatedConsequences,
      currentSeverity,
    };
  }, [flippedPile, equipped, consequences]);
};
