import React, { useRef, useEffect } from 'react';
import { X, Shield, Skull, Zap, ChevronRight, Layers } from 'lucide-react';
import { DefenseDetails, CoreCard, ActorState } from '../../generated/types';
import { CoreCardComponent, ConsequenceCardComponent } from '../Card/Card';
import { CardStack } from '../Card/CardStack';
import { ClientCard } from '../../store/selectors';

// Updated imports for strict view usage with Wrappers
// Note: We'll use simple div wrappers for some "chips" but standard components for full cards

export type DefenseModalCard = ClientCard;

interface DefenseWidgetProps {
  isOpen: boolean;
  onClose: () => void;
  // Challenge Context (Global)
  attackStack: DefenseModalCard[]; // Incoming Attack (Action + Resources)
  attackTarget: number;
  attackColor: 'red' | 'yellow' | 'blue';
  // Actor State (Optional - if missing, we ask user to select)
  activeActor?: ActorState;
  // Actions
  onDefend: () => void;
  onAddConsequence: (severity?: number) => void;
  onClearDefense: () => void;
  // Warning Banner
  warningMessage?: string | null;
  onDismissWarning?: () => void;
}

export const DefenseWidget: React.FC<DefenseWidgetProps> = ({
  isOpen,
  onClose,
  attackStack,
  attackTarget,
  attackColor,
  activeActor,
  onDefend,
  onAddConsequence,
  onClearDefense,
  warningMessage,
  onDismissWarning,
}) => {
  const scrollRef = useRef<HTMLDivElement>(null);

  // --- Resolve Actor Data if Present ---
  const defaultDefenseDetails: DefenseDetails = {
    values: { red: 0, yellow: 0, blue: 0 },
    impact: 0,
    consequencesFromDefense: 0,
    nextSeverity: 1,
  };

  // Resolve Consequences
  const consequences = activeActor?.tableState.consequences || [];

  // Resolve Defense Stack
  const defenseStack = activeActor?.coreState.defending?.cards || [];

  const defenseDetails = activeActor?.defenseDetails || defaultDefenseDetails;
  const currentDefense = activeActor?.defense || 0;
  const currentResilience = activeActor?.resilience || 0;

  // Auto-scroll defense stack when new cards arrive
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollLeft = 0;
    }
  }, [defenseStack.length]);

  if (!isOpen) return null;

  // Identify the most recently added consequence
  // Assuming the last one in the list is the newest
  const recentConsequence = consequences.length > 0 ? consequences[consequences.length - 1] : null;
  const olderConsequences = consequences.length > 0 ? consequences.slice(0, -1) : [];

  // Identify Controlling Card (First card in attack stack usually, or explicit source)
  const controllingCard = attackStack.length > 0 ? attackStack[0] : null;
  const attackResources = attackStack.length > 1 ? attackStack.slice(1) : [];

  return (
    <div className="fixed bottom-4 right-80 z-40 mb-4 mr-4 w-[26rem] flex flex-col gap-2 pointer-events-none">
      {/* 
        Container is pointer-events-none so we don't block clicks around it if we add transparency 
        But children need pointer-events-auto
      */}

      {/* WARNING BANNER */}
      {warningMessage && (
        <div className="bg-yellow-950/90 border border-yellow-600 rounded-lg p-3 shadow-xl pointer-events-auto backdrop-blur-sm animate-in slide-in-from-bottom-2 flex justify-between items-start gap-3">
          <div className="text-xs text-yellow-200">
            <span className="font-bold block mb-1 text-yellow-500 uppercase flex items-center gap-1">
              <Zap size={12} /> Active Defense Conflict
            </span>
            {warningMessage}
          </div>
          <button
            onClick={onDismissWarning}
            className="text-yellow-600 hover:text-yellow-400 transition-colors"
          >
            <X size={14} />
          </button>
        </div>
      )}

      {/* MAIN WIDGET */}
      <div className="bg-slate-900 border border-slate-700 shadow-2xl rounded-xl overflow-hidden pointer-events-auto flex flex-col">
        {/* HEADER */}
        <div className="bg-slate-800 px-3 py-2 flex items-center justify-between border-b border-slate-700">
          <div className="flex items-center gap-2">
            <Shield className="text-blue-400 w-4 h-4" />
            <span className="text-sm font-bold text-slate-200">Defense Resolution</span>
          </div>
          <button onClick={onClose} className="text-slate-500 hover:text-white transition-colors">
            <X size={16} />
          </button>
        </div>

        {/* CHALLENGE BANNER */}
        <div className="relative bg-black/40 p-3 border-b border-slate-800">
          {/* Color Accent Line */}
          <div
            className={`absolute left-0 top-0 bottom-0 w-1 
             ${attackColor === 'red' ? 'bg-red-500' : ''}
             ${attackColor === 'yellow' ? 'bg-yellow-500' : ''}
             ${attackColor === 'blue' ? 'bg-blue-500' : ''}
           `}
          />

          <div className="flex items-start gap-3 pl-2">
            {/* Thumbnail of Controlling Action */}
            {/* Full Controlling Card (Scale Down slightly) */}
            {controllingCard && 'stats' in controllingCard ? (
              <div className="shrink-0 transform scale-75 origin-top-left -mb-10">
                <CoreCardComponent card={controllingCard as CoreCard} selected={false} />
              </div>
            ) : (
              <div className="w-12 h-16 bg-slate-800 flex items-center justify-center rounded border border-dashed border-slate-600 text-xs text-slate-500">
                ?
              </div>
            )}

            {/* VS Math */}
            <div className="flex-1 flex flex-col justify-start h-32 py-1">
              <div className="flex flex-col">
                <span className="text-[10px] uppercase text-slate-400 font-bold">
                  Incoming Attack
                </span>
                <div className="flex items-baseline gap-1">
                  <span
                    className={`text-3xl font-black 
                      ${attackColor === 'red' ? 'text-red-400' : ''}
                      ${attackColor === 'yellow' ? 'text-yellow-400' : ''}
                      ${attackColor === 'blue' ? 'text-blue-400' : ''}
                    `}
                  >
                    {attackTarget}
                  </span>
                  <span className="text-sm font-bold text-slate-500 capitalize">{attackColor}</span>
                </div>
              </div>

              {/* Resources Indicator */}
              {attackResources.length > 0 && (
                <div className="mt-2 flex items-center gap-1 text-xs text-slate-400 bg-slate-800/50 px-2 py-1 rounded w-fit">
                  <Layers size={14} />
                  <span>+{attackResources.length} cards support</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* CONTENT AREA: Depends on Actor Presence */}
        {activeActor ? (
          <>
            {/* DEFENSE AREA */}
            <div className="p-3 bg-slate-800/30 flex flex-col gap-3">
              {/* Stats Row */}
              {/* Defense Totals Breakdown */}
              <div className="flex flex-col gap-2 bg-slate-900/50 p-2 rounded border border-slate-800">
                {/* Totals Row */}
                <div className="flex justify-between items-center text-xs text-slate-400 pb-2 border-b border-slate-700/50">
                  <div className="flex gap-3">
                    <div className="flex items-center gap-1">
                      <div className="w-2 h-2 rounded-full bg-red-500" />
                      <span className={attackColor === 'red' ? 'text-red-100 font-bold' : ''}>
                        {defenseDetails.values.red}
                      </span>
                    </div>
                    <div className="flex items-center gap-1">
                      <div className="w-2 h-2 rounded-full bg-yellow-500" />
                      <span className={attackColor === 'yellow' ? 'text-yellow-100 font-bold' : ''}>
                        {defenseDetails.values.yellow}
                      </span>
                    </div>
                    <div className="flex items-center gap-1">
                      <div className="w-2 h-2 rounded-full bg-blue-500" />
                      <span className={attackColor === 'blue' ? 'text-blue-100 font-bold' : ''}>
                        {defenseDetails.values.blue}
                      </span>
                    </div>
                  </div>
                  <div className="font-mono opacity-50">Totals</div>
                </div>

                {/* Net Row */}
                <div className="flex justify-between items-center pt-1">
                  <div className="flex gap-4">
                    <div>
                      <span className="text-[10px] text-slate-500 block uppercase">Defense</span>
                      <span className="text-xl font-bold text-blue-400">{currentDefense}</span>
                    </div>
                    <div>
                      <span className="text-[10px] text-slate-500 block uppercase">Resil.</span>
                      <span className="text-xl font-bold text-red-500/80">{currentResilience}</span>
                    </div>
                  </div>

                  <div className="flex flex-col items-end">
                    <span className="text-[10px] text-slate-500 block uppercase">Net Impact</span>
                    <div className="flex items-center gap-2">
                      <span
                        className={`text-xl font-black ${defenseDetails.impact > 0 ? 'text-red-500' : 'text-green-500'}`}
                      >
                        {defenseDetails.impact}
                      </span>
                      {defenseDetails.consequencesFromDefense > 0 && (
                        <span className="text-[10px] bg-red-900/50 text-red-200 px-1 rounded border border-red-800 animate-pulse">
                          +{defenseDetails.consequencesFromDefense} Conseq
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              {/* Flipped Cards Strip */}
              <div ref={scrollRef} className="w-full">
                <CardStack
                  cards={defenseStack}
                  mode="row"
                  scale={0.9}
                  className="pb-2 min-h-[4rem] items-center"
                  emptyMessage={
                    <div className="w-full text-center text-xs text-slate-600 italic py-2">
                      Use your deck to defend...
                    </div>
                  }
                />
              </div>
            </div>

            {/* ACTION BAR */}
            <div className="p-3 bg-slate-800 border-t border-slate-700 grid grid-cols-2 gap-2">
              <button
                onClick={onDefend}
                className="bg-blue-600 hover:bg-blue-500 text-white font-md py-2 px-3 rounded shadow flex items-center justify-center gap-2 transition-colors"
              >
                <Zap size={16} fill="currentColor" />
                <span>Flip Card</span>
              </button>

              <div className="flex gap-1">
                <button
                  onClick={() => onAddConsequence()}
                  className="flex-1 bg-red-900/60 hover:bg-red-800 text-red-100 text-xs font-bold py-1 px-2 rounded-l border border-red-800 flex flex-col items-center justify-center"
                  title={`Add Consequence (Sev ${defenseDetails.nextSeverity})`}
                >
                  <span>Take Conseq</span>
                  <span className="text-[9px] opacity-60">Sev {defenseDetails.nextSeverity}</span>
                </button>
                <div className="flex flex-col w-6">
                  {[3, 2, 1].map((sev) => (
                    <button
                      key={sev}
                      onClick={() => onAddConsequence(sev)}
                      className="flex-1 bg-slate-700 hover:bg-red-700 text-[8px] text-white flex items-center justify-center border-b border-black/20 last:border-0 first:rounded-tr last:rounded-br"
                    >
                      {sev}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Footer Actions */}
            <div className="px-3 pb-3 bg-slate-800 flex justify-between">
              <button
                onClick={onClearDefense}
                className="text-xs text-slate-500 hover:text-slate-300 underline decoration-slate-600"
              >
                Clear / End
              </button>
            </div>
          </>
        ) : (
          /* NO ACTOR SELECTED STATE */
          <div className="p-8 flex flex-col items-center justify-center text-slate-500 bg-slate-900/50 min-h-[12rem]">
            <p className="text-sm text-center mb-2 italic">Who is defending?</p>
            <p className="text-xs text-center opacity-70 max-w-[16rem]">
              Select a token on the board to resolve defense against this attack.
            </p>
          </div>
        )}
      </div>

      {/* CONSEQUENCE NOTIFICATION AREA (Only show if actor selected and present) */}
      {activeActor && consequences.length > 0 && (
        <div className="bg-slate-900/90 border border-slate-700 rounded-lg p-3 shadow-xl pointer-events-auto backdrop-blur-sm animate-in slide-in-from-bottom-2">
          <div className="flex items-center gap-2 mb-2 text-xs font-bold text-slate-400 uppercase">
            <Skull size={12} />
            <span>Consequences</span>
          </div>

          <div className="space-y-2">
            {/* Recent Consequence (Highlighted) */}
            {recentConsequence && (
              <div className="relative group">
                <div className="text-[10px] text-red-400 font-bold mb-1 flex items-center gap-1">
                  <ChevronRight size={10} /> Most Recent
                </div>
                {/* We render a full card component but maybe simplified or scaled? 
                        ConsequenceCardComponent is standard size. Let's just use it.
                    */}
                <ConsequenceCardComponent card={recentConsequence} selected={false} />
              </div>
            )}

            {/* Older Consequences (Chips) */}
            {olderConsequences.length > 0 && (
              <div className="flex flex-wrap gap-1 mt-2 pt-2 border-t border-slate-700/50">
                {olderConsequences.map((c) => (
                  <div key={c.id} className="group relative">
                    <div className="bg-red-950/40 border border-red-900/60 text-red-200 text-xs px-2 py-1 rounded cursor-help hover:bg-red-900/80 transition-colors">
                      {c.name}
                    </div>
                    {/* Hover Popup */}
                    <div className="absolute bottom-full mb-2 left-0 w-64 hidden group-hover:block z-50">
                      <ConsequenceCardComponent card={c} selected={false} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
