import React from 'react';
import { Layers, X } from 'lucide-react';
import { CoreCard } from '../../types';
import { CardComponent } from '../Card/Card';

interface DeckViewerModalProps {
  isOpen: boolean;
  onClose: () => void;
  cards: CoreCard[];
}

export const DeckViewerModal: React.FC<DeckViewerModalProps> = ({
  isOpen,
  onClose,
  cards,
}) => {
  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-8 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="bg-slate-900 border border-slate-700 rounded-xl shadow-2xl w-full max-w-5xl h-full max-h-[90vh] flex flex-col overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="p-4 border-b border-slate-700 flex justify-between items-center bg-slate-950">
          <h2 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Layers className="text-indigo-500" /> Deck Viewer ({cards.length}{' '}
            cards)
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-800 rounded-full text-slate-400 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>
        <div className="flex-1 overflow-y-auto p-6 bg-slate-900/50">
          <div className="flex flex-wrap gap-4 justify-center">
            {cards.map((card, idx) => (
              <div key={`${card.id}-${idx}`} className="scale-90 origin-top">
                <CardComponent card={card} />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
