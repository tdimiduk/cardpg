import { useEffect } from 'react';
import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameAction } from './useGameAction';

export const useGameSync = () => {
  const { lastMessage, clientId } = useWebSocket();
  const { _applyAction } = useGameAction();

  useEffect(() => {
    if (lastMessage) {
      if (lastMessage.tag === 'BroadcastMessage') {
        // Ignore our own messages (we apply them optimistically)
        if (lastMessage.fromClientId === clientId) return;

        const action = lastMessage.payload;
        console.log('Received broadcast:', action);

        _applyAction(action);
      } else if (lastMessage.tag === 'Welcome') {
        console.log('Replaying history:', lastMessage.history.length, 'actions');
        lastMessage.history.forEach((action) => {
          _applyAction(action);
        });
      }
    }
  }, [lastMessage, clientId, _applyAction]);
};
