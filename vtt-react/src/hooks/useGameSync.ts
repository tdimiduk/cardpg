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
        const actions = msg.payload;
        console.log('Received broadcast actions:', actions);

        actions.forEach((action) => {
          _applyAction(action);
        });
      } else if (msg.type === 'welcome') {
        // Sync initial actors first so names are available for history
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

        console.log('Replaying history:', msg.history.length, 'actions');
        msg.history.forEach((action) => {
          _applyAction(action);
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
