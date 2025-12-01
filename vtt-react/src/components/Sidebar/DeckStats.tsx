import React from 'react';
import { RefreshCw, Layers } from 'lucide-react';
import { PlayerDeckState } from '../../types';

interface DeckStatsProps {
  deckState: PlayerDeckState;
  onDraw: (count: number) => void;
  onReshuffle: () => void;
  onViewDeck: () => void;
}

export const DeckStats: React.FC<DeckStatsProps> = ({
  deckState,
  onDraw,
  onReshuffle,
  onViewDeck,
}) => {
  return (
    <div className="p-4 border-b border-slate-800">
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">
          Deck & Resources
        </span>
        <button
          onClick={onReshuffle}
          className="flex items-center gap-1 text-[10px] bg-slate-800 hover:bg-blue-900 text-slate-400 hover:text-blue-200 px-2 py-1 rounded border border-slate-700 transition-colors"
          title="Shuffle Discard into Draw Pile"
        >
          <RefreshCw size={10} /> Reshuffle
        </button>
      </div>

      <div className="grid grid-cols-2 gap-2 mb-4">
        <div className="bg-slate-900 p-2 rounded border border-slate-800 flex flex-col items-center relative group">
          <span className="text-xs text-slate-500">Draw Pile</span>
          <span className="text-xl font-bold text-slate-200">{deckState.drawPile.length}</span>
          <button
            onClick={() => onDraw(1)}
            className="mt-1 w-full text-[10px] bg-slate-800 hover:bg-slate-700 py-1 rounded text-slate-300"
          >
            Draw 1
          </button>
          <button
            onClick={onViewDeck}
            className="absolute top-1 right-1 p-1 text-slate-600 hover:text-indigo-400 transition-opacity"
            title="View Deck"
          >
            <Layers size={12} />
          </button>
        </div>
        <div className="bg-slate-900 p-2 rounded border border-slate-800 flex flex-col items-center">
          <span className="text-xs text-slate-500">Discard</span>
          <span className="text-xl font-bold text-slate-200">
            {deckState.discardPile.length}
          </span>
          <span className="text-[8px] text-slate-600 mt-1 h-5"></span>
        </div>
      </div>
    </div>
  );
};
