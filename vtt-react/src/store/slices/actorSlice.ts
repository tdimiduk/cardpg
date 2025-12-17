import { StateCreator } from 'zustand';
import { ActorState, UIPlannedAction, StateUpdate } from '../../types';
import { ActorState as ServerActorState } from '../../generated/types';

import { INITIAL_ACTORS } from '../../constants';
import { LogSlice } from './logSlice';
import { hydrateActor, hydratePlannedAction } from '../../utils/hydration';

export interface ActorSlice {
  actors: Record<string, ActorState>;
  plannedActions: Record<string, UIPlannedAction>;

  initializeGame: () => void;
  addActor: (
    name: string,
    type: import('../../types').TokenType,
    color: string,
    templateId?: string,
  ) => void;
  removeActor: (actorId: string) => void;

  // Server Sync
  updateActorState: (update: StateUpdate) => void;
  // Server Sync Helpers
  setPlannedMove: (actorId: string, x: number, y: number) => void;
}

export const createActorSlice: StateCreator<
  ActorSlice & LogSlice, // removed explicit tokens requirement as it's part of ActorSlice now
  [['zustand/immer', never]],
  [],
  ActorSlice
> = (set) => ({
  actors: INITIAL_ACTORS,
  plannedActions: {},

  initializeGame: () =>
    set((state) => {
      // Clear all data to prepare for server sync
      state.actors = {};
      state.plannedActions = {};
    }),

  addActor: (_name, _actorType, _color, _templateId) =>
    set((_state) => {
      console.warn('addActor is deprecated/disabled. Expecting server to spawn actors.');
    }),

  removeActor: (_actorId: string) =>
    set((_state) => {
      console.warn('removeActor is deprecated. Expecting server to remove actors.');
    }),

  updateActorState: (update: StateUpdate) =>
    set((state) => {
      const targetId = update.updateActorId; // UUID
      const serverState = update.updateActorState as unknown as ServerActorState;
      // Cast is now safe because we are about to pass it to a function that expects ServerActorState
      // In the future we should update StateUpdate type to use ServerActorState directly if possible

      if (!state.actors[targetId]) {
        console.log('Received update for new actor:', targetId);
      }

      // Hydrate Actor State
      const hydratedActor = hydrateActor(serverState, targetId, state.actors[targetId]);
      state.actors[targetId] = hydratedActor;

      // Hydrate Planned Actions
      const plannedAction = hydratePlannedAction(serverState, targetId, hydratedActor.registry);
      if (plannedAction) {
        state.plannedActions[targetId] = plannedAction;
      } else {
        delete state.plannedActions[targetId];
      }
    }),

  setPlannedMove: (actorId, x, y) =>
    set((state) => {
      if (state.actors[actorId]) {
        state.actors[actorId].plannedMove = { x, y };
      }
    }),
});
