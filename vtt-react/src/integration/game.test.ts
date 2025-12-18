import { describe, it, expect, beforeEach } from 'vitest';
import { useGameStore } from '../store/gameStore';
import { INITIAL_ACTORS } from '../constants';
import type { ActorState, CoreCard } from '../generated/types';

describe('Game Store Integration', () => {
  beforeEach(() => {
    useGameStore.setState({
      actors: INITIAL_ACTORS,
      logs: [],
      phase: 'planning',
      activeActorId: Object.keys(INITIAL_ACTORS)[0] || null,
    });
  });

  it('should handle planning and resolution flow', () => {
    // Setup - Simulate Server State Update
    const testActorId = 'actor-1';
    const testCardId = 'card-1';

    const testCard: CoreCard = {
      type: 'coreCard',
      name: 'Slash',
      stats: { red: 0, yellow: 0, blue: 0 },
    };

    const testActor: ActorState = {
      name: 'Test Actor',
      actorType: 'PC',
      coreState: {
        deck: [],
        hand: [testCardId],
        discard: [],
        defending: [],
        inPlay: {},
        registry: { [testCardId]: testCard },
      },
      tableState: {
        assets: {},
        registry: {},
        consequences: [],
        consequenceRegistry: {},
      },
      spatial: { posX: 0, posY: 0, size: 1 },
      defense: 1,
      resilience: 1,
    };

    useGameStore.setState((state) => {
      state.actors[testActorId] = testActor;
      state.activeActorId = testActorId;
    });

    const store = useGameStore.getState();

    // Reveal
    store.revealAndResolve();
    expect(useGameStore.getState().phase).toBe('resolution');

    // End Round
    store.setPhase('planning');
    expect(useGameStore.getState().phase).toBe('planning');
  });
});
