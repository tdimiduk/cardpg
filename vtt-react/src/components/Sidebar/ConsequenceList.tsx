import React from 'react';
import { AlertTriangle, X } from 'lucide-react';
import { CoreCard } from '../../types';

interface ConsequenceListProps {
  consequences: CoreCard[];
  currentSeverity: number;
  onAddConsequence: () => void;
  onRemoveConsequence: (cardId: string) => void;
}

export const ConsequenceList: React.FC<ConsequenceListProps> = ({
  consequences,
  currentSeverity,
  onAddConsequence,
  onRemoveConsequence,
}) => {
  return (
    <div className="p-4">
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs text-slate-500 font-bold uppercase flex items-center gap-1">
          <AlertTriangle size={12} /> Consequences
        </span>
        <button
          onClick={onAddConsequence}
          className="text-[10px] bg-slate-800 hover:bg-red-900 text-slate-400 hover:text-red-200 px-2 py-0.5 rounded border border-slate-700 transition-colors"
        >
          + Add
        </button>
      </div>

      <div className="mb-3 bg-red-950/20 border border-red-900/30 p-2 rounded text-center">
        <span className="text-[10px] text-red-400 uppercase tracking-widest block mb-1">
          Severity Level
        </span>
        <span className="text-2xl font-black text-red-500">{currentSeverity}</span>
      </div>

      <div className="space-y-2">
        {consequences.length === 0 ? (
          <div className="text-[10px] text-slate-600 text-center italic py-2">
            No active consequences.
          </div>
        ) : (
          consequences.map((c) => (
            <div
              key={c.id}
              className="bg-slate-800 p-2 rounded border-l-2 border-red-500 text-xs text-slate-300 shadow-sm relative group"
            >
              <div className="font-bold text-red-200 mb-1 flex justify-between items-start pr-4">
                <span>{c.name}</span>
                <button
                  onClick={() => onRemoveConsequence(c.id)}
                  className="absolute top-1 right-1 text-slate-600 hover:text-slate-300 p-0.5 rounded transition-colors"
                  title="Remove Consequence"
                >
                  <X size={12} />
                </button>
              </div>
              <div className="text-[10px] text-slate-400 whitespace-normal leading-normal">
                {c.flavor && c.flavor[0]?.type === 'textRun' ? c.flavor[0].content : ''}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
