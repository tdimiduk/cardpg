import { CoreCard, ItemCard } from '../types';
import generatedCards from '../data/generated_cards.json';

export interface ActorTemplate {
  id: string;
  name: string;
  tags: string[];
  items: ItemCard[];
  deck: CoreCard[];
}

// Cast the imported JSON to the correct type and normalize
const ACTOR_DATA: ActorTemplate[] = (generatedCards as any[]).map((actor) => ({
  ...actor,
  items: actor.items
    ? actor.items.map((item: any) => ({
        ...item,
        type: 'item',
        traits: item.traits || [],
        tags: item.tags || [],
      }))
    : [],
  deck: actor.deck
    ? actor.deck.map((card: any) => ({
        ...card,
        type: 'core',
        tags: card.tags || [],
      }))
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

export const generateStarterDeck = (): { deck: CoreCard[]; equipped: ItemCard[] } => {
  // Fallback to swashbuckler if called without ID (legacy support)
  return generateDeck('swashbuckler');
};

export const generateMonsterDeck = (): { deck: CoreCard[]; equipped: ItemCard[] } => {
  // Fallback to lizard warrior if called without ID (legacy support)
  return generateDeck('lizard-warrior');
};
