import { Token, ActorState } from './types';

export const GRID_SIZE = 64; // pixels per square

export const INITIAL_ACTORS: Record<string, ActorState> = {};

export const INITIAL_TOKENS: Token[] = [];

export const MOCK_MAP_IMAGE = 'https://picsum.photos/1920/1080?grayscale&blur=2';

export const RESOURCE_TYPES = {
  RED: 'red',
  YELLOW: 'yellow',
  BLUE: 'blue',
} as const;
