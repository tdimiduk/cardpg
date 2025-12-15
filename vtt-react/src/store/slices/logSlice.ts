import { StateCreator } from 'zustand';
import { LogEntry } from '../../types';

export interface LogSlice {
  logs: LogEntry[];
  addLog: (
    message: string,
    sender?: LogEntry['sender'],
    type?: LogEntry['type'],
    actionResult?: LogEntry['actionResult'],
    defense?: LogEntry['defense'],
    attack?: LogEntry['attack'],
  ) => void;
  updateLog: (id: string, updates: Partial<LogEntry>) => void;
}

export const createLog = (
  content: string,
  sender: LogEntry['sender'] = 'System',
  type: LogEntry['type'] = 'info',
  actionResult?: LogEntry['actionResult'],
  defense?: LogEntry['defense'],
  attack?: LogEntry['attack'],
): LogEntry => ({
  id: Math.random().toString(36),
  timestamp: Date.now(),
  sender,
  content,
  type,
  actionResult,
  defense,
  attack,
});

export const createLogSlice: StateCreator<LogSlice, [['zustand/immer', never]], [], LogSlice> = (
  set,
) => ({
  logs: [createLog('Welcome to caRdPG. Begin Planning Phase.')],
  addLog: (message, sender, type, actionResult, defense, attack) =>
    set((state) => {
      state.logs.push(createLog(message, sender, type, actionResult, defense, attack));
    }),
  updateLog: (id, updates) =>
    set((state) => {
      const logIndex = state.logs.findIndex((l) => l.id === id);
      if (logIndex !== -1) {
        state.logs[logIndex] = { ...state.logs[logIndex], ...updates };
      }
    }),
});
