import React from 'react';
import { X, Shield, Skull, AlertCircle } from 'lucide-react';
import { DefenseDetails, ConsequenceCard, CoreCard } from '../../generated/types';

// Updated imports for strict view usage with Wrappers
import { CoreCardComponent, ConsequenceCardComponent } from '../Card/Card';

// We define a specialized type for cards used in this modal
export type DefenseModalCard = (ConsequenceCard & { id: string }) | (CoreCard & { id: string });

interface DefenseModalProps {
  isOpen: boolean;
  onClose: () => void;
  attackStack: DefenseModalCard[]; // Attack stack is strictly CoreCards
  attackTarget: number;
  attackColor: 'red' | 'yellow' | 'blue';
  defenseDetails: DefenseDetails;
  currentDefense: number;
  currentResilience: number;
  consequences: (ConsequenceCard & { id: string })[]; // Explicitly Consequence Cards
  onDefend: () => void;
  onAddConsequence: (severity?: number) => void;
  onClearDefense: () => void;
}

export const DefenseModal: React.FC<DefenseModalProps> = ({
  isOpen,
  onClose,
  attackStack,
  attackTarget,
  attackColor,
  defenseDetails,
  currentDefense,
  currentResilience,
  consequences,
  onDefend,
  onAddConsequence,
  onClearDefense,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 backdrop-blur-sm p-4">
      <div className="bg-slate-900 border border-slate-700 rounded-xl shadow-2xl w-full max-w-5xl h-[90vh] flex flex-col overflow-hidden relative">
        {/* Header */}
        <div className="bg-slate-800 p-4 flex items-center justify-between border-b border-slate-700 shrink-0">
          <h2 className="text-xl font-bold flex items-center gap-2">
            <Shield className="text-blue-400" />
            Defense & Impact
          </h2>
          <button
            onClick={onClose}
            className="p-1 hover:bg-slate-700 rounded text-slate-400 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        {/* content grid */}
        <div className="flex-1 grid grid-cols-12 overflow-hidden">
          {/* LEFT: Incoming Attack (Stack) */}
          <div className="col-span-8 bg-black/20 p-6 overflow-y-auto flex flex-col items-center">
            {/* Attack Summary Banner */}
            <div
              className={`
              w-full max-w-2xl mb-8 p-4 rounded-lg border flex items-center justify-between
              ${attackColor === 'red' ? 'bg-red-900/20 border-red-500/50 text-red-100' : ''}
              ${attackColor === 'yellow' ? 'bg-yellow-900/20 border-yellow-500/50 text-yellow-100' : ''}
              ${attackColor === 'blue' ? 'bg-blue-900/20 border-blue-500/50 text-blue-100' : ''}
            `}
            >
              <div className="flex flex-col">
                <span className="text-xs uppercase font-bold opacity-70">Incoming Force</span>
                <span className="text-3xl font-black">{attackTarget}</span>
              </div>
              <div className="flex flex-col items-end text-right">
                <span className="text-xs uppercase font-bold opacity-70">Target Attribute</span>
                <span className="text-xl font-bold capitalize">{attackColor}</span>
              </div>
            </div>

            {/* The Stack Display */}
            <div className="flex flex-col items-center gap-4 w-full max-w-3xl">
              {/* Stack Cards Grid */}
              <div className="flex flex-wrap justify-center gap-4">
                {attackStack.map((card, idx) =>
                  // Using CoreCardComponent which wraps BaseCard
                  'stats' in card ? (
                    <CoreCardComponent
                      key={`${card.id}-${idx}`}
                      card={card as CoreCard}
                      // Interactive Props from BaseCard are optional but typically false here
                      selected={false}
                    />
                  ) : (
                    // Fallback just in case, though stack should be core
                    <div key={idx} className="bg-red-500 text-white p-2">
                      Invalid Card: Not Core
                    </div>
                  ),
                )}
                {attackStack.length === 0 && (
                  <div className="text-slate-500 italic p-8 border-2 border-dashed border-slate-700 rounded-lg">
                    Waiting for attack cards...
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* RIGHT: Defense & Resolution */}
          <div className="col-span-4 bg-slate-800/50 border-l border-slate-700 p-6 flex flex-col overflow-hidden">
            {/* Defense Stats */}
            <div className="mb-6 bg-slate-900 rounded p-4 border border-slate-700 shadow-inner">
              <div className="grid grid-cols-2 gap-4 mb-4">
                <div className="flex flex-col">
                  <span className="text-xs text-slate-400">Current Defense</span>
                  <span className="text-2xl font-bold text-blue-400">{currentDefense}</span>
                </div>
                <div className="flex flex-col">
                  <span className="text-xs text-slate-400">Resilience</span>
                  <span className="text-2xl font-bold text-red-400">{currentResilience}</span>
                </div>
              </div>

              {/* Impact Calculation */}
              <div className="border-t border-slate-700 pt-4 mt-2">
                <div className="flex justify-between items-center mb-2">
                  <span className="font-bold text-slate-300">Net Impact</span>
                  <span
                    className={`text-2xl font-black ${defenseDetails.impact > 0 ? 'text-red-500' : 'text-green-500'}`}
                  >
                    {defenseDetails.impact}
                  </span>
                </div>

                {defenseDetails.consequencesFromDefense > 0 && (
                  <div className="text-xs text-yellow-400 flex items-center gap-1 mt-1">
                    <AlertCircle size={12} />
                    Takes {defenseDetails.consequencesFromDefense} Consequence(s)
                  </div>
                )}
              </div>
            </div>

            {/* Action Buttons */}
            <div className="grid grid-cols-2 gap-3 mb-6 shrink-0">
              <button
                onClick={onDefend}
                className="bg-blue-600 hover:bg-blue-500 text-white font-bold py-3 px-4 rounded shadow-lg flex items-center justify-center gap-2 transition-all"
              >
                <Shield size={18} />
                Defend
              </button>
              <div className="flex gap-1">
                <button
                  onClick={() => onAddConsequence()} // Default server severity
                  className="flex-1 bg-red-900/80 hover:bg-red-800 text-red-100 font-bold py-2 px-2 rounded-l border border-red-700 flex flex-col items-center justify-center transition-all"
                  title="Add Consequence (Auto Severity)"
                >
                  <div className="flex items-center gap-1">
                    <Skull size={16} />
                    <span className="text-xs">Add</span>
                  </div>
                  <span className="text-[10px] opacity-75">Sev {defenseDetails.nextSeverity}</span>
                </button>
                {/* Manual Severity Override Buttons */}
                <div className="flex flex-col w-6">
                  {[3, 2, 1].map((sev) => (
                    <button
                      key={sev}
                      onClick={() => onAddConsequence(sev)}
                      className="flex-1 bg-slate-700 hover:bg-red-700 text-[8px] border-b border-black/20 last:border-0 text-white flex items-center justify-center"
                      title={`Force Severity ${sev}`}
                    >
                      {sev}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <button
              onClick={onClearDefense}
              className="w-full mb-6 bg-slate-700 hover:bg-slate-600 text-slate-300 py-2 rounded text-sm transition-colors"
            >
              End Defense / Clear Stack
            </button>

            {/* Active Consequences List */}
            <div className="flex-1 overflow-hidden flex flex-col">
              <h3 className="text-sm font-bold text-slate-400 mb-2 flex items-center gap-2 uppercase tracking-wider">
                <Skull size={14} /> Active Consequences
              </h3>
              <div className="flex-1 overflow-y-auto custom-scrollbar space-y-2 pr-1">
                {consequences.map((card) => (
                  <div key={card.id} className="relative group">
                    {/* Explicitly use ConsequenceCardComponent */}
                    <ConsequenceCardComponent card={card} selected={false} />
                  </div>
                ))}
                {consequences.length === 0 && (
                  <div className="text-center py-8 text-slate-600 text-xs italic">
                    No active consequences
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
