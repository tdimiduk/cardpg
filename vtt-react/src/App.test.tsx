import { render, screen, fireEvent } from '@testing-library/react';
import { vi, describe, it, expect, beforeEach, Mock } from 'vitest';
import App from './App';
import { useGameStore } from './store/gameStore';
import { useWebSocket } from './contexts/WebSocketContext';
import { useGameSync } from './hooks/useGameSync';
import { useGameDispatch } from './hooks/useGameDispatch';
import { CoreCard } from './types';

// Mock dependencies
vi.mock('./store/gameStore');
vi.mock('./contexts/WebSocketContext');
vi.mock('./hooks/useGameSync');
vi.mock('./hooks/useGameDispatch');

// Mock child components to avoid complex rendering and isolate App logic
vi.mock('./components/Game/MapBoard', () => ({
  MapBoard: ({
    setActiveActorId,
  }: {
    setActiveActorId: (id: string) => void;
  }) => (
    <div data-testid="map-board">
      <button onClick={() => setActiveActorId && setActiveActorId('token-1')} data-testid="select-token-btn">
        Select Token
      </button>
    </div>
  ),
}));

vi.mock('./components/Player/PlayerHand', () => ({
  PlayerHand: ({ hand }: { hand: CoreCard[] }) => (
    <div data-testid="player-hand">Hand Size: {hand.length}</div>
  ),
}));

vi.mock('./components/Sidebar/SidebarLeft', () => ({
  SidebarLeft: () => <div data-testid="sidebar-left" />,
}));

vi.mock('./components/Sidebar/SidebarRight', () => ({
  SidebarRight: () => <div data-testid="sidebar-right" />,
}));

describe('App Component', () => {
  const mockInitializeGame = vi.fn();
  const mockSetActiveActor = vi.fn();
  const mockDispatch = vi.fn();

  const mockActors = {
    'actor-1': {
      id: 'actor-1',
      name: 'Hero',
      deck: {
        hand: [{ id: 'c1', name: 'Strike' }],
        drawPile: [],
        discardPile: [],
        consequences: [],
      },
    },
  };

  const mockTokens = [{ id: 'token-1', actorId: 'actor-1', x: 0, y: 0 }];

  beforeEach(() => {
    vi.clearAllMocks();

    // Mock WebSocket
    (useWebSocket as Mock).mockReturnValue({ clientId: 'client-1' });

    // Mock GameSync
    (useGameSync as Mock).mockReturnValue({});

    // Mock GameDispatch
    (useGameDispatch as Mock).mockReturnValue({ dispatch: mockDispatch });

    // Mock Store Default State
    (useGameStore as unknown as Mock).mockImplementation((selector) => {
      const state = {
        phase: 'planning',
        plannedActions: {},
        tokens: mockTokens,
        actors: mockActors,
        logs: [],
        activeActorId: null,
        setActiveActor: mockSetActiveActor,
        addActor: vi.fn(),
        removeActor: vi.fn(),
        addLog: vi.fn(),
        initializeGame: mockInitializeGame,
      };
      return selector(state);
    });
  });

  it('should call initializeGame on mount if decks are empty', () => {
    // Setup state with empty decks
    const emptyActors = {
      'actor-1': {
        ...mockActors['actor-1'],
        deck: { hand: [], drawPile: [], discardPile: [], consequences: [] },
      },
    };

    (useGameStore as unknown as Mock).mockImplementation((selector) => {
      const state = {
        phase: 'planning',
        plannedActions: {},
        tokens: mockTokens,
        actors: emptyActors,
        logs: [],
        activeActorId: null,
        setActiveActor: mockSetActiveActor,
        initializeGame: mockInitializeGame,
      };
      return selector(state);
    });

    render(<App />);
    expect(mockInitializeGame).toHaveBeenCalled();
  });

  it('should NOT call initializeGame on mount if decks are populated', () => {
    render(<App />);
    expect(mockInitializeGame).not.toHaveBeenCalled();
  });

  it('should handle token selection', () => {
    render(<App />);

    const selectBtn = screen.getByTestId('select-token-btn');
    fireEvent.click(selectBtn);

    expect(mockSetActiveActor).toHaveBeenCalledWith('token-1');
  });

  it('should render PlayerHand when a token is active', () => {
    // Mock state with active token
    (useGameStore as unknown as Mock).mockImplementation((selector) => {
      const state = {
        phase: 'planning',
        plannedActions: {},
        tokens: mockTokens,
        actors: mockActors,
        logs: [],
        activeActorId: 'actor-1',
        setActiveActor: mockSetActiveActor,
        initializeGame: mockInitializeGame,
      };
      return selector(state);
    });

    render(<App />);

    expect(screen.getByTestId('player-hand')).toBeInTheDocument();
    expect(screen.getByText('Hand Size: 1')).toBeInTheDocument();
  });

  it('should NOT render PlayerHand when no token is active', () => {
    render(<App />);
    expect(screen.queryByTestId('player-hand')).not.toBeInTheDocument();
  });
});
