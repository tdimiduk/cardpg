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
        case 'playStack':
          if (action.phase === 'planning') {
            commitPlan(
              action.activeTokenId,
              action.selectedCards,
              action.strengthColor,
              action.modifier,
              action.actionName,
              action.targetDefense,
            );
          } else {
            playImmediate(
              action.activeTokenId,
              action.selectedCards,
              action.strengthColor,
              action.modifier,
              action.actionName,
              action.targetDefense,
            );
          }
          break;
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
