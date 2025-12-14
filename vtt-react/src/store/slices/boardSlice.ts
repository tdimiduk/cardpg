import { StateCreator } from 'zustand';
import { Token, UIPlannedAction, ActorState } from '../../types';
import { INITIAL_TOKENS, RESOURCE_TYPES } from '../../constants';

export interface BoardSlice {
  tokens: Token[];
  activeTokenId: string | null;
  setActiveToken: (tokenId: string | null) => void;
  updateTokenPosition: (token: Token) => void;
  spawnToken: (actorId: string, x: number, y: number) => void;
  despawnToken: (tokenId: string) => void;
}

// We'll use a generic for the store type to allow access to other slices
export const createBoardSlice: StateCreator<
  BoardSlice & {
    phase: string;
    plannedActions: Record<string, UIPlannedAction>;
    actors: Record<string, ActorState>;
  }, // Partial definition of full store for TS
  [['zustand/immer', never]],
  [],
  BoardSlice
> = (set) => ({
  tokens: INITIAL_TOKENS,
  activeTokenId: INITIAL_TOKENS[0]?.id || null,

  setActiveToken: (tokenId) =>
    set((state) => {
      state.activeTokenId = tokenId;
    }),

  updateTokenPosition: (token) =>
    set((state) => {
      // Resolution: Move immediately
      if (state.phase === 'resolution') {
        const idx = state.tokens.findIndex((t) => t.id === token.id);
        if (idx !== -1) state.tokens[idx] = token;
      }
      // Planning: Update Move Plan
      else {
        if (!state.plannedActions[token.id]) {
          const actor = state.actors[token.actorId];
          state.plannedActions[token.id] = {
            actorId: token.id,
            actorName: actor?.name || 'Unknown',
            cards: [],
            strengthColor: RESOURCE_TYPES.RED,
            modifier: 0,
            actionName: undefined,
          };
        }
        state.plannedActions[token.id].move = { x: token.x, y: token.y };
      }
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
      state.tokens = state.tokens.filter((t) => t.id !== tokenId);
      delete state.plannedActions[tokenId];
      if (state.activeTokenId === tokenId) {
        state.activeTokenId = null;
      }
    }),
});
