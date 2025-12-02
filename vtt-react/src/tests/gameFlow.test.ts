import { describe, it, expect, beforeEach } from 'vitest';
import { useGameStore } from '../store/gameStore';
import { INITIAL_ACTORS, INITIAL_TOKENS, RESOURCE_TYPES } from '../constants';
import { CoreCard, Rule, LogEntry } from '../types';

describe('Game Flow Scenarios', () => {
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

  it('should allow a player to move and attack', () => {
    useGameStore.getState().initializeGame();
    const store = useGameStore.getState();

    const tokenId = store.tokens[0].id;
    const actor = store.actors[store.tokens[0].actorId];

    // Move
    const newToken = { ...store.tokens[0], x: 100, y: 100 };
    store.updateTokenPosition(newToken);

    // Plan Attack
    const attackCard = actor.deck.hand.find((c: CoreCard) =>
      c.rules?.some((r: Rule) => r.type === 'attack'),
    );

    if (attackCard) {
      store.commitPlan(tokenId, [attackCard], RESOURCE_TYPES.RED, 0);

      const plan = useGameStore.getState().plannedActions[tokenId];
      expect(plan.move).toEqual({ x: 100, y: 100 });
      expect(plan.cards).toHaveLength(1);
    }
  });

  it('should resolve combat correctly', () => {
    useGameStore.getState().initializeGame();
    const store = useGameStore.getState();

    const attackerId = store.tokens[0].id;
    const defenderId = store.tokens[1]?.id; // Assuming 2nd token exists

    if (!defenderId) return; // Skip if only 1 token

    const attacker = store.actors[store.tokens[0].actorId];
    const attackCard = attacker.deck.hand.find((c: CoreCard) =>
      c.rules?.some((r: Rule) => r.type === 'attack'),
    );

    if (attackCard) {
      // Plan Attack
      store.commitPlan(attackerId, [attackCard], RESOURCE_TYPES.RED, 0);

      // Resolve
      store.revealAndResolve();

      // Check logs for resolution
      const logs = useGameStore.getState().logs;
      const resolutionLog = logs.find(
        (l: LogEntry) => l.type === 'action' && l.content.includes('resolves Action'),
      );
      expect(resolutionLog).toBeDefined();
    }
  });

  it('should handle fatigue when deck runs out', () => {
    useGameStore.getState().initializeGame();
    const store = useGameStore.getState();

    const tokenId = store.tokens[0].id;

    // Force empty deck
    useGameStore.setState((state) => {
      const a = state.actors[store.tokens[0].actorId];
      a.deck.drawPile = [];
      a.deck.discardPile = []; // Ensure discard is also empty so fatigue triggers
    });

    // Draw
    store.drawCards(tokenId, 1);

    const logs = useGameStore.getState().logs;
    const fatigueLog = logs.find((l: LogEntry) => l.content.includes('Fatigue Cycle'));
    expect(fatigueLog).toBeDefined();
  });

  it('should allow adding and removing consequences', () => {
    useGameStore.getState().initializeGame();
    const store = useGameStore.getState();

    const tokenId = store.tokens[0].id;

    store.addConsequence(tokenId);

    const actor = useGameStore.getState().actors[store.tokens[0].actorId];
    expect(actor.deck.consequences.length).toBe(1);

    const consequenceId = actor.deck.consequences[0].id;
    store.removeConsequence(tokenId, consequenceId);

    const updatedActor = useGameStore.getState().actors[store.tokens[0].actorId];
    expect(updatedActor.deck.consequences.length).toBe(0);
  });
});
