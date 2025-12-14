import { StateCreator } from 'zustand';
import { GamePhase, UIPlannedAction, CoreCard, ResourceType, Token, ActorState } from '../../types';
import { RESOURCE_TYPES } from '../../constants';
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

// Helper to get actor
const getActor = (
  state: { tokens: Token[]; actors: Record<string, ActorState> },
  tokenId: string,
) => {
  const token = state.tokens.find((t) => t.id === tokenId);
  if (!token) return undefined;
  return state.actors[token.actorId];
};

export const createGameSlice: StateCreator<
  GameSlice & LogSlice & ActorSlice & { tokens: Token[]; actors: Record<string, ActorState> },
  [['zustand/immer', never]],
  [],
  GameSlice
> = (set) => ({
  phase: 'planning',
  plannedActions: {},

  commitPlan: (tokenId, cards, strengthColor, modifier, actionName, targetDefense) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;

      // Remove cards from hand
      const cardIds = new Set(cards.map((c) => c.id));
      actor.deck.hand = actor.deck.hand.filter((c) => !cardIds.has(c.id));

      // Set Plan
      state.plannedActions[tokenId] = {
        actorId: tokenId,
        actorName: actor.name,
        cards: cards,
        strengthColor: strengthColor,
        modifier: modifier,
        actionName: actionName,
        targetDefense: targetDefense,
        move: state.plannedActions[tokenId]?.move,
      };

      state.logs.push(createLog(`${actor.name} has prepared an action.`, 'Player'));
    }),

  cancelPlan: (tokenId) =>
    set((state) => {
      const plan = state.plannedActions[tokenId];
      if (!plan) return;

      // Return cards to hand
      const actor = getActor(state, tokenId);
      if (actor && plan.cards.length > 0) {
        actor.deck.hand.push(...plan.cards);
      }

      // Reset Plan (keep move)
      state.plannedActions[tokenId] = {
        ...plan,
        cards: [],
        actionName: undefined,
        modifier: 0,
      };

      state.logs.push(createLog(`${actor?.name || 'Unknown'} is revising their plan.`, 'System'));
    }),

  passTurn: (tokenId) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      state.plannedActions[tokenId] = {
        actorId: tokenId,
        actorName: actor?.name || 'Unknown',
        cards: [],
        strengthColor: RESOURCE_TYPES.RED,
        modifier: 0,
        actionName: 'Pass',
        move: state.plannedActions[tokenId]?.move,
      };
      state.logs.push(createLog(`${actor?.name || 'Unknown'} passes and waits.`, 'Player'));
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

  playImmediate: (tokenId, cards, _strengthColor, _modifier, actionName, _targetDefense) =>
    set((state) => {
      // Deprecated/Optimistic Only - Server Authoritative now.
      // This might be removed entirely if 'playImmediate' is not used.
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const cardNames = cards.map((c) => c.name).join(' + ');

      state.logs.push(
        createLog(`Action performed: ${actionName || 'Improvise'} (${cardNames})`, 'Player'),
      );
    }),
});
