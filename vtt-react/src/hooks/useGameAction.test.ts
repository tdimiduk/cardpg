import { renderHook } from '@testing-library/react';
import { useGameAction } from './useGameAction';
import { useGameStore } from '../store/gameStore';
import { ActorGameEvent } from '../generated/types';
import { RESOURCE_TYPES } from '../constants';
import { vi, describe, it, expect, beforeEach } from 'vitest';

// Mock dependencies
vi.mock('../store/gameStore');

describe('useGameAction', () => {
  const mockRevealAndResolve = vi.fn();
  const mockEndRound = vi.fn();
  const mockUpdateTokenPosition = vi.fn();
  const mockSetAttackResolution = vi.fn();
  const mockAddLog = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();

    const mockState = {
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
      setAttackResolution: mockSetAttackResolution,
      addLog: mockAddLog,
      tokens: [{ id: 'token-1', actorId: 'actor-1' }],
      actors: { 'actor-1': { id: 'actor-1', name: 'Test Actor' } },
    };

    (
      useGameStore as unknown as {
        getState: () => unknown;
      }
    ).getState = vi.fn(() => mockState);

    (
      useGameStore as unknown as {
        mockImplementation: (
          fn: (selector: (s: typeof mockState) => unknown) => unknown,
        ) => unknown;
      }
    ).mockImplementation((selector: (s: typeof mockState) => unknown) => {
      return selector(mockState);
    });
  });

  it('should handle actionRevealed (Reveal & Attack)', () => {
    const { result } = renderHook(() => useGameAction());
    const event: ActorGameEvent = {
      actorId: 'actor-1',
      event: {
        type: 'actionRevealed',
        data: [
          { type: 'pPass' } as import('../generated/types').PlannedAction, // Dummy plan
          {
            type: 'rEAttack',
            data: {
              attackCard: 'c1',
              attackStrength: 5,
              defenseColor: RESOURCE_TYPES.RED,
            } as import('../generated/types').RealizedAttack,
          },
        ],
      },
    };
    result.current._applyAction(event);

    expect(mockRevealAndResolve).toHaveBeenCalled();
    expect(mockSetAttackResolution).toHaveBeenCalledWith(
      'actor-1',
      expect.objectContaining({ attackStrength: 5 }),
    );
  });

  it('should handle planCanceled', () => {
    const { result } = renderHook(() => useGameAction());
    const event: ActorGameEvent = {
      actorId: 'actor-1',
      event: {
        type: 'planCanceled',
        data: { type: 'pPass' } as import('../generated/types').PlannedAction,
      },
    };
    result.current._applyAction(event);
    expect(mockAddLog).toHaveBeenCalledWith(
      expect.stringContaining('canceled their plan'),
      'System',
      'info',
    );
  });

  it('should handle cardDrawn log', () => {
    const { result } = renderHook(() => useGameAction());
    const event: ActorGameEvent = {
      actorId: 'actor-1',
      event: {
        type: 'cardDrawn',
        data: 'c1',
      },
    };
    result.current._applyAction(event);
    expect(mockAddLog).toHaveBeenCalledWith(
      expect.stringContaining('drew a card'),
      'System',
      'info',
    );
  });
});
