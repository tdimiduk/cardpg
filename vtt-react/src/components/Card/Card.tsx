import React from 'react';
import {
  CoreCard,
  ConsequenceCard,
  Rule,
  TableCard, // The Generated Wrapper Union: ITCItem | ITCNature...
} from '../../generated/types';
import { Square, Circle, Diamond, Shield, Heart, Skull, AlertCircle } from 'lucide-react';
import { InlineIcon } from './InlineIcon';
import { RichTextRenderer } from './RichTextRenderer';

// Updated types to reflect wrapper usage
export type AnyCard = CoreCard | TableCard | ConsequenceCard;
export type Card = AnyCard; // Backward compatibility alias

export interface CardProps {
  card: AnyCard;
  selected?: boolean;
  onClick?: () => void;
  scale?: number;
  className?: string;
}

const BaseCard: React.FC<{
  card: AnyCard;
  children: React.ReactNode;
  selected?: boolean;
  onClick?: () => void;
  scale?: number;
  className?: string;
}> = ({ card, children, selected, onClick, scale = 1, className = '' }) => {
  // Safe helper to check card type for CoreCard styling
  const isCore = 'type' in card && card.type === 'coreCard';
  const hasCost = isCore && (card as CoreCard).cost !== undefined;

  return (
    <div
      data-testid="card"
      onClick={onClick}
      className={`
        relative bg-slate-200 text-slate-900 rounded-lg shadow-xl overflow-hidden select-none
        transition-all duration-200 border-2 cursor-pointer z-0 flex
        ${selected ? 'border-yellow-500 z-10 ring-2 ring-yellow-300' : 'border-slate-400 hover:-translate-y-2'}
        ${className}
      `}
      style={{
        width: `${160 * scale}px`,
        height: `${220 * scale}px`,
        minWidth: `${160 * scale}px`,
      }}
    >
      {/* Cost Badge (Core Only) */}
      {isCore && hasCost && (
        <div className="absolute top-1 right-1 bg-slate-900 text-white rounded border border-slate-600 z-20 flex flex-col items-center justify-center w-7 h-8 shadow-sm">
          <span className="text-[10px] text-slate-400 leading-none pt-0.5">Cost</span>
          <span className="font-bold text-sm leading-none pb-0.5">{(card as CoreCard).cost}</span>
        </div>
      )}

      {children}
    </div>
  );
};

const RuleList: React.FC<{ rules: Rule[] }> = ({ rules }) => {
  return (
    <div className="flex-1 overflow-hidden flex flex-col gap-1">
      {rules.map((rule, idx) => (
        <div
          key={idx}
          className="text-[9px] leading-tight border-t border-slate-100 pt-1 first:border-t-0 first:pt-0"
        >
          {rule.type === 'attack' && (
            <>
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
            </>
          )}
          {rule.type === 'general' && (
            <>
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
            </>
          )}
          {rule.type === 'task' && (
            <>
              <span className="font-bold uppercase">Task: {rule.data.name}</span>
              {(rule.data.check || rule.data.time || rule.data.cost) && (
                <span className="font-bold text-slate-700">
                  {' ('}
                  {rule.data.check && (
                    <>
                      Check <InlineIcon color={rule.data.check.attribute} /> {rule.data.check.value}
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
            </>
          )}
          {rule.type === 'narrative' && (
            <div className="font-serif italic">
              <RichTextRenderer content={rule.data} />
            </div>
          )}
        </div>
      ))}
    </div>
  );
};

export const CoreCardView: React.FC<{ card: CoreCard }> = ({ card }) => {
  return (
    <>
      <div className="w-1/4 h-full bg-slate-100 border-r border-slate-300 flex flex-col items-center pt-2 gap-3 shrink-0">
        <div className="relative flex items-center justify-center group">
          <Square size={24} className="text-red-600 fill-white" strokeWidth={2.5} />
          <span className="absolute text-xs font-bold text-red-900">{card.stats.red}</span>
        </div>
        <div className="relative flex items-center justify-center group">
          <Circle size={24} className="text-yellow-500 fill-white" strokeWidth={2.5} />
          <span className="absolute text-xs font-bold text-yellow-900">{card.stats.yellow}</span>
        </div>
        <div className="relative flex items-center justify-center group">
          <Diamond size={24} className="text-blue-600 fill-white" strokeWidth={2.5} />
          <span className="absolute text-xs font-bold text-blue-900">{card.stats.blue}</span>
        </div>
      </div>

      <div className={`flex-1 p-2 flex flex-col ${card.cost !== undefined ? 'pt-6' : 'pt-2'}`}>
        <div className="h-20 bg-slate-300 mb-2 rounded border border-slate-400 overflow-hidden relative shrink-0 flex items-center justify-center text-center p-1">
          <div className="absolute inset-0 opacity-20 bg-gradient-to-br from-slate-400 to-slate-600 z-0"></div>
          <span className="text-xs font-serif font-bold leading-tight z-10">{card.name}</span>
        </div>

        <div className="flex-1 bg-white rounded p-1.5 border border-slate-200 shadow-inner overflow-hidden flex flex-col gap-1">
          {card.rules && <RuleList rules={card.rules} />}
        </div>
      </div>
    </>
  );
};

// --- Consequence View ---

export const ConsequenceCardView: React.FC<{ card: ConsequenceCard }> = ({ card }) => {
  return (
    <div className="w-full h-full p-2 flex flex-col">
      <div
        className={`h-24 bg-slate-300 mb-2 rounded border border-slate-400 overflow-hidden relative shrink-0 flex items-center justify-center text-center p-1`}
      >
        {/* Ominous Red Header */}
        <div
          className={`absolute inset-0 opacity-20 bg-gradient-to-br from-red-900 to-slate-800 z-0`}
        ></div>
        <div className="z-10 flex flex-col items-center">
          <span className="text-sm font-serif font-bold leading-tight">{card.name}</span>
          <span className="text-[10px] bg-red-800 text-white px-2 py-0.5 rounded-full mt-1 flex items-center gap-1">
            <AlertCircle size={8} /> Severity {card.severity}
          </span>
        </div>
      </div>

      <div
        className={`flex-1 bg-red-50 border-red-200 rounded p-2 border shadow-inner overflow-hidden flex flex-col gap-2`}
      >
        {/* Effects */}
        {'effects' in card && card.effects && (
          <div className="flex flex-col gap-1 mt-1">
            {card.effects.map((effect: string, i: number) => (
              <div key={i} className="text-[10px] flex items-start gap-1">
                <Skull size={10} className="mt-0.5 text-red-800 shrink-0" />
                <span>{effect}</span>
              </div>
            ))}
          </div>
        )}

        {'rules' in card && card.rules && (
          <div className="mt-2 pt-2 border-t border-red-200">
            <RuleList rules={card.rules} />
          </div>
        )}

        {'passive' in card && card.passive && (
          <div className="text-[10px] italic bg-white/50 p-1 rounded border border-black/5">
            {card.passive}
          </div>
        )}
      </div>
    </div>
  );
};

// --- Table View (Dispatcher for Wrappers) ---

export const TableCardView: React.FC<{ card: TableCard }> = ({ card }) => {
  // Otherwise, render generic table view (Item, Nature, Talent)
  const data = card.data;

  const bgClass = 'bg-gradient-to-br from-amber-700 to-slate-600';
  const bodyBgClass = 'bg-amber-50 border-amber-200';

  return (
    <div className="w-full h-full p-2 flex flex-col">
      <div
        className={`h-24 bg-slate-300 mb-2 rounded border border-slate-400 overflow-hidden relative shrink-0 flex items-center justify-center text-center p-1`}
      >
        <div className={`absolute inset-0 opacity-20 ${bgClass} z-0`}></div>
        <div className="z-10 flex flex-col items-center">
          <span className="text-sm font-serif font-bold leading-tight">{data.name}</span>
        </div>
      </div>

      <div
        className={`flex-1 ${bodyBgClass} rounded p-2 border shadow-inner overflow-hidden flex flex-col gap-2`}
      >
        {'flavor' in data && data.flavor && (
          <p className="text-xs font-serif text-slate-800 italic text-center border-b border-black/10 pb-2">
            <RichTextRenderer content={data.flavor} />
          </p>
        )}

        <div className="flex justify-around text-[10px] font-bold text-slate-700">
          {'defense' in data && data.defense !== undefined && (
            <div className="flex items-center gap-1">
              <Shield size={12} /> Def: {data.defense}
            </div>
          )}
          {'resilience' in data && data.resilience !== undefined && (
            <div className="flex items-center gap-1">
              <Heart size={12} /> Res: {data.resilience}
            </div>
          )}
        </div>

        {'traits' in data && data.traits && data.traits.length > 0 && (
          <div className="text-[10px]">
            <span className="font-bold">Traits:</span> {data.traits.join(', ')}
          </div>
        )}

        {'passive' in data && data.passive && (
          <div className="text-[10px] italic bg-white/50 p-1 rounded border border-black/5">
            {data.passive}
          </div>
        )}
      </div>
    </div>
  );
};

// --- Component Wrappers (View + Shell) ---

export const CoreCardComponent: React.FC<CardProps & { card: CoreCard }> = (props) => (
  <BaseCard {...props}>
    <CoreCardView card={props.card} />
  </BaseCard>
);

export const ConsequenceCardComponent: React.FC<CardProps & { card: ConsequenceCard }> = (
  props,
) => (
  <BaseCard {...props}>
    <ConsequenceCardView card={props.card} />
  </BaseCard>
);

export const TableCardComponent: React.FC<CardProps & { card: TableCard }> = (props) => (
  <BaseCard {...props}>
    <TableCardView card={props.card} />
  </BaseCard>
);

// --- Main Dispatcher ---

export const CardView: React.FC<CardProps> = (props) => {
  const { card } = props;

  if (card.type === 'coreCard') {
    return <CoreCardComponent {...props} card={card} />;
  }

  if (card.type === 'consequenceCard') {
    return <ConsequenceCardComponent {...props} card={card} />;
  }

  if (card.type === 'tCItem' || card.type === 'tCNature' || card.type === 'tCTalent') {
    return <TableCardComponent {...props} card={card} />;
  }

  return null;
};

// Deprecated export name, aliased for backward compatibility
export const CardComponent = CardView;

// --- Lookup Components ---
