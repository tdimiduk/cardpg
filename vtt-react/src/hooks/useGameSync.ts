import { useEffect } from 'react';
import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameStore } from '../store/gameStore';

/**
 * Synchronizes local state with authoritative server state.
 * All state updates come from the server - this is a pure presentation layer.
 */
export const useGameSync = () => {
  const { subscribe, clientId } = useWebSocket();

  useEffect(() => {
    function handleMessage(msg: import('../generated/types').ServerMessage) {
      if (msg.type === 'welcome') {
        // Reset client state to avoid duplicate actors from previous session
        useGameStore.getState().initializeGame();

        // Sync initial actors
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

        // Sync Readiness
        useGameStore.getState().setReadiness(msg.readyCount, msg.totalCount);
      } else if (msg.type === 'gameStateUpdate') {
        console.log('Received State Updates:', msg.updates);
        msg.updates.forEach((update) => {
          useGameStore.getState().updateActorState(update);
        });
        if (msg.newPhase) {
          useGameStore.getState().setPhase(msg.newPhase);
        }
        useGameStore.getState().setReadiness(msg.readyCount, msg.totalCount);
      } else if (msg.type === 'newLogs') {
        if (msg.logs && Array.isArray(msg.logs)) {
          console.log('Received New Logs:', msg.logs.length, msg.logs);
          msg.logs.forEach((l) => useGameStore.getState().receiveLog(l));
        }
      } else if (msg.type === 'multiMessage') {
        console.log('Received Batch Message:', msg.messages.length);
        msg.messages.forEach(handleMessage);
      }
    }

    const unsubscribe = subscribe(handleMessage);
    return () => {
      unsubscribe();
    };
  }, [subscribe, clientId]);
};
