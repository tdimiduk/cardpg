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
      activeTokenId: INITIAL_TOKENS[0]?.id || null,
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

  it('should handle card drawing', () => {
    const { initializeGame, drawCards, tokens } = useGameStore.getState();
    initializeGame();

    const tokenId = tokens[0].id;
    const initialHandSize = 4;

    drawCards(tokenId, 2);

    const actor = useGameStore.getState().actors[tokens[0].actorId];
    expect(actor.deck.hand.length).toBe(initialHandSize + 2);
  });

  it('should handle planning and resolution flow', () => {
    useGameStore.getState().initializeGame();

    const store = useGameStore.getState();
    const tokenId = store.tokens[0].id;
    const actor = store.actors[store.tokens[0].actorId];
    const cardToPlay = actor.deck.hand[0];

    // Commit Plan
    store.commitPlan(tokenId, [cardToPlay], RESOURCE_TYPES.RED, 0);

    expect(useGameStore.getState().plannedActions[tokenId]).toBeDefined();
    expect(useGameStore.getState().plannedActions[tokenId].cards[0].id).toBe(cardToPlay.id);

    // Reveal
    store.revealAndResolve();
    expect(useGameStore.getState().phase).toBe('resolution');

    // End Round
    store.endRound();
    expect(useGameStore.getState().phase).toBe('planning');
    expect(useGameStore.getState().plannedActions[tokenId]).toBeUndefined();
  });
});
