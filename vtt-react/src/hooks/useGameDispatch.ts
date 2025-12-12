import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameAction } from './useGameAction';
import { BroadcastAction, Command } from '../types';

export const useGameDispatch = () => {
  const { sendMessage } = useWebSocket();
  const { _applyAction } = useGameAction();

  const dispatch = (action: BroadcastAction) => {
    // 1. Apply locally
    _applyAction(action);

    // 2. Broadcast to other clients
    sendMessage({ type: 'broadcast', payload: action });
  };

  const dispatchCommand = (command: Command) => {
    sendMessage({ type: 'gameCommand', command });
  };

  return { dispatch, dispatchCommand };
};
