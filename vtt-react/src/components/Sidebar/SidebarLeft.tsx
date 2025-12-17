import React, { useMemo } from 'react';
import {
  Token,
  TokenType,
  PlayerDeckState,
  ActorState,
  ActorDefinition,
  CardLocation,
  GamePhase,
  UIPlannedAction,
} from '../../types';
import { getActorTemplates } from '../../services/deckFactory';
import { useActorStats } from '../../hooks/useActorStats';
import { ACTOR_COLORS } from '../../theme';
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
import { ActorSelectorModal } from './ActorSelectorModal';
import { DeckViewerModal } from './DeckViewerModal';

// --- View ---

export interface SidebarLeftProps {
  deckState: PlayerDeckState | null | undefined;
  onDraw: (count: number) => void;
  onDefend: () => void;
  onClearDefense: () => void;
  onReshuffle: () => void;
  onSelectToken: (tokenId: string) => void;
  onAddConsequence: (severity?: number) => void;
  onRemoveConsequence: (cardId: string) => void;
  onAddStatusCard: (type: string, destination: CardLocation) => void;
  onRemoveStatusCard: (type: string) => void;
  tokens: Token[];
  activeToken?: Token;
  activeActorId: string;
  hasPlannedAction?: boolean;
  actors: Record<string, ActorState>;
  onAddActor: (name: string, type: TokenType, color: string, templateId?: string) => void;
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
  tokens,
  activeToken,
  activeActorId,
  actors,
  onAddActor,
  onRemoveActor,
  phase,
  plannedActions,
}) => {
  const [showDeckModal, setShowDeckModal] = React.useState(false);
  const [showActorSelector, setShowActorSelector] = React.useState(false);
  const [selectorType, setSelectorType] = React.useState<TokenType>(TokenType.PC);

  const stats = useActorStats(deckState);

  const handleOpenSelector = (type: TokenType) => {
    setSelectorType(type);
    setShowActorSelector(true);
  };

  const handleSelectTemplate = (template: ActorDefinition) => {
    // Use template name, but append random number if needed or just use it as base
    // We'll use the template name + random number to ensure uniqueness if multiple are added
    const name = `${template.name} ${Math.floor(Math.random() * 100)}`;
    const color = selectorType === TokenType.MONSTER ? ACTOR_COLORS.MONSTER : ACTOR_COLORS.PC;
    onAddActor(name, selectorType, color, template.id);
    setShowActorSelector(false);
  };

  const availableTemplates = React.useMemo(() => {
    if (!showActorSelector) return [];
    const typeTag = selectorType === TokenType.MONSTER ? 'monster' : 'pc';
    return getActorTemplates(typeTag);
  }, [showActorSelector, selectorType]);

  // Empty State / Character Selector
  if (!deckState || !activeToken) {
    return (
      <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl">
        <SidebarHeader />
        <ActorList
          tokens={tokens}
          actors={actors}
          onSelectToken={onSelectToken}
          onRemoveActor={onRemoveActor}
          onAddActor={handleOpenSelector}
          phase={phase}
          plannedActions={plannedActions}
        />

        {/* Actor Selector Modal for Empty State */}
        <ActorSelectorModal
          isOpen={showActorSelector}
          onClose={() => setShowActorSelector(false)}
          onSelectTemplate={handleSelectTemplate}
          selectorType={selectorType}
          availableTemplates={availableTemplates}
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

      <ActorSelectorModal
        isOpen={showActorSelector}
        onClose={() => setShowActorSelector(false)}
        onSelectTemplate={handleSelectTemplate}
        selectorType={selectorType}
        availableTemplates={availableTemplates}
      />

      <SidebarHeader />

      {activeToken && actors[activeToken.actorId] && (
        <ActiveActorHeader
          activeActorId={activeActorId}
          actor={activeToken ? actors[activeToken.actorId] : actors[Object.keys(actors)[0]]}
        />
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
  const tokens = useGameStore((state) => state.tokens);
  const phase = useGameStore((state) => state.phase);
  const plannedActions = useGameStore((state) => state.plannedActions);
  const setActiveActor = useGameStore((state) => state.setActiveActor);
  const addActor = useGameStore((state) => state.addActor);
  const removeActor = useGameStore((state) => state.removeActor);

  const { dispatchCommand } = useGameDispatch();

  // Derived State
  const activeToken = useMemo(
    () => (activeActorId ? tokens.find((t) => t.actorId === activeActorId) : undefined),
    [activeActorId, tokens],
  );
  const activeActor = activeActorId ? actors[activeActorId] : undefined;
  const deckState = activeActor?.deck;

  const activeAction = activeActorId && activeToken ? plannedActions[activeActorId] : undefined;
  const hasPlannedAction =
    !!activeAction && (activeAction.cards.length > 0 || activeAction.actionName === 'Pass');

  // Handlers
  const handleDraw = (count: number) => {
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
    const token = tokens.find((t) => t.id === id);
    if (token) setActiveActor(token.actorId);
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
      type: 'removeConsequenceIntent',
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
    dispatchCommand({ type: 'removeStatusIntent', actorId: activeActorId, statusType: type });
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
      tokens={tokens}
      activeToken={activeToken}
      activeActorId={activeActorId || ''}
      hasPlannedAction={hasPlannedAction}
      actors={actors}
      onAddActor={addActor}
      onRemoveActor={removeActor}
      phase={phase}
      plannedActions={plannedActions}
    />
  );
};

export default SidebarLeftContainer;
