import React, { useMemo } from 'react';
import { useHandSelection } from '../../hooks/useHandSelection';
import { CoreCard, ResourceType, GamePhase, UIPlannedAction } from '../../types';
import { CardComponent } from '../Card/Card';
import {
  Square,
  Circle,
  Diamond,
  X,
  Zap,
  Layers,
  Lock,
  SkipForward,
  RotateCcw,
  ArrowUp,
} from 'lucide-react';
import { RESOURCE_TYPES } from '../../constants';
import { useGameStore } from '../../store/gameStore';
import { useGameDispatch } from '../../hooks/useGameDispatch';

// --- View ---
export interface PlayerHandProps {
  hand: CoreCard[];
  onPlayStack: (
    selectedCards: CoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
    actionCardId?: string,
  ) => void;
  onDiscard: (selectedCards: CoreCard[]) => void;
  onPass: () => void;
  onCancelPlan: () => void;
  onReturnToDeck: (selectedCards: CoreCard[]) => void;
  phase: GamePhase;
  hasPlanned: boolean;
  plannedAction?: UIPlannedAction;
}

// Helper Component for Action Button Icons
const ColorIcon = ({ color }: { color: ResourceType }) => {
  switch (color) {
    case RESOURCE_TYPES.RED:
      return <Square size={14} className="inline fill-current" />;
    case RESOURCE_TYPES.YELLOW:
      return <Circle size={14} className="inline fill-current" />;
    case RESOURCE_TYPES.BLUE:
      return <Diamond size={14} className="inline fill-current" />;
  }
};

export const PlayerHandView: React.FC<PlayerHandProps> = ({
  hand,
  onPlayStack,
  onDiscard,
  onPass,
  onCancelPlan,
  onReturnToDeck,
  phase,
  hasPlanned,
  plannedAction,
}) => {
  const {
    selectedIds,
    selectedCards,
    actionCards,
    toggleSelection,
    clearSelection,
    handleImprovise,
    handleSpecificAction,
    getActionRule,
  } = useHandSelection({ hand, onPlayStack });

  // If actor has already planned, hide hand and show locked state
  if (hasPlanned && phase === 'planning') {
    return (
      <div className="absolute bottom-0 left-0 right-0 z-40 h-72 flex flex-col items-center justify-end bg-gradient-to-t from-black via-slate-950/90 to-transparent pointer-events-none pb-6">
        <div className="pointer-events-auto flex flex-col items-center gap-4 animate-fade-in-up">
          {/* Status Header & Cancel */}
          <div className="flex items-center gap-4 bg-slate-900/80 backdrop-blur px-6 py-2 rounded-full border border-indigo-500/30 shadow-2xl">
            <div className="flex items-center gap-2 text-indigo-300 font-bold uppercase tracking-widest text-xs">
              <Lock size={14} />
              <span>Plan: {plannedAction?.actionName || 'Pass'}</span>
            </div>
            <div className="h-4 w-px bg-slate-700"></div>
            <button
              onClick={onCancelPlan}
              className="text-red-400 hover:text-red-300 text-xs font-bold uppercase tracking-wide flex items-center gap-1 transition-colors"
            >
              <RotateCcw size={14} /> Revise
            </button>
          </div>

          {/* Cards Display */}
          {plannedAction && plannedAction.cards.length > 0 ? (
            <div className="flex -space-x-8 justify-center items-end px-8">
              {plannedAction.cards.map((card, idx) => (
                <div
                  key={`${card.id}-${idx}`}
                  className="relative transform scale-75 origin-bottom hover:scale-90 transition-transform duration-300 z-10 hover:z-20 cursor-default shadow-2xl"
                  style={{ zIndex: idx }}
                >
                  <CardComponent card={card} selected={false} onClick={() => {}} />
                </div>
              ))}
            </div>
          ) : (
            <div className="text-slate-500 text-sm italic h-32 flex items-center justify-center">
              (No cards committed)
            </div>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="absolute bottom-0 left-0 right-0 z-40 pointer-events-none flex flex-col justify-end">
      {/* Action Bar */}
      {selectedCards.length > 0 ? (
        <div className="mx-auto mb-4 pointer-events-auto bg-slate-900/95 text-white p-3 rounded-xl shadow-2xl border border-slate-700 backdrop-blur animate-fade-in-up flex flex-col items-center gap-3 max-w-4xl">
          {/* Top Row: Info & Context */}
          <div className="flex items-center justify-between w-full border-b border-slate-800 pb-2 mb-1">
            <div className="text-sm font-bold text-slate-400 uppercase tracking-wider flex items-center gap-2">
              <Layers size={14} />
              {selectedCards.length} Cards Selected
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => {
                  onReturnToDeck(selectedCards);
                  clearSelection();
                }}
                className="text-slate-500 hover:text-blue-400 px-2 flex items-center gap-1 text-xs transition-colors border-r border-slate-700 pr-3"
                title="Return selected cards to top of draw pile"
              >
                <ArrowUp size={14} /> To Deck
              </button>
              <button
                onClick={() => {
                  onDiscard(selectedCards);
                  clearSelection();
                }}
                className="text-slate-500 hover:text-red-400 px-2 flex items-center gap-1 text-xs transition-colors"
                title="Discard selected cards"
              >
                <X size={14} /> Discard
              </button>
            </div>
          </div>

          <div className="flex gap-4 flex-wrap justify-center w-full">
            {/* Specific Action Buttons */}
            {actionCards.length > 0 ? (
              <>
                {actionCards.map((card, idx) => {
                  const cost = card.cost!;
                  const requiredTotal = cost + 1;

                  const currentCount = selectedCards.length;
                  const diff = requiredTotal - currentCount;
                  const isValid = diff === 0;

                  const rule = getActionRule(card);
                  // We know rule exists because of filter

                  return (
                    <button
                      key={`${card.id}-${idx}`}
                      onClick={() => isValid && handleSpecificAction(card)}
                      disabled={!isValid}
                      className={`
                                        flex flex-col items-center gap-1 px-4 py-2 rounded border transition-all group min-w-[180px]
                                        ${
                                          isValid
                                            ? 'bg-indigo-900/60 hover:bg-indigo-600 text-indigo-100 border-indigo-500/50 shadow-[0_0_15px_rgba(99,102,241,0.3)]'
                                            : 'bg-slate-800/50 text-slate-500 border-slate-700 opacity-70 cursor-not-allowed'
                                        }
                                    `}
                    >
                      <span className="font-bold flex items-center gap-2 text-sm">
                        <Zap
                          size={14}
                          className={isValid ? 'fill-yellow-400 text-yellow-400' : 'text-slate-600'}
                        />
                        {phase === 'planning' ? `Plan ${card.name}` : `Cast ${card.name}`}
                      </span>

                      {isValid && rule && (
                        <div className="text-[10px] text-indigo-300 group-hover:text-white flex items-center gap-2 bg-indigo-950/50 px-2 py-1 rounded">
                          {rule.type === 'attack' && (
                            <>
                              <span
                                className={
                                  rule.data.power.source === RESOURCE_TYPES.RED
                                    ? 'text-red-400'
                                    : rule.data.power.source === RESOURCE_TYPES.YELLOW
                                      ? 'text-yellow-400'
                                      : 'text-blue-400'
                                }
                              >
                                <ColorIcon color={rule.data.power.source} />
                              </span>
                              {rule.data.resistedBy && (
                                <>
                                  <span className="text-slate-400 text-[9px]">VS</span>
                                  <span
                                    className={
                                      rule.data.resistedBy === RESOURCE_TYPES.RED
                                        ? 'text-red-400'
                                        : rule.data.resistedBy === RESOURCE_TYPES.YELLOW
                                          ? 'text-yellow-400'
                                          : 'text-blue-400'
                                    }
                                  >
                                    <ColorIcon color={rule.data.resistedBy} />
                                  </span>
                                </>
                              )}
                              <span className="font-mono ml-1">
                                ({rule.data.power.modifier > 0 ? '+' : ''}
                                {rule.data.power.modifier})
                              </span>
                            </>
                          )}
                          {rule.type === 'general' && rule.data.difficulty && (
                            <>
                              <span
                                className={
                                  rule.data.difficulty.attribute === RESOURCE_TYPES.RED
                                    ? 'text-red-400'
                                    : rule.data.difficulty.attribute === RESOURCE_TYPES.YELLOW
                                      ? 'text-yellow-400'
                                      : 'text-blue-400'
                                }
                              >
                                <ColorIcon color={rule.data.difficulty.attribute} />
                              </span>
                              <span className="font-mono ml-1">
                                (Diff {rule.data.difficulty.value})
                              </span>
                            </>
                          )}
                        </div>
                      )}
                      {!isValid && (
                        <span className="text-[10px] text-red-400 font-semibold animate-pulse">
                          {diff > 0 ? `Select ${diff} more` : `Select ${Math.abs(diff)} fewer`}{' '}
                          (Cost: {cost})
                        </span>
                      )}
                    </button>
                  );
                })}

                <div className="w-px bg-slate-700 mx-2"></div>
              </>
            ) : null}

            {/* Improvise options */}
            <div className="flex gap-2">
              <button
                onClick={() => handleImprovise(RESOURCE_TYPES.RED)}
                className="flex items-center gap-2 bg-red-950/40 hover:bg-red-900/80 text-red-200 px-3 py-2 rounded font-bold text-xs border border-red-900/50 transition-colors"
              >
                <Square size={14} fill="currentColor" />{' '}
                {phase === 'planning' ? 'Plan Force' : 'Force'}
              </button>
              <button
                onClick={() => handleImprovise(RESOURCE_TYPES.YELLOW)}
                className="flex items-center gap-2 bg-yellow-950/40 hover:bg-yellow-900/80 text-yellow-200 px-3 py-2 rounded font-bold text-xs border border-yellow-900/50 transition-colors"
              >
                <Circle size={14} fill="currentColor" />{' '}
                {phase === 'planning' ? 'Plan Speed' : 'Speed'}
              </button>
              <button
                onClick={() => handleImprovise(RESOURCE_TYPES.BLUE)}
                className="flex items-center gap-2 bg-blue-950/40 hover:bg-blue-900/80 text-blue-200 px-3 py-2 rounded font-bold text-xs border border-blue-900/50 transition-colors"
              >
                <Diamond size={14} fill="currentColor" />{' '}
                {phase === 'planning' ? 'Plan Mind' : 'Mind'}
              </button>
            </div>
          </div>
        </div>
      ) : (
        /* Empty Selection State - Show Pass Button if in Planning */
        phase === 'planning' && (
          <div className="mx-auto mb-4 pointer-events-auto">
            <button
              onClick={onPass}
              className="flex items-center gap-2 bg-slate-800/80 hover:bg-slate-700 text-slate-300 px-6 py-3 rounded-full border border-slate-600 shadow-lg backdrop-blur transition-all font-bold hover:text-white"
            >
              <SkipForward size={18} />
              Pass / Wait
            </button>
          </div>
        )
      )}

      {/* Cards Container */}
      <div className="w-full overflow-x-auto px-8 pb-4 pt-10 flex justify-center items-end pointer-events-auto min-h-[240px] custom-scrollbar">
        <div className="flex -space-x-12 hover:-space-x-4 transition-all duration-300 items-end px-12">
          {hand.map((card, idx) => (
            <div
              key={`${card.id}-${idx}`}
              className="relative transform transition-transform hover:z-30 hover:-translate-y-8"
            >
              <CardComponent
                card={card}
                selected={selectedIds.has(card.id)}
                onClick={() => toggleSelection(card.id)}
              />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// --- Container ---

const PlayerHandContainer: React.FC = () => {
  const activeActorId = useGameStore((state) => state.activeActorId);
  const actors = useGameStore((state) => state.actors);
  const phase = useGameStore((state) => state.phase);
  const plannedActions = useGameStore((state) => state.plannedActions);
  const tokens = useGameStore((state) => state.tokens);

  const { dispatchCommand } = useGameDispatch();

  // Derived
  const activeToken = useMemo(
    () => (activeActorId ? tokens.find((t) => t.actorId === activeActorId) : undefined),
    [activeActorId, tokens],
  );
  const activeActor = activeActorId ? actors[activeActorId] : undefined;
  const currentDeck = activeActor?.deck;
  const activeAction = activeActorId && activeToken ? plannedActions[activeActorId] : undefined;
  const userHasPlannedAction =
    !!activeAction && (activeAction.cards.length > 0 || activeAction.actionName === 'Pass');

  // If no active actor or no deck, we render nothing
  if (!activeActorId || !currentDeck) return null;

  // Handlers
  const handlePlayStack = (
    selectedCards: CoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
    actionCardId?: string,
  ) => {
    if (phase === 'planning') {
      if (selectedCards.length === 0) return;

      if (actionCardId) {
        const resourceIds = selectedCards.filter((c) => c.id !== actionCardId).map((c) => c.id);
        dispatchCommand({
          type: 'planAction',
          actorId: activeActorId,
          actionCardId: actionCardId,
          resourceCardIds: resourceIds,
        });
      } else {
        // Narrative Action / Improvise
        dispatchCommand({
          type: 'planNarrative',
          actorId: activeActorId,
          cardIds: selectedCards.map((c) => c.id),
          color: strengthColor,
        });
      }
      return;
    }

    console.warn('Attempted to play stack in non-planning phase or fallback.');
  };

  const handleDiscard = (cards: CoreCard[]) => {
    dispatchCommand({
      type: 'discardCardsIntent',
      actorId: activeActorId,
      cardIds: cards.map((c) => c.id),
    });
  };

  const handlePass = () => {
    dispatchCommand({ type: 'passIntent', actorId: activeActorId });
  };

  const handleCancelPlan = () => {
    dispatchCommand({ type: 'cancelPlanIntent', actorId: activeActorId });
  };

  const handleReturnToDeck = (cards: CoreCard[]) => {
    dispatchCommand({
      type: 'returnToDeckIntent',
      actorId: activeActorId,
      cardIds: cards.map((c) => c.id),
    });
  };

  return (
    <PlayerHandView
      hand={currentDeck.hand}
      onPlayStack={handlePlayStack}
      onDiscard={handleDiscard}
      onPass={handlePass}
      onCancelPlan={handleCancelPlan}
      onReturnToDeck={handleReturnToDeck}
      phase={phase}
      hasPlanned={userHasPlannedAction}
      plannedAction={activeAction}
    />
  );
};

export default PlayerHandContainer;
