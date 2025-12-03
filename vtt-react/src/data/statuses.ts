import { CoreCard } from '../types';
import { T } from '../utils';

export const STATUS_CARDS: CoreCard[] = [
  {
    type: 'coreCard',
    id: 'fatigue',
    name: 'Fatigue',
    stats: { red: 1, yellow: 1, blue: 1 },
    rules: [],
    tags: ['fatigue'],
  },
  {
    type: 'coreCard',
    id: 'injury',
    name: 'Injury',
    stats: { red: 0, yellow: 0, blue: 0 },
    rules: [
      {
        type: 'narrative',
        data: [T('If this card is in your hand at the end of the Resolve Step, expend it.')],
      },
    ],
    tags: ['wound'],
  },
];
