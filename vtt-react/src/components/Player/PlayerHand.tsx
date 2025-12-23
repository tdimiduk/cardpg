import React, { useMemo } from 'react';
import { useGameStore } from '../../store/gameStore';
import { useGameDispatch } from '../../hooks/useGameDispatch';
import { useHandSelection } from '../../hooks/useHandSelection';
import { CoreCardComponent } from '../Card/Card';
import { CardStack } from '../Card/CardStack';
import { SkipForward, Lock, RotateCcw, Layers, Zap, Check, Ban } from 'lucide-react';
import {
  selectHand,
  selectPlannedAction,
  UIPlannedAction,
  ClientCoreCard,
} from '../../store/selectors';
import { Phase, ResourceType } from '../../generated/types';

// --- View ---
export interface PlayerHandProps {
  hand: ClientCoreCard[];
  onPlayStack: (
    selectedCards: ClientCoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
    actionCardId?: string,
  ) => void;
  onDiscard: (selectedCards: ClientCoreCard[]) => void;
  onPass: () => void;
  onCancelPlan: () => void;
  onReturnToDeck: (selectedCards: ClientCoreCard[]) => void;
  phase: Phase;
  hasPlanned: boolean;
  plannedAction?: UIPlannedAction;
}

export const PlayerHandView: React.FC<PlayerHandProps> = ({
  hand,
  onPlayStack,
  onPass,
  onCancelPlan,
  phase,
  hasPlanned,
  plannedAction,
}) => {
  const {
    stagedActionCard,
    stagedResourceCards,
    stagedResourceIds,
    actionCandidates,
    isReady,
    missingCount,
    stageAction,
    unstageAction,
    toggleResource,
    commitAction,
  } = useHandSelection({ hand, onPlayStack });

  // Filter visible hand: hide staged cards OR planned cards (if planned)
  const visibleHand = useMemo(() => {
    if (hasPlanned && plannedAction) {
      // Create set of IDs to hide based on action type
      const plannedIds = new Set<string>();

      if (plannedAction.type === 'standard') {
        plannedIds.add(plannedAction.actionCard.id);
        plannedAction.resources.forEach((c) => plannedIds.add(c.id));
      } else if (plannedAction.type === 'narrative') {
        plannedAction.cards.forEach((c) => plannedIds.add(c.id));
      }

      return hand.filter((c) => !plannedIds.has(c.id));
    }
    return hand;
  }, [hand, hasPlanned, plannedAction]);

  const planName = !plannedAction
    ? ''
    : plannedAction.type === 'standard'
      ? plannedAction.actionCard.name
      : plannedAction.type === 'narrative'
        ? 'Improvise'
        : 'Pass';

  const isStaging = !!stagedActionCard;

  // --- Render Layout Logic ---

  // 1. STAGING MODE: Staging Widget ABOVE Hand
  if (isStaging) {
    return (
      <div className="absolute bottom-0 left-0 right-0 z-40 pointer-events-none flex flex-col justify-end h-screen pb-4">
        {/* Staging Widget (Centered, above hand) */}
        <div className="flex-1 flex flex-col items-center justify-end pb-8 pointer-events-none">
          {/* A. Staging Widget */}
          <div className="pointer-events-auto bg-slate-900/90 backdrop-blur-md border border-slate-700 rounded-3xl p-6 shadow-2xl flex flex-col items-center gap-6 animate-in slide-in-from-bottom-10 fade-in duration-300 min-w-[320px]">
            {/* Header */}
            <div className="flex flex-col items-center gap-0.5">
              <div className="text-indigo-200 font-bold tracking-wider uppercase text-xs flex items-center gap-2">
                <Zap size={14} className="fill-current text-indigo-400" />
                Preparing Action
              </div>
              <div className="text-slate-400 text-[10px] text-center">
                Add <strong>{missingCount}</strong> more resource{missingCount !== 1 ? 's' : ''}
              </div>
            </div>

            {/* Staging Slots */}
            <div className="flex gap-4 items-end justify-center py-2">
              {/* Action Card */}
              <div className="relative group cursor-pointer origin-bottom" onClick={unstageAction}>
                <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-indigo-600 text-white text-[10px] uppercase font-bold px-2 py-0.5 rounded shadow z-50">
                  Action
                </div>
                <CoreCardComponent card={stagedActionCard} selected={true} />
              </div>

              {/* Resources (Tiny Pile) */}
              <div className="flex">
                <CardStack
                  cards={stagedResourceCards}
                  mode="stack"
                  onCardClick={(c) => toggleResource(c.id)}
                  emptyMessage={
                    <div className="w-[100px] h-[140px] border-2 border-dashed border-slate-700 rounded-lg bg-slate-800/50 flex items-center justify-center">
                      <Layers size={24} className="text-slate-600" />
                    </div>
                  }
                />
              </div>
            </div>

            {/* Controls */}
            <div className="flex gap-2 w-full">
              <button
                onClick={unstageAction}
                className="flex-1 py-2 rounded-lg border border-slate-600 text-slate-400 hover:bg-slate-800 text-[10px] uppercase font-bold"
              >
                Cancel
              </button>
              <button
                onClick={commitAction}
                disabled={!isReady}
                className={`flex-1 py-2 rounded-lg border flex items-center justify-center gap-1 text-[10px] uppercase font-bold transition-all ${isReady ? 'bg-indigo-600 text-white' : 'bg-slate-800 text-slate-600'}`}
              >
                {isReady ? (
                  <>
                    <Check size={12} /> Commit
                  </>
                ) : (
                  <>
                    <Ban size={12} /> Wait
                  </>
                )}
              </button>
            </div>
          </div>
        </div>

        {/* Hand Area (Bottom) */}
        <div className="w-full flex justify-center items-end px-8 pointer-events-none">
          <div className="flex justify-center items-end" style={{ minHeight: '260px' }}>
            {hand
              .filter((card) => !stagedResourceIds.has(card.id) && card.id !== stagedActionCard?.id)
              .map((card, idx) => {
                // In Staging Mode, everything remaining is a resource candidate

                return (
                  <div
                    key={card.id}
                    className="pointer-events-auto -ml-12 first:ml-0 relative group"
                    style={{ zIndex: idx, width: '160px' }}
                  >
                    <div
                      className="transition-transform duration-200 ease-out origin-bottom cursor-pointer hover:-translate-y-8 hover:z-50"
                      onClick={() => toggleResource(card.id)}
                    >
                      <CoreCardComponent
                        card={card}
                        className="hover:ring-2 hover:ring-amber-400 hover:ring-offset-2 hover:ring-offset-black/50"
                      />
                      <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-amber-600 text-white text-[10px] uppercase font-bold px-2 py-0.5 rounded shadow z-50 opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                        Add Resource
                      </div>
                    </div>
                  </div>
                );
              })}
          </div>
        </div>
      </div>
    );
  }

  // 2. DEFAULT / PLANNED MODE: Planned Stack Inline LEFT of Hand
  return (
    <div className="absolute bottom-0 left-0 right-0 z-40 pointer-events-none flex flex-col justify-end pb-4">
      {/* Container: Inline Layout (Planned | Hand) */}
      <div className="flex items-end justify-center gap-12 w-full px-8">
        {/* --- LEFT ZONE: Planned Action --- */}
        {hasPlanned && plannedAction && (
          <div className="flex-shrink-0 animate-in fade-in slide-in-from-left-10 duration-500 pointer-events-auto flex flex-col items-center gap-2">
            {/* Planned Header */}
            <div className="flex items-center gap-2 bg-slate-900/90 backdrop-blur px-4 py-1.5 rounded-full border border-indigo-500/30 shadow-lg">
              <Lock size={12} className="text-indigo-400" />
              <span className="text-indigo-200 text-xs font-bold uppercase">{planName}</span>
              <div className="w-px h-3 bg-slate-700 mx-1" />
              <button
                onClick={onCancelPlan}
                className="text-red-400 hover:text-red-300 text-[10px] font-bold uppercase flex items-center gap-1"
              >
                <RotateCcw size={10} /> Revise
              </button>
            </div>

            {/* Planned Stack Visualization */}
            {plannedAction.type === 'standard' ? (
              <div className="relative mt-4" style={{ width: '160px', height: '220px' }}>
                {/* Resources: Straight Horizontal Offset */}
                {plannedAction.resources.map((res, i) => (
                  <div
                    key={res.id}
                    className="absolute top-0 left-0 shadow-xl"
                    style={{
                      transform: `translate(${-(i + 1) * 40}px, 0px)`,
                      zIndex: 10 - i,
                    }}
                  >
                    <CoreCardComponent card={res} className="brightness-75" />
                  </div>
                ))}
                {/* Action Card */}
                <div className="absolute top-0 left-0 z-20 shadow-2xl hover:scale-105 transition-transform">
                  <CoreCardComponent card={plannedAction.actionCard} selected={true} />
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-indigo-600 text-white text-[10px] uppercase font-bold px-2 py-0.5 rounded shadow z-50">
                    Planned
                  </div>
                </div>
              </div>
            ) : (
              // Narrative / Pass Stack
              <div className="flex -space-x-8">
                {plannedAction.type === 'narrative' &&
                  plannedAction.cards.map((c) => (
                    <div
                      key={c.id}
                      className="relative z-10 hover:z-20 transform hover:-translate-y-2 transition-transform"
                    >
                      <CoreCardComponent card={c} />
                    </div>
                  ))}
                {plannedAction.type === 'pass' && (
                  <div className="text-slate-500 italic text-sm">Passed turn</div>
                )}
              </div>
            )}
          </div>
        )}

        {/* --- RIGHT ZONE: Remaining Hand --- */}
        <div className="flex-shrink-0 pointer-events-none">
          <div
            className={`flex items-end transition-opacity duration-300 ${hasPlanned ? 'opacity-60 grayscale-[0.3]' : 'opacity-100'}`}
            style={{ minHeight: '260px' }}
          >
            {visibleHand.length > 0
              ? visibleHand.map((card, idx) => {
                  // Normal Play Mode
                  const isPlayableAction = !hasPlanned && actionCandidates.has(card.id);

                  return (
                    <div
                      key={card.id}
                      className="pointer-events-auto -ml-12 first:ml-0 relative group"
                      style={{ zIndex: idx, width: '160px' }}
                    >
                      <div
                        className={`transition-transform duration-200 ease-out origin-bottom ${isPlayableAction ? 'cursor-pointer hover:-translate-y-8 hover:z-50' : 'cursor-default'}`}
                        onClick={() => {
                          if (isPlayableAction) stageAction(card.id);
                        }}
                      >
                        <CoreCardComponent
                          card={card}
                          className={
                            isPlayableAction
                              ? 'ring-2 ring-indigo-400 ring-offset-2 ring-offset-black/50'
                              : !hasPlanned
                                ? 'brightness-75 contrast-75'
                                : ''
                          }
                        />
                        {isPlayableAction && (
                          <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-indigo-600 text-white text-[10px] uppercase font-bold px-2 py-0.5 rounded shadow z-50 opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                            Play Action
                          </div>
                        )}
                      </div>
                    </div>
                  );
                })
              : !hasPlanned && (
                  <div className="text-slate-500 text-sm italic w-[200px] text-center pb-20">
                    No cards in hand
                  </div>
                )}
          </div>
        </div>

        {/* --- Pass Button --- */}
        {!hasPlanned && phase === 'planning' && visibleHand.length > 0 && (
          <div className="absolute bottom-64 pt-8 pointer-events-auto">
            <button
              onClick={onPass}
              className="flex items-center gap-2 bg-slate-800/80 hover:bg-slate-700 text-slate-300 px-4 py-2 rounded-full border border-slate-600 shadow backdrop-blur transition-all font-bold hover:text-white group text-xs uppercase tracking-wider"
            >
              <SkipForward size={14} className="group-hover:translate-x-0.5 transition-transform" />{' '}
              Pass
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

// --- Container (Unchanged except imports) ---

const PlayerHand: React.FC<{ actorId: string }> = ({ actorId }) => {
  const { dispatchCommand } = useGameDispatch();

  // Select stable raw data from store - these references don't change unless store updates
  const actor = useGameStore((state) => state.actors[actorId]);
  const activeActorId = useGameStore((state) => state.activeActorId);
  const phase = useGameStore((state) => state.phase);

  // Derive hydrated cards in useMemo - only recomputes when actor changes
  const hand = useMemo((): ClientCoreCard[] => {
    if (!actor) return [];
    return selectHand({ actors: { [actorId]: actor } }, actorId);
  }, [actor, actorId]);

  const plannedAction = useMemo((): UIPlannedAction | undefined => {
    if (!actor) return undefined;
    return selectPlannedAction({ actors: { [actorId]: actor } }, actorId);
  }, [actor, actorId]);

  // Handlers
  const handlePlayStack = (
    selectedCards: ClientCoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
    actionCardId?: string,
  ) => {
    if (!activeActorId) return;

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
  };

  const handleDiscard = (cards: ClientCoreCard[]) => {
    if (!activeActorId) return;
    dispatchCommand({
      type: 'discardCardsIntent',
      actorId: activeActorId,
      cardIds: cards.map((c) => c.id),
    });
  };

  const handlePass = () => {
    if (!activeActorId) return;
    dispatchCommand({ type: 'passIntent', actorId: activeActorId });
  };

  const handleCancelPlan = () => {
    if (!activeActorId) return;
    dispatchCommand({ type: 'cancelPlanIntent', actorId: activeActorId });
  };

  const handleReturnToDeck = (cards: ClientCoreCard[]) => {
    if (!activeActorId) return;
    dispatchCommand({
      type: 'returnToDeckIntent',
      actorId: activeActorId,
      cardIds: cards.map((c) => c.id),
    });
  };

  return (
    <PlayerHandView
      hand={hand}
      onPlayStack={handlePlayStack}
      onDiscard={handleDiscard}
      onPass={handlePass}
      onCancelPlan={handleCancelPlan}
      onReturnToDeck={handleReturnToDeck}
      phase={phase}
      hasPlanned={!!plannedAction}
      plannedAction={plannedAction}
    />
  );
};

export default PlayerHand;
