import { describe, it, expect } from 'vitest';
import { getActorTemplates } from '../services/deckFactory';

describe('deckFactory Normalization', () => {
  it('should inject type: "core" into deck cards', () => {
    const templates = getActorTemplates();
    const actor = templates[0];
    const card = actor.deck[0];

    expect(card.type).toBe('core');
  });

  it('should inject type: "item" into items', () => {
    const templates = getActorTemplates();
    // Find an actor with items
    const actor = templates.find((a) => a.items.length > 0);
    expect(actor).toBeDefined();
    if (actor) {
      const item = actor.items[0];
      expect(item.type).toBe('item');
    }
  });

  it('should inject empty tags if missing', () => {
    const templates = getActorTemplates();
    const actor = templates[0];

    // Check deck cards
    if (actor.deck.length > 0) {
      const card = actor.deck[0];
      expect(card.tags).toBeDefined();
      expect(Array.isArray(card.tags)).toBe(true);
    }

    // Check items
    if (actor.items.length > 0) {
      const item = actor.items[0];
      expect(item.tags).toBeDefined();
      expect(Array.isArray(item.tags)).toBe(true);
    }
  });
});
