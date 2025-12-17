import { useEffect } from 'react';
import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameAction } from './useGameAction';
import { useGameStore } from '../store/gameStore';

export const useGameSync = () => {
  const { subscribe, clientId } = useWebSocket();
  const { _applyAction } = useGameAction();

  useEffect(() => {
    // Handler for messages
    function handleMessage(msg: import('../generated/types').ServerMessage) {
      if (msg.type === 'broadcastMessage') {
        const events = msg.payload;
        console.log('Received game events:', events);

        events.forEach((actorEvent) => {
          _applyAction(actorEvent);
        });
      } else if (msg.type === 'welcome') {
        // Reset client state to avoid duplicate actors from previous session
        useGameStore.getState().initializeGame();

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

        // Sync History (Logs)
        if (msg.history) {
          useGameStore.getState().setLogs(msg.history);
        }
      } else if (msg.type === 'gameStateUpdate') {
        console.log('Received State Updates:', msg.updates);
        msg.updates.forEach((update) => {
          useGameStore.getState().updateActorState(update);
        });
        if (msg.newPhase) {
          useGameStore.getState().setPhase(msg.newPhase);
        }
      } else if (msg.type === 'newLogs') {
        // Handle batch of new logs
        if (msg.logs && Array.isArray(msg.logs)) {
          console.log('Received New Logs:', msg.logs.length, msg.logs);
          msg.logs.forEach((l) => useGameStore.getState().receiveLog(l));
        }
      } else if (msg.type === 'multiMessage') {
        console.log('Received Batch Message:', msg.messages.length);
        msg.messages.forEach(handleMessage);
      }
    }

    // Subscribe
    const unsubscribe = subscribe(handleMessage);

    // Cleanup on unmount or if dependencies change (unlikely for subscribe)
    return () => {
      unsubscribe();
    };
  }, [subscribe, clientId, _applyAction]);
};
