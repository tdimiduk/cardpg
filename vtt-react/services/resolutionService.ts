
import { Token, PlannedAction, LogEntry } from '../types';
import { GRID_SIZE } from '../constants';

export const resolveMovement = (tokens: Token[], plannedActions: Record<string, PlannedAction>): { movedTokens: Token[], logs: string[] } => {
  const movedTokens = [...tokens];
  const logs: string[] = [];

  Object.values(plannedActions).forEach(action => {
      if (action.move) {
          const tokenIndex = movedTokens.findIndex(t => t.id === action.actorId);
          if (tokenIndex !== -1) {
              const t = movedTokens[tokenIndex];
              // Calculate distance for flavor text
              const dist = Math.max(Math.abs(action.move.x - t.x), Math.abs(action.move.y - t.y));
              
              // Update position
              movedTokens[tokenIndex] = { ...t, x: action.move.x, y: action.move.y };
              
              if (dist > 0) {
                  logs.push(`${action.actorName} moved ${dist} spaces.`);
              }
          }
      }
  });

  return { movedTokens, logs };
};
