
import { Token, TokenType } from './types';

export const GRID_SIZE = 64; // pixels per square

export const INITIAL_TOKENS: Token[] = [
  {
    id: 'hero-1',
    name: 'Vallhach',
    x: 2,
    y: 2,
    color: '#3b82f6',
    type: TokenType.PC,
    size: 1,
    imageUrl: 'https://picsum.photos/64/64?random=1'
  },
  {
    id: 'monster-1',
    name: 'Lizard Warrior',
    x: 8,
    y: 6,
    color: '#10b981',
    type: TokenType.MONSTER,
    size: 1,
    imageUrl: 'https://picsum.photos/128/128?random=3'
  }
];

export const MOCK_MAP_IMAGE = 'https://picsum.photos/1920/1080?grayscale&blur=2';
