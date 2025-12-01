import { describe, it, expect } from 'vitest';
import { getActorTemplates, generateDeck } from './deckFactory';

describe('deckFactory', () => {
  it('should load actor templates from JSON', () => {
    const templates = getActorTemplates();
    expect(templates.length).toBeGreaterThan(0);
  });

  it('should filter templates by type', () => {
    const heroes = getActorTemplates('pc');
    const monsters = getActorTemplates('monster');

    expect(heroes.length).toBeGreaterThan(0);
    expect(monsters.length).toBeGreaterThan(0);

    // Verify tags
    heroes.forEach((h) => expect(h.tags).toContain('pc'));
    monsters.forEach((m) => expect(m.tags).toContain('monster'));
  });

  it('should generate a deck for a specific template', () => {
    const heroes = getActorTemplates('pc');
    const templateId = heroes[0].id;
    const { deck } = generateDeck(templateId);

    expect(deck.length).toBeGreaterThan(0);
    // Equipped might be empty for some, but usually not.
    // expect(equipped.length).toBeGreaterThan(0);
  });

  it('should handle invalid template ID gracefully', () => {
    const { deck, equipped } = generateDeck('invalid-id');
    expect(deck).toEqual([]);
    expect(equipped).toEqual([]);
  });

  it('should support legacy fallbacks', () => {
    // Assuming 'swashbuckler' and 'lizard-warrior' exist in the JSON
    // If they don't, these tests will fail and we'll know we need to update the IDs in deckFactory.ts

    const { deck: starterDeck } = generateDeck('swashbuckler');
    expect(starterDeck.length).toBeGreaterThan(0);

    const { deck: monsterDeck } = generateDeck('lizard-warrior');
    expect(monsterDeck.length).toBeGreaterThan(0);
  });
});
