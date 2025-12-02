import { Token, Actor, TokenType } from './types';
import { ACTOR_COLORS } from './theme';

export const GRID_SIZE = 64; // pixels per square

export const INITIAL_ACTORS: Record<string, Actor> = {
  'hero-1': {
    id: 'hero-1',
    name: 'Vallhach',
    type: TokenType.PC,
    color: ACTOR_COLORS.PC,
    deck: {
      drawPile: [],
      hand: [],
      discardPile: [],
      flippedPile: [],
      equipped: [],
      consequences: [],
    },
  },
  'monster-1': {
    id: 'monster-1',
    name: 'Lizard Warrior',
    type: TokenType.MONSTER,
    color: ACTOR_COLORS.MONSTER,
    deck: {
      drawPile: [],
      hand: [],
      discardPile: [],
      flippedPile: [],
      equipped: [],
      consequences: [],
    },
  },
};

export const INITIAL_TOKENS: Token[] = [
  {
    id: 'token-1',
    actorId: 'hero-1',
    x: 2,
    y: 2,
    size: 1,
  },
  {
    id: 'token-2',
    actorId: 'monster-1',
    x: 8,
    y: 6,
    size: 1,
  },
];

export const MOCK_MAP_IMAGE = 'https://picsum.photos/1920/1080?grayscale&blur=2';

export const RESOURCE_TYPES = {
  RED: 'red',
  YELLOW: 'yellow',
  BLUE: 'blue',
} as const;
