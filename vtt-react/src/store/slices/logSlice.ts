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
        // Map metadata to flat properties if needed, or types ensures compatibility
        // Assuming LogEntry from types.ts is strictly compatible with Server LogEntry JSON
        state.logs = logs.map(l => ({
            ...l,
            // Map metadata to top-level fields for UI compatibility if needed
            ...(((l as any).metadata) || {})
        }));
    }),
  receiveLog: (log) =>
    set((state) => {
      state.logs.push({
          ...log,
          ...(((log as any).metadata) || {})
      });
    }),
  addLog: (message, sender = 'System', type = 'info') =>
    set((state) => {
        // Legacy local logs (e.g. connection errors)
        state.logs.push({
            id: Math.random().toString(36),
            timestamp: Date.now(),
            sender: sender as any,
            content: message,
            type: type as any,
        });
    }),
});
