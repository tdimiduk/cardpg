import { describe, test, expect } from 'vitest';
import { drawCards, calculateStackStrength, performDefend } from '../services/ruleService';
import { createCard } from '../services/deckFactory';
import { T } from '../data/cardData';
import { PlayerDeckState } from '../types';

describe('Rule Service', () => {
  // --- Setup Mocks ---
  const cardA = createCard('A', 2, 2, 2, [T('A')], undefined); // 2/2/2
  const cardB = createCard('B', 3, 3, 3, [T('B')], undefined); // 3/3/3
  const itemCard = createCard('Item', undefined, undefined, undefined, [T('I')], undefined, undefined, 'item'); // undefined stats
  const fatigueCard = createCard('Fatigue', 0, 0, 0, [T('F')], undefined, undefined, 'fatigue'); // 0/0/0

  test('Basic Draw', () => {
    const deck1: PlayerDeckState = {
      drawPile: [cardA, cardB], // Stack: Top is right (pop)
      hand: [],
      discardPile: [],
      flippedPile: [],
      equipped: [],
      consequences: []
    };
    
    const res1 = drawCards(deck1, 1);
    expect(res1.drawn.length).toBe(1);
    expect(res1.newState.hand.length).toBe(1);
    expect(res1.newState.drawPile.length).toBe(1);
  });

  test('Fatigue Cycle', () => {
    const deck2: PlayerDeckState = {
      drawPile: [],
      hand: [],
      discardPile: [cardA, cardB],
      flippedPile: [],
      equipped: [],
      consequences: []
    };
    
    // Requesting 1 card from empty pile should trigger shuffle
    const res2 = drawCards(deck2, 1);
    expect(res2.fatigueTriggered).toBe(true);
    // Discard (2) + Fatigue (2) - Drawn (1) = 3 remaining in draw pile
    expect(res2.newState.drawPile.length).toBe(3);
    expect(res2.newState.discardPile.length).toBe(0);
  });

  test('Strength Calculation', () => {
    // Stack: CardA (2 Red) + CardB (3 Red) + Item (Undefined/0 Red)
    const stack = [cardA, cardB, itemCard];
    const strRed = calculateStackStrength(stack, 'red', 0);
    expect(strRed).toBe(5); // 2 + 3 + 0 = 5
    
    const strMod = calculateStackStrength(stack, 'red', 2);
    expect(strMod).toBe(7); // 5 + 2 = 7

    const strBlue = calculateStackStrength([fatigueCard, itemCard], 'blue', 0);
    expect(strBlue).toBe(0); // 0 + undefined = 0
  });

  test('Defense Logic', () => {
    const deck3: PlayerDeckState = {
      drawPile: [cardB], // Top is CardB (3)
      hand: [],
      discardPile: [],
      flippedPile: [cardA], // Already flipped CardA (2)
      equipped: [],
      consequences: []
    };

    // Defending vs Target 10. Current flipeed (2). Next card (3). Total should be 5.
    const defRes = performDefend(deck3, 10, 'red');
    expect(defRes.total).toBe(5);
    expect(defRes.newState.flippedPile.length).toBe(2);
    expect(defRes.newState.drawPile.length).toBe(0);
  });

  test('Plan & Cancel Simulation', () => {
    // Simulate the data flow of planning an action and then cancelling it
    const handStart = [cardA, cardB];
    const planningStack = [cardA];
    
    // 1. Plan: Remove A from hand
    const handPlanned = handStart.filter(c => c.id !== cardA.id);
    expect(handPlanned.length).toBe(1);
    expect(handPlanned[0].id).toBe(cardB.id);

    // 2. Cancel: Return A to hand
    const handRestored = [...handPlanned, ...planningStack];
    expect(handRestored.length).toBe(2);
    expect(handRestored.some(c => c.id === cardA.id)).toBe(true);
  });

  test('Planned Action Strength', () => {
    // Simulate calculating strength for a revealed plan (e.g., Attack Red: Blue + 2) using 2 cards
    // CardA(Blue:2) + CardB(Blue:3) + Modifier(2)
    const planStack = [cardA, cardB];
    const planStrength = calculateStackStrength(planStack, 'blue', 2);
    expect(planStrength).toBe(2 + 3 + 2);
  });
});
