import { T } from './cardData';
import { CoreCard } from '../types';

export const STATUS_CARDS: CoreCard[] = [
  {
    type: 'core',
    id: 'fatigue',
    name: 'Fatigue',
    stats: { red: 1, yellow: 1, blue: 1 },
    rules: [],
    tags: ['fatigue']
  },
  {
    type: 'core',
    id: 'injury',
    name: 'Injury',
    stats: { red: 0, yellow: 0, blue: 0 },
    rules: [
        {
            type: 'narrative',
            data: [T('If this card is in your hand at the end of the Resolve Step, expend it.')]
        }
    ],
    tags: ['wound']
  }
];