import React from 'react';
import { Layers, X } from 'lucide-react';
import { CardComponent, Card } from '../Card/Card';

interface StackViewerModalProps {
  isOpen: boolean;
  onClose: () => void;
  cards: (Card & { id: string })[];
  title: string;
}

export const StackViewerModal: React.FC<StackViewerModalProps> = ({
  isOpen,
  onClose,
  cards,
  title,
}) => {
  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 bg-black/20 flex items-center justify-center p-8 transition-colors"
      onClick={onClose}
    >
      <div
        className="bg-slate-900 border border-slate-700 rounded-xl shadow-2xl w-auto max-w-[95vw] h-auto max-h-[90vh] flex flex-col overflow-hidden animate-pop-in"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="p-4 border-b border-slate-700 flex justify-between items-center bg-slate-950">
          <h2 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Layers className="text-indigo-500" /> {title} ({cards.length} cards)
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-800 rounded-full text-slate-400 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>
        <div className="flex-1 overflow-y-auto p-4 bg-slate-900/50 min-w-[320px] min-h-[200px] flex items-center justify-center">
          <div className="flex flex-wrap gap-2 justify-center">
            {cards.map((card, idx) => {
              // Dynamic scale: If few cards, decent size. If many, shrink to fit.
              // Assuming normal card is ~200-300px wide.
              // Logic: Default 0.9. If > 4 cards, 0.75. If > 8 cards, 0.6.
              const scaleClass =
                cards.length > 8 ? 'scale-60' : cards.length > 4 ? 'scale-75' : 'scale-90';
              // Adjust margin to compensate for scale shrinking space
              const marginClass = cards.length > 8 ? '-m-8' : cards.length > 4 ? '-m-4' : '-m-2';

              return (
                <div
                  key={`${card.id}-${idx}`}
                  className={`${scaleClass} ${marginClass} origin-top transition-all duration-300`}
                >
                  <CardComponent card={card} />
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};
