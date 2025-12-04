import React from 'react';
import { Inline } from '../../types';
import { InlineIcon } from './InlineIcon';

export const RichTextRenderer = ({ content }: { content?: Inline[] | null }) => {
  if (!content) return null;

  return (
    <>
      {content.map((part, index) => {
        if (part.type === 'colorValue') {
          const { source, modifier, conditional } = part.value;
          if (modifier === 0 && !conditional) {
            return <InlineIcon key={index} color={source} />;
          }
          return (
            <span key={index}>
              <InlineIcon color={source} />
              {modifier !== 0 && (modifier > 0 ? ` + ${modifier}` : ` - ${Math.abs(modifier)}`)}
              {conditional && ` ${conditional}`}
            </span>
          );
        }
        if (part.type === 'textRun')
          return (
            <span
              key={index}
              className={
                part.style === 'bold'
                  ? 'font-bold'
                  : part.style === 'italic'
                    ? 'italic'
                    : part.style === 'gameKeyword'
                      ? 'font-mono text-xs bg-slate-200 px-0.5 rounded'
                      : ''
              }
            >
              {part.content}
            </span>
          );
        if (part.type === 'break') return <br key={index} />;
        if (part.type === 'difficultyValue') {
          return (
            <span key={index} className="font-bold">
              Check <InlineIcon color={part.difficulty.attribute} /> {part.difficulty.value}
            </span>
          );
        }
        return null;
      })}
    </>
  );
};
