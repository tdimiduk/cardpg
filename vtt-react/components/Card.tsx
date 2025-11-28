
import React from 'react';
import { CoreCard, ResourceType, Inline } from '../types';
import { Square, Circle, Diamond } from 'lucide-react';

interface CardProps {
  card: CoreCard;
  selected?: boolean;
  onClick?: () => void;
  scale?: number;
}

// Helper to render small inline icons
const InlineIcon: React.FC<{ color: ResourceType }> = ({ color }) => {
  switch (color) {
    case 'Red': return <Square size={12} className="inline text-red-600 fill-white border-red-600 align-middle mx-0.5" strokeWidth={3} />;
    case 'Yellow': return <Circle size={12} className="inline text-yellow-500 fill-white border-yellow-500 align-middle mx-0.5" strokeWidth={3} />;
    case 'Blue': return <Diamond size={12} className="inline text-blue-600 fill-white border-blue-600 align-middle mx-0.5" strokeWidth={3} />;
  }
  return null;
};

const RichTextRenderer = ({ content }: { content: Inline[] }) => (
  <>
    {content.map((part, index) => {
      if (part.type === 'icon') return <InlineIcon key={index} color={part.color} />;
      if (part.type === 'textRun') return <span key={index} className={part.style === 'Bold' ? 'font-bold' : part.style === 'Italic' ? 'italic' : ''}>{part.content}</span>;
      if (part.type === 'break') return <br key={index} />;
      return null;
    })}
  </>
);

export const CardComponent: React.FC<CardProps> = ({ card, selected, onClick, scale = 1 }) => {
  // Determine if we should show stats. 
  // If all are 0, it might be an Item/Character card or Status.
  // We check if it has stats > 0 or if it's NOT a status/wound/item (which might have 0 stats but we show them differently?)
  // Actually, let's just show stats if any is > 0 or if it's a character.
  // For now, consistent with old logic: show if defined. In new schema, they are always defined (0).
  // So we show them always unless it's a pure flavor card?
  // Let's show them always for now.
  const showStats = true; 

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
      {/* Cost / Play Count Badge - Only render if cost is defined */}
      {card.cost !== undefined && card.cost !== null && (
        <div className="absolute top-1 right-1 bg-slate-900 text-white rounded border border-slate-600 z-20 flex flex-col items-center justify-center w-7 h-8 shadow-sm">
            <span className="text-[10px] text-slate-400 leading-none pt-0.5">Cost</span>
            <span className="font-bold text-sm leading-none pb-0.5">{card.cost}</span>
        </div>
      )}

      <div className="flex h-full">
        {/* Left Sidebar: Stats */}
        {showStats && (
          <div className="w-1/4 h-full bg-slate-100 border-r border-slate-300 flex flex-col items-center pt-2 gap-2 shrink-0">
            
            {/* Red / Force */}
            <div className="flex flex-col items-center group">
              <div className="relative flex items-center justify-center">
                  <Square size={24} className="text-red-600 fill-white" strokeWidth={2.5} />
                  <span className="absolute text-xs font-bold text-red-900">{card.stats.red}</span>
              </div>
            </div>

            {/* Yellow / Speed */}
            <div className="flex flex-col items-center group">
              <div className="relative flex items-center justify-center">
                  <Circle size={24} className="text-yellow-500 fill-white" strokeWidth={2.5} />
                  <span className="absolute text-xs font-bold text-yellow-900">{card.stats.yellow}</span>
              </div>
            </div>

            {/* Blue / Intellect */}
            <div className="flex flex-col items-center group">
              <div className="relative flex items-center justify-center">
                  <Diamond size={24} className="text-blue-600 fill-white" strokeWidth={2.5} />
                  <span className="absolute text-xs font-bold text-blue-900">{card.stats.blue}</span>
              </div>
            </div>

          </div>
        )}

        {/* Right Content */}
        <div className={`flex-1 p-2 flex flex-col ${card.cost !== undefined ? 'pt-6' : 'pt-2'}`}> 
            <div className="h-20 bg-slate-300 mb-2 rounded border border-slate-400 overflow-hidden relative shrink-0">
                {/* Placeholder Art */}
                <div className="w-full h-full opacity-20 bg-gradient-to-br from-slate-400 to-slate-600"></div>
                <div className="absolute inset-0 flex items-center justify-center text-center p-1">
                    <span className="text-xs font-serif font-bold leading-tight">{card.name}</span>
                </div>
            </div>
            
            <div className="flex-1 bg-white rounded p-1.5 border border-slate-200 shadow-inner overflow-hidden flex flex-col gap-1">
                {/* Flavor Text */}
                {card.flavor && (
                  <p className="text-[10px] leading-tight font-serif text-slate-800 italic">
                    <RichTextRenderer content={card.flavor} />
                  </p>
                )}

                {/* Rules */}
                {card.rules.map((rule, idx) => (
                   <div key={idx} className="text-[9px] leading-tight border-t border-slate-100 pt-1">
                      {rule.type === 'attack' && (
                        <div>
                          <span className="font-bold uppercase">Attack</span> <InlineIcon color={rule.data.power.source} /> 
                          {rule.data.power.modifier > 0 ? `+${rule.data.power.modifier}` : rule.data.power.modifier}
                        </div>
                      )}
                      {rule.type === 'general' && (
                         <div>
                            <span className="font-bold uppercase mr-1">Effect</span>
                            <span className="font-serif italic">
                                <RichTextRenderer content={rule.data.effect} />
                            </span>
                         </div>
                      )}
                      {/* Add other rule types as needed */}
                   </div>
                ))}
            </div>
            
            {card.tags.includes('fatigue') && (
                <div className="mt-1 text-[8px] bg-red-100 text-red-800 text-center rounded border border-red-200 font-bold">FATIGUE</div>
            )}
        </div>
      </div>
    </div>
  );
};