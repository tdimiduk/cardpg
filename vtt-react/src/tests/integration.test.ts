import { describe, it, expect, beforeEach } from 'vitest';
import { useGameStore } from '../store/gameStore';
import { INITIAL_ACTORS, INITIAL_TOKENS, RESOURCE_TYPES } from '../constants';

describe('Game Store Integration', () => {
  beforeEach(() => {
    useGameStore.setState({
      actors: INITIAL_ACTORS,
      tokens: INITIAL_TOKENS,
      logs: [],
      phase: 'planning',
      activeActorId: Object.keys(INITIAL_ACTORS)[0] || null,
      plannedActions: {},
    });
  });

  it('should initialize game state', () => {
    const { initializeGame } = useGameStore.getState();
    initializeGame();

    const actorList = Object.values(useGameStore.getState().actors);
    expect(actorList.length).toBeGreaterThan(0);
    actorList.forEach((actor) => {
      expect(actor.deck.drawPile.length).toBeGreaterThan(0);
      expect(actor.deck.hand.length).toBe(4);
    });
  });

  it('should handle planning and resolution flow', () => {
    useGameStore.getState().initializeGame();

    const store = useGameStore.getState();
    const tokenId = store.tokens[0].id;
    const actor = store.actors[store.tokens[0].actorId];
    const cardToPlay = actor.deck.hand[0];

    // Commit Plan
    store.commitPlan(tokenId, [cardToPlay], RESOURCE_TYPES.RED, 0);

    // plannedActions stored by actorId
    const actingActorId = store.tokens.find((t) => t.id === tokenId)?.actorId || '';
    expect(useGameStore.getState().plannedActions[actingActorId]).toBeDefined();
    expect(useGameStore.getState().plannedActions[actingActorId].cards[0].id).toBe(cardToPlay.id);

    // Reveal
    store.revealAndResolve();
    expect(useGameStore.getState().phase).toBe('resolution');

    // End Round
    store.endRound();
    expect(useGameStore.getState().phase).toBe('planning');
    // plan stored by actorId
    // We already have actingActorId
    expect(useGameStore.getState().plannedActions[actingActorId]).toBeUndefined();
  });
});
