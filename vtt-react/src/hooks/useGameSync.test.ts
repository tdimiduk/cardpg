import { renderHook } from '@testing-library/react';
import { useGameSync } from './useGameSync';
import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameStore } from '../store/gameStore';
import { BroadcastAction } from '../types/sync';
import { vi, describe, it, expect, beforeEach, Mock } from 'vitest';

// Mock dependencies
vi.mock('../contexts/WebSocketContext');
vi.mock('../store/gameStore');

describe('useGameSync', () => {
  const mockCommitPlan = vi.fn();
  const mockPlayImmediate = vi.fn();
  const mockPassTurn = vi.fn();
  const mockRevealAndResolve = vi.fn();
  const mockEndRound = vi.fn();
  const mockUpdateTokenPosition = vi.fn();

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
      };
      return selector(state);
    });
  });

  it('should ignore messages from self', () => {
    (useWebSocket as Mock).mockReturnValue({
      lastMessage: {
        tag: 'BroadcastMessage',
        fromClientId: 'my-id',
        payload: { type: 'REVEAL' },
      },
      clientId: 'my-id',
    });

    renderHook(() => useGameSync());

    expect(mockRevealAndResolve).not.toHaveBeenCalled();
  });

  it('should handle REVEAL action', () => {
    (useWebSocket as Mock).mockReturnValue({
      lastMessage: {
        tag: 'BroadcastMessage',
        fromClientId: 'other-id',
        payload: { type: 'REVEAL' },
      },
      clientId: 'my-id',
    });

    renderHook(() => useGameSync());

    expect(mockRevealAndResolve).toHaveBeenCalled();
  });

  it('should handle PASS action', () => {
    (useWebSocket as Mock).mockReturnValue({
      lastMessage: {
        tag: 'BroadcastMessage',
        fromClientId: 'other-id',
        payload: { type: 'PASS', activeTokenId: 'token-1' },
      },
      clientId: 'my-id',
    });

    renderHook(() => useGameSync());

    expect(mockPassTurn).toHaveBeenCalledWith('token-1');
  });

  it('should handle PLAY_STACK action in planning phase', () => {
    const payload: BroadcastAction = {
      type: 'PLAY_STACK',
      activeTokenId: 'token-1',
      selectedCards: [],
      strengthColor: 'Red',
      modifier: 0,
      phase: 'planning',
    };

    (useWebSocket as Mock).mockReturnValue({
      lastMessage: {
        tag: 'BroadcastMessage',
        fromClientId: 'other-id',
        payload,
      },
      clientId: 'my-id',
    });

    renderHook(() => useGameSync());

    expect(mockCommitPlan).toHaveBeenCalledWith(
      'token-1',
      [],
      'Red',
      0,
      undefined,
      undefined
    );
  });
});
