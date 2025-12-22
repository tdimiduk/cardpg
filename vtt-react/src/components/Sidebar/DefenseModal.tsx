import React from 'react';
import { X } from 'lucide-react';
import { DefenseDetails, ResourceType } from '../../generated/types';
import { DefenseStats } from './DefenseStats';
import { Card as CardType, CardComponent } from '../Card/Card';

export type DefenseModalCard = CardType & { id: string };

interface DefenseModalProps {
  isOpen: boolean;
  onClose: () => void;

  // Attack Context
  attackStack: DefenseModalCard[];
  attackTarget: number;
  attackColor: ResourceType;

  // Defense Context
  defenseDetails: DefenseDetails;
  currentDefense: number;
  currentResilience: number;
  consequences: (CardType & { id: string })[];

  // Actions
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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm animate-fade-in">
      <div className="bg-slate-950 border border-slate-700 rounded-lg shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-4 border-b border-slate-800 flex justify-between items-center bg-slate-900">
          <h2 className="text-lg font-bold text-slate-100 flex items-center gap-2">
            Defense & Impact
          </h2>
          <button onClick={onClose} className="text-slate-400 hover:text-white transition-colors">
            <X size={20} />
          </button>
        </div>

        {/* Content - Scrollable */}
        <div className="overflow-y-auto p-4 space-y-6 flex-1 custom-scrollbar">
          {/* Attack Stack Section */}
          {/* Attack Stack Section */}
          <div className="flex-1 min-h-0 bg-slate-900/50 rounded border border-slate-800/50 overflow-hidden flex items-stretch justify-center p-2 min-h-[220px]">
            {/* Left: Controlling Action */}
            <div className="flex flex-col items-center justify-center">
              {attackStack.length > 0 ? (
                <CardComponent
                  card={attackStack[0]}
                  className="transform hover:scale-110 hover:z-10"
                />
              ) : (
                <div className="text-slate-600 text-sm italic">No active attack.</div>
              )}
            </div>

            {/* Vertical Divider */}
            <div className="w-[2px] bg-slate-700/50 my-1 mx-2" />

            {/* Right: Resources */}
            <div className="flex-1 flex items-center justify-start overflow-x-auto custom-scrollbar p-1">
              <div className="flex items-center">
                {attackStack.length > 1 ? (
                  attackStack.slice(1).map((card, idx) => (
                    <CardComponent
                      key={`${card.id}-${idx}-res`}
                      card={card}
                      scale={0.9}
                      className="flex-shrink-0 transform hover:scale-110 hover:z-10 origin-center mx-1"
                    />
                  ))
                ) : (
                  <div className="text-slate-700 text-sm italic pl-2">No additional resources.</div>
                )}
              </div>
            </div>
          </div>

          {/* Defense Controls */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Left Col: Stats & Actions */}
            <div>
              <div className="text-xs font-bold text-slate-500 uppercase mb-2">Response</div>
              <DefenseStats
                details={defenseDetails}
                defenseStat={currentDefense}
                resilienceStat={currentResilience}
                onDefend={onDefend}
                onAddConsequence={onAddConsequence}
                targetStrength={attackTarget}
                attackColor={attackColor}
              />
            </div>

            {/* Right Col: Consequence Grid */}
            <div>
              <div className="text-xs font-bold text-slate-500 uppercase mb-2">
                Active Consequences
              </div>
              <div className="bg-slate-900/50 p-3 rounded min-h-[150px] border border-slate-800/50">
                {consequences.length === 0 ? (
                  <div className="text-slate-600 text-xs italic p-2 text-center">
                    No active consequences.
                  </div>
                ) : (
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                    {consequences.map((card) => (
                      <div key={card.id} className="relative group">
                        <div className="transform scale-75 origin-top-left">
                          <CardComponent card={card} />
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Footer Actions */}
        <div className="p-4 border-t border-slate-800 bg-slate-900/50 flex justify-end gap-2">
          <button
            onClick={() => {
              onClearDefense();
              onClose();
            }}
            className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded border border-slate-600 font-bold text-sm transition-colors"
          >
            End Defense
          </button>
          <button
            onClick={onClose}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded font-bold text-sm shadow-lg shadow-indigo-900/20 transition-colors"
          >
            Done (Keep Defending)
          </button>
        </div>
      </div>
    </div>
  );
};
