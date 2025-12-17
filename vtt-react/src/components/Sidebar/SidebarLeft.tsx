import React from 'react';
import { PlayerDeckState, ActorState, CardLocation, GamePhase, UIPlannedAction } from '../../types';
import { useActorStats } from '../../hooks/useActorStats';
import { useGameStore } from '../../store/gameStore';
import { useGameDispatch } from '../../hooks/useGameDispatch';

// Import new sub-components
import { SidebarHeader } from './SidebarHeader';
import { ActorList } from './ActorList';
import { ActiveActorHeader } from './ActiveActorHeader';
import { DeckStats } from './DeckStats';
import { StatusManager } from './StatusManager';
import { DefenseStats } from './DefenseStats';
import { ConsequenceList } from './ConsequenceList';
import { EquippedList } from './EquippedList';
import { DeckViewerModal } from './DeckViewerModal';

// --- View ---

export interface SidebarLeftProps {
  deckState: PlayerDeckState | null | undefined;
  onDraw: (count: number) => void;
  onDefend: () => void;
  onClearDefense: () => void;
  onReshuffle: () => void;
  onSelectToken: (actorId: string) => void;
  onAddConsequence: (severity?: number) => void;
  onRemoveConsequence: (cardId: string) => void;
  onAddStatusCard: (type: string, destination: CardLocation) => void;
  onRemoveStatusCard: (type: string) => void;
  // tokens removed
  // activeToken removed (use activeActor check)
  activeActorId: string;
  hasPlannedAction?: boolean;
  actors: Record<string, ActorState>;
  // onAddActor removed
  onRemoveActor: (actorId: string) => void;
  phase: GamePhase;
  plannedActions: Record<string, UIPlannedAction>;
}

export const SidebarLeftView: React.FC<SidebarLeftProps> = ({
  deckState,
  onDraw,
  onDefend,
  onClearDefense,
  onReshuffle,
  onSelectToken,
  onAddConsequence,
  onRemoveConsequence,
  onAddStatusCard,
  onRemoveStatusCard,
  activeActorId,
  actors,
  onRemoveActor,
  phase,
  plannedActions,
}) => {
  const [showDeckModal, setShowDeckModal] = React.useState(false);

  const stats = useActorStats(deckState);

  // Empty State / Character Selector
  if (!activeActorId || !deckState) {
    return (
      <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl">
        <SidebarHeader />
        <ActorList
          actors={actors}
          onSelectToken={onSelectToken}
          onRemoveActor={onRemoveActor}
          phase={phase}
          plannedActions={plannedActions}
        />
      </div>
    );
  }

  if (!stats) return null;

  const {
    defenseTotal,
    defenseStat,
    resilienceStat,
    impact,
    calculatedConsequences,
    currentSeverity,
  } = stats;

  return (
    <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl relative">
      <DeckViewerModal
        isOpen={showDeckModal}
        onClose={() => setShowDeckModal(false)}
        cards={deckState.drawPile}
      />

      <SidebarHeader />

      {activeActorId && actors[activeActorId] && (
        <ActiveActorHeader activeActorId={activeActorId} actor={actors[activeActorId]} />
      )}

      <div className="flex-1 overflow-y-auto custom-scrollbar space-y-1">
        <DeckStats
          deckState={deckState}
          onDraw={onDraw}
          onReshuffle={onReshuffle}
          onViewDeck={() => setShowDeckModal(true)}
        />

        <StatusManager onAddStatusCard={onAddStatusCard} onRemoveStatusCard={onRemoveStatusCard} />

        <DefenseStats
          defenseTotal={defenseTotal}
          defenseStat={defenseStat}
          resilienceStat={resilienceStat}
          impact={impact}
          calculatedConsequences={calculatedConsequences}
          onDefend={onDefend}
          onClearDefense={onClearDefense}
          hasFlippedCards={deckState.flippedPile.length > 0}
        />

        <ConsequenceList
          consequences={deckState.consequences}
          currentSeverity={currentSeverity}
          onAddConsequence={onAddConsequence}
          onRemoveConsequence={onRemoveConsequence}
        />

        <EquippedList equipped={deckState.equipped} />
      </div>
    </div>
  );
};

// --- Container ---

const SidebarLeftContainer: React.FC = () => {
  const actors = useGameStore((state) => state.actors);
  const activeActorId = useGameStore((state) => state.activeActorId);
  const phase = useGameStore((state) => state.phase);
  const plannedActions = useGameStore((state) => state.plannedActions);
  const setActiveActor = useGameStore((state) => state.setActiveActor);
  const removeActor = useGameStore((state) => state.removeActor);

  const { dispatchCommand } = useGameDispatch();

  // Derived State
  const activeActor = activeActorId ? actors[activeActorId] : undefined;
  const deckState = activeActor?.deck;

  const activeAction = activeActorId ? plannedActions[activeActorId] : undefined;
  const hasPlannedAction =
    !!activeAction && (activeAction.cards.length > 0 || activeAction.actionName === 'Pass');

  // Handlers
  const handleDraw = (_count: number) => {
    if (!activeActorId) return;
    dispatchCommand({ type: 'drawIntent', actorId: activeActorId }); // Note: count ignored in current intent
  };

  const handleDefend = () => {
    if (!activeActorId) return;
    dispatchCommand({ type: 'defendIntent', actorId: activeActorId });
  };

  const handleClearDefense = () => {
    if (!activeActorId) return;
    dispatchCommand({ type: 'endDefenseIntent', actorId: activeActorId });
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
      deckState={deckState}
      onDraw={handleDraw}
      onDefend={handleDefend}
      onClearDefense={handleClearDefense}
      onReshuffle={handleReshuffle}
      onSelectToken={handleSelectToken}
      onAddConsequence={handleAddConsequence}
      onRemoveConsequence={handleRemoveConsequence}
      onAddStatusCard={handleAddStatusCard}
      onRemoveStatusCard={handleRemoveStatusCard}
      activeActorId={activeActorId || ''}
      hasPlannedAction={hasPlannedAction}
      actors={actors}
      onRemoveActor={removeActor}
      phase={phase}
      plannedActions={plannedActions}
    />
  );
};

export default SidebarLeftContainer;
