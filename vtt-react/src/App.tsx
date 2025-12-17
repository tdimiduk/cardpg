import React from 'react';
import { MapBoard } from './components/Game/MapBoard';
// Importing default exports which are now Containers
import SidebarLeft from './components/Sidebar/SidebarLeft';
import SidebarRight from './components/Sidebar/SidebarRight';
import PlayerHand from './components/Player/PlayerHand';
import { useGameStore } from './store/gameStore';
import { useWebSocket } from './contexts/WebSocketContext';
import { useGameSync } from './hooks/useGameSync';
import { useGameDispatch } from './hooks/useGameDispatch';

const App: React.FC = () => {
  // --- Store Hooks Needed for Layout/Initialization ---
  const phase = useGameStore((state) => state.phase);
  const actors = useGameStore((state) => state.actors);
  const activeActorId = useGameStore((state) => state.activeActorId);

  // Actions
  const setActiveActor = useGameStore((state) => state.setActiveActor);

  // --- Helpers ---
  // Calculate defeated for visualization - check tableState.consequences for "Taken Out"
  const defeatedTokenIds = Object.entries(actors)
    .filter(([_, actor]) => actor.tableState.consequences.includes('Taken Out'))
    .map(([id]) => `token-${id}`);

  // --- WebSocket Integration ---
  useWebSocket();
  useGameSync();
  const { dispatchCommand } = useGameDispatch();

  return (
    <div className="flex h-screen w-screen bg-slate-950 text-slate-200 font-sans overflow-hidden">
      <SidebarLeft />

      <main className="flex-1 flex flex-col relative overflow-hidden shadow-inner bg-slate-900">
        <div className="absolute top-4 left-4 z-10 pointer-events-none">
          <div className="bg-slate-900/80 backdrop-blur border border-slate-700 px-4 py-2 rounded-full text-xs text-slate-400 shadow-lg flex items-center gap-4">
            <span>Grid: 64px</span>
            <span
              className={`font-bold ${phase === 'planning' ? 'text-blue-400' : 'text-red-400'}`}
            >
              Phase: {phase.toUpperCase()}
            </span>
          </div>
        </div>

        <MapBoard
          onUpdateToken={(actorId, x, y) => {
            console.log('[App] onUpdateToken called:', { actorId, x, y });
            dispatchCommand({ type: 'planMove', actorId, x, y });
          }}
          activeActorId={activeActorId}
          setActiveActorId={(id) => setActiveActor(id)}
          defeatedTokenIds={defeatedTokenIds}
          actors={actors}
          phase={phase}
          plannedActions={{}}
        />

        {activeActorId && <PlayerHand actorId={activeActorId} />}
      </main>

      <SidebarRight />
    </div>
  );
};

export default App;
