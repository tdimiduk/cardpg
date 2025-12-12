import { describe, test, expect } from 'vitest';
import { calculateStackStrength } from '../services/ruleService';
import { CoreCard, ItemCard, Inline } from '../types';
import { T } from '../utils';
import { RESOURCE_TYPES } from '../constants';

// Helper for tests
const createCard = (
  name: string,
  red?: number,
  yellow?: number,
  blue?: number,
  flavor: Inline[] = [],
  id?: string,
  tags?: string[],
  type: 'coreCard' | 'itemCard' | 'fatigue' = 'coreCard',
): CoreCard | ItemCard => {
  if (type === 'itemCard') {
    return {
      type: 'itemCard',
      id: id || name,
      name,
      flavor,
      tags: tags || [],
      weight: 0,
      value: 0,
    } as ItemCard;
  }
  return {
    type: 'coreCard',
    id: id || name,
    name,
    stats: { red: red || 0, yellow: yellow || 0, blue: blue || 0 },
    flavor,
    tags: type === 'fatigue' ? ['fatigue'] : tags || [],
    rules: [],
  } as CoreCard;
};

describe('Rule Service', () => {
  // --- Setup Mocks ---
  const cardA = createCard('A', 2, 2, 2, [T('A')], undefined) as CoreCard; // 2/2/2
  const cardB = createCard('B', 3, 3, 3, [T('B')], undefined) as CoreCard; // 3/3/3
  const fatigueCard = createCard(
    'Fatigue',
    0,
    0,
    0,
    [T('F')],
    undefined,
    undefined,
    'fatigue',
  ) as CoreCard; // 0/0/0

  test('Strength Calculation', () => {
    // Stack: CardA (2 Red) + CardB (3 Red)
    const stack = [cardA, cardB];
    const strRed = calculateStackStrength(stack, RESOURCE_TYPES.RED, 0);
    expect(strRed).toBe(5); // 2 + 3 = 5

    const strMod = calculateStackStrength(stack, RESOURCE_TYPES.RED, 2);
    expect(strMod).toBe(7); // 5 + 2 = 7

    const strBlue = calculateStackStrength([fatigueCard], RESOURCE_TYPES.BLUE, 0);
    expect(strBlue).toBe(0); // 0
  });

  test('Plan & Cancel Simulation', () => {
    // Simulate the data flow of planning an action and then cancelling it
    const handStart = [cardA, cardB];
    const planningStack = [cardA];

    // 1. Plan: Remove A from hand
    const handPlanned = handStart.filter((c) => c.id !== cardA.id);
    expect(handPlanned.length).toBe(1);
    expect(handPlanned[0].id).toBe(cardB.id);

    // 2. Cancel: Return A to hand
    const handRestored = [...handPlanned, ...planningStack];
    expect(handRestored.length).toBe(2);
    expect(handRestored.some((c) => c.id === cardA.id)).toBe(true);
  });

  test('Planned Action Strength', () => {
    // Simulate calculating strength for a revealed plan (e.g., Attack Red: Blue + 2) using 2 cards
    // CardA(Blue:2) + CardB(Blue:3) + Modifier(2)
    const planStack = [cardA, cardB];
    const planStrength = calculateStackStrength(planStack, RESOURCE_TYPES.BLUE, 2);
    expect(planStrength).toBe(2 + 3 + 2);
  });
});
