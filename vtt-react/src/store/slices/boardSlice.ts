import { StateCreator } from 'zustand';

export interface BoardSlice {
  activeActorId: string | null;
  setActiveActor: (actorId: string | null) => void;
}

export const createBoardSlice: StateCreator<
  BoardSlice,
  [['zustand/immer', never]],
  [],
  BoardSlice
> = (set) => ({
  activeActorId: null,

  setActiveActor: (actorId) =>
    set((state) => {
      state.activeActorId = actorId;
    }),
});
