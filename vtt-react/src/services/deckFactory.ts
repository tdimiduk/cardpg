import { CoreCard, ItemCard, ActorData, ActorDataSchema, CoreCardSchema } from '../types';
import generatedCards from '../data/generated_cards.json';
import { z } from 'zod';

// Schema for the entire generated cards JSON file to ensure type safety at runtime
const GeneratedDataSchema = z.object({
  actors: z.array(ActorDataSchema),
  statuses: z.array(CoreCardSchema),
});

// Cast the imported JSON to the correct type and normalize
const rawData = GeneratedDataSchema.parse(generatedCards);

export const ACTOR_DATA: ActorData[] = rawData.actors;

export const STATUS_DATA: CoreCard[] = rawData.statuses;

export const getActorTemplates = (type?: 'pc' | 'monster'): ActorData[] => {
  if (!type) {
    return ACTOR_DATA;
  }
  return ACTOR_DATA.filter((actor) => actor.tags?.includes(type));
};

export const getActorTemplate = (id: string): ActorData | undefined => {
  return ACTOR_DATA.find((actor) => actor.id === id);
};

export const generateDeck = (templateId: string): { deck: CoreCard[]; equipped: ItemCard[] } => {
  const template = getActorTemplate(templateId);

  if (!template) {
    console.error(`Template not found: ${templateId}`);
    return { deck: [], equipped: [] };
  }

  // Deep copy to avoid mutating the template
  const deck = JSON.parse(JSON.stringify(template.deck));
  const equipped = JSON.parse(JSON.stringify(template.items));

  return { deck, equipped };
};
