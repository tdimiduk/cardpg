import { StateCreator } from 'zustand';
import { Token, ActorState } from '../../types';
import { INITIAL_TOKENS } from '../../constants';

export interface BoardSlice {
  tokens: Token[];
  activeActorId: string | null;
  setActiveActor: (actorId: string | null) => void;
  updateTokenPosition: (token: Token) => void;
  spawnToken: (actorId: string, x: number, y: number) => void;
  despawnToken: (tokenId: string) => void;
}

// We'll use a generic for the store type to allow access to other slices
export const createBoardSlice: StateCreator<
  BoardSlice & {
    phase: string;
    actors: Record<string, ActorState>;
  }, // Partial definition of full store for TS
  [['zustand/immer', never]],
  [],
  BoardSlice
> = (set) => ({
  tokens: INITIAL_TOKENS,
  activeActorId: null, // Default to null, or maybe first actor?

  setActiveActor: (actorId) =>
    set((state) => {
      state.activeActorId = actorId;
    }),

  updateTokenPosition: (token) =>
    set((state) => {
      // Resolution: Move immediately
      if (state.phase === 'resolution') {
        const idx = state.tokens.findIndex((t) => t.id === token.id);
        if (idx !== -1) state.tokens[idx] = token;
      }
      // Planning: Move Plan handled by server command 'PlanMove' dispatched from UI
    }),

  spawnToken: (actorId, x, y) =>
    set((state) => {
      if (!state.actors[actorId]) return;
      state.tokens.push({
        id: `token-${Math.random().toString(36).substr(2, 9)}`,
        actorId,
        x,
        y,
        size: 1,
      });
    }),

  despawnToken: (tokenId) =>
    set((state) => {
      const token = state.tokens.find((t) => t.id === tokenId);
      if (token && state.activeActorId === token.actorId) {
        state.activeActorId = null;
      }
      state.tokens = state.tokens.filter((t) => t.id !== tokenId);
    }),
});
