import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MapBoard } from './MapBoard';
import { Token, ActorState, TokenType } from '../../types';

describe('MapBoard', () => {
  const mockUpdateToken = vi.fn();
  const mockSetActiveToken = vi.fn();

  const mockToken: Token = {
    id: 'token-1',
    actorId: 'actor-1',
    x: 2,
    y: 2,
    size: 1,
  };

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
  };

  const defaultProps = {
    tokens: [mockToken],
    onUpdateToken: mockUpdateToken,
    activeTokenId: null,
    setActiveTokenId: mockSetActiveToken,
    actors: { 'actor-1': mockActor },
    defeatedTokenIds: [],
  };

  it('should not call onUpdateToken when clicking without dragging', () => {
    const { container } = render(<MapBoard {...defaultProps} />);
    const tokenElement = screen.getByTestId('token-entity');
    const boardElement = container.firstChild as HTMLElement;

    // Simulate Click
    fireEvent.mouseDown(tokenElement, { clientX: 100, clientY: 100 });
    fireEvent.mouseUp(boardElement, { clientX: 100, clientY: 100 });

    expect(mockUpdateToken).not.toHaveBeenCalled();
    expect(mockSetActiveToken).toHaveBeenCalledWith('token-1'); // It should still select
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
    expect(mockUpdateToken).toHaveBeenCalledWith(
      expect.objectContaining({
        x: 3, // 2 + 1 (+64px / 64) = 3?
        // Initial token X=2.
        // In MapBoard:
        // deltaX = 164 - 100 = 64.
        // setDragPreview: initialTokenX * 64 + delta = 2*64 + 64 = 192.
        // onMouseUp: newGridX = round(192 / 64) = 3.
        // So X should be 3.
        y: 3,
      }),
    );
  });
});
