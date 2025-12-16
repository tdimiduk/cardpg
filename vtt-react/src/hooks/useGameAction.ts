import { useCallback } from 'react';
import { useGameStore } from '../store/gameStore';
import { ActorGameEvent } from '../generated/types';

/**
 * Hook to apply game actions to the local store.
 *
 * @internal DO NOT USE DIRECTLY. Use useGameDispatch instead to ensure synchronization.
 */
export const useGameAction = () => {
  // Store actions

  const revealAndResolve = useGameStore((state) => state.revealAndResolve);
  const endRound = useGameStore((state) => state.endRound);
  const updateTokenPosition = useGameStore((state) => state.updateTokenPosition);
  const addLog = useGameStore((state) => state.addLog);


  const _applyAction = useCallback(
    (actorEvent: ActorGameEvent) => {
      const { actorId, event } = actorEvent;



      switch (event.type) {
        case 'actionRevealed': {
          if (!event.data) break;
          const effect = Array.isArray(event.data) ? event.data[1] : undefined;

          if (effect && effect.type === 'rEAttack') {
            // Animation logic or specialized handling ONLY (logs handled by server)
            revealAndResolve();
          } else if (effect && effect.type === 'rEPass') {
             revealAndResolve();
          } else if (effect && effect.type === 'rEInvalid') {
             revealAndResolve();
          }

          revealAndResolve();
          break;
        }
        case 'illegalAction': {
          // Maybe show a toast/alert? Logs handled by server.
          break;
        }
        case 'cardDrawn':
          break;
        case 'cardDefended': {
          // Animation trigger if needed
          break;
        }
        case 'defenseEnded': {
           // Animation trigger
           break;
        }
        case 'deckShuffled':
          break;
        case 'consequenceAdded':
          break;
        case 'consequenceRemoved':
          break;
        case 'statusAdded':
          break;
        case 'statusRemoved':
          break;
        case 'planCanceled':
          break;
        case 'cardsCreated':
        case 'movePlanned':
        case 'actorMoved':
        case 'actionPlanned':
          // Ignore
          break;
        default:
          console.warn('Unhandled event:', event);
      }
    },
    [revealAndResolve, endRound, updateTokenPosition, addLog],
  );

  return { _applyAction };
};
