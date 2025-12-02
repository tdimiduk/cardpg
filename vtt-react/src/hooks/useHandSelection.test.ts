import { describe, it, expect, vi } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useHandSelection } from './useHandSelection';
import { CoreCard } from '../types';

describe('useHandSelection', () => {
  const mockCard1: CoreCard = {
    id: '1',
    name: 'Strike',
    type: 'core',
    cost: 0,
    stats: { red: 0, yellow: 0, blue: 0 },
    rules: [
      {
        type: 'attack',
        data: {
          power: { source: 'Red', modifier: 2 },
          resistedBy: 'Blue',
        },
      },
    ],
  };

  const mockCard2: CoreCard = {
    id: '2',
    name: 'Boost',
    type: 'core',
    cost: undefined, // Not an action card
    stats: { red: 0, yellow: 0, blue: 0 },
  };

  const mockHand = [mockCard1, mockCard2];
  const mockOnPlayStack = vi.fn();

  it('initializes with empty selection', () => {
    const { result } = renderHook(() =>
      useHandSelection({ hand: mockHand, onPlayStack: mockOnPlayStack }),
    );
    expect(result.current.selectedIds.size).toBe(0);
    expect(result.current.selectedCards).toHaveLength(0);
  });

  it('toggles selection', () => {
    const { result } = renderHook(() =>
      useHandSelection({ hand: mockHand, onPlayStack: mockOnPlayStack }),
    );

    act(() => {
      result.current.toggleSelection('1');
    });

    expect(result.current.selectedIds.has('1')).toBe(true);
    expect(result.current.selectedCards).toHaveLength(1);
    expect(result.current.selectedCards[0].id).toBe('1');

    act(() => {
      result.current.toggleSelection('1');
    });

    expect(result.current.selectedIds.has('1')).toBe(false);
  });

  it('identifies action cards correctly', () => {
    const { result } = renderHook(() =>
      useHandSelection({ hand: mockHand, onPlayStack: mockOnPlayStack }),
    );

    act(() => {
      result.current.toggleSelection('1'); // Action card
      result.current.toggleSelection('2'); // Non-action card
    });

    expect(result.current.actionCards).toHaveLength(1);
    expect(result.current.actionCards[0].id).toBe('1');
  });

  it('handles improvise action', () => {
    const { result } = renderHook(() =>
      useHandSelection({ hand: mockHand, onPlayStack: mockOnPlayStack }),
    );

    act(() => {
      result.current.toggleSelection('2');
    });

    act(() => {
      result.current.handleImprovise('Blue');
    });

    expect(mockOnPlayStack).toHaveBeenCalledWith(
      [mockCard2],
      'Blue',
      0,
      undefined,
      'Improvised Action',
    );
    expect(result.current.selectedIds.size).toBe(0); // Should clear selection
  });

  it('handles specific action', () => {
    const { result } = renderHook(() =>
      useHandSelection({ hand: mockHand, onPlayStack: mockOnPlayStack }),
    );

    act(() => {
      result.current.toggleSelection('1');
    });

    act(() => {
      result.current.handleSpecificAction(mockCard1);
    });

    expect(mockOnPlayStack).toHaveBeenCalledWith([mockCard1], 'Red', 2, 'Blue', 'Strike');
    expect(result.current.selectedIds.size).toBe(0);
  });
});
