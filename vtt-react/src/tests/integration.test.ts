import { describe, it, expect } from 'vitest';
import { useGameStore } from '../store/gameStore';
import { getActorTemplates } from '../services/deckFactory';

describe('App Initialization', () => {
  it('should initialize game without crashing', () => {
    const store = useGameStore.getState();
    expect(store).toBeDefined();

    // Simulate App.tsx useEffect
    store.dispatch({ type: 'INITIALIZE_GAME' });

    const state = useGameStore.getState();
    const actors = Object.values(state.actors);
    expect(actors.length).toBeGreaterThan(0);

    actors.forEach((actor) => {
      expect(actor.deck.drawPile.length).toBeGreaterThanOrEqual(0);
      // It might be 0 if they drew everything, but hand should have cards
      expect(actor.deck.hand.length).toBe(4);
    });
  });

  it('should load templates correctly', () => {
    const templates = getActorTemplates();
    expect(Array.isArray(templates)).toBe(true);
    expect(templates.length).toBeGreaterThan(0);

    // Verify normalization
    templates.forEach((t) => {
      t.items.forEach((item) => {
        expect(item.traits).toBeDefined();
        expect(Array.isArray(item.traits)).toBe(true);
      });
    });
  });
});
