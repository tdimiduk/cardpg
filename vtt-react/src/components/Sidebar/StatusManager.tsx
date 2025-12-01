import React from 'react';
import { Activity, Minus, Hand, ArrowUp, Archive, AlertOctagon } from 'lucide-react';

interface StatusManagerProps {
  onAddStatusCard: (type: 'fatigue' | 'wound', destination: 'discard' | 'hand' | 'draw') => void;
  onRemoveStatusCard: (type: 'fatigue' | 'wound') => void;
}

export const StatusManager: React.FC<StatusManagerProps> = ({
  onAddStatusCard,
  onRemoveStatusCard,
}) => {
  return (
    <div className="bg-slate-900/50 rounded border border-slate-800 p-2 mx-4 mb-4">
      <span className="text-[10px] text-slate-500 font-bold uppercase mb-2 block">
        Status Cards in Deck
      </span>

      {/* Fatigue Row */}
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs text-slate-300 flex items-center gap-1">
          <Activity size={12} className="text-red-400" /> Fatigue
        </span>
        <div className="flex gap-1">
          <button
            onClick={() => onRemoveStatusCard('fatigue')}
            className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-red-900/50 text-slate-400 hover:text-red-300 border border-slate-700"
            title="Remove 1 Fatigue from Game"
          >
            <Minus size={10} />
          </button>
          <button
            onClick={() => onAddStatusCard('fatigue', 'hand')}
            className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
            title="Add Fatigue to Hand"
          >
            <Hand size={10} />
          </button>
          <button
            onClick={() => onAddStatusCard('fatigue', 'draw')}
            className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
            title="Add Fatigue to Top of Deck"
          >
            <ArrowUp size={10} />
          </button>
          <button
            onClick={() => onAddStatusCard('fatigue', 'discard')}
            className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
            title="Add Fatigue to Discard"
          >
            <Archive size={10} />
          </button>
        </div>
      </div>

      {/* Injury Row */}
      <div className="flex items-center justify-between">
        <span className="text-xs text-slate-300 flex items-center gap-1">
          <AlertOctagon size={12} className="text-orange-400" /> Injury
        </span>
        <div className="flex gap-1">
          <button
            onClick={() => onRemoveStatusCard('wound')}
            className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-orange-900/50 text-slate-400 hover:text-orange-300 border border-slate-700"
            title="Remove 1 Injury from Game"
          >
            <Minus size={10} />
          </button>
          <button
            onClick={() => onAddStatusCard('wound', 'hand')}
            className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
            title="Add Injury to Hand"
          >
            <Hand size={10} />
          </button>
          <button
            onClick={() => onAddStatusCard('wound', 'draw')}
            className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
            title="Add Injury to Top of Deck"
          >
            <ArrowUp size={10} />
          </button>
          <button
            onClick={() => onAddStatusCard('wound', 'discard')}
            className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
            title="Add Injury to Discard"
          >
            <Archive size={10} />
          </button>
        </div>
      </div>
    </div>
  );
};
