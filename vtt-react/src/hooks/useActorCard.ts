import { useGameStore } from '../store/gameStore';
import { CoreCard, TableCard, ConsequenceCard } from '../generated/types';

// Union of all possible "Card" types the application might handle polymorphically
export type AnyCard = CoreCard | TableCard | ConsequenceCard;

export function useActorCoreCard(actorId: string, cardId: string): CoreCard | undefined {
  return useGameStore((state) => {
    const actor = state.actors[actorId];
    return actor?.coreState.registry[cardId];
  });
}

export function useActorTableCard(actorId: string, cardId: string): TableCard | undefined {
  return useGameStore((state) => {
    const actor = state.actors[actorId];
    if (!actor) return undefined;

    // Check standard table registry - which returns TableCard (wrappers)
    const tableCard = actor.tableState.registry[cardId];
    if (tableCard) return tableCard;

    // Check consequence registry - returns ConsequenceCard (unwrapped)
    // We wrap it in tCConsequence to maintain consistent TableCard return type
    const consequence = actor.tableState.consequenceRegistry[cardId];
    if (consequence) {
      return { type: 'tCConsequence', data: consequence };
    }

    return undefined;
  });
}

export function useActorCard(actorId: string, cardId: string): AnyCard | undefined {
  const core = useActorCoreCard(actorId, cardId);
  if (core) return core;
  return useActorTableCard(actorId, cardId);
}
