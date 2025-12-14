import { useEffect } from 'react';
import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameAction } from './useGameAction';
import { useGameStore } from '../store/gameStore';

export const useGameSync = () => {
  const { lastMessage, clientId } = useWebSocket();
  const { _applyAction } = useGameAction();

  useEffect(() => {
    if (lastMessage) {
      if (lastMessage.type === 'broadcastMessage') {
        const actions = lastMessage.payload;
        console.log('Received broadcast actions:', actions);

        actions.forEach((action) => {
          _applyAction(action);
        });
      } else if (lastMessage.type === 'welcome') {
        // Sync initial actors first so names are available for history
        if (lastMessage.initialActors) {
          console.log('Syncing initial actors:', lastMessage.initialActors.length);
          lastMessage.initialActors.forEach((update) => {
            useGameStore.getState().updateActorState(update);
          });
        }

        // Sync phase
        if (lastMessage.phase) {
          useGameStore.getState().setPhase(lastMessage.phase);
        }

        console.log('Replaying history:', lastMessage.history.length, 'actions');
        lastMessage.history.forEach((action) => {
          _applyAction(action);
        });
      } else if (lastMessage.type === 'gameStateUpdate') {
        console.log('Received State Updates:', lastMessage.updates);
        lastMessage.updates.forEach((update) => {
          useGameStore.getState().updateActorState(update);
        });
        if (lastMessage.newPhase) {
          useGameStore.getState().setPhase(lastMessage.newPhase);
        }
      }
    }
  }, [lastMessage, clientId, _applyAction]);
};
