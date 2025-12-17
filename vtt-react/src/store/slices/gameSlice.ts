import { StateCreator } from 'zustand';
import { GamePhase, ActorState } from '../../types';
import { LogSlice } from './logSlice';
import { ActorSlice } from './actorSlice';

export interface GameSlice {
  phase: GamePhase;
  revealAndResolve: () => void;
  setPhase: (phase: GamePhase) => void;
  setResolutionPhase: () => void;
}

export const createGameSlice: StateCreator<
  GameSlice & LogSlice & ActorSlice & { actors: Record<string, ActorState> },
  [['zustand/immer', never]],
  [],
  GameSlice
> = (set) => ({
  phase: 'planning',

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
});
