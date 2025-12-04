import { describe, it, expect } from 'vitest';
import { createActor } from '../services/actorFactory';
import { TokenType } from '../types';

describe('actorFactory', () => {
  it('should create an actor with matching deck name', () => {
    const actor = createActor('Lizard Warrior', TokenType.MONSTER);
    expect(actor.name).toBe('Lizard Warrior');
    expect(actor.deck.drawPile.length).toBeGreaterThan(0);
    // Check if deck is lizard-warrior (has specific cards or stats)
    // We can check if the deck size matches the expected size for lizard-warrior (24)
    expect(actor.deck.drawPile.length + actor.deck.hand.length).toBe(24);
  });

  it('should fallback to default deck for unknown PC', () => {
    const actor = createActor('Unknown Hero', TokenType.PC);
    expect(actor.name).toBe('Unknown Hero');
    expect(actor.deck.drawPile.length).toBeGreaterThan(0);
    // Swashbuckler deck size is also 24, but we can check if it works
    expect(actor.deck.drawPile.length + actor.deck.hand.length).toBe(24);
  });

  it('should fallback to default deck for unknown Monster', () => {
    const actor = createActor('Unknown Monster', TokenType.MONSTER);
    expect(actor.name).toBe('Unknown Monster');
    expect(actor.deck.drawPile.length).toBeGreaterThan(0);
    expect(actor.deck.drawPile.length + actor.deck.hand.length).toBe(24);
  });

  it('should use provided templateId if given', () => {
    // Force a specific template regardless of name
    const actor = createActor('My Custom Hero', TokenType.PC, undefined, 'lizard-warrior');
    expect(actor.name).toBe('My Custom Hero');
    expect(actor.deck.drawPile.length).toBeGreaterThan(0);
  });
});
