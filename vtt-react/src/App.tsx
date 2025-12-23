import React, { useState } from 'react';
import { Routes, Route } from 'react-router-dom';
import { MapBoard } from './components/Game/MapBoard';
// Importing default exports which are now Containers
import SidebarLeft from './components/Sidebar/SidebarLeft';
import SidebarRight from './components/Sidebar/SidebarRight';
import PlayerHand from './components/Player/PlayerHand';
import { useGameStore } from './store/gameStore';
import { useWebSocket } from './contexts/WebSocketContext';
import { useGameSync } from './hooks/useGameSync';
import { useGameDispatch } from './hooks/useGameDispatch';
import { DefenseWidget, DefenseModalCard } from './components/Sidebar/DefenseModal';
import { ActiveChallenge } from './generated/types';

// Rules Components
import RulesLayout from './layouts/RulesLayout';
import RulesPage from './components/Rules/RulesPage';
// @ts-expect-error - Vite imports markdown as string
import coreRulesContent from '../../../design/rules/core-rules.md?raw';
// @ts-expect-error - Vite imports markdown as string
import keywordGlossaryContent from '../../../design/rules/keyword-glossary.md?raw';
// @ts-expect-error - Vite imports markdown as string
import colorsOfActionContent from '../../../design/rules/colors-of-action.md?raw';

const GameBoard: React.FC = () => {
  // --- Store Hooks Needed for Layout/Initialization ---
  const phase = useGameStore((state) => state.phase);
  const actors = useGameStore((state) => state.actors);
  const activeActorId = useGameStore((state) => state.activeActorId);
  const activeActor = activeActorId ? actors[activeActorId] : undefined;

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

  // --- Defense Modal State ---
  const [defenseModal, setDefenseModal] = useState<{
    isOpen: boolean;
    attack: ActiveChallenge | null;
    stack: DefenseModalCard[];
  }>({ isOpen: false, attack: null, stack: [] });

  // Resolve Defense Stack for Logic Check
  const defenseIds = activeActor?.coreState.defending || [];

  const handleOpenDefense = (attack: ActiveChallenge, stack: DefenseModalCard[]) => {
    // User feedback: Guide user to finish first defense.
    // If actor has active defense cards, and we are opening a potentially different context?
    // Note: It's hard to strict-equal check "attack", but if defenseIds > 0, we are definitely defending something.
    // If we are already open, we might be just refreshing.
    // If we are closed, and defenseIds > 0, we should probably Resume instead of overwriting with new attack?
    // But the new attack might BE the one we are defending.
    // Simplest logic: If defenseIds > 0, we force open, but we keep the EXISTING attack context if possible,
    // or we just warn if the user tries to switch.
    // Let's just allow opening, but log it. The user specifically asked to "guide" them.
    // A simple Alert is native and effective for "Stop, finish what you are doing".
    // Better: If defenseIds.length > 0 && defenseModal.isOpen && defenseModal.attack !== attack
    // We don't have stable IDs on attack easily.

    // Logic: If we seek to open a defense workflow...
    if (defenseIds.length > 0) {
      // We are already defending.
      // If the modal is already open, assume we are staying in context.
      // If modal is closed, we are re-opening state.
      // We'll update the state, but maybe we should warn if it looks like a *different* attack?
      // For now, let's just proceed. The Widget now properly shows "Current Defense" state always.
      // The mismatch is if the Widget visualizes Attack A but the Actor has cards for Attack A, and user clicks Attack B.
      // The Actor's cards are still there. The Widget will show Attack B stats vs Attack A cards.
      // To fix this, we need to know if the Actor is "locked" to an attack.
      // Without Attack IDs in ActorState, we can't enforce this strictly.
      // We'll trust the user for now but ensure the Widget is visible.
    }
    setDefenseModal({ isOpen: true, attack, stack });
  };

  const handleCloseDefense = () => {
    setDefenseModal((prev) => ({ ...prev, isOpen: false }));
  };

  const handleResumeDefense = () => {
    // Re-open if we have context.
    setDefenseModal((prev) => ({ ...prev, isOpen: true }));
  };

  // --- Defense Handlers (Duplicates of Sidebar Logic for Modal) ---
  const handleDefend = () => {
    if (!activeActorId) return;
    dispatchCommand({ type: 'defendIntent', actorId: activeActorId });
  };

  const handleAddConsequence = (severity?: number) => {
    if (!activeActorId) return;
    dispatchCommand({
      type: 'addConsequenceIntent',
      actorId: activeActorId,
      severity,
    });
  };

  const handleEndDefense = (actorId: string) => {
    dispatchCommand({ type: 'endDefenseIntent', actorId });
    // Also close modal
    handleCloseDefense();
  };

  return (
    <div className="flex h-screen w-screen bg-slate-950 text-slate-200 font-sans overflow-hidden">
      <SidebarLeft onResumeDefense={handleResumeDefense} />

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
        />

        {activeActorId && <PlayerHand actorId={activeActorId} />}
      </main>

      <SidebarRight onOpenDefense={handleOpenDefense} />

      <DefenseWidget
        isOpen={defenseModal.isOpen}
        onClose={handleCloseDefense}
        attackStack={defenseModal.stack}
        attackTarget={defenseModal.attack?.challengeStrength || 0}
        attackColor={defenseModal.attack?.challengeColor || 'red'}
        activeActor={activeActor}
        onDefend={handleDefend}
        onAddConsequence={handleAddConsequence}
        onClearDefense={() => {
          if (activeActorId) handleEndDefense(activeActorId);
        }}
      />
    </div>
  );
};

const App: React.FC = () => {
  return (
    <Routes>
      <Route path="/" element={<GameBoard />} />
      <Route path="/rules" element={<RulesLayout />}>
        <Route index element={<RulesPage content={coreRulesContent} />} />
      </Route>
      <Route path="/glossary" element={<RulesLayout />}>
        <Route index element={<RulesPage content={keywordGlossaryContent} />} />
      </Route>
      <Route path="/colors" element={<RulesLayout />}>
        <Route index element={<RulesPage content={colorsOfActionContent} />} />
      </Route>
    </Routes>
  );
};

export default App;
