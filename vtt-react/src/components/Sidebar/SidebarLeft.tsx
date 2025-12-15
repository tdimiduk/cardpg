import React from 'react';
import { Token, TokenType, PlayerDeckState, ActorState, ActorDefinition } from '../../types';
import { getActorTemplates } from '../../services/deckFactory';
import { useActorStats } from '../../hooks/useActorStats';
import { ACTOR_COLORS } from '../../theme';

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

interface SidebarLeftProps {
  deckState: PlayerDeckState | null | undefined;
  onDraw: (count: number) => void;
  onDefend: () => void;
  onClearDefense: () => void;
  onReshuffle: () => void;
  onSelectToken: (tokenId: string) => void;
  onAddConsequence: (severity?: number) => void;
  onRemoveConsequence: (cardId: string) => void;
  onAddStatusCard: (type: string, destination: 'discard' | 'hand' | 'draw') => void;
  onRemoveStatusCard: (type: string) => void;
  tokens: Token[];
  activeToken?: Token;
  activeActorId: string;
  hasPlannedAction?: boolean;
  actors: Record<string, ActorState>;
  onAddActor: (name: string, type: TokenType, color: string, templateId?: string) => void;
  onRemoveActor: (actorId: string) => void;
  phase: import('../../types').GamePhase;
  plannedActions: Record<string, import('../../types').UIPlannedAction>;
}

export const SidebarLeft: React.FC<SidebarLeftProps> = ({
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
