import { describe, it, expect } from 'vitest';
import { renderHook } from '@testing-library/react';
import { useActorStats } from './useActorStats';
import { PlayerDeckState, CoreCard, ItemCard } from '../types';

describe('useActorStats', () => {
  const mockDeckState: PlayerDeckState = {
    drawPile: [],
    hand: [],
    discardPile: [],
    flippedPile: [
      { id: '1', type: 'core', name: 'Flip1', stats: { red: 1, yellow: 0, blue: 0 } } as CoreCard,
      { id: '2', type: 'core', name: 'Flip2', stats: { red: 2, yellow: 1, blue: 0 } } as CoreCard,
    ],
    equipped: [{ id: '3', type: 'item', name: 'Shield', defense: 2, resilience: 1 } as ItemCard],
    consequences: [
      {
        id: '4',
        type: 'core',
        name: 'Wound',
        severity: 1,
        stats: { red: 0, yellow: 0, blue: 0 },
      } as unknown as CoreCard,
    ],
  };

  it('returns null if deckState is missing', () => {
    const { result } = renderHook(() => useActorStats(null));
    expect(result.current).toBeNull();
  });

  it('calculates defense totals correctly', () => {
    const { result } = renderHook(() => useActorStats(mockDeckState));
    expect(result.current?.defenseTotal).toEqual({
      red: 3,
      yellow: 1,
      blue: 0,
    });
  });

  it('calculates derived stats from equipment', () => {
    const { result } = renderHook(() => useActorStats(mockDeckState));
    expect(result.current?.defenseStat).toBe(2);
    expect(result.current?.resilienceStat).toBe(1);
  });

  it('calculates impact and consequences', () => {
    const { result } = renderHook(() => useActorStats(mockDeckState));
    // Impact = 2 flipped cards
    // Defense = 2
    // Consequences = floor(2 / 2) = 1
    expect(result.current?.impact).toBe(2);
    expect(result.current?.calculatedConsequences).toBe(1);
  });

  it('calculates severity', () => {
    const { result } = renderHook(() => useActorStats(mockDeckState));
    // 1 consequence, resilience 1 => severity calculation depends on ruleService
    // Assuming calculateSeverity = floor(consequences.length / resilience) + 1
    // floor(1/1) + 1 = 2
    expect(result.current?.currentSeverity).toBe(2);
  });
});
