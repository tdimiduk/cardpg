import { Card, CardColor, PlayerDeckState } from "../types";
import { STATUS_CARDS } from "../data/statuses";

export const shuffle = <T>(array: T[]): T[] => {
  const newArray = [...array];
  for (let i = newArray.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
  }
  return newArray;
};

// Helper to get a fresh instance of a status card
const getStatusCard = (type: 'fatigue' | 'wound'): Card => {
    const template = STATUS_CARDS.find(c => c.type === type);
    if (!template) throw new Error(`Status card type ${type} not found`);
    return { ...template, id: Math.random().toString() } as Card;
};

export const drawCards = (currentDeck: PlayerDeckState, count: number): { newState: PlayerDeckState, drawn: Card[], fatigueTriggered: boolean } => {
  let { drawPile, discardPile, hand } = currentDeck;
  const drawn: Card[] = [];
  let fatigueTriggered = false;

  for (let i = 0; i < count; i++) {
    if (drawPile.length === 0) {
      // Fatigue Cycle
      fatigueTriggered = true;
      const fatigue1 = getStatusCard('fatigue');
      const fatigue2 = getStatusCard('fatigue');
      
      // Reshuffle discard + 2 fatigue
      drawPile = shuffle([...discardPile, fatigue1, fatigue2]);
      discardPile = [];
    }

    if (drawPile.length > 0) {
      const card = drawPile.pop()!;
      drawn.push(card);
    }
  }

  return {
    newState: {
      ...currentDeck,
      drawPile,
      discardPile,
      hand: [...hand, ...drawn]
    },
    drawn,
    fatigueTriggered
  };
};

export const calculateStackStrength = (stack: Card[], strengthColor: CardColor, modifier: number = 0): number => {
  // Rule: Sum of color values in stack + modifier
  // Safe access: card[strengthColor] might be undefined for Items/Char cards, fallback to 0
  const base = stack.reduce((sum, card) => sum + (card[strengthColor] ?? 0), 0);
  return base + modifier;
};

export const performDefend = (currentDeck: PlayerDeckState, targetValue: number, color: CardColor): { newState: PlayerDeckState, flipped: Card[], success: boolean, total: number } => {
  let { drawPile, discardPile, flippedPile } = currentDeck;
  const newFlipped: Card[] = [];
  let currentTotal = 0;

  // If we are continuing a defense, count existing flipped
  currentTotal = flippedPile.reduce((sum, c) => sum + (c[color] ?? 0), 0);
  
  if (drawPile.length === 0 && discardPile.length > 0) {
       drawPile = shuffle([...discardPile]);
       discardPile = [];
  }

  if (drawPile.length > 0) {
    const card = drawPile.pop()!;
    newFlipped.push(card);
    currentTotal += (card[color] ?? 0);
  }

  return {
    newState: {
      ...currentDeck,
      drawPile,
      discardPile,
      flippedPile: [...flippedPile, ...newFlipped]
    },
    flipped: newFlipped,
    success: currentTotal >= targetValue,
    total: currentTotal
  };
};

export const getAttributeValue = (equipped: Card[], stat: 'def' | 'res'): number => {
  let max = 0;
  let found = false;
  equipped.forEach(c => {
      if (c[stat] !== undefined) {
          max = Math.max(max, c[stat]!);
          found = true;
      }
  });
  return found ? max : 1;
};

export const calculateSeverity = (consequences: Card[], resilience: number): number => {
  return Math.floor(consequences.length / resilience) + 1;
};