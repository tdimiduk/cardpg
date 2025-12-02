import { CoreCard, ItemCard } from '../types';
import generatedCards from '../data/generated_cards.json';

export interface ActorTemplate {
  id: string;
  name: string;
  tags: string[];
  items: ItemCard[];
  deck: CoreCard[];
}

interface RawStats {
  red: number;
  yellow: number;
  blue: number;
}

interface RawItem {
  traits?: string[];
  tags?: string[];
  [key: string]: unknown;
}

interface RawCard {
  tags?: string[];
  stats?: RawStats;
  [key: string]: unknown;
}

interface RawActor {
  items?: RawItem[];
  deck?: RawCard[];
  [key: string]: unknown;
}

// Cast the imported JSON to the correct type and normalize
const ACTOR_DATA: ActorTemplate[] = (generatedCards as RawActor[]).map((actor) => ({
  ...actor,
  id: actor.id as string,
  name: actor.name as string,
  tags: (actor.tags as string[]) || [],
  items: actor.items
    ? actor.items.map((item) => ({
        ...item,
        type: 'item' as const,
        id: item.id as string,
        name: item.name as string,
        traits: item.traits || [],
        tags: item.tags || [],
      }))
    : [],
  deck: actor.deck
    ? actor.deck.map((card) => ({
        ...card,
        type: 'core' as const,
        id: card.id as string,
        name: card.name as string,
        stats: card.stats as RawStats,
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
