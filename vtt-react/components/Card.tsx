import React from 'react';
import { Card, CardColor } from '../types';
import { Square, Circle, Diamond } from 'lucide-react';

interface CardProps {
  card: Card;
  selected?: boolean;
  onClick?: () => void;
  scale?: number;
}

// Helper to render small inline icons
const InlineIcon = ({ color }: { color: CardColor }) => {
  switch (color) {
    case 'red': return <Square size={12} className="inline text-red-600 fill-white border-red-600 align-middle mx-0.5" strokeWidth={3} />;
    case 'yellow': return <Circle size={12} className="inline text-yellow-500 fill-white border-yellow-500 align-middle mx-0.5" strokeWidth={3} />;
    case 'blue': return <Diamond size={12} className="inline text-blue-600 fill-white border-blue-600 align-middle mx-0.5" strokeWidth={3} />;
  }
};

export const CardComponent: React.FC<CardProps> = ({ card, selected, onClick, scale = 1 }) => {
  // Determine if we should show stats. 
  // If all are undefined, it's an Item/Character card.
  // If they are 0, they are shown (Status/Injury).
  const showStats = card.red !== undefined || card.yellow !== undefined || card.blue !== undefined;

  return (
    <div 
      onClick={onClick}
      className={`
        relative bg-slate-200 text-slate-900 rounded-lg shadow-xl overflow-hidden select-none
        transition-all duration-200 border-2 cursor-pointer
        ${selected ? 'border-yellow-500 -translate-y-4 z-10 ring-2 ring-yellow-300' : 'border-slate-400 hover:-translate-y-2'}
      `}
      style={{
        width: `${160 * scale}px`,
        height: `${220 * scale}px`,
        minWidth: `${160 * scale}px`,
      }}
    >
      {/* Cost / Play Count Badge - Only render if playCount is defined */}
      {card.playCount !== undefined && (
        <div className="absolute top-1 right-1 bg-slate-900 text-white rounded border border-slate-600 z-20 flex flex-col items-center justify-center w-7 h-8 shadow-sm">
            <span className="text-[10px] text-slate-400 leading-none pt-0.5">Cost</span>
            <span className="font-bold text-sm leading-none pb-0.5">{card.playCount}</span>
        </div>
      )}

      <div className="flex h-full">
        {/* Left Sidebar: Stats (Conditional) */}
        {showStats && (
          <div className="w-1/4 h-full bg-slate-100 border-r border-slate-300 flex flex-col items-center pt-2 gap-2 shrink-0">
            
            {/* Red / Force */}
            <div className="flex flex-col items-center group">
              <div className="relative flex items-center justify-center">
                  <Square size={24} className="text-red-600 fill-white" strokeWidth={2.5} />
                  <span className="absolute text-xs font-bold text-red-900">{card.red ?? 0}</span>
              </div>
            </div>

            {/* Yellow / Speed */}
            <div className="flex flex-col items-center group">
              <div className="relative flex items-center justify-center">
                  <Circle size={24} className="text-yellow-500 fill-white" strokeWidth={2.5} />
                  <span className="absolute text-xs font-bold text-yellow-900">{card.yellow ?? 0}</span>
              </div>
            </div>

            {/* Blue / Intellect */}
            <div className="flex flex-col items-center group">
              <div className="relative flex items-center justify-center">
                  <Diamond size={24} className="text-blue-600 fill-white" strokeWidth={2.5} />
                  <span className="absolute text-xs font-bold text-blue-900">{card.blue ?? 0}</span>
              </div>
            </div>

          </div>
        )}

        {/* Right Content */}
        <div className={`flex-1 p-2 flex flex-col ${card.playCount !== undefined ? 'pt-6' : 'pt-2'}`}> 
            <div className="h-20 bg-slate-300 mb-2 rounded border border-slate-400 overflow-hidden relative shrink-0">
                {/* Placeholder Art */}
                <div className="w-full h-full opacity-20 bg-gradient-to-br from-slate-400 to-slate-600"></div>
                <div className="absolute inset-0 flex items-center justify-center text-center p-1">
                    <span className="text-xs font-serif font-bold leading-tight">{card.name}</span>
                </div>
            </div>
            
            <div className="flex-1 bg-white rounded p-1.5 border border-slate-200 shadow-inner overflow-hidden">
                <p className="text-[10px] leading-tight font-serif text-slate-800">
                  {card.text.map((part, index) => (
                    part.type === 'icon' 
                      ? <InlineIcon key={index} color={part.color} /> 
                      : <span key={index}>{part.content}</span>
                  ))}
                </p>
                {card.actionDefinition && (
                    <div className="mt-1 pt-1 border-t border-slate-100 text-[8px] text-slate-500 flex flex-wrap gap-1">
                        <span className="uppercase font-bold tracking-wider">{card.actionDefinition.type}</span>
                        {card.actionDefinition.modifier !== 0 && (
                            <span className={card.actionDefinition.modifier > 0 ? 'text-green-600' : 'text-red-600'}>
                                ({card.actionDefinition.modifier > 0 ? '+' : ''}{card.actionDefinition.modifier})
                            </span>
                        )}
                    </div>
                )}
            </div>
            
            {card.type === 'fatigue' && (
                <div className="mt-1 text-[8px] bg-red-100 text-red-800 text-center rounded border border-red-200 font-bold">FATIGUE</div>
            )}
        </div>
      </div>
    </div>
  );
};