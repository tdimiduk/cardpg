import { useMemo } from 'react';
import { PlayerDeckState } from '../types';
import { getAttributeValue, calculateSeverity } from '../services/ruleService';

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

export const useActorStats = (deckState: PlayerDeckState | null | undefined): ActorStats | null => {
  return useMemo(() => {
    if (!deckState) return null;

    const defenseTotal = {
      red: deckState.flippedPile.reduce((sum, c) => sum + (c.stats.red ?? 0), 0),
      yellow: deckState.flippedPile.reduce((sum, c) => sum + (c.stats.yellow ?? 0), 0),
      blue: deckState.flippedPile.reduce((sum, c) => sum + (c.stats.blue ?? 0), 0),
    };

    const defenseStat = getAttributeValue(deckState.equipped, 'def');
    const resilienceStat = getAttributeValue(deckState.equipped, 'res');

    const impact = deckState.flippedPile.length;
    const calculatedConsequences = Math.floor(impact / defenseStat);
    const currentSeverity = calculateSeverity(deckState.consequences, resilienceStat);

    return {
      defenseTotal,
      defenseStat,
      resilienceStat,
      impact,
      calculatedConsequences,
      currentSeverity,
    };
  }, [deckState]);
};
