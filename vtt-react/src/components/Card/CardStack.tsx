import React from 'react';
import { CardView, AnyCard } from './Card';
import { Layers } from 'lucide-react';

export type StackLayoutMode = 'row' | 'grid' | 'fan' | 'stack' | 'list';

export interface CardStackProps {
  cards: (AnyCard & { id: string })[];
  mode?: StackLayoutMode;
  scale?: number;
  className?: string;
  onCardClick?: (card: AnyCard & { id: string }) => void;
  selectedIds?: Set<string>;
  emptyMessage?: React.ReactNode;
  // Optional override if we don't want to use standard CardView (e.g. for simple badges in list mode)
  renderCard?: (card: AnyCard & { id: string }, index: number) => React.ReactNode;
}

export const CardStack: React.FC<CardStackProps> = ({
  cards,
  mode = 'row',
  scale = 1,
  className = '',
  onCardClick,
  selectedIds,
  emptyMessage,
  renderCard,
}) => {
  if (cards.length === 0) {
    return (
      <div className={`flex items-center justify-center text-slate-500 italic ${className}`}>
        {emptyMessage || (
          <div className="flex flex-col items-center gap-2 opacity-50 p-4">
            <Layers size={24} />
            <span className="text-xs">No cards</span>
          </div>
        )}
      </div>
    );
  }

  // --- Render Helpers ---

  const defaultRender = (card: AnyCard & { id: string }, index: number, extraClass = '') => {
    if (renderCard) return renderCard(card, index);

    const isSelected = selectedIds?.has(card.id);
    return (
      <CardView
        card={card}
        scale={scale}
        selected={isSelected}
        onClick={onCardClick ? () => onCardClick(card) : undefined}
        className={extraClass}
      />
    );
  };

  // --- Layouts ---

  if (mode === 'grid') {
    return (
      <div className={`flex flex-wrap gap-4 justify-center ${className}`}>
        {cards.map((card, idx) => (
          <div key={card.id || idx} className="relative">
            {defaultRender(card, idx)}
          </div>
        ))}
      </div>
    );
  }

  if (mode === 'row') {
    return (
      <div className={`flex gap-2 overflow-x-auto custom-scrollbar p-2 ${className}`}>
        {cards.map((card, idx) => (
          <div key={card.id || idx} className="shrink-0">
            {defaultRender(card, idx)}
          </div>
        ))}
      </div>
    );
  }

  if (mode === 'fan') {
    return (
      <div
        className={`relative ${className}`}
        style={{ width: `${160 * scale}px`, height: `${220 * scale}px` }}
      >
        {cards.map((card, idx) => (
          <div
            key={card.id || idx}
            className="absolute top-0 left-0 shadow-xl transition-transform hover:z-50"
            style={{
              transform: `translate(${idx * 20}px, ${idx * 2}px) rotate(${idx * 2}deg)`,
              zIndex: idx,
            }}
          >
            {defaultRender(card, idx, 'hover:scale-110')}
          </div>
        ))}
      </div>
    );
  }

  if (mode === 'stack') {
    return (
      <div className={`flex -space-x-12 hover:-space-x-4 transition-all p-2 ${className}`}>
        {cards.map((card, idx) => (
          <div
            key={card.id || idx}
            className="relative transition-transform hover:-translate-y-4 hover:z-50"
            style={{ zIndex: idx }}
          >
            {defaultRender(card, idx)}
          </div>
        ))}
      </div>
    );
  }

  return null;
};
