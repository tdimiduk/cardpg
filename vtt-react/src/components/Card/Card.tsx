import React from 'react';
import { Card, CoreCard, TableCard } from '../../types';
import { Square, Circle, Diamond, Shield, Heart } from 'lucide-react';
import { InlineIcon } from './InlineIcon';
import { RichTextRenderer } from './RichTextRenderer';

interface CardProps {
  card: Card;
  selected?: boolean;
  onClick?: () => void;
  scale?: number;
}

const BaseCard: React.FC<{
  card: Card;
  children: React.ReactNode;
  selected?: boolean;
  onClick?: () => void;
  scale?: number;
}> = ({ card, children, selected, onClick, scale = 1 }) => {
  return (
    <div
      onClick={onClick}
      className={`
        relative bg-slate-200 text-slate-900 rounded-lg shadow-xl overflow-hidden select-none
        transition-all duration-200 border-2 cursor-pointer z-0
        ${selected ? 'border-yellow-500 -translate-y-4 z-10 ring-2 ring-yellow-300' : 'border-slate-400 hover:-translate-y-2'}
      `}
      style={{
        width: `${160 * scale}px`,
        height: `${220 * scale}px`,
        minWidth: `${160 * scale}px`,
      }}
    >
      {/* Cost Badge (Core Only) */}
      {card.type === 'coreCard' && card.cost !== undefined && card.cost !== null && (
        <div className="absolute top-1 right-1 bg-slate-900 text-white rounded border border-slate-600 z-20 flex flex-col items-center justify-center w-7 h-8 shadow-sm">
          <span className="text-[10px] text-slate-400 leading-none pt-0.5">Cost</span>
          <span className="font-bold text-sm leading-none pb-0.5">{card.cost}</span>
        </div>
      )}

      <div className="flex h-full">{children}</div>
    </div>
  );
};

const CoreCardView: React.FC<{ card: CoreCard }> = ({ card }) => {
  return (
    <>
      {/* Left Sidebar: Stats */}
      <div className="w-1/4 h-full bg-slate-100 border-r border-slate-300 flex flex-col items-center pt-2 gap-2 shrink-0">
        <div className="flex flex-col items-center group">
          <div className="relative flex items-center justify-center">
            <Square size={24} className="text-red-600 fill-white" strokeWidth={2.5} />
            <span className="absolute text-xs font-bold text-red-900">{card.stats.red}</span>
          </div>
        </div>
        <div className="flex flex-col items-center group">
          <div className="relative flex items-center justify-center">
            <Circle size={24} className="text-yellow-500 fill-white" strokeWidth={2.5} />
            <span className="absolute text-xs font-bold text-yellow-900">{card.stats.yellow}</span>
          </div>
        </div>
        <div className="flex flex-col items-center group">
          <div className="relative flex items-center justify-center">
            <Diamond size={24} className="text-blue-600 fill-white" strokeWidth={2.5} />
            <span className="absolute text-xs font-bold text-blue-900">{card.stats.blue}</span>
          </div>
        </div>
      </div>

      {/* Right Content */}
      <div className={`flex-1 p-2 flex flex-col ${card.cost !== undefined ? 'pt-6' : 'pt-2'}`}>
        <div className="h-20 bg-slate-300 mb-2 rounded border border-slate-400 overflow-hidden relative shrink-0">
          <div className="w-full h-full opacity-20 bg-gradient-to-br from-slate-400 to-slate-600"></div>
          <div className="absolute inset-0 flex items-center justify-center text-center p-1">
            <span className="text-xs font-serif font-bold leading-tight">{card.name}</span>
          </div>
        </div>

        <div className="flex-1 bg-white rounded p-1.5 border border-slate-200 shadow-inner overflow-hidden flex flex-col gap-1">
          {/* Flavor text removed for space constraints */}

          {card.rules?.map((rule, idx) => (
            <div
              key={idx}
              className="text-[9px] leading-tight border-t border-slate-100 pt-1 first:border-t-0 first:pt-0"
            >
              {rule.type === 'attack' && (
                <div>
                  <div className="flex items-center gap-1">
                    <span className="font-bold uppercase">Attack</span>{' '}
                    <InlineIcon color={rule.data.power.source} />
                    {rule.data.power.modifier > 0
                      ? `+${rule.data.power.modifier}`
                      : rule.data.power.modifier}
                  </div>
                  {rule.data.effect && (
                    <div className="font-serif italic pl-1 mt-0.5">
                      <RichTextRenderer content={rule.data.effect} />
                    </div>
                  )}
                </div>
              )}
              {rule.type === 'general' && (
                <div className="leading-tight">
                  <span className="font-bold uppercase">Action: {rule.data.name}</span>
                  {(rule.data.cost || rule.data.difficulty) && (
                    <span className="font-bold text-slate-700">
                      {' ('}
                      {rule.data.difficulty && (
                        <>
                          Check <InlineIcon color={rule.data.difficulty.attribute} />{' '}
                          {rule.data.difficulty.value}
                        </>
                      )}
                      {rule.data.difficulty && rule.data.cost && '; '}
                      {rule.data.cost && <RichTextRenderer content={rule.data.cost} />}
                      {')'}
                    </span>
                  )}
                  {' -> '}
                  <span className="font-serif italic">
                    <RichTextRenderer content={rule.data.effect} />
                  </span>
                </div>
              )}
              {rule.type === 'task' && (
                <div className="leading-tight">
                  <span className="font-bold uppercase">Task: {rule.data.name}</span>
                  {(rule.data.check || rule.data.time || rule.data.cost) && (
                    <span className="font-bold text-slate-700">
                      {' ('}
                      {rule.data.check && (
                        <>
                          Check <InlineIcon color={rule.data.check.attribute} />{' '}
                          {rule.data.check.value}
                        </>
                      )}
                      {rule.data.check && (rule.data.time || rule.data.cost) && '; '}
                      {rule.data.time && (
                        <>
                          Time <RichTextRenderer content={rule.data.time} />
                        </>
                      )}
                      {rule.data.time && rule.data.cost && '; '}
                      {rule.data.cost && <RichTextRenderer content={rule.data.cost} />}
                      {')'}
                    </span>
                  )}
                  {' -> '}
                  <span className="font-serif italic">
                    <RichTextRenderer content={rule.data.effect} />
                  </span>
                </div>
              )}
              {rule.type === 'narrative' && (
                <div className="font-serif italic">
                  <RichTextRenderer content={rule.data} />
                </div>
              )}
              {/* Add other rule types as needed */}
            </div>
          ))}
        </div>
      </div>
    </>
  );
};

const TableCardView: React.FC<{ card: TableCard }> = ({ card }) => {
  return (
    <div className="w-full h-full p-2 flex flex-col">
      <div className="h-24 bg-slate-300 mb-2 rounded border border-slate-400 overflow-hidden relative shrink-0">
        <div className="w-full h-full opacity-20 bg-gradient-to-br from-amber-700 to-slate-600"></div>
        <div className="absolute inset-0 flex items-center justify-center text-center p-1">
          <span className="text-sm font-serif font-bold leading-tight">{card.name}</span>
        </div>
      </div>

      <div className="flex-1 bg-amber-50 rounded p-2 border border-amber-200 shadow-inner overflow-hidden flex flex-col gap-2">
        {card.flavor && (
          <p className="text-xs font-serif text-slate-800 italic text-center border-b border-amber-200 pb-2">
            <RichTextRenderer content={card.flavor} />
          </p>
        )}

        <div className="flex justify-around text-[10px] font-bold text-slate-700">
          {card.defense !== undefined && (
            <div className="flex items-center gap-1">
              <Shield size={12} /> Def: {card.defense}
            </div>
          )}
          {/* Check for resilience existence since it is optional on TableCard union members */}
          {'resilience' in card && card.resilience !== undefined && (
            <div className="flex items-center gap-1">
              <Heart size={12} /> Res: {card.resilience}
            </div>
          )}
        </div>

        {card.traits && card.traits.length > 0 && (
          <div className="text-[10px]">
            <span className="font-bold">Traits:</span> {card.traits.join(', ')}
          </div>
        )}

        {card.passive && (
          <div className="text-[10px] italic bg-white/50 p-1 rounded">{card.passive}</div>
        )}
      </div>
    </div>
  );
};

export const CardComponent: React.FC<CardProps> = (props) => {
  return (
    <BaseCard {...props}>
      {props.card.type === 'coreCard' ? (
        <CoreCardView card={props.card} />
      ) : (
        <TableCardView card={props.card} />
      )}
    </BaseCard>
  );
};
