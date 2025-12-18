import { StateCreator } from 'zustand';
import { LogEntry, LogPayload } from '../../generated/types';

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
      // Defense grouping logic
      if (log.payload.type === 'logDefense') {
        const actorId = log.payload.defenseActorId;
        // Search backwards for an active defense log for this actor
        for (let i = state.logs.length - 1; i >= 0; i--) {
          const existingLog = state.logs[i];
          if (
            existingLog.payload.type === 'logDefense' &&
            existingLog.payload.defenseActorId === actorId
          ) {
            // Found the last defense log for this actor
            if (!existingLog.payload.ended) {
              // It's still active, so update it with the new state
              state.logs[i] = log;
              return;
            } else {
              // It ended, so we must start a new one (break loop and push)
              break;
            }
          }
        }
      }
      state.logs.push(log);
    }),
  addLog: (message, sender = 'System', type = 'info') =>
    set((state) => {
      // Legacy local logs
      // Map legacy types to new payload types
      let payload: LogPayload;
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
