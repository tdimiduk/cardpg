import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MapBoard } from './MapBoard';
import { ActorState, TokenType } from '../../types';

describe('MapBoard', () => {
  const mockUpdateToken = vi.fn();
  const mockSetActiveToken = vi.fn();

  const mockActor: ActorState = {
    id: 'actor-1',
    name: 'Test Actor',
    color: '#ff0000',
    type: TokenType.PC,
    deck: {
      hand: [],
      drawPile: [],
      discardPile: [],
      flippedPile: [],
      equipped: [],
      consequences: [],
    },
    plannedMove: undefined,
    registry: {},
    x: 2,
    y: 2,
    size: 1,
  };

  const defaultProps = {
    onUpdateToken: mockUpdateToken,
    activeActorId: null,
    setActiveActorId: mockSetActiveToken, // Function signature compatible
    actors: { 'actor-1': mockActor },
    defeatedTokenIds: [],
    phase: 'planning' as const,
    plannedActions: {},
  };

  it('should not call onUpdateToken when clicking without dragging', () => {
    const { container } = render(<MapBoard {...defaultProps} />);
    const tokenElement = screen.getByTestId('token-entity');
    const boardElement = container.firstChild as HTMLElement;

    // Simulate Click
    fireEvent.mouseDown(tokenElement, { clientX: 100, clientY: 100 });
    fireEvent.mouseUp(boardElement, { clientX: 100, clientY: 100 });

    expect(mockUpdateToken).not.toHaveBeenCalled();
    expect(mockSetActiveToken).toHaveBeenCalledWith('actor-1'); // It should select actorId
  });

  it('should call onUpdateToken when dragging to a new position', () => {
    const { container } = render(<MapBoard {...defaultProps} />);
    const tokenElement = screen.getByTestId('token-entity');
    const boardElement = container.firstChild as HTMLElement;

    // Simulate Drag
    fireEvent.mouseDown(tokenElement, { clientX: 100, clientY: 100 });

    // Move enough to change grid position (Grid size is 64)
    // Move from (2,2) -> 128px, 128px.
    // Move to (3,3) -> 192px, 192px.
    // Delta +64
    fireEvent.mouseMove(boardElement, { clientX: 164, clientY: 164 }); // +64

    fireEvent.mouseUp(boardElement, { clientX: 164, clientY: 164 });

    expect(mockUpdateToken).toHaveBeenCalledTimes(1);
    expect(mockUpdateToken).toHaveBeenCalledWith('actor-1', 3, 3);
  });
});
