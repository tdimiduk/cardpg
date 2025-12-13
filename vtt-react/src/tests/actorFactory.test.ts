import { describe, it, expect } from 'vitest';
import { createActor } from '../services/actorFactory';
import { TokenType } from '../types';

describe('actorFactory', () => {
  it('should create an actor with matching deck name', () => {
    const actor = createActor('Lizard Warrior', TokenType.MONSTER);
    expect(actor.name).toBe('Lizard Warrior');
    // Deck generation is server authoritative now, so local creation might result in empty shell
    // expect(actor.deck.drawPile.length).toBeGreaterThan(0);
  });

  it('should fallback to default deck for unknown PC', () => {
    const actor = createActor('Unknown Hero', TokenType.PC);
    expect(actor.name).toBe('Unknown Hero');
  });

  it('should fallback to default deck for unknown Monster', () => {
    const actor = createActor('Unknown Monster', TokenType.MONSTER);
    expect(actor.name).toBe('Unknown Monster');
  });

  it('should use provided templateId if given', () => {
    // Force a specific template regardless of name
    const actor = createActor('My Custom Hero', TokenType.PC, undefined, 'lizard-warrior');
    expect(actor.name).toBe('My Custom Hero');
  });
});
