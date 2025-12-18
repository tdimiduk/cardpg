import React, { useState, useRef, useEffect } from 'react';
import { AlertTriangle, X, ChevronDown } from 'lucide-react';
import { ConsequenceCard } from '../../generated/types';
import { RuleRenderer } from '../Card/RuleRenderer';

interface ConsequenceListProps {
  consequences: (ConsequenceCard & { id: string })[];
  currentSeverity: number;
  onAddConsequence: (severity?: number) => void;
  onRemoveConsequence: (cardId: string) => void;
}

export const ConsequenceList: React.FC<ConsequenceListProps> = ({
  consequences,
  currentSeverity,
  onAddConsequence,
  onRemoveConsequence,
}) => {
  const [showDropdown, setShowDropdown] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Click outside handler
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setShowDropdown(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="p-4">
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs text-slate-500 font-bold uppercase flex items-center gap-1">
          <AlertTriangle size={12} /> Consequences
        </span>

        <div className="relative flex items-center" ref={dropdownRef}>
          <button
            onClick={() => onAddConsequence(undefined)}
            className="text-[10px] bg-slate-800 hover:bg-red-900 text-slate-400 hover:text-red-200 px-2 py-0.5 rounded-l border border-slate-700 border-r-0 transition-colors"
            title="Add Consequence (Auto Severity)"
          >
            + Add
          </button>
          <button
            onClick={() => setShowDropdown(!showDropdown)}
            className="text-[10px] bg-slate-800 hover:bg-slate-700 text-slate-400 px-1 py-0.5 rounded-r border border-slate-700 transition-colors flex items-center h-full"
          >
            <ChevronDown size={10} />
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
                <span className="text-[9px] text-slate-500 uppercase tracking-wider border border-slate-700 px-1 rounded">
                  Sev {c.severity}
                </span>
                <button
                  onClick={() => onRemoveConsequence(c.id)}
                  className="absolute top-1 right-1 text-slate-600 hover:text-slate-300 p-0.5 rounded transition-colors"
                  title="Remove Consequence"
                >
                  <X size={12} />
                </button>
              </div>
              {/* Effects */}
              {c.effects && c.effects.length > 0 && (
                <div className="mb-2 space-y-1">
                  {c.effects.map((effect, idx) => (
                    <div key={idx} className="text-[10px] text-slate-400">
                      {effect}
                    </div>
                  ))}
                </div>
              )}

              {/* Passive */}
              {c.passive && (
                <div className="mb-2 text-[10px] text-slate-400">
                  <span className="font-bold text-slate-300">Passive:</span> {c.passive}
                </div>
              )}

              {/* Rules */}
              {c.rules && c.rules.length > 0 && (
                <div className="space-y-1">
                  {c.rules.map((rule, idx) => (
                    <RuleRenderer key={idx} rule={rule} />
                  ))}
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};
