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
        // Ignore our own messages (we apply them optimistically)
        if (lastMessage.fromClientId === clientId) return;

        const action = lastMessage.payload;
        console.log('Received broadcast:', action);

        _applyAction(action);
      } else if (lastMessage.type === 'welcome') {
        console.log('Replaying history:', lastMessage.history.length, 'actions');
        lastMessage.history.forEach((action) => {
          _applyAction(action);
        });

        // Sync initial actors
        if (lastMessage.initialActors) {
          console.log('Syncing initial actors:', lastMessage.initialActors.length);
          lastMessage.initialActors.forEach((update) => {
            useGameStore.getState().updateActorState(update);
          });
        }
      } else if (lastMessage.type === 'gameStateUpdate') {
        console.log('Received State Update:', lastMessage.update);
        useGameStore.getState().updateActorState(lastMessage.update);
      }
    }
  }, [lastMessage, clientId, _applyAction]);
};
