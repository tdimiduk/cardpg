import { StateCreator } from 'zustand';
import { GamePhase, PlannedAction, CoreCard, ResourceType, Token, Actor } from '../../types';
import { RESOURCE_TYPES } from '../../constants';
import { calculateStackStrength, drawCards } from '../../services/ruleService';
import { resolveMovement } from '../../services/resolutionService';
import { LogSlice, createLog } from './logSlice';
import { ActorSlice } from './actorSlice';

export interface GameSlice {
  phase: GamePhase;
  plannedActions: Record<string, PlannedAction>;

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
const getActor = (state: { tokens: Token[]; actors: Record<string, Actor> }, tokenId: string) => {
  const token = state.tokens.find((t) => t.id === tokenId);
  if (!token) return undefined;
  return state.actors[token.actorId];
};

export const createGameSlice: StateCreator<
  GameSlice & LogSlice & ActorSlice & { tokens: Token[]; actors: Record<string, Actor> },
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
      state.logs.push(createLog('All actions revealed! Resolving now...', 'GM'));

      // Resolve Actions & Discard Played Cards
      Object.entries(state.plannedActions).forEach(([tokenId, plan]) => {
        const actor = getActor(state, tokenId);

        if (plan.actionName === 'Pass' && plan.cards.length === 0) {
          state.logs.push(createLog(`${plan.actorName} takes no action.`, 'System'));
          return;
        }

        if (plan.cards.length > 0) {
          const cards = plan.cards as CoreCard[];
          const strength = calculateStackStrength(cards, plan.strengthColor, plan.modifier);
          const cardNames = cards.map((c) => c.name).join(' + ');

          state.logs.push(
            createLog(
              plan.actionName
                ? `${plan.actorName} resolves ${plan.actionName} (${cardNames})`
                : `${plan.actorName} resolves Action (${cardNames})`,
              'System',
              'action',
              {
                total: strength,
                color: plan.strengthColor,
                targetColor: plan.targetDefense,
                label: 'Strength',
              },
            ),
          );

          // Move to discard
          if (actor) {
            actor.deck.discardPile.push(...cards);
          }
        }
      });
    }),

  endRound: () =>
    set((state) => {
      // 1. Resolve Movement
      const { movedTokens, logs: moveLogs } = resolveMovement(state.tokens, state.plannedActions);
      state.tokens = movedTokens;
      if (moveLogs.length > 0) {
        state.logs.push(createLog(moveLogs.join(' '), 'System'));
      }

      // Identify defeated
      const defeatedIds = Object.values(state.actors)
        .filter((a) => a.deck.consequences.some((c) => c.name === 'Taken Out'))
        .map((a) => a.id);

      // Reset Plans
      const nextPlans: Record<string, PlannedAction> = {};
      state.tokens.forEach((t) => {
        const actor = state.actors[t.actorId];
        if (actor && defeatedIds.includes(actor.id)) {
          nextPlans[t.id] = {
            actorId: t.id,
            actorName: actor.name,
            cards: [],
            strengthColor: RESOURCE_TYPES.RED,
            modifier: 0,
            actionName: 'Pass',
          };
        }
      });
      state.plannedActions = nextPlans;
      state.phase = 'planning';

      // Draw Cards
      let activeCount = 0;
      let fatigueMsg = '';

      Object.values(state.actors).forEach((actor) => {
        if (defeatedIds.includes(actor.id)) return;

        const { newState, fatigueTriggered } = drawCards(actor.deck, 2);
        actor.deck = newState;
        activeCount++;
        if (fatigueTriggered) fatigueMsg += ` Fatigue for ${actor.name}.`;
      });

      state.logs.push(
        createLog(`Round Ended. ${activeCount} active actors drew cards.${fatigueMsg}`, 'GM'),
      );
    }),

  playImmediate: (tokenId, cards, strengthColor, modifier, actionName, targetDefense) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;

      // Remove from hand
      const cardIds = new Set(cards.map((c) => c.id));
      actor.deck.hand = actor.deck.hand.filter((c) => !cardIds.has(c.id));

      // Discard
      actor.deck.discardPile.push(...cards);

      // Log
      const strength = calculateStackStrength(cards, strengthColor, modifier);
      const cardNames = cards.map((c) => c.name).join(' + ');

      state.logs.push(
        createLog(
          actionName
            ? `${actor.name} used ${actionName} (${cardNames})`
            : `${actor.name} performed Action (${cardNames})`,
          'Player',
          'action',
          {
            total: strength,
            color: strengthColor,
            targetColor: targetDefense,
            label: 'Strength',
          },
        ),
      );
    }),
});
