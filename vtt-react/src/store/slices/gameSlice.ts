import { StateCreator } from 'zustand';
import { Phase, ActorState } from '../../generated/types';
import { LogSlice } from './logSlice';
import { ActorSlice } from './actorSlice';

export interface GameSlice {
  phase: Phase;
  readyCount: number;
  totalCount: number;
  revealAndResolve: () => void;
  setPhase: (phase: Phase) => void;
  setResolutionPhase: () => void;
  setReadiness: (ready: number, total: number) => void;
}

export const createGameSlice: StateCreator<
  GameSlice & LogSlice & ActorSlice & { actors: Record<string, ActorState> },
  [['zustand/immer', never]],
  [],
  GameSlice
> = (set) => ({
  phase: 'planning',
  readyCount: 0,
  totalCount: 0,

  revealAndResolve: () =>
    set((state) => {
      // Manual trigger backup, usually triggered by server 'startResolutionPhase'
      state.phase = 'resolution';
    }),

  setPhase: (phase) =>
    set((state) => {
      if (state.phase !== phase) {
        state.phase = phase;
      }
    }),

  setResolutionPhase: () =>
    set((state) => {
      state.phase = 'resolution';
    }),

  setReadiness: (ready, total) =>
    set((state) => {
      state.readyCount = ready;
      state.totalCount = total;
    }),
});
