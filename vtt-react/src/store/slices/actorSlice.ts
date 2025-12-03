import { StateCreator } from 'zustand';
import { Actor, TokenType, PlayerDeckState, Token, CoreCard } from '../../types';
import { INITIAL_ACTORS, RESOURCE_TYPES } from '../../constants';
import { generateDeck } from '../../services/deckFactory';
import {
  drawCards,
  performDefend,
  getAttributeValue,
  calculateSeverity,
} from '../../services/ruleService';
import { shuffle } from '../../utils';
import { STATUS_CARDS } from '../../data/statuses';
import { CONSEQUENCE_DEFINITIONS } from '../../data/consequences';
import { LogSlice, createLog } from './logSlice';
import { ACTOR_COLORS } from '../../theme';

export interface ActorSlice {
  actors: Record<string, Actor>;
  initializeGame: () => void;
  addActor: (name: string, type: TokenType, color: string, templateId?: string) => void;
  removeActor: (actorId: string) => void;

  // Deck Actions
  drawCards: (tokenId: string, count: number) => void;
  defend: (tokenId: string) => void;
  clearDefense: (tokenId: string) => void;
  reshuffle: (tokenId: string) => void;
  discardCards: (tokenId: string, cardIds: string[]) => void;
  returnToDeck: (tokenId: string, cardIds: string[]) => void;

  // Status & Consequences
  addConsequence: (tokenId: string) => void;
  removeConsequence: (tokenId: string, cardId: string) => void;
  addStatus: (
    tokenId: string,
    statusType: 'fatigue' | 'wound',
    destination: 'discard' | 'hand' | 'draw',
  ) => void;
  removeStatus: (tokenId: string, statusType: 'fatigue' | 'wound') => void;
}

// Helper to get actor from state
const getActor = (state: { tokens: Token[]; actors: Record<string, Actor> }, tokenId: string) => {
  const token = state.tokens.find((t) => t.id === tokenId);
  if (!token) return undefined;
  return state.actors[token.actorId];
};

export const createActorSlice: StateCreator<
  ActorSlice & LogSlice & { tokens: Token[] },
  [['zustand/immer', never]],
  [],
  ActorSlice
> = (set) => ({
  actors: INITIAL_ACTORS,

  initializeGame: () =>
    set((state) => {
      Object.values(state.actors).forEach((actor) => {
        const { deck, equipped } =
          actor.type === TokenType.MONSTER
            ? generateDeck('lizard-warrior')
            : generateDeck('swashbuckler');

        const deckState: PlayerDeckState = {
          drawPile: deck,
          hand: [],
          discardPile: [],
          flippedPile: [],
          equipped: equipped,
          consequences: [],
        };

        const result = drawCards(deckState, 4);
        actor.deck = result.newState;
      });
    }),

  addActor: (name, actorType, color, templateId) =>
    set((state) => {
      const id = Math.random().toString(36).substr(2, 9);
      let deckRes;
      if (templateId) {
        deckRes = generateDeck(templateId);
      } else if (actorType === TokenType.MONSTER) {
        deckRes = generateDeck('lizard-warrior');
      } else {
        deckRes = generateDeck('swashbuckler');
      }

      const newActor: Actor = {
        id,
        name,
        type: actorType,
        color: color || (actorType === TokenType.MONSTER ? ACTOR_COLORS.MONSTER : ACTOR_COLORS.PC),
        deck: {
          drawPile: deckRes.deck,
          hand: [],
          discardPile: [],
          flippedPile: [],
          equipped: deckRes.equipped,
          consequences: [],
        },
      };

      const drawRes = drawCards(newActor.deck, 4);
      newActor.deck = drawRes.newState;

      state.actors[id] = newActor;

      // Also spawn token (Logic moved from dispatch, but requires access to tokens)
      // We can call the board slice action if we had access, or just mutate here since we are in the same store
      state.tokens.push({
        id: `token-${id}`,
        actorId: id,
        x: 0,
        y: 0,
        size: 1,
      });

      state.logs.push(createLog(`Added actor: ${name}`, 'GM'));
    }),

  removeActor: (actorId) =>
    set((state) => {
      if (!state.actors[actorId]) return;

      // Remove tokens
      state.tokens = state.tokens.filter((t) => t.actorId !== actorId);
      // Remove actor
      delete state.actors[actorId];
      // Remove plans (handled in board/game slice usually, but we can do it here if we have access)
      // Ideally we'd call a cleanup action, but direct mutation is fine in combined store
      // We'll leave plan cleanup for now or add it if we can access plannedActions
      state.logs.push(createLog(`Removed actor ${actorId}`, 'GM'));
    }),

  drawCards: (tokenId, count) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const { newState, drawn, fatigueTriggered } = drawCards(actor.deck, count);
      actor.deck = newState;

      if (fatigueTriggered) {
        state.logs.push(createLog(`Fatigue Cycle triggered for ${actor.name}.`, 'System'));
      }
      if (drawn.length > 0) {
        state.logs.push(createLog(`${actor.name} drew ${drawn.length} card(s).`, 'System'));
      }
    }),

  defend: (tokenId) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const { newState, flipped } = performDefend(actor.deck, 999, RESOURCE_TYPES.RED);
      actor.deck = newState;
      if (flipped.length > 0) {
        state.logs.push(
          createLog(`${actor.name} flipped for Defense: ${flipped[0].name}`, 'Player'),
        );
      }
    }),

  clearDefense: (tokenId) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      actor.deck.discardPile.push(...actor.deck.flippedPile);
      actor.deck.flippedPile = [];
    }),

  reshuffle: (tokenId) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const newDraw = shuffle([...actor.deck.drawPile, ...actor.deck.discardPile]);
      actor.deck.drawPile = newDraw;
      actor.deck.discardPile = [];
      state.logs.push(createLog(`${actor.name} reshuffled discard pile into deck.`, 'System'));
    }),

  discardCards: (tokenId, cardIds) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const cardsToDiscard = actor.deck.hand.filter((c) => cardIds.includes(c.id));
      actor.deck.hand = actor.deck.hand.filter((c) => !cardIds.includes(c.id));
      actor.deck.discardPile.push(...cardsToDiscard);
      state.logs.push(
        createLog(`${actor.name} discarded ${cardsToDiscard.length} card(s).`, 'System'),
      );
    }),

  returnToDeck: (tokenId, cardIds) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const cards = actor.deck.hand.filter((c) => cardIds.includes(c.id));
      actor.deck.hand = actor.deck.hand.filter((c) => !cardIds.includes(c.id));
      actor.deck.drawPile.push(...cards);
      state.logs.push(
        createLog(`${actor.name} returned ${cards.length} card(s) to top of deck.`, 'System'),
      );
    }),

  addConsequence: (tokenId) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const resilience = getAttributeValue(actor.deck.equipped, 'res');
      const currentSeverity = calculateSeverity(actor.deck.consequences, resilience);
      const targetSeverity = Math.min(currentSeverity, 3);

      const pool = CONSEQUENCE_DEFINITIONS.filter((c) => c.severity === targetSeverity);
      const selection =
        pool.length > 0
          ? pool[Math.floor(Math.random() * pool.length)]
          : { name: 'Generic Wound', text: 'You are hurt.', severity: targetSeverity };

      const newConsequence = {
        type: 'coreCard' as const,
        id: Math.random().toString(),
        name: selection.name,
        flavor: [{ type: 'textRun' as const, content: selection.text }],
        tags: ['wound'],
        stats: { red: 0, yellow: 0, blue: 0 },
        rules: [],
        cost: undefined,
      };

      actor.deck.consequences.push(newConsequence as CoreCard);
      state.logs.push(
        createLog(
          `${actor.name} takes a Level ${targetSeverity} Consequence: ${selection.name}.`,
          'System',
        ),
      );
    }),

  removeConsequence: (tokenId, cardId) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const target = actor.deck.consequences.find((c) => c.id === cardId);
      actor.deck.consequences = actor.deck.consequences.filter((c) => c.id !== cardId);
      if (target) {
        state.logs.push(
          createLog(`${actor.name} removed consequence: "${target.name}".`, 'System'),
        );
      }
    }),

  addStatus: (tokenId, statusType, destination) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const template = STATUS_CARDS.find((c) => c.tags?.includes(statusType));
      if (!template) return;

      const newCard: CoreCard = { ...template, id: Math.random().toString() };

      if (destination === 'discard') actor.deck.discardPile.push(newCard);
      else if (destination === 'draw') actor.deck.drawPile.push(newCard);
      else actor.deck.hand.push(newCard); // Added hand case

      const label =
        destination === 'draw'
          ? 'top of deck'
          : destination === 'discard'
            ? 'discard pile'
            : 'hand';
      state.logs.push(createLog(`${actor.name} added ${newCard.name} to ${label}.`, 'System'));
    }),

  removeStatus: (tokenId, statusType) =>
    set((state) => {
      const actor = getActor(state, tokenId);
      if (!actor) return;
      const removeFirst = (arr: CoreCard[]) => {
        const idx = arr.findIndex((c) => c.tags?.includes(statusType));
        if (idx > -1) {
          const removed = arr.splice(idx, 1)[0];
          return removed;
        }
        return null;
      };

      let removed = removeFirst(actor.deck.discardPile);
      if (!removed) removed = removeFirst(actor.deck.drawPile);
      if (!removed) removed = removeFirst(actor.deck.hand);

      if (removed) {
        state.logs.push(createLog(`Removed ${removed.name} from ${actor.name}'s deck.`, 'System'));
      } else {
        state.logs.push(createLog(`No ${statusType} cards found to remove.`, 'System'));
      }
    }),
});
