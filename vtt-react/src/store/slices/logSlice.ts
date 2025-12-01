import { StateCreator } from 'zustand';
import { LogEntry } from '../../types';

export interface LogSlice {
  logs: LogEntry[];
  addLog: (
    message: string,
    sender?: LogEntry['sender'],
    type?: LogEntry['type'],
    actionResult?: LogEntry['actionResult'],
  ) => void;
}

export const createLog = (
  content: string,
  sender: LogEntry['sender'] = 'System',
  type: LogEntry['type'] = 'info',
  actionResult?: LogEntry['actionResult'],
): LogEntry => ({
  id: Math.random().toString(36),
  timestamp: Date.now(),
  sender,
  content,
  type,
  actionResult,
});

export const createLogSlice: StateCreator<LogSlice, [['zustand/immer', never]], [], LogSlice> = (
  set,
) => ({
  logs: [createLog('Welcome to caRdPG. Begin Planning Phase.')],
  addLog: (message, sender, type, actionResult) =>
    set((state) => {
      state.logs.push(createLog(message, sender, type, actionResult));
    }),
});
