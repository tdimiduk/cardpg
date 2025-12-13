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
        case 'attackAction': {
          // Handle visualized attack from server
          // Maybe show animation?
          // For now, no storage update needed as GameStateUpdate handles state.
          // Can trigger 'revealAndResolve' visual equivalent if needed.
          break;
        }
        case 'pass':
          passTurn(action.actingActor);
          break;
        case 'reveal':
          revealAndResolve();
          break;
        case 'endRound':
          endRound();
          break;
        case 'moveToken':
          // MoveToken actingActor field exists but logic uses action.token
          updateTokenPosition(action.token);
          break;
        case 'drawCards':
          drawCards(action.actingActor, action.count);
          break;
        case 'defend':
          defend(action.actingActor);
          break;
        case 'clearDefense':
          clearDefense(action.actingActor);
          break;
        case 'reshuffle':
          reshuffle(action.actingActor);
          break;
        case 'addConsequence':
          addConsequence(action.actingActor);
          break;
        case 'removeConsequence':
          removeConsequence(action.actingActor, action.cardId);
          break;
        case 'addStatus':
          addStatus(
            action.actingActor,
            action.statusType,
            action.destination as 'discard' | 'hand' | 'draw',
          );
          break;
        case 'removeStatus':
          removeStatus(action.actingActor, action.statusType);
          break;
        case 'discardCards':
          discardCards(action.actingActor, action.cardIds);
          break;
        case 'cancelPlan':
          cancelPlan(action.actingActor);
          break;
        case 'returnToDeck':
          returnToDeck(action.actingActor, action.cardIds);
          break;
        case 'startResolutionPhase':
          // Optional: Show phase change specific UI if needed
          break;
        case 'invalidAction':
          console.error(`Invalid Action for ${action.actingActor}: ${action.message}`);
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
