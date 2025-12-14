import { StateCreator } from 'zustand';
import { GamePhase, UIPlannedAction, CoreCard, ResourceType, Token, ActorState } from '../../types';
import { LogSlice, createLog } from './logSlice';
import { ActorSlice } from './actorSlice';

export interface GameSlice {
  phase: GamePhase;
  plannedActions: Record<string, UIPlannedAction>;

  commitPlan: (
    tokenId: string,
    cards: CoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    actionName?: string,
    targetDefense?: ResourceType,
  ) => void;
  cancelPlan: (tokenId: string) => void;
  passTurn: (tokenId: string) => void;
  revealAndResolve: () => void;
  endRound: () => void;
  playImmediate: (
    tokenId: string,
    cards: CoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    actionName?: string,
    targetDefense?: ResourceType,
  ) => void;
}

export const createGameSlice: StateCreator<
  GameSlice & LogSlice & ActorSlice & { tokens: Token[]; actors: Record<string, ActorState> },
  [['zustand/immer', never]],
  [],
  GameSlice
> = (set) => ({
  phase: 'planning',
  plannedActions: {},

  commitPlan: (_tokenId, _cards, _strengthColor, _modifier, _actionName, _targetDefense) =>
    set((_state) => {
      // Deprecated: Optimistic updates removed in favor of Server Authoritative StateUpdate.
      // Logic handled by actorSlice.updateActorState
    }),

  cancelPlan: (_tokenId) =>
    set((_state) => {
      // Deprecated: Logic handled by actorSlice.updateActorState
    }),

  passTurn: (_tokenId) =>
    set((_state) => {
      // Deprecated: Logic handled by actorSlice.updateActorState
    }),

  revealAndResolve: () =>
    set((state) => {
      state.phase = 'resolution';
      state.logs.push(createLog('Phase changed to Resolution.', 'System'));
      // Actual resolution happens on server. State updates will follow.
    }),

  endRound: () =>
    set((state) => {
      // Logic handled by server (movement, clearing plans, etc)
      // We process StateUpdates to reflect changes.
      // We optimistically switch phase here to update UI immediately?
      // Or better wait for server?
      // Safe to switch phase as next round implies Planning.
      state.phase = 'planning';
      state.logs.push(createLog('Round Ended. Starting new Planning Phase.', 'GM'));
    }),

  playImmediate: (_tokenId, _cards, _strengthColor, _modifier, _actionName, _targetDefense) =>
    set((_state) => {
       // Deprecated: Server Authoritative
    }),
});
