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
import { resolveChallengeStack } from './utils';

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
  const logs = useGameStore((state) => state.logs);
  const actors = useGameStore((state) => state.actors);
  const activeActorId = useGameStore((state) => state.activeActorId);
  const activeActor = activeActorId ? actors[activeActorId] : undefined;

  // Actions
  const setActiveActor = useGameStore((state) => state.setActiveActor);

  // --- Helpers ---
  // Calculate defeated for visualization - check tableState.consequences for "Taken Out"
  const defeatedTokenIds = Object.entries(actors)
    .filter(([_, actor]) => actor.tableState.consequences.some((c) => c.name === 'Taken Out'))
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
  const [warningMessage, setWarningMessage] = useState<string | null>(null);

  // Helper to reconstruct defense state from active actor
  const reconstructDefenseState = () => {
    const defending = activeActor?.coreState.defending;
    if (!defending) return null;

    const activeChallenge = defending.activeChallenge;
    // Try to find context from logs to enrich visuals (the stack)
    const originalLog = logs.find(
      (l) => l.payload.type === 'logChallenge' && l.payload.challenge.id === activeChallenge.id,
    );

    let stack: DefenseModalCard[] = [];

    if (originalLog && originalLog.payload.type === 'logChallenge') {
      const senderId = originalLog.senderId;
      const sender = senderId ? actors[senderId] : undefined;
      stack = resolveChallengeStack(
        originalLog.payload.challenge,
        originalLog.payload.plannedAction,
        originalLog.id,
        sender,
      );
    }

    return { attack: activeChallenge, stack };
  };

  // Resolve Defense Stack for Logic Check
  const handleOpenDefense = (attack: ActiveChallenge, stack: DefenseModalCard[]) => {
    const defending = activeActor?.coreState.defending;

    if (defending) {
      // Logic: Always prefer the Active State if we are defending.
      const reconstructed = reconstructDefenseState();

      if (reconstructed) {
        setDefenseModal({
          isOpen: true,
          attack: reconstructed.attack,
          stack: reconstructed.stack.length > 0 ? reconstructed.stack : stack, // Fallback to passed stack if log lookup failed but we have passed data (e.g. from just clicking the log)
        });

        // Warn if they clicked a different one
        if (defending.activeChallenge.id !== attack.id) {
          setWarningMessage(
            'You are already defending against another challenge. We have brought up your active defense instead.',
          );
        } else {
          setWarningMessage(null);
        }
        return;
      }
    }

    // Not defending yet? Start new.
    setDefenseModal({ isOpen: true, attack, stack });
    setWarningMessage(null);
  };

  const handleCloseDefense = () => {
    setDefenseModal((prev) => ({ ...prev, isOpen: false }));
    setWarningMessage(null);
  };

  const handleResumeDefense = () => {
    // Logic: derived entirely from state
    const reconstructed = reconstructDefenseState();
    if (reconstructed) {
      setDefenseModal({
        isOpen: true,
        attack: reconstructed.attack,
        stack: reconstructed.stack,
      });
      setWarningMessage(null);
    } else {
      console.warn('Attempted to resume defense but no active defense state found.');
    }
  };

  // --- Defense Handlers (Duplicates of Sidebar Logic for Modal) ---
  const handleDefend = () => {
    if (!activeActorId || !defenseModal.attack) return;

    // We now have the ID directly on the challenge object
    const targetChallengeId = defenseModal.attack.id;

    dispatchCommand({
      type: 'defendIntent',
      actorId: activeActorId,
      targetChallengeId,
    });
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
        warningMessage={warningMessage}
        onDismissWarning={() => setWarningMessage(null)}
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
