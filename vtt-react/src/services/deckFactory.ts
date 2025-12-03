import { CoreCard, ItemCard } from '../types';
import generatedCards from '../data/generated_cards.json';

export interface ActorTemplate {
  id: string;
  name: string;
  tags: string[];
  items: ItemCard[];
  deck: CoreCard[];
}

import { z } from 'zod';
import { CoreCardSchema, ItemCardSchema } from '../types';

// Define Raw Schema for JSON input (looser validation before normalization)
const RawActorSchema = z.object({
  id: z.string(),
  name: z.string(),
  tags: z.array(z.string()).optional(),
  items: z.array(z.record(z.string(), z.unknown())).optional(),
  deck: z.array(z.record(z.string(), z.unknown())).optional(),
});

const RawDataSchema = z.array(RawActorSchema);

// Cast the imported JSON to the correct type and normalize
const rawData = RawDataSchema.parse(generatedCards);

const ACTOR_DATA: ActorTemplate[] = rawData.map((actor) => ({
  id: actor.id,
  name: actor.name,
  tags: actor.tags || [],
  items: actor.items
    ? actor.items.map((item) => {
        const itemObj = {
          ...item,
          type: item.type as 'itemCard',
          id: item.id as string,
          name: item.name as string,
          traits: (item.traits as string[]) || [],
          tags: (item.tags as string[]) || [],
        };
        return ItemCardSchema.parse(itemObj);
      })
    : [],
  deck: actor.deck
    ? actor.deck.map((card) => {
        const cardObj = {
          ...card,
          type: card.type as 'coreCard',
          id: card.id as string,
          name: card.name as string,
          stats: card.stats,
          tags: (card.tags as string[]) || [],
        };
        return CoreCardSchema.parse(cardObj);
      })
    : [],
}));

export const getActorTemplates = (type?: 'pc' | 'monster'): ActorTemplate[] => {
  if (!type) {
    return ACTOR_DATA;
  }
  return ACTOR_DATA.filter((actor) => actor.tags.includes(type));
};

export const getActorTemplate = (id: string): ActorTemplate | undefined => {
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
