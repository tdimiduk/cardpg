import { useCallback } from 'react';
import { useGameStore } from '../store/gameStore';
import { ActorGameEvent, RealizedAttack } from '../generated/types';

/**
 * Hook to apply game actions to the local store.
 *
 * @internal DO NOT USE DIRECTLY. Use useGameDispatch instead to ensure synchronization.
 */
export const useGameAction = () => {
  // Store actions
  // Store actions
  const revealAndResolve = useGameStore((state) => state.revealAndResolve);
  const endRound = useGameStore((state) => state.endRound);
  const updateTokenPosition = useGameStore((state) => state.updateTokenPosition);
  const addLog = useGameStore((state) => state.addLog);
  const updateLog = useGameStore((state) => state.updateLog);
  const setResolutionPhase = useGameStore((state) => state.setResolutionPhase);
  const setAttackResolution = useGameStore((state) => state.setAttackResolution);

  const _applyAction = useCallback(
    (actorEvent: ActorGameEvent) => {
      const { actorId, event } = actorEvent;

      const resolveName = (id: string) => {
        const state = useGameStore.getState();
        const actors = state.actors || {}; // Safety check
        // Check if actor
        if (actors[id]) return actors[id].name;
        // Check registries
        for (const actor of Object.values(actors)) {
          if (actor.registry && actor.registry[id]) {
            return actor.registry[id].name;
          }
        }
        return id;
      };

      const actorName = actorId ? resolveName(actorId) : 'System';

      switch (event.type) {
        case 'actionRevealed': {
          if (!event.data) break;
          const effect = Array.isArray(event.data) ? event.data[1] : undefined;

          if (effect && effect.type === 'rEAttack') {
            const attack = effect.data as RealizedAttack;
            setAttackResolution(actorId, attack);
          } else if (effect && effect.type === 'rEPass') {
            addLog(`${actorName} passed.`, 'System', 'info');
          } else if (effect && effect.type === 'rEInvalid') {
            const msg = effect.data as string;
            addLog(`Invalid Action for ${actorName}: ${msg}`, 'System', 'info');
          }

          revealAndResolve();
          break;
        }
        case 'illegalAction': {
          const reason = Array.isArray(event.data) ? event.data[1] : 'Unknown reason';
          addLog(`Illegal Action for ${actorName}: ${reason}`, 'System', 'info');
          break;
        }
        case 'cardDrawn':
          addLog(`${actorName} drew a card.`, 'System', 'info');
          break;
        case 'cardDefended': {
          // Check if there is already an active defense log for this actor
          const currentLogs = useGameStore.getState().logs;
          const activeDefense = currentLogs.find(
            (l) => l.type === 'defense' && l.defense?.actorId === actorId && !l.defense.ended,
          );

          if (!activeDefense) {
            addLog(`${actorName} is defending.`, 'System', 'defense', undefined, {
              actorId,
              ended: false,
            });
          }
          break;
        }
        case 'defenseEnded': {
          const currentLogs = useGameStore.getState().logs;
          const activeDefense = [...currentLogs]
            .reverse()
            .find(
              (l) => l.type === 'defense' && l.defense?.actorId === actorId && !l.defense.ended,
            );

          // Snapshot the cards for history
          const actors = useGameStore.getState().actors;
          const flippedPile = actors[actorId]?.deck.flippedPile || [];
          const cardNames = flippedPile.map((c) => c.name);

          if (activeDefense) {
            updateLog(activeDefense.id, {
              defense: { ...activeDefense.defense!, ended: true, snapshot: cardNames },
              content: `${actorName} defense ended.`,
            });
          } else {
            addLog(`${actorName} cleared defense.`, 'System', 'info');
          }
          break;
        }
        case 'deckShuffled':
          addLog(`${actorName} reshuffled their deck.`, 'System', 'info');
          break;
        case 'consequenceAdded':
          addLog(`${actorName} gained a consequence.`, 'System', 'info');
          break;
        case 'consequenceRemoved':
          addLog(
            `${actorName} removed consequence "${resolveName(event.data as string)}".`,
            'System',
            'info',
          );
          break;
        case 'statusAdded':
          if (Array.isArray(event.data)) {
            const [sType, dest] = event.data;
            addLog(
              `${actorName} added status "${sType}" to ${resolveName(dest)}.`,
              'System',
              'info',
            );
          }
          break;
        case 'statusRemoved':
          if (Array.isArray(event.data)) {
            const [sType, dest] = event.data;
            addLog(
              `${actorName} removed status "${sType}" from ${resolveName(dest)}.`,
              'System',
              'info',
            );
          }
          break;
        case 'planCanceled':
          addLog(`${actorName} canceled their plan.`, 'System', 'info');
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
    [
      revealAndResolve,
      endRound,
      updateTokenPosition,
      addLog,
      updateLog,
      setResolutionPhase,
      setAttackResolution,
    ],
  );

  return { _applyAction };
};
