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
  const cancelPlan = useGameStore((state) => state.cancelPlan);
  const playImmediate = useGameStore((state) => state.playImmediate);
  const passTurn = useGameStore((state) => state.passTurn);
  const revealAndResolve = useGameStore((state) => state.revealAndResolve);
  const endRound = useGameStore((state) => state.endRound);
  const updateTokenPosition = useGameStore((state) => state.updateTokenPosition);
  const addLog = useGameStore((state) => state.addLog);

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
          addLog(`${action.actingActor} drew ${action.count} card(s).`, 'System', 'info');
          break;
        case 'defend':
          addLog(`${action.actingActor} is defending.`, 'System', 'info');
          break;
        case 'clearDefense':
          addLog(`${action.actingActor} cleared defense.`, 'System', 'info');
          break;
        case 'reshuffle':
          addLog(`${action.actingActor} reshuffled their deck.`, 'System', 'info');
          break;
        case 'addConsequence':
          addLog(`${action.actingActor} gained a consequence.`, 'System', 'info');
          break;
        case 'removeConsequence':
          addLog(`${action.actingActor} removed a consequence.`, 'System', 'info');
          break;
        case 'addStatus':
          addLog(
            `${action.actingActor} added status "${action.statusType}" to ${action.destination}.`,
            'System',
            'info',
          );
          break;
        case 'removeStatus':
          addLog(
            `${action.actingActor} removed status "${action.statusType}" from ${action.destination}.`,
            'System',
            'info',
          );
          break;
        case 'discardCards':
          addLog(
            `${action.actingActor} discarded ${action.cardIds.length} card(s).`,
            'System',
            'info',
          );
          break;
        case 'cancelPlan':
          cancelPlan(action.actingActor);
          break;
        case 'returnToDeck':
          addLog(
            `${action.actingActor} returned ${action.cardIds.length} card(s) to deck.`,
            'System',
            'info',
          );
          break;
        case 'startResolutionPhase':
          // Optional: Show phase change specific UI if needed
          break;
        case 'invalidAction':
          addLog(`Invalid Action for ${action.actingActor}: ${action.message}`, 'System');
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
      cancelPlan,
      addLog,
    ],
  );

  return { _applyAction };
};
