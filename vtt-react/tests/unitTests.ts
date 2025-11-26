
import { drawCards, calculateStackStrength, performDefend } from '../services/ruleService';
import { createCard } from '../services/deckFactory';
import { T } from '../data/cardData';
import { PlayerDeckState } from '../types';

type TestResult = { passed: boolean; message: string };

const assert = (condition: boolean, message: string): TestResult => {
  return { passed: condition, message: condition ? `PASS: ${message}` : `FAIL: ${message}` };
};

export const runUnitTests = (): string[] => {
  const results: TestResult[] = [];

  // --- Setup Mocks ---
  const cardA = createCard('A', 2, 2, 2, [T('A')], undefined); // 2/2/2
  const cardB = createCard('B', 3, 3, 3, [T('B')], undefined); // 3/3/3
  const itemCard = createCard('Item', undefined, undefined, undefined, [T('I')], undefined, undefined, 'item'); // undefined stats
  const fatigueCard = createCard('Fatigue', 0, 0, 0, [T('F')], undefined, undefined, 'fatigue'); // 0/0/0

  // --- Test 1: Basic Draw ---
  const deck1: PlayerDeckState = {
    drawPile: [cardA, cardB], // Stack: Top is right (pop)
    hand: [],
    discardPile: [],
    flippedPile: [],
    equipped: [],
    consequences: []
  };
  
  const res1 = drawCards(deck1, 1);
  results.push(assert(res1.drawn.length === 1, 'Draws 1 card'));
  results.push(assert(res1.newState.hand.length === 1, 'Hand size increases'));
  results.push(assert(res1.newState.drawPile.length === 1, 'Draw pile decreases'));

  // --- Test 2: Fatigue Cycle ---
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
  results.push(assert(res2.fatigueTriggered === true, 'Fatigue triggered on empty draw'));
  // Discard (2) + Fatigue (2) - Drawn (1) = 3 remaining in draw pile
  results.push(assert(res2.newState.drawPile.length === 3, 'Deck reshuffled with 2 fatigue cards added'));
  results.push(assert(res2.newState.discardPile.length === 0, 'Discard pile cleared after reshuffle'));

  // --- Test 3: Strength Calculation ---
  // Stack: CardA (2 Red) + CardB (3 Red) + Item (Undefined/0 Red)
  const stack = [cardA, cardB, itemCard];
  const strRed = calculateStackStrength(stack, 'red', 0);
  results.push(assert(strRed === 5, 'Strength Sum (Red): 2 + 3 + 0 = 5'));
  
  const strMod = calculateStackStrength(stack, 'red', 2);
  results.push(assert(strMod === 7, 'Strength with Modifier: 5 + 2 = 7'));

  const strBlue = calculateStackStrength([fatigueCard, itemCard], 'blue', 0);
  results.push(assert(strBlue === 0, 'Strength with Fatigue(0) and Item(undefined) = 0'));

  // --- Test 4: Defense Logic ---
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
  results.push(assert(defRes.total === 5, 'Defense accumulates: Existing(2) + New(3) = 5'));
  results.push(assert(defRes.newState.flippedPile.length === 2, 'Flipped pile grows'));
  results.push(assert(defRes.newState.drawPile.length === 0, 'Card moved from draw to flipped'));

  // --- Test 5: Plan & Cancel Simulation ---
  // Simulate the data flow of planning an action and then cancelling it
  const handStart = [cardA, cardB];
  const planningStack = [cardA];
  
  // 1. Plan: Remove A from hand
  const handPlanned = handStart.filter(c => c.id !== cardA.id);
  results.push(assert(handPlanned.length === 1 && handPlanned[0].id === cardB.id, 'Planning removes card from hand'));

  // 2. Cancel: Return A to hand
  const handRestored = [...handPlanned, ...planningStack];
  results.push(assert(handRestored.length === 2, 'Cancelling restores hand size'));
  results.push(assert(handRestored.some(c => c.id === cardA.id), 'Restored hand contains original card'));

  // --- Test 6: Planned Action Strength ---
  // Simulate calculating strength for a revealed plan (e.g., Attack Red: Blue + 2) using 2 cards
  // CardA(Blue:2) + CardB(Blue:3) + Modifier(2)
  const planStack = [cardA, cardB];
  const planStrength = calculateStackStrength(planStack, 'blue', 2);
  results.push(assert(planStrength === 2 + 3 + 2, `Planned Strength: 2+3+2 = ${planStrength}`));

  return results.map(r => r.message);
};
