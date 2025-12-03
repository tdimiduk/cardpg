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
  tags: z.array(z.string()).optional().default([]),
  items: z.array(z.record(z.string(), z.unknown())).optional().default([]),
  deck: z.array(z.record(z.string(), z.unknown())).optional().default([]),
});

const RawDataSchema = z.array(RawActorSchema);

// Cast the imported JSON to the correct type and normalize
const rawData = RawDataSchema.parse(generatedCards);

const ACTOR_DATA: ActorTemplate[] = rawData.map((actor) => ({
  id: actor.id,
  name: actor.name,
  tags: actor.tags,
  items: actor.items.map((item) => {
    // Ensure discriminators and defaults are present before parsing
    const itemObj = {
      ...item,
      type: 'itemCard',
      tags: item.tags || [],
      traits: item.traits || [],
    };
    return ItemCardSchema.parse(itemObj);
  }),
  deck: actor.deck.map((card) => {
    // Ensure discriminators and defaults are present before parsing
    const cardObj = {
      ...card,
      type: 'coreCard',
      tags: card.tags || [],
    };
    return CoreCardSchema.parse(cardObj);
  }),
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
