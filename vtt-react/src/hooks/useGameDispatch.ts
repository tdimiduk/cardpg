import { useWebSocket } from '../contexts/WebSocketContext';
import { Command, AdminCommand } from '../generated/types';

export const useGameDispatch = () => {
  const { sendMessage } = useWebSocket();
  // const { _applyAction } = useGameAction(); // Optimistic updates removed for now

  const dispatchCommand = (command: Command) => {
    sendMessage({ type: 'gameCommand', command });
  };

  const dispatchAdmin = (adminCommand: AdminCommand) => {
    sendMessage({ type: 'admin', adminCommand } as any);
  };

  return { dispatchCommand, dispatchAdmin };
};
