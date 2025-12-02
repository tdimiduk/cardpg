import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameAction } from './useGameAction';
import { BroadcastAction } from '../types/sync';

export const useGameDispatch = () => {
  const { sendMessage } = useWebSocket();
  const { _applyAction } = useGameAction();

  const dispatch = (action: BroadcastAction) => {
    // 1. Apply locally
    _applyAction(action);

    // 2. Broadcast to other clients
    sendMessage({ tag: 'Broadcast', payload: action });
  };

  return { dispatch };
};
