import { renderHook } from '@testing-library/react';
import { useGameAction } from './useGameAction';
import { useGameStore } from '../store/gameStore';
import { BroadcastAction } from '../types/sync';
import { RESOURCE_TYPES } from '../constants';
import { vi, describe, it, expect, beforeEach, Mock } from 'vitest';

// Mock dependencies
vi.mock('../store/gameStore');

describe('useGameAction', () => {
  const mockCommitPlan = vi.fn();
  const mockPlayImmediate = vi.fn();
  const mockPassTurn = vi.fn();
  const mockRevealAndResolve = vi.fn();
  const mockEndRound = vi.fn();
  const mockUpdateTokenPosition = vi.fn();
  const mockDiscardCards = vi.fn();
  const mockCancelPlan = vi.fn();
  const mockReturnToDeck = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
    (useGameStore as unknown as Mock).mockImplementation((selector) => {
      const state = {
        commitPlan: mockCommitPlan,
        playImmediate: mockPlayImmediate,
        passTurn: mockPassTurn,
        revealAndResolve: mockRevealAndResolve,
        endRound: mockEndRound,
        updateTokenPosition: mockUpdateTokenPosition,
        drawCards: vi.fn(),
        defend: vi.fn(),
        clearDefense: vi.fn(),
        reshuffle: vi.fn(),
        addConsequence: vi.fn(),
        removeConsequence: vi.fn(),
        addStatus: vi.fn(),
        removeStatus: vi.fn(),
        discardCards: mockDiscardCards,
        cancelPlan: mockCancelPlan,
        returnToDeck: mockReturnToDeck,
      };
      return selector(state);
    });
  });

  it('should handle REVEAL action', () => {
    const { result } = renderHook(() => useGameAction());
    result.current._applyAction({ type: 'REVEAL' });
    expect(mockRevealAndResolve).toHaveBeenCalled();
  });

  it('should handle PASS action', () => {
    const { result } = renderHook(() => useGameAction());
    result.current._applyAction({ type: 'PASS', activeTokenId: 'token-1' });
    expect(mockPassTurn).toHaveBeenCalledWith('token-1');
  });

  it('should handle PLAY_STACK action in planning phase', () => {
    const payload: BroadcastAction = {
      type: 'PLAY_STACK',
      activeTokenId: 'token-1',
      selectedCards: [],
      strengthColor: RESOURCE_TYPES.RED,
      modifier: 0,
      phase: 'planning',
    };

    const { result } = renderHook(() => useGameAction());
    result.current._applyAction(payload);

    expect(mockCommitPlan).toHaveBeenCalledWith(
      'token-1',
      [],
      RESOURCE_TYPES.RED,
      0,
      undefined,
      undefined,
    );
  });

  it('should handle DISCARD_CARDS action', () => {
    const { result } = renderHook(() => useGameAction());
    result.current._applyAction({
      type: 'DISCARD_CARDS',
      activeTokenId: 'token-1',
      cardIds: ['c1'],
    });
    expect(mockDiscardCards).toHaveBeenCalledWith('token-1', ['c1']);
  });
});
