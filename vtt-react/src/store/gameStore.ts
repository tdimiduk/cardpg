import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { ActorSlice, createActorSlice } from './slices/actorSlice';
import { BoardSlice, createBoardSlice } from './slices/boardSlice';
import { LogSlice, createLogSlice } from './slices/logSlice';
import { GameSlice, createGameSlice } from './slices/gameSlice';

// Combined Store Type
export type GameStore = ActorSlice & BoardSlice & LogSlice & GameSlice;

export const useGameStore = create<GameStore>()(
  immer((...a) => ({
    ...createLogSlice(...(a as Parameters<typeof createLogSlice>)),
    ...createBoardSlice(...(a as Parameters<typeof createBoardSlice>)),
    ...createActorSlice(...(a as Parameters<typeof createActorSlice>)),
    ...createGameSlice(...(a as Parameters<typeof createGameSlice>)),
  })),
);
