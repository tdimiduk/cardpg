import { StateCreator } from 'zustand';
import { ActorState, UIPlannedAction, StateUpdate, Token } from '../../types';
import { ActorState as ServerActorState } from '../../generated/types';

import { INITIAL_ACTORS } from '../../constants';
import { LogSlice } from './logSlice';
import { createActor } from '../../services/actorFactory';
import { hydrateActor, hydratePlannedAction } from '../../utils/hydration';

export interface ActorSlice {
  actors: Record<string, ActorState>;
  tokens: Token[];
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
}

export const createActorSlice: StateCreator<
  ActorSlice & LogSlice, // removed explicit tokens requirement as it's part of ActorSlice now
  [['zustand/immer', never]],
  [],
  ActorSlice
> = (set) => ({
  actors: INITIAL_ACTORS,
  tokens: [],
  plannedActions: {},

  initializeGame: () =>
    set((_state) => {
      // No-op for now, waiting for server?
      // Or keep local for standalone dev
      console.log('Initialize Game called - expecting server state.');
    }),

  addActor: (name, actorType, color, templateId) =>
    set((state) => {
      const newActor = createActor(name, actorType, color, templateId);
      state.actors[newActor.id] = newActor;

      state.tokens.push({
        id: `token-${newActor.id}`,
        actorId: newActor.id,
        x: 0,
        y: 0,
        size: 1,
      });
    }),

  removeActor: (actorId: string) =>
    set((state) => {
      if (!state.actors[actorId]) return;
      state.tokens = state.tokens.filter((t) => t.actorId !== actorId);
      delete state.actors[actorId];
    }),

  updateActorState: (update: StateUpdate) =>
    set((state) => {
      const targetId = update.updateActorId; // UUID
      const serverState = update.updateActorState as unknown as ServerActorState;
      // Cast is now safe because we are about to pass it to a function that expects ServerActorState
      // In the future we should update StateUpdate type to use ServerActorState directly if possible

      if (!state.actors[targetId]) {
        console.log('Received update for new actor:', targetId);
        // Create token for new actor
        state.tokens.push({
          id: `token-${targetId}`,
          actorId: targetId,
          x: 0,
          y: 0,
          size: 1,
        });
      }

      // Hydrate Actor State
      const hydratedActor = hydrateActor(serverState, targetId, state.actors[targetId]);
      state.actors[targetId] = hydratedActor;

      // Sync Spatial State to Token (Needs to be separate because Token is separate from Actor in frontend model currently)
      const token = state.tokens.find((t: Token) => t.actorId === targetId);
      if (token && serverState.spatial) {
        token.x = serverState.spatial.posX;
        token.y = serverState.spatial.posY;
        token.size = serverState.spatial.size ?? 1;
      }

      // Hydrate Planned Actions
      const plannedAction = hydratePlannedAction(
        serverState,
        targetId,
        serverState.coreState.registry,
      );
      if (plannedAction) {
        state.plannedActions[targetId] = plannedAction;
      } else {
        delete state.plannedActions[targetId];
      }
    }),
});
