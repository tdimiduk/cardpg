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

        // Sync History (Logs)
        if ((msg as any).history) {
           useGameStore.getState().setLogs((msg as any).history);
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
         const newLogs = (msg as any).logs;
         if (newLogs && Array.isArray(newLogs)) {
             newLogs.forEach(l => useGameStore.getState().receiveLog(l));
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
