import { CoreCard, ResourceType, Token } from '../types';

export type BroadcastAction =
  | {
      type: 'PLAY_STACK';
      activeTokenId: string;
      selectedCards: CoreCard[];
      strengthColor: ResourceType;
      modifier: number;
      targetDefense?: ResourceType;
      actionName?: string;
      phase: string;
    }
  | { type: 'PASS'; activeTokenId: string }
  | { type: 'REVEAL' }
  | { type: 'END_ROUND' }
  | { type: 'MOVE_TOKEN'; token: Token }
  | { type: 'DRAW_CARDS'; activeTokenId: string; count: number }
  | { type: 'DEFEND'; activeTokenId: string }
  | { type: 'CLEAR_DEFENSE'; activeTokenId: string }
  | { type: 'RESHUFFLE'; activeTokenId: string }
  | { type: 'ADD_CONSEQUENCE'; activeTokenId: string }
  | { type: 'REMOVE_CONSEQUENCE'; activeTokenId: string; cardId: string }
  | { type: 'ADD_STATUS'; activeTokenId: string; statusType: string; destination: string }
  | { type: 'REMOVE_STATUS'; activeTokenId: string; statusType: string }
  | { type: 'DISCARD_CARDS'; activeTokenId: string; cardIds: string[] }
  | { type: 'CANCEL_PLAN'; activeTokenId: string }
  | { type: 'RETURN_TO_DECK'; activeTokenId: string; cardIds: string[] };
