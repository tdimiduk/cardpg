import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import App from '../App';
import { WebSocketProvider } from '../contexts/WebSocketContext';
import { GRID_SIZE } from '../constants';
import { useGameStore } from '../store/gameStore';

// We assume the server is running on localhost:3001
const TEST_WS_URL = 'ws://localhost:3001/api';

describe('Game Lifecycle Integration', () => {
  it('runs through a full round lifecycle', async () => {
    render(
      <WebSocketProvider url={TEST_WS_URL}>
        <App />
      </WebSocketProvider>
    );

    // 1. Wait for connection and initial state
    await waitFor(
      () => {
        expect(screen.getByText(/Phase: PLANNING/i)).toBeInTheDocument();
      },
      { timeout: 5000 }
    );

    // Wait for tokens to appear.
    await waitFor(
      () => {
        expect(screen.getAllByTestId('token-entity').length).toBeGreaterThan(0);
      },
      { timeout: 5000 }
    );

    const tokens = screen.getAllByTestId('token-entity');
    console.log(`Found ${tokens.length} tokens`);

    // 2. For each actor/token...
    const mapBoard = document.querySelector('.bg-grid-pattern');
    if (!mapBoard) throw new Error('MapBoard not found');

    const expectedPositions: Record<string, { x: number; y: number }> = {};

    for (let i = 0; i < tokens.length; i++) {
      const tokenEl = tokens[i];
      console.log(`State before click: activeTokenId=${useGameStore.getState().activeTokenId}`);

      // Select token
      fireEvent.mouseDown(tokenEl);

      // Wait for store update
      await waitFor(() => {
         const activeId = useGameStore.getState().activeTokenId;
         expect(activeId).toBeTruthy();
      });

      console.log(`State after click: activeTokenId=${useGameStore.getState().activeTokenId}`);
      
      const state = useGameStore.getState();
      const activeTokenId = state.activeTokenId;
      const activeToken = state.tokens.find(t => t.id === activeTokenId);
      
      if (activeToken) {
          // Record expected position (current + 1 grid unit)
          expectedPositions[activeToken.id] = { 
              x: activeToken.x + 1, 
              y: activeToken.y + 1 
          };
          console.log(`Active Actor: ${state.actors[activeToken.actorId].name}, Token: ${activeToken.id} @ ${activeToken.x},${activeToken.y}`);
      } else {
          throw new Error('Active token found in state');
      }

      // Wait for Sidebar to update
      const drawBtn = await screen.findByRole('button', { name: /Draw 1/i }, { timeout: 3000 });
      fireEvent.click(drawBtn);

      // Plan move
      const startX = 100;
      const startY = 100;

      fireEvent.mouseDown(tokenEl, { clientX: startX, clientY: startY, bubbles: true });

      // Move 64px (GRID_SIZE)
      fireEvent.mouseMove(mapBoard, {
        clientX: startX + GRID_SIZE,
        clientY: startY + GRID_SIZE,
        bubbles: true,
      });

      fireEvent.mouseUp(mapBoard, { bubbles: true });

      // Wait for move to be planned (round-trip to server)
      await waitFor(() => {
          const updatedState = useGameStore.getState();
          const actor = updatedState.actors[activeToken!.actorId];
          expect(actor.plannedMove).toBeDefined();
          expect(actor.plannedMove?.x).toBe(activeToken!.x + 1);
          expect(actor.plannedMove?.y).toBe(activeToken!.y + 1);
      }, { timeout: 2000 });

      // Click Pass
      const passBtn = await screen.findByRole('button', { name: /Pass/i });
      fireEvent.click(passBtn);
    }

    // 3. Resolve Round
    const revealBtn = await screen.findByRole('button', { name: /Reveal/i });
    fireEvent.click(revealBtn);

    // Wait for phase change
    await waitFor(() => {
        expect(screen.getByText(/Phase: RESOLUTION/i)).toBeInTheDocument();
    });

    const endRoundBtn = await screen.findByRole('button', { name: /End Round/i });
    fireEvent.click(endRoundBtn);

    // 4. Assertions
    await waitFor(() => {
      expect(screen.getByText(/Phase: PLANNING/i)).toBeInTheDocument();
    });

    // Verify token movement
    await waitFor(() => {
        const currentState = useGameStore.getState();
        Object.entries(expectedPositions).forEach(([tokenId, expected]) => {
            const token = currentState.tokens.find(t => t.id === tokenId);
            expect(token).toBeDefined();
            if (token) {
                // console.log(`Verifying token ${tokenId}: Expected (${expected.x}, ${expected.y}), Got (${token.x}, ${token.y})`);
                expect(token.x).toBe(expected.x);
                expect(token.y).toBe(expected.y);
            }
        });
    }, { timeout: 2000 });
  });
});
