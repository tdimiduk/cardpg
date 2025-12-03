import { useCallback } from 'react';
import { useGameStore } from '../store/gameStore';
import { BroadcastAction } from '../types/sync';

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
        case 'PLAY_STACK':
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
        case 'PASS':
          passTurn(action.activeTokenId);
          break;
        case 'REVEAL':
          revealAndResolve();
          break;
        case 'END_ROUND':
          endRound();
          break;
        case 'MOVE_TOKEN':
          updateTokenPosition(action.token);
          break;
        case 'DRAW_CARDS':
          drawCards(action.activeTokenId, action.count);
          break;
        case 'DEFEND':
          defend(action.activeTokenId);
          break;
        case 'CLEAR_DEFENSE':
          clearDefense(action.activeTokenId);
          break;
        case 'RESHUFFLE':
          reshuffle(action.activeTokenId);
          break;
        case 'ADD_CONSEQUENCE':
          addConsequence(action.activeTokenId);
          break;
        case 'REMOVE_CONSEQUENCE':
          removeConsequence(action.activeTokenId, action.cardId);
          break;
        case 'ADD_STATUS':
          addStatus(
            action.activeTokenId,
            action.statusType,
            action.destination as 'discard' | 'hand' | 'draw',
          );
          break;
        case 'REMOVE_STATUS':
          removeStatus(action.activeTokenId, action.statusType);
          break;
        case 'DISCARD_CARDS':
          discardCards(action.activeTokenId, action.cardIds);
          break;
        case 'CANCEL_PLAN':
          cancelPlan(action.activeTokenId);
          break;
        case 'RETURN_TO_DECK':
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
