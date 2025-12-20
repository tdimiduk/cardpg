import React, { useMemo, useState } from 'react';
import { useGameStore } from '../../store/gameStore';
import { useGameDispatch } from '../../hooks/useGameDispatch';
import {
  ActorState,
  CardLocation,
  Phase,
  CoreCard,
  ConsequenceCard,
  DefenseDetails,
} from '../../generated/types';
import { EquipmentCardWithId } from './EquippedList';

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

export type IdentifiedCoreCard = CoreCard & { id: string };
export type IdentifiedConsequenceCard = ConsequenceCard & { id: string };

export interface SidebarLeftProps {
  drawPile: IdentifiedCoreCard[];
  drawPileCount: number;
  discardPile: IdentifiedCoreCard[];
  discardPileCount: number;
  flippedPile: IdentifiedCoreCard[];
  consequences: IdentifiedConsequenceCard[];
  equipped: EquipmentCardWithId[];
  defense: number;
  resilience: number;
  defenseDetails: DefenseDetails;

  onDraw: (count: number) => void;
  onDefend: () => void;
  onClearDefense: () => void;
  onReshuffle: () => void;
  onSelectActor: (actorId: string) => void;
  onAddConsequence: (severity?: number) => void;
  onRemoveConsequence: (cardId: string) => void;
  onAddStatusCard: (type: string, destination: CardLocation) => void;
  onRemoveStatusCard: (type: string) => void;
  activeActorId: string;
  actors: Record<string, ActorState>;
  onRemoveActor: (actorId: string) => void;
  phase: Phase;
  plannedActions: Record<string, unknown>; // Legacy stub
}

export const SidebarLeftView: React.FC<SidebarLeftProps> = ({
  drawPile,
  drawPileCount,
  discardPile,
  discardPileCount,
  flippedPile,
  consequences,
  equipped,
  defense,
  resilience,
  defenseDetails,
  onDraw,
  onDefend,
  onClearDefense,
  onReshuffle,
  onSelectActor,
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
          drawPileCount={drawPileCount}
          discardPileCount={discardPileCount}
          onDraw={onDraw}
          onReshuffle={onReshuffle}
          onViewDeck={() => setShowDeckModal(true)}
          onViewDiscard={() => setShowDiscardModal(true)}
        />

        <StatusManager onAddStatusCard={onAddStatusCard} onRemoveStatusCard={onRemoveStatusCard} />

        <DefenseStats
          details={defenseDetails}
          defenseStat={defense}
          resilienceStat={resilience}
          onDefend={onDefend}
          onClearDefense={onClearDefense}
          hasFlippedCards={flippedPile.length > 0}
        />

        <ConsequenceList
          consequences={consequences}
          currentSeverity={defenseDetails.nextSeverity}
          onAddConsequence={onAddConsequence}
          onRemoveConsequence={onRemoveConsequence}
        />

        <EquippedList equipped={equipped} />
      </div>
    </div>
  );
};

// --- Container ---

const SidebarLeftContainer: React.FC = () => {
  const actors = useGameStore((state) => state.actors);
  const activeActorId = useGameStore((state) => state.activeActorId);
  const phase = useGameStore((state) => state.phase);
  const plannedActions = {}; // Stub

  const setActiveActor = useGameStore((state) => state.setActiveActor);

  const removeActor = (_id: string) => console.log('Remove actor not implemented');

  const { dispatchCommand } = useGameDispatch();

  // Derived State
  const activeActor = activeActorId ? actors[activeActorId] : undefined;

  // Default defense details if not available
  const defaultDefenseDetails: DefenseDetails = {
    values: {
      red: 0,
      yellow: 0,
      blue: 0,
    },
    impact: 0,
    consequencesFromDefense: 0,
    nextSeverity: 1, // Default next severity usually 1
  };

  // Resolve IDs to Card Objects
  const {
    drawPile,
    discardPile,
    flippedPile,
    consequences,
    equipped,
    drawPileCount,
    discardPileCount,
  } = useMemo(() => {
    if (!activeActor) {
      return {
        drawPile: [],
        discardPile: [],
        flippedPile: [],
        consequences: [],
        equipped: [],
        drawPileCount: 0,
        discardPileCount: 0,
      };
    }

    const resolveCore = (ids: string[]) =>
      ids
        .map((id) => {
          const card = activeActor.coreState.registry[id];
          // Manually adding ID as it's missing from record value
          return card ? { ...card, id } : undefined;
        })
        .filter((c): c is IdentifiedCoreCard => !!c);

    const resolveConsequences = (ids: string[]) =>
      ids
        .map((id) => {
          const card = activeActor.tableState.consequenceRegistry[id];
          return card ? { ...card, id } : undefined;
        })
        .filter((c): c is IdentifiedConsequenceCard => !!c);

    // Resolving equipped items
    // Filter assets for type: "equipped"
    const equippedAssets = Object.entries(activeActor.tableState.assets)
      .filter(([_, asset]) => asset && asset.type === 'equipped')
      .map(([id, _]) => id);

    // Look up table cards
    const equippedCards = equippedAssets
      .map((id) => {
        const cardWrapper = activeActor.tableState.registry[id];
        // TableCard is union of wrappers with 'data' property
        if (!cardWrapper) return undefined;

        // Handling discrimination based on TableCard union
        if (
          cardWrapper.type === 'tCItem' ||
          cardWrapper.type === 'tCNature' ||
          cardWrapper.type === 'tCTalent'
        ) {
          return { ...cardWrapper.data, id };
        }
        return undefined;
      })
      .filter((c): c is EquipmentCardWithId => !!c);

    return {
      drawPile: resolveCore(activeActor.coreState.deck),
      discardPile: resolveCore(activeActor.coreState.discard),
      flippedPile: resolveCore(activeActor.coreState.defending),
      consequences: resolveConsequences(activeActor.tableState.consequences),
      equipped: equippedCards,
      drawPileCount: activeActor.coreState.deck.length,
      discardPileCount: activeActor.coreState.discard.length,
    };
  }, [activeActor]);

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
      drawPile={drawPile}
      drawPileCount={drawPileCount}
      discardPile={discardPile}
      discardPileCount={discardPileCount}
      flippedPile={flippedPile}
      consequences={consequences}
      equipped={equipped}
      defense={activeActor?.defense ?? 1}
      resilience={activeActor?.resilience ?? 1}
      defenseDetails={activeActor?.defenseDetails ?? defaultDefenseDetails}
      onDraw={handleDraw}
      onDefend={handleDefend}
      onClearDefense={handleClearDefense}
      onReshuffle={handleReshuffle}
      onSelectActor={handleSelectToken}
      onAddConsequence={handleAddConsequence}
      onRemoveConsequence={handleRemoveConsequence}
      onAddStatusCard={handleAddStatusCard}
      onRemoveStatusCard={handleRemoveStatusCard}
      activeActorId={activeActorId || ''}
      actors={actors}
      onRemoveActor={removeActor}
      phase={phase}
      plannedActions={plannedActions}
    />
  );
};

export default SidebarLeftContainer;
