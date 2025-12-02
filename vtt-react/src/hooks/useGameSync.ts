import { useEffect } from 'react';
import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameAction } from './useGameAction';

export const useGameSync = () => {
  const { lastMessage, clientId } = useWebSocket();
  const { _applyAction } = useGameAction();

  useEffect(() => {
    if (lastMessage && lastMessage.tag === 'BroadcastMessage') {
      // Ignore our own messages (we apply them optimistically)
      if (lastMessage.fromClientId === clientId) return;

      const action = lastMessage.payload;
      console.log('Received broadcast:', action);

      _applyAction(action);
    }
  }, [lastMessage, clientId, _applyAction]);
};
