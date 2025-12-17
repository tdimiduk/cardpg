import { StateCreator } from 'zustand';
import { LogSlice } from './logSlice';
import { ActorState, StateUpdate } from '../../generated/types';

// NOTE: We are intentionally temporarily breaking plannedActions until we refactor that slice too.
// For now, it will be removed or commented out.

export interface ActorSlice {
  actors: Record<string, ActorState>;

  initializeGame: () => void;
  // Server Sync
  updateActorState: (update: StateUpdate) => void;

  // Server Sync Helpers
  setPlannedMove: (actorId: string, x: number, y: number) => void;
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

  setPlannedMove: (actorId, x, y) =>
    set((state) => {
      if (state.actors[actorId]) {
        state.actors[actorId].plannedMove = [x, y];
      }
    }),
});
