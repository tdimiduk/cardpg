import React, { useState } from 'react';
import { Shield, Plus, ChevronDown } from 'lucide-react';
import { DefenseDetails, ResourceType } from '../../generated/types';

interface DefenseStatsProps {
  details: DefenseDetails;
  defenseStat: number;
  resilienceStat: number;
  onDefend: () => void;
  // onClearDefense removed from here, handled by parent/modal
  // hasFlippedCards removed, handled by parent/modal
  targetStrength?: number;
  attackColor?: ResourceType;
  onAddConsequence: (severity?: number) => void;
}

export const DefenseStats: React.FC<DefenseStatsProps> = ({
  details,
  defenseStat,
  resilienceStat,
  onDefend,
  targetStrength,
  attackColor = 'red',
  onAddConsequence,
}) => {
  const [showDropdown, setShowDropdown] = useState(false);

  const getColorClass = (color?: ResourceType) => {
    switch (color) {
      case 'red':
        return 'text-red-400';
      case 'blue':
        return 'text-blue-400';
      case 'yellow':
        return 'text-yellow-400';
      default:
        return 'text-white';
    }
  };

  return (
    <div className="p-4 bg-slate-900/50 rounded-lg">
      {/* Target & Current Defense */}
      <div className="flex items-center justify-between mb-6">
        <div className="text-center">
          <div className="text-[10px] text-slate-500 uppercase tracking-widest mb-1">Target</div>
          <div className={`text-4xl font-black ${getColorClass(attackColor)}`}>
            {targetStrength !== undefined ? targetStrength : '-'}
          </div>
        </div>

        <div className="text-slate-600 font-bold text-xl">VS</div>

        <div className="text-center">
          <div className="text-[10px] text-slate-500 uppercase tracking-widest mb-1">Total</div>
          <div className="grid grid-cols-3 gap-1">
            <div className="bg-red-950/40 p-1 rounded border border-red-900/30 min-w-[32px]">
              <div className="text-xs font-bold text-red-200">{details.values.red}</div>
            </div>
            <div className="bg-yellow-950/40 p-1 rounded border border-yellow-900/30 min-w-[32px]">
              <div className="text-xs font-bold text-yellow-200">{details.values.yellow}</div>
            </div>
            <div className="bg-blue-950/40 p-1 rounded border border-blue-900/30 min-w-[32px]">
              <div className="text-xs font-bold text-blue-200">{details.values.blue}</div>
            </div>
          </div>
        </div>
      </div>

      <button
        onClick={onDefend}
        className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-bold py-3 rounded shadow-lg shadow-indigo-900/20 flex items-center justify-center gap-2 transition-all transform active:scale-95 mb-6"
      >
        <Shield size={18} className="fill-current" />
        Flip for Defense
      </button>

      {/* Stats Row */}
      <div className="grid grid-cols-2 gap-4 mb-4 pb-4 border-b border-slate-700/50">
        <div className="flex justify-between items-center bg-slate-950/50 p-2 rounded">
          <span className="text-xs text-slate-400 font-bold uppercase">Defense</span>
          <span className="text-white font-mono font-bold text-lg">{defenseStat}</span>
        </div>
        <div className="flex justify-between items-center bg-slate-950/50 p-2 rounded">
          <span className="text-xs text-slate-400 font-bold uppercase">Resilience</span>
          <span className="text-white font-mono font-bold text-lg">{resilienceStat}</span>
        </div>
      </div>

      {/* Impact & Consequences */}
      <div className="space-y-3">
        <div className="bg-slate-950 p-3 rounded border border-slate-800">
          <div className="flex justify-between items-center mb-2">
            <span className="text-slate-400 text-sm">Impact (Cards Flipped)</span>
            <span className="text-white font-bold font-mono pl-4">{details.impact}</span>
          </div>
          <div className="flex justify-between items-center text-orange-300">
            <span className="text-sm">Consequences</span>
            <span className="font-bold">
              {details.consequencesFromDefense > 0 ? details.consequencesFromDefense : '-'}
            </span>
          </div>
        </div>

        {/* Add Consequence UI */}
        <div className="bg-slate-950 p-3 rounded border border-slate-800">
          <div className="text-xs font-bold text-slate-500 uppercase mb-2 flex items-center gap-1">
            <span className="text-orange-500">⚠</span> Add Consequence
          </div>

          {/* Split Button: Auto & Manual */}
          <div className="relative flex items-center">
            <button
              onClick={() => onAddConsequence(undefined)}
              className="flex-1 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold py-2 rounded-l border border-slate-700 border-r-0 flex items-center justify-center gap-2 transition-colors"
              title={`Add Consequence (Sev ${details.nextSeverity || '?'})`}
            >
              <Plus size={14} />
              Add Consequence (Sev {details.nextSeverity})
            </button>

            <div className="relative">
              <button
                onClick={() => setShowDropdown(!showDropdown)}
                className="bg-slate-800 hover:bg-slate-700 text-slate-400 px-2 py-2 rounded-r border border-slate-700 transition-colors flex items-center justify-center h-full"
              >
                <ChevronDown size={14} />
              </button>

              {showDropdown && (
                <div className="absolute top-full right-0 mt-1 w-32 bg-slate-800 border border-slate-700 rounded shadow-lg z-50 overflow-hidden">
                  <div className="text-[9px] uppercase tracking-wider text-slate-500 px-2 py-1 bg-slate-900/50">
                    Specific Severity
                  </div>
                  {[1, 2, 3].map((sev) => (
                    <button
                      key={sev}
                      onClick={() => {
                        onAddConsequence(sev);
                        setShowDropdown(false);
                      }}
                      className="w-full text-left px-3 py-1.5 text-xs text-slate-300 hover:bg-slate-700 hover:text-white transition-colors"
                    >
                      Severity {sev}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Click outside to close dropdown handled by just using local state for now, 
                could improve with a hook or proper overlay if needed, 
                but for a small sidebar modal this is usually fine or user clicks toggle again. 
                Added a simple overlay for better UX. */}
          {showDropdown && (
            <div
              className="fixed inset-0 z-40 bg-transparent"
              onClick={() => setShowDropdown(false)}
            />
          )}
        </div>
      </div>
    </div>
  );
};
