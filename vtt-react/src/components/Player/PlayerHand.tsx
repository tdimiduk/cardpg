import React from 'react';
import { useHandSelection } from '../../hooks/useHandSelection';
import { CoreCard, ResourceType, GamePhase, PlannedAction, Rule } from '../../types';
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

interface PlayerHandProps {
  hand: CoreCard[];
  onPlayStack: (
    selectedCards: CoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
  ) => void;
  onDiscard: (selectedCards: CoreCard[]) => void;
  onPass: () => void;
  onCancelPlan: () => void;
  onReturnToDeck: (selectedCards: CoreCard[]) => void;
  phase: GamePhase;
  hasPlanned: boolean;
  plannedAction?: PlannedAction;
}

// Helper Component for Action Button Icons
const ColorIcon = ({ color }: { color: ResourceType }) => {
  switch (color) {
    case 'Red':
      return <Square size={14} className="inline fill-current" />;
    case 'Yellow':
      return <Circle size={14} className="inline fill-current" />;
    case 'Blue':
      return <Diamond size={14} className="inline fill-current" />;
  }
};

export const PlayerHand: React.FC<PlayerHandProps> = ({
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
      <div className="absolute bottom-0 left-0 right-0 z-40 h-48 flex items-center justify-center bg-black/50 backdrop-blur-sm pointer-events-none">
        <button
          onClick={onCancelPlan}
          className="pointer-events-auto bg-slate-900 border border-indigo-500 p-6 rounded-xl shadow-2xl flex flex-col items-center gap-2 hover:bg-slate-800 transition-all group cursor-pointer relative overflow-hidden min-w-[300px]"
        >
          <div className="absolute inset-0 bg-indigo-500/10 group-hover:bg-indigo-500/20 transition-colors"></div>

          {/* Header with Icon transition */}
          <div className="flex items-center gap-2 text-indigo-400 mb-1">
            <div className="relative">
              <Lock
                size={20}
                className="group-hover:opacity-0 transition-opacity absolute top-0 left-0"
              />
              <RotateCcw
                size={20}
                className="opacity-0 group-hover:opacity-100 transition-opacity"
              />
              <div className="w-5 h-5"></div> {/* Spacer */}
            </div>
            <span className="text-xs font-bold uppercase tracking-widest group-hover:text-indigo-300">
              Plan Locked
            </span>
          </div>

          {/* Action Name */}
          <h3 className="text-xl font-bold text-indigo-100">
            {plannedAction?.actionName || 'Pass'}
          </h3>

          {/* Card Details */}
          {plannedAction && plannedAction.cards.length > 0 ? (
            <div className="text-slate-400 text-sm flex flex-col items-center mt-1">
              <span className="text-[10px] uppercase text-slate-500">Using Cards</span>
              <span className="font-mono text-indigo-300 font-semibold text-center px-4">
                {plannedAction.cards.map((c) => c.name).join(' + ')}
              </span>
            </div>
          ) : (
            <div className="text-slate-500 text-xs italic mt-1">No cards committed</div>
          )}

          {/* CTA */}
          <div className="mt-3 text-xs text-slate-500 group-hover:text-red-400 transition-colors font-bold uppercase tracking-wider border-t border-slate-700 pt-2 w-full text-center">
            Click to Cancel & Revise
          </div>
        </button>
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
                {actionCards.map((card) => {
                  const cost = card.cost!;
                  const requiredTotal = cost + 1;

                  const currentCount = selectedCards.length;
                  const diff = requiredTotal - currentCount;
                  const isValid = diff === 0;

                  const rule = getActionRule(card);
                  // We know rule exists because of filter

                  return (
                    <button
                      key={card.id}
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
                                  rule.data.power.source === 'Red'
                                    ? 'text-red-400'
                                    : rule.data.power.source === 'Yellow'
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
                                      rule.data.resistedBy === 'Red'
                                        ? 'text-red-400'
                                        : rule.data.resistedBy === 'Yellow'
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
                          {rule.type === 'general' && rule.data.power && (
                            <>
                              <span
                                className={
                                  rule.data.power.source === 'Red'
                                    ? 'text-red-400'
                                    : rule.data.power.source === 'Yellow'
                                      ? 'text-yellow-400'
                                      : 'text-blue-400'
                                }
                              >
                                <ColorIcon color={rule.data.power.source} />
                              </span>
                              <span className="font-mono ml-1">
                                ({rule.data.power.modifier > 0 ? '+' : ''}
                                {rule.data.power.modifier})
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
                onClick={() => handleImprovise('Red')}
                className="flex items-center gap-2 bg-red-950/40 hover:bg-red-900/80 text-red-200 px-3 py-2 rounded font-bold text-xs border border-red-900/50 transition-colors"
              >
                <Square size={14} fill="currentColor" />{' '}
                {phase === 'planning' ? 'Plan Force' : 'Force'}
              </button>
              <button
                onClick={() => handleImprovise('Yellow')}
                className="flex items-center gap-2 bg-yellow-950/40 hover:bg-yellow-900/80 text-yellow-200 px-3 py-2 rounded font-bold text-xs border border-yellow-900/50 transition-colors"
              >
                <Circle size={14} fill="currentColor" />{' '}
                {phase === 'planning' ? 'Plan Speed' : 'Speed'}
              </button>
              <button
                onClick={() => handleImprovise('Blue')}
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
          {hand.map((card) => (
            <div
              key={card.id}
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
