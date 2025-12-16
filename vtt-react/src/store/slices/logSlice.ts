import { StateCreator } from 'zustand';
import { LogEntry } from '../../types';

export interface LogSlice {
  logs: LogEntry[];
  setLogs: (logs: LogEntry[]) => void;
  receiveLog: (log: LogEntry) => void;
  // Keep addLog for transitioning, but it will just create a local log which we might want to deprecate or use for errors
  addLog: (message: string, sender?: string, type?: string) => void;
}

export const createLogSlice: StateCreator<LogSlice, [['zustand/immer', never]], [], LogSlice> = (
  set,
) => ({
  logs: [],
  setLogs: (logs) =>
    set((state) => {
      state.logs = logs;
    }),
  receiveLog: (log) =>
    set((state) => {
      state.logs.push(log);
    }),
  addLog: (message, sender = 'System', type = 'info') =>
    set((state) => {
      // Legacy local logs
      // Map legacy types to new payload types
      let payload: import('../../types').LogPayload;
      if (type === 'chat') {
        payload = { type: 'logChat', content: message };
      } else {
        // Default to info
        payload = { type: 'logInfo', content: message };
      }

      state.logs.push({
        id: Math.random().toString(36),
        timestamp: Date.now(),
        sender: sender,
        payload: payload,
      });
    }),
});
