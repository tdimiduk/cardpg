import { StateCreator } from 'zustand';
import { GamePhase, Token, ActorState } from '../../types';
import { LogSlice, createLog } from './logSlice';
import { ActorSlice } from './actorSlice';

export interface GameSlice {
  phase: GamePhase;
  currentResolution: {
    actorId: string;
    attack: import('../../types').RealizedAttack;
    resourceCardIds?: string[];
  } | null;
  revealAndResolve: () => void;
  setPhase: (phase: GamePhase) => void;
  setResolutionPhase: () => void;
  setAttackResolution: (
    actorId: string,
    attack: import('../../types').RealizedAttack,
    resourceCardIds?: string[],
  ) => void;
  endRound: () => void;
}

export const createGameSlice: StateCreator<
  GameSlice & LogSlice & ActorSlice & { tokens: Token[]; actors: Record<string, ActorState> },
  [['zustand/immer', never]],
  [],
  GameSlice
> = (set) => ({
  phase: 'planning',
  currentResolution: null,

  revealAndResolve: () =>
    set((state) => {
      // Manual trigger backup, usually triggered by server 'startResolutionPhase'
      state.phase = 'resolution';
    }),

  setPhase: (phase) =>
    set((state) => {
      if (state.phase !== phase) {
        state.phase = phase;
        state.logs.push(createLog(`Phase changed to ${phase}.`, 'System'));
      }
    }),

  setResolutionPhase: () =>
    set((state) => {
      state.phase = 'resolution';
      state.logs.push(createLog('Phase changed to Resolution.', 'System'));
    }),

  setAttackResolution: (actorId, attack, resourceCardIds) =>
    set((state) => {
      state.currentResolution = { actorId, attack, resourceCardIds };
      // Log the attack start if needed, or let the text log handle it.
      // This state is just for visualization in sidebar.
    }),

  endRound: () =>
    set((state) => {
      // Logic handled by server (movement, clearing plans, etc)
      // We process StateUpdates to reflect changes.
      // We optimistically switch phase here to update UI immediately?
      // Or better wait for server?
      // Safe to switch phase as next round implies Planning.
      state.phase = 'planning';
      state.currentResolution = null;
      // Note: We might want to keep defense visible if it persists across turns, but usually it clears.
      // For now, let's not auto-clear defense here unless explicitly told by server events.
      state.logs.push(createLog('Round Ended. Starting new Planning Phase.', 'GM'));
    }),
});
