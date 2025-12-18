import { useWebSocket } from '../contexts/WebSocketContext';
import { Command, AdminCommand } from '../generated/types';

export const useGameDispatch = () => {
  const { sendMessage } = useWebSocket();

  const dispatchCommand = (command: Command) => {
    console.log('[Dispatch] Dispatching command:', command);
    sendMessage({ type: 'gameCommand', command });
  };

  const dispatchAdmin = (adminCommand: AdminCommand) => {
    sendMessage({ type: 'admin', adminCommand } as any);
  };

  return { dispatchCommand, dispatchAdmin };
};
