import { StateCreator } from 'zustand';
import { Token, PlannedAction, Actor } from '../../types';
import { INITIAL_TOKENS } from '../../constants'; // Circular dependency for types? No, just interface usage if needed, but here we just need types.
// Actually, updateTokenPosition needs to check phase, so we might need access to GameSlice state if we were combining them in one object,
// but with slices, `set` and `get` work on the whole store.
// Let's define the combined store type for the creator if needed, or just use generic.

// We need to know the full store type to access other slices in `set` / `get` if we use them.
// For now, let's define BoardSlice independently and assume we can access phase via `get().phase` if we type it correctly.

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
    plannedActions: Record<string, PlannedAction>;
    actors: Record<string, Actor>;
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
            strengthColor: 'Red',
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
