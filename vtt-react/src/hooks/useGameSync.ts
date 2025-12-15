import { useEffect } from 'react';
import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameAction } from './useGameAction';
import { useGameStore } from '../store/gameStore';

export const useGameSync = () => {
  const { lastMessage, clientId } = useWebSocket();
  const { _applyAction } = useGameAction();

  useEffect(() => {
    function handleMessage(msg: import('../generated/types').ServerMessage) {
      if (msg.type === 'broadcastMessage') {
        const events = msg.payload;
        console.log('Received game events:', events);

        events.forEach((actorEvent) => {
          _applyAction(actorEvent);
        });
      } else if (msg.type === 'welcome') {
        // Sync initial actors first so names are available
        if (msg.initialActors) {
          console.log('Syncing initial actors:', msg.initialActors.length);
          msg.initialActors.forEach((update) => {
            useGameStore.getState().updateActorState(update);
          });
        }

        // Sync phase
        if (msg.phase) {
          useGameStore.getState().setPhase(msg.phase);
        }

        // Rehydrate transient UI state (Defense Logs, Attacks)
        const { actors, logs, addLog, phase, plannedActions } = useGameStore.getState();
        Object.entries(actors).forEach(([actorId, actor]) => {
          // Rehydrate Defense Log
          if (actor.deck.flippedPile && actor.deck.flippedPile.length > 0) {
            const alreadyLogged = logs.some(
              (l) => l.type === 'defense' && l.defense?.actorId === actorId && !l.defense.ended,
            );
            if (!alreadyLogged) {
              addLog(`${actor.name} is defending.`, 'System', 'defense', undefined, {
                actorId,
                ended: false,
              });
            }
          }

          // Rehydrate Active Attack (Resolution Phase)
          if (phase === 'resolution' && actor.revealed) {
            const revealed = actor.revealed;
            if (revealed.type === 'rEAttack') {
              const attack = revealed.data;
              let resourceCardIds: string[] | undefined;

              const storedPlan = plannedActions[actorId];
              if (storedPlan) {
                // Exclude action card from resources
                resourceCardIds = storedPlan.cards
                  .filter((c) => c.id !== attack.attackCard)
                  .map((c) => c.id);
              }

              // Check if already logged to avoid duplicates on quick reconnects
              // (though logs are usually wiped on refresh unless persisted, checking 'logs' from store which might be fresh empty or not)
              const alreadyLogged = logs.some(
                (l) =>
                  l.type === 'attack' &&
                  l.attack?.actorId === actorId &&
                  l.attack?.attack.attackCard === attack.attackCard,
              );

              if (!alreadyLogged) {
                addLog(`${actor.name} attacks!`, 'System', 'attack', undefined, undefined, {
                  actorId,
                  attack,
                  resourceCardIds,
                });
              }
            }
          }
        });
      } else if (msg.type === 'gameStateUpdate') {
        console.log('Received State Updates:', msg.updates);
        msg.updates.forEach((update) => {
          useGameStore.getState().updateActorState(update);
        });
        if (msg.newPhase) {
          useGameStore.getState().setPhase(msg.newPhase);
        }
      } else if (msg.type === 'multiMessage') {
        console.log('Received Batch Message:', msg.messages.length);
        msg.messages.forEach(handleMessage);
      }
    }

    if (lastMessage) {
      handleMessage(lastMessage);
    }
  }, [lastMessage, clientId, _applyAction]);
};
