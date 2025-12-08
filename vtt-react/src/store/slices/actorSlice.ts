import { StateCreator } from 'zustand';
import {
  ActorState,
  TokenType,
  PlayerDeckState,
  Token,
  CoreCard,
  ConsequenceCard,
} from '../../types';
import { INITIAL_ACTORS, RESOURCE_TYPES } from '../../constants';
import { generateDeck } from '../../services/deckFactory';
import {
  drawCards,
  performDefend,
  getAttributeValue,
  calculateSeverity,
} from '../../services/ruleService';
import { shuffle } from '../../utils';
import { STATUS_DATA } from '../../services/deckFactory';
import GENERATED_DATA from '../../data/generated_cards.json';
import { LogSlice, createLog } from './logSlice';
import { createActor } from '../../services/actorFactory';

export interface ActorSlice {
  actors: Record<string, ActorState>;
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
    statusType: string,
    destination: 'discard' | 'hand' | 'draw',
  ) => void;
  removeStatus: (tokenId: string, statusType: string) => void;
}

// Helper to get actor from state
const getActor = (
  state: { tokens: Token[]; actors: Record<string, ActorState> },
  tokenId: string,
) => {
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
        const templateId = actor.name.toLowerCase().replace(/\s+/g, '-');
        const { deck, equipped } = generateDeck(templateId);

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
      const newActor = createActor(name, actorType, color, templateId);
      state.actors[newActor.id] = newActor;

      // Also spawn token (Logic moved from dispatch, but requires access to tokens)
      state.tokens.push({
        id: `token-${newActor.id}`,
        actorId: newActor.id,
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

      // Filter by severity field
      const pool = (GENERATED_DATA.consequences as ConsequenceCard[]).filter(
        (c) => c.severity === targetSeverity,
      );

      const selection =
        pool.length > 0
          ? pool[Math.floor(Math.random() * pool.length)]
          : {
              id: `generic-sev-${targetSeverity}`,
              name: 'Generic Wound',
              type: 'consequenceCard',
              tags: [`Severity_${targetSeverity}`],
              effects: ['You are hurt.'],
              severity: targetSeverity,
            };

      const newConsequence: ConsequenceCard = {
        ...selection,
        id: Math.random().toString(),
        type: 'consequenceCard',
      } as ConsequenceCard;

      actor.deck.consequences.push(newConsequence);
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
      // Look up by exact ID first (e.g. "status-fatigue")
      const template = STATUS_DATA.find((c) => c.id === statusType);
      if (!template) {
        console.warn(`Status card template not found for id: ${statusType}`);
        return;
      }

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
        // We need to match the card type. The instantiated cards have random IDs.
        // But they should share the same name or we can check if the ID starts with the statusType (if we preserved it)
        // Current implementation assigns `Math.random()` to ID, so we can't rely on ID prefix.
        // We must rely on Name or Tags.
        // The `statusType` passed in is now the `id` of the template (e.g. "status-fatigue").
        // Let's find the template to get the name.
        const template = STATUS_DATA.find((c) => c.id === statusType);
        if (!template) return null;

        const idx = arr.findIndex((c) => c.name === template.name);
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
