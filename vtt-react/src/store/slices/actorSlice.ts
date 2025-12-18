import { StateCreator } from 'zustand';
import { LogSlice } from './logSlice';
import { ActorState, StateUpdate } from '../../generated/types';

export interface ActorSlice {
  actors: Record<string, ActorState>;

  initializeGame: () => void;
  updateActorState: (update: StateUpdate) => void;
}

export const createActorSlice: StateCreator<
  ActorSlice & LogSlice,
  [['zustand/immer', never]],
  [],
  ActorSlice
> = (set) => ({
  actors: {},

  initializeGame: () =>
    set((state) => {
      state.actors = {};
    }),

  updateActorState: (update: StateUpdate) =>
    set((state) => {
      const targetId = update.updateActorId;
      const serverState = update.updateActorState;

      state.actors[targetId] = serverState;
    }),
});
