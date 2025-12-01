import { Token } from '../types';

// AI functionality has been disabled for playtesting focus.

export const generateFlavorText = async (
  _prompt: string,
  _contextTokens: Token[],
): Promise<string> => {
  return 'AI features are currently disabled.';
};

export const generateNpcAction = async (
  _monsterName: string,
  _situation: string,
): Promise<string> => {
  return 'AI features are currently disabled.';
};
