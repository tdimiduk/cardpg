import { useWebSocket } from '../contexts/WebSocketContext';
import { Command } from '../types';

export const useGameDispatch = () => {
  const { sendMessage } = useWebSocket();
  // const { _applyAction } = useGameAction(); // Optimistic updates removed for now

  const dispatchCommand = (command: Command) => {
    sendMessage({ type: 'gameCommand', command });
  };

  return { dispatchCommand };
};
