import { CoreCard, ResourceType, PlayerDeckState, Stats, Card } from "../types";
import { STATUS_CARDS } from "../data/statuses";
import { createCardFromDefinition } from "./deckFactory";
import { shuffle } from "../utils";

// Helper to get a fresh instance of a status card
const getStatusCard = (type: 'fatigue' | 'wound'): CoreCard => {
    const template = STATUS_CARDS.find(c => c.tags?.includes(type));
    if (!template) throw new Error(`Status card type ${type} not found`);
    return { ...template, id: Math.random().toString() };
};

export const drawCards = (currentDeck: PlayerDeckState, count: number): { newState: PlayerDeckState, drawn: CoreCard[], fatigueTriggered: boolean } => {
  let { drawPile, discardPile, hand } = currentDeck;
  const drawn: CoreCard[] = [];
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

export const calculateStackStrength = (stack: CoreCard[], strengthColor: ResourceType, modifier: number = 0): number => {
  // Rule: Sum of color values in stack + modifier
  const key = strengthColor.toLowerCase() as keyof Stats;
  const base = stack.reduce((sum, card) => sum + (card.stats[key] ?? 0), 0);
  return base + modifier;
};

export const performDefend = (currentDeck: PlayerDeckState, targetValue: number, color: ResourceType): { newState: PlayerDeckState, flipped: CoreCard[], success: boolean, total: number } => {
  let { drawPile, discardPile, flippedPile } = currentDeck;
  const newFlipped: CoreCard[] = [];
  let currentTotal = 0;
  const key = color.toLowerCase() as keyof Stats;

  // If we are continuing a defense, count existing flipped
  currentTotal = flippedPile.reduce((sum, c) => sum + (c.stats[key] ?? 0), 0);
  
  if (drawPile.length === 0 && discardPile.length > 0) {
       drawPile = shuffle([...discardPile]);
       discardPile = [];
  }

  if (drawPile.length > 0) {
    const card = drawPile.pop()!;
    newFlipped.push(card);
    currentTotal += (card.stats[key] ?? 0);
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
      if (c.type === 'item') {
          const val = stat === 'def' ? c.defense : c.resilience;
          if (val !== undefined && val !== null) {
              max = Math.max(max, val);
              found = true;
          }
      }
  });
  return found ? max : 1; // Default Res 1, Def 1
};

export const calculateSeverity = (consequences: CoreCard[], resilience: number): number => {
  return Math.floor(consequences.length / resilience) + 1;
};