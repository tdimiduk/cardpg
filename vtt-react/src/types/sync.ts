import { z } from 'zod';
import { CoreCardSchema, ResourceTypeSchema, TokenSchema } from '../types';

export const BroadcastActionSchema = z.discriminatedUnion('type', [
  z.object({
    type: z.literal('PLAY_STACK'),
    activeTokenId: z.string(),
    selectedCards: z.array(CoreCardSchema),
    strengthColor: ResourceTypeSchema,
    modifier: z.number(),
    targetDefense: ResourceTypeSchema.optional(),
    actionName: z.string().optional(),
    phase: z.string(),
  }),
  z.object({ type: z.literal('PASS'), activeTokenId: z.string() }),
  z.object({ type: z.literal('REVEAL') }),
  z.object({ type: z.literal('END_ROUND') }),
  z.object({ type: z.literal('MOVE_TOKEN'), token: TokenSchema }),
  z.object({ type: z.literal('DRAW_CARDS'), activeTokenId: z.string(), count: z.number() }),
  z.object({ type: z.literal('DEFEND'), activeTokenId: z.string() }),
  z.object({ type: z.literal('CLEAR_DEFENSE'), activeTokenId: z.string() }),
  z.object({ type: z.literal('RESHUFFLE'), activeTokenId: z.string() }),
  z.object({ type: z.literal('ADD_CONSEQUENCE'), activeTokenId: z.string() }),
  z.object({
    type: z.literal('REMOVE_CONSEQUENCE'),
    activeTokenId: z.string(),
    cardId: z.string(),
  }),
  z.object({
    type: z.literal('ADD_STATUS'),
    activeTokenId: z.string(),
    statusType: z.string(),
    destination: z.string(),
  }),
  z.object({
    type: z.literal('REMOVE_STATUS'),
    activeTokenId: z.string(),
    statusType: z.string(),
  }),
  z.object({
    type: z.literal('DISCARD_CARDS'),
    activeTokenId: z.string(),
    cardIds: z.array(z.string()),
  }),
  z.object({ type: z.literal('CANCEL_PLAN'), activeTokenId: z.string() }),
  z.object({
    type: z.literal('RETURN_TO_DECK'),
    activeTokenId: z.string(),
    cardIds: z.array(z.string()),
  }),
]);

export type BroadcastAction = z.infer<typeof BroadcastActionSchema>;
