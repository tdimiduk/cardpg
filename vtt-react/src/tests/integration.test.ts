import { describe, it, expect, beforeEach } from 'vitest';
import { useGameStore } from '../store/gameStore';
import { INITIAL_ACTORS, INITIAL_TOKENS } from '../constants';

describe('Game Store Integration', () => {
  beforeEach(() => {
    useGameStore.setState({
      actors: INITIAL_ACTORS,
      tokens: INITIAL_TOKENS,
      logs: [],
      phase: 'planning',
      activeActorId: Object.keys(INITIAL_ACTORS)[0] || null,
    });
  });

  it('should handle planning and resolution flow', () => {
    // Setup - Simulate Server State Update
    const testActorId = 'actor-1';
    const testTokenId = 'token-1';
    const testCardId = 'card-1';
    
    useGameStore.setState((state) => {
      state.actors[testActorId] = {
        id: testActorId,
        name: 'Test Actor',
        type: 'PC' as any,
        color: '#ff0000',
        deck: {
          drawPile: [],
          hand: [{ id: testCardId, name: 'Slash', type: 'coreCard', stats: {} } as any],
          discardPile: [],
          flippedPile: [],
          equipped: [],
          consequences: [],
        },
        registry: {
          [testCardId]: { name: 'Slash', type: 'coreCard' } as any
        }
      };
      state.tokens.push({
        id: testTokenId,
        actorId: testActorId,
        x: 0, 
        y: 0,
        size: 1
      });
      state.activeActorId = testActorId;
    });

    const store = useGameStore.getState();

    // Reveal
    store.revealAndResolve();
    expect(useGameStore.getState().phase).toBe('resolution');

    // End Round
    store.endRound();
    expect(useGameStore.getState().phase).toBe('planning');
  });
});
