import React, { useState } from 'react';
import { useGameStore } from '../../store/gameStore';
import { useGameDispatch } from '../../hooks/useGameDispatch';
import { useResolvedCards } from '../../hooks/useCardResolution';
import { ActorState, CardLocation, Phase, CoreCard, ConsequenceCard } from '../../generated/types';

// Import new sub-components

import { SidebarHeader } from './SidebarHeader';
import { ActorList } from './ActorList';
import { ActiveActorHeader } from './ActiveActorHeader';
import { DeckStats } from './DeckStats';
import { StatusManager } from './StatusManager';
import { ConsequenceList } from './ConsequenceList';
import { EquippedList } from './EquippedList';
import { DeckViewerModal } from './DeckViewerModal';

// --- View ---

export type IdentifiedCoreCard = CoreCard & { id: string };
export type IdentifiedConsequenceCard = ConsequenceCard & { id: string };

export interface SidebarLeftProps {
  activeActor?: ActorState;

  // Keep piles for Modals, since modals take simple arrays and we don't want to refactor them right now
  drawPile: IdentifiedCoreCard[];
  discardPile: IdentifiedCoreCard[];

  flippedPile: IdentifiedCoreCard[]; // Used for "Resume Defense" check

  onDraw: (count: number) => void;
  onReshuffle: () => void;
  onSelectActor: (actorId: string) => void;
  onAddConsequence: (severity?: number) => void;
  onRemoveConsequence: (cardId: string) => void;
  onAddStatusCard: (type: string, destination: CardLocation) => void;
  onRemoveStatusCard: (type: string) => void;
  onResumeDefense: () => void;
  activeActorId: string;
  actors: Record<string, ActorState>;
  onRemoveActor: (actorId: string) => void;
  phase: Phase;
  plannedActions: Record<string, unknown>; // Legacy stub
}

export const SidebarLeftView: React.FC<SidebarLeftProps> = ({
  activeActor,
  drawPile,
  discardPile,
  flippedPile,
  onDraw,
  onReshuffle,
  onSelectActor,
  onAddConsequence,
  onRemoveConsequence,
  onAddStatusCard,
  onRemoveStatusCard,
  onResumeDefense,
  activeActorId,
  actors,
  onRemoveActor,
  phase,
  plannedActions,
}) => {
  const [showDeckModal, setShowDeckModal] = useState(false);
  const [showDiscardModal, setShowDiscardModal] = useState(false);

  // Empty State / Character Selector
  if (!activeActorId) {
    return (
      <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl">
        <SidebarHeader />
        <ActorList
          actors={actors}
          onSelectActor={onSelectActor}
          onRemoveActor={onRemoveActor}
          phase={phase}
          plannedActions={plannedActions}
        />
        <div className="p-4 border-t border-slate-800 mt-auto">
          <button
            onClick={() => {
              if (window.confirm('Reset Identity? This will create a new user ID.')) {
                localStorage.removeItem('cardpg_client_id');
                window.location.reload();
              }
            }}
            className="text-xs text-slate-500 hover:text-slate-300 w-full text-center"
          >
            Debug: Reset Identity
          </button>
        </div>
      </div>
    );
  }

  const defense = activeActor?.defense ?? 1;
  const resilience = activeActor?.resilience ?? 1;

  return (
    <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl relative">
      <DeckViewerModal
        isOpen={showDeckModal}
        onClose={() => setShowDeckModal(false)}
        cards={drawPile}
      />
      <DeckViewerModal
        isOpen={showDiscardModal}
        onClose={() => setShowDiscardModal(false)}
        cards={discardPile}
      />

      <SidebarHeader />

      {activeActorId && actors[activeActorId] && (
        <ActiveActorHeader activeActorId={activeActorId} actor={actors[activeActorId]} />
      )}

      <div className="flex-1 overflow-y-auto custom-scrollbar space-y-1">
        <DeckStats
          actor={activeActor}
          onDraw={onDraw}
          onReshuffle={onReshuffle}
          onViewDeck={() => setShowDeckModal(true)}
          onViewDiscard={() => setShowDiscardModal(true)}
        />

        <StatusManager onAddStatusCard={onAddStatusCard} onRemoveStatusCard={onRemoveStatusCard} />

        {/* Compact Stats & Active Defense */}
        <div className="px-4 py-2 border-b border-slate-800 bg-slate-900/10 flex flex-col gap-2">
          <div className="flex justify-between items-center text-sm font-bold opacity-90">
            <span className="text-blue-300 flex items-center gap-1">🛡 Defense: {defense}</span>
            <span className="text-red-300 flex items-center gap-1">
              💖 Resilience: {resilience}
            </span>
          </div>

          {flippedPile.length > 0 && (
            <button
              onClick={onResumeDefense}
              className="w-full text-xs bg-indigo-900/80 hover:bg-indigo-800 text-indigo-200 border border-indigo-700/50 rounded py-1 px-2 animate-pulse font-bold transition-all shadow-sm flex items-center justify-center gap-2"
            >
              <span className="w-2 h-2 rounded-full bg-indigo-400 animate-ping" />
              Resume Active Defense
            </button>
          )}
        </div>

        <ConsequenceList
          activeActor={activeActor}
          onAddConsequence={onAddConsequence}
          onRemoveConsequence={onRemoveConsequence}
        />

        <EquippedList activeActor={activeActor} />
      </div>
    </div>
  );
};

// --- Container ---

// --- Container ---

interface SidebarLeftContainerProps {
  onResumeDefense: () => void;
}

const SidebarLeftContainer: React.FC<SidebarLeftContainerProps> = ({ onResumeDefense }) => {
  const actors = useGameStore((state) => state.actors);
  const activeActorId = useGameStore((state) => state.activeActorId);
  const phase = useGameStore((state) => state.phase);
  const plannedActions = {}; // Stub

  const setActiveActor = useGameStore((state) => state.setActiveActor);

  const removeActor = (_id: string) => console.log('Remove actor not implemented');

  const { dispatchCommand } = useGameDispatch();

  // Derived State
  const activeActor = activeActorId ? actors[activeActorId] : undefined;

  // Resolve IDs to Card Objects
  const drawPile = useResolvedCards(activeActor?.coreState.deck, activeActor?.coreState.registry);
  const discardPile = useResolvedCards(
    activeActor?.coreState.discard,
    activeActor?.coreState.registry,
  );
  const flippedPile = useResolvedCards(
    activeActor?.coreState.defending,
    activeActor?.coreState.registry,
  );

  // Handlers
  const handleDraw = (_count: number) => {
    if (!activeActorId) return;
    dispatchCommand({ type: 'drawIntent', actorId: activeActorId }); // Note: count ignored in current intent
  };

  const handleReshuffle = () => {
    if (!activeActorId) return;
    dispatchCommand({ type: 'reshuffleIntent', actorId: activeActorId });
  };

  const handleSelectToken = (id: string) => {
    // If id has "token-" prefix, strip it (legacy handling fallback)
    const actorId = id.replace(/^token-/, '');
    if (actors[actorId]) setActiveActor(actorId);
  };

  const handleAddConsequence = (severity?: number) => {
    if (!activeActorId) return;
    dispatchCommand({
      type: 'addConsequenceIntent',
      actorId: activeActorId,
      severity: severity,
    });
  };

  const handleRemoveConsequence = (cardId: string) => {
    if (!activeActorId) return;
    dispatchCommand({
      type: 'destroyConsequenceIntent',
      actorId: activeActorId,
      cardId,
    });
  };

  const handleAddStatusCard = (type: string, destination: CardLocation) => {
    if (!activeActorId) return;
    dispatchCommand({
      type: 'addStatusIntent',
      actorId: activeActorId,
      statusType: type,
      destination,
    });
  };

  const handleRemoveStatusCard = (type: string) => {
    if (!activeActorId) return;
    dispatchCommand({ type: 'destroyStatusIntent', actorId: activeActorId, statusType: type });
  };

  return (
    <SidebarLeftView
      activeActor={activeActor}
      drawPile={drawPile}
      discardPile={discardPile}
      flippedPile={flippedPile}
      onDraw={handleDraw}
      onReshuffle={handleReshuffle}
      onSelectActor={handleSelectToken}
      onAddConsequence={handleAddConsequence}
      onRemoveConsequence={handleRemoveConsequence}
      onAddStatusCard={handleAddStatusCard}
      onRemoveStatusCard={handleRemoveStatusCard}
      onResumeDefense={onResumeDefense}
      activeActorId={activeActorId || ''}
      actors={actors}
      onRemoveActor={removeActor}
      phase={phase}
      plannedActions={plannedActions}
    />
  );
};

export default SidebarLeftContainer;
