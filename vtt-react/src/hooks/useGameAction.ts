import { useCallback } from 'react';
import { useGameStore } from '../store/gameStore';
import { BroadcastAction } from '../types';

function assertUnreachable(_x: never): never {
  throw new Error("Didn't expect to get here");
}

/**
 * Hook to apply game actions to the local store.
 *
 * @internal DO NOT USE DIRECTLY. Use useGameDispatch instead to ensure synchronization.
 */
export const useGameAction = () => {
  // Store actions
  const commitPlan = useGameStore((state) => state.commitPlan);
  const playImmediate = useGameStore((state) => state.playImmediate);
  const passTurn = useGameStore((state) => state.passTurn);
  const revealAndResolve = useGameStore((state) => state.revealAndResolve);
  const endRound = useGameStore((state) => state.endRound);
  const updateTokenPosition = useGameStore((state) => state.updateTokenPosition);
  const drawCards = useGameStore((state) => state.drawCards);
  const defend = useGameStore((state) => state.defend);
  const clearDefense = useGameStore((state) => state.clearDefense);
  const reshuffle = useGameStore((state) => state.reshuffle);
  const addConsequence = useGameStore((state) => state.addConsequence);
  const removeConsequence = useGameStore((state) => state.removeConsequence);
  const addStatus = useGameStore((state) => state.addStatus);
  const removeStatus = useGameStore((state) => state.removeStatus);
  const discardCards = useGameStore((state) => state.discardCards);
  const cancelPlan = useGameStore((state) => state.cancelPlan);
  const returnToDeck = useGameStore((state) => state.returnToDeck);

  const _applyAction = useCallback(
    (action: BroadcastAction) => {
      switch (action.type) {
        case 'playStack': {
          const state = useGameStore.getState();
          const token = state.tokens.find((t) => t.id === action.activeTokenId);
          const actor = token ? state.actors[token.actorId] : undefined;

          // Hydrate cards with IDs from hand if possible
          // We need to track used IDs to avoid mapping same hand-card to multiple action-cards
          const usedIds = new Set<string>();

          const hydratedCards = action.selectedCards.map((c) => {
            if (actor) {
              // Find a card in hand that matches name and hasn't been used yet
              const match = actor.deck.hand.find((h) => h.name === c.name && !usedIds.has(h.id));
              if (match) {
                usedIds.add(match.id);
                return match;
              }
            }
            // Fallback: Use server definition but add a fake ID to satisfy type reqs
            // This is safe because server state update will overwrite the hand authoritatively anyway.
            return { ...c, id: `broadcast-${Math.random()}` };
          });

          if (action.phase === 'planning') {
            commitPlan(
              action.activeTokenId,
              hydratedCards,
              action.strengthColor,
              action.modifier,
              action.actionName,
              action.targetDefense,
            );
          } else {
            playImmediate(
              action.activeTokenId,
              hydratedCards,
              action.strengthColor,
              action.modifier,
              action.actionName,
              action.targetDefense,
            );
          }
          break;
        }
        case 'pass':
          passTurn(action.activeTokenId);
          break;
        case 'reveal':
          revealAndResolve();
          break;
        case 'endRound':
          endRound();
          break;
        case 'moveToken':
          updateTokenPosition(action.token);
          break;
        case 'drawCards':
          drawCards(action.activeTokenId, action.count);
          break;
        case 'defend':
          defend(action.activeTokenId);
          break;
        case 'clearDefense':
          clearDefense(action.activeTokenId);
          break;
        case 'reshuffle':
          reshuffle(action.activeTokenId);
          break;
        case 'addConsequence':
          addConsequence(action.activeTokenId);
          break;
        case 'removeConsequence':
          removeConsequence(action.activeTokenId, action.cardId);
          break;
        case 'addStatus':
          addStatus(
            action.activeTokenId,
            action.statusType,
            action.destination as 'discard' | 'hand' | 'draw',
          );
          break;
        case 'removeStatus':
          removeStatus(action.activeTokenId, action.statusType);
          break;
        case 'discardCards':
          discardCards(action.activeTokenId, action.cardIds);
          break;
        case 'cancelPlan':
          cancelPlan(action.activeTokenId);
          break;
        case 'returnToDeck':
          returnToDeck(action.activeTokenId, action.cardIds);
          break;
        default:
          assertUnreachable(action);
      }
    },
    [
      commitPlan,
      playImmediate,
      passTurn,
      revealAndResolve,
      endRound,
      updateTokenPosition,
      drawCards,
      defend,
      clearDefense,
      reshuffle,
      addConsequence,
      removeConsequence,
      addStatus,
      removeStatus,
      discardCards,
      cancelPlan,
      returnToDeck,
    ],
  );

  return { _applyAction };
};
