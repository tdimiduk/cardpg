import React from 'react';
import { Shield, Square, Circle, Diamond } from 'lucide-react';
import { DefenseDetails } from '../../generated/types';

interface DefenseStatsProps {
  details: DefenseDetails;
  defenseStat: number;
  resilienceStat: number;
  onDefend: () => void;
  onClearDefense: () => void;
  hasFlippedCards: boolean;
}

export const DefenseStats: React.FC<DefenseStatsProps> = ({
  details,
  defenseStat,
  resilienceStat,
  onDefend,
  onClearDefense,
  hasFlippedCards,
}) => {
  return (
    <div className="p-4 border-b border-slate-800 bg-slate-900/20">
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs text-slate-500 font-bold uppercase tracking-wider flex items-center gap-1">
          <Shield size={12} /> Defense & Impact
        </span>
        {hasFlippedCards && (
          <button
            onClick={onClearDefense}
            className="text-[10px] text-slate-400 hover:text-white underline"
          >
            Clear
          </button>
        )}
      </div>

      {/* Active Defense Stats */}
      <div className="grid grid-cols-3 gap-2 text-center mb-3">
        <div className="bg-red-950/30 p-1 rounded border border-red-900/50">
          <Square size={12} className="mx-auto mb-1 text-red-500" />
          <span className="text-sm font-bold text-red-200">{details.red}</span>
        </div>
        <div className="bg-yellow-950/30 p-1 rounded border border-yellow-900/50">
          <Circle size={12} className="mx-auto mb-1 text-yellow-500" />
          <span className="text-sm font-bold text-yellow-200">{details.yellow}</span>
        </div>
        <div className="bg-blue-950/30 p-1 rounded border border-blue-900/50">
          <Diamond size={12} className="mx-auto mb-1 text-blue-500" />
          <span className="text-sm font-bold text-blue-200">{details.blue}</span>
        </div>
      </div>

      <button
        onClick={onDefend}
        className="w-full bg-indigo-900/40 hover:bg-indigo-800/60 border border-indigo-500/30 text-indigo-200 text-xs font-bold py-2 rounded flex items-center justify-center gap-2 transition-all mb-4"
      >
        <Shield size={14} /> Flip for Defense
      </button>

      {/* Derived Stats */}
      <div className="space-y-3 text-xs border-t border-slate-800 pt-3">
        <div className="flex justify-between items-center">
          <span className="text-slate-400">Defense:</span>
          <span className="text-white font-mono font-bold">{defenseStat}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-slate-400">Resilience:</span>
          <span className="text-white font-mono font-bold">{resilienceStat}</span>
        </div>

        <div className="bg-slate-800 p-2 rounded space-y-1">
          <div className="flex justify-between text-slate-300">
            <span>Impact (Cards Flipped):</span>
            <span className="font-bold">{details.impact}</span>
          </div>
          <div className="flex justify-between text-orange-300 border-t border-slate-700 pt-1 mt-1">
            <span>Consequences:</span>
            <span className="font-bold">
              {details.consequencesFromDefense > 0 ? details.consequencesFromDefense : '-'}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
