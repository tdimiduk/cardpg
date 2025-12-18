import React from 'react';
import { Rule } from '../../generated/types';
import { RichTextRenderer } from './RichTextRenderer';
import { InlineIcon } from './InlineIcon';

export const RuleRenderer = ({ rule }: { rule: Rule }) => {
  switch (rule.type) {
    case 'task': {
      const { name, check, time, cost, effect } = rule.data;
      return (
        <div className="text-[10px] text-slate-400 mb-1">
          <span className="font-bold text-slate-300">Task: {name}</span>
          {' ('}
          {check && (
            <>
              Check <InlineIcon color={check.attribute} /> {check.value}
            </>
          )}
          {time && (
            <>
              {check ? '; ' : ''}
              Time <RichTextRenderer content={time} />
            </>
          )}
          {cost && (
            <>
              {check || time ? '; ' : ''}
              Cost <RichTextRenderer content={cost} />
            </>
          )}
          {') -> '}
          <RichTextRenderer content={effect} />
        </div>
      );
    }
    case 'narrative':
      return (
        <div className="text-[10px] text-slate-400 mb-1">
          <RichTextRenderer content={rule.data} />
        </div>
      );
    case 'passive': {
      const { bonus, condition } = rule.data;
      return (
        <div className="text-[10px] text-slate-400 mb-1">
          <span className="font-bold text-slate-300">Passive:</span>{' '}
          {bonus.modifier !== 0 && (
            <>
              {bonus.modifier > 0 ? '+' : ''}
              {bonus.modifier} <InlineIcon color={bonus.source} />
            </>
          )}
          {condition && ` ${condition}`}
        </div>
      );
    }
    case 'trigger': {
      const { trigger, effect } = rule.data;
      return (
        <div className="text-[10px] text-slate-400 mb-1">
          <span className="italic">{trigger}</span>
          {' -> '}
          <RichTextRenderer content={effect} />
        </div>
      );
    }
    default:
      return null;
  }
};
