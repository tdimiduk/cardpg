import { ResourceType, Inline } from './generated/types';

export const T = (content: string): Inline => ({ type: 'textRun', content });
export const I = (color: ResourceType): Inline => ({
  type: 'colorValue',
  value: { source: color, modifier: 0, conditional: undefined },
});

export const shuffle = <T>(array: T[]): T[] => {
  const newArray = [...array];
  for (let i = newArray.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
  }
  return newArray;
};
