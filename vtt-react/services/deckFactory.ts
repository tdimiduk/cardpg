import { Card, CoreCard, ItemCard, Rule, Stats, ResourceType, Inline } from '../types';
import { T } from '../data/cardData';
import { CardDefinition } from '../data/cardDefinitions';
import { shuffle } from '../utils';
import generatedCards from '../data/generated_cards.json';

// --- Types for Generated JSON ---

interface GeneratedRule {
    type: string;
    data: any;
}

interface GeneratedCoreCard {
    type?: 'core'; // Might be missing in JSON, implied by location in 'deck'
    id: string;
    name: string;
    tags?: string[];
    stats: { red: number, yellow: number, blue: number };
    cost?: number;
    rules?: GeneratedRule[];
    flavor?: any; // RichString in JSON
}

interface GeneratedItemCard {
    type?: 'item'; // Might be missing in JSON, implied by location in 'items'
    id: string;
    name: string;
    tags?: string[];
    flavor?: any;
    weight?: number;
    value?: number;
    traits?: string[];
    passive?: string;
    defense?: number;
    resilience?: number;
}

interface GeneratedActor {
    id: string;
    name: string;
    tags: string[];
    items: GeneratedItemCard[];
    deck: GeneratedCoreCard[];
}

const actors = generatedCards as unknown as GeneratedActor[];

// --- Loader Logic ---

// Helper to convert JSON rules to internal Rule objects
const convertJsonRule = (r: any): Rule => {
    if (r.type === 'attack') {
        // The generated JSON should match the Rule type exactly.
        return r as Rule;
    } 
    return r as Rule;
};

const convertCoreCard = (c: GeneratedCoreCard): CoreCard => ({
    type: 'core',
    id: c.id,
    name: c.name,
    tags: c.tags || [],
    stats: c.stats || { red: 0, yellow: 0, blue: 0 },
    cost: c.cost,
    rules: (c.rules || []).map(convertJsonRule),
    flavor: c.flavor,
});

const convertItemCard = (c: GeneratedItemCard): ItemCard => ({
    type: 'item',
    id: c.id,
    name: c.name,
    tags: c.tags || [],
    flavor: c.flavor,
    weight: c.weight,
    value: c.value,
    traits: c.traits || [],
    passive: c.passive,
    defense: c.defense,
    resilience: c.resilience
});

// Cache for flattened cards to avoid re-scanning every time
let allCardsCache: Card[] | null = null;

const getAllCards = (): Card[] => {
    if (allCardsCache) return allCardsCache;
    
    const cards: Card[] = [];
    actors.forEach(actor => {
        actor.deck.forEach(c => cards.push(convertCoreCard(c)));
        actor.items.forEach(i => cards.push(convertItemCard(i)));
    });
    
    allCardsCache = cards;
    return cards;
};

export const loadCard = (id: string): Card | null => {
    const card = getAllCards().find(c => c.id === id);
    return card || null;
};

export const getActorsByTag = (tag: string): GeneratedActor[] => {
    return actors.filter(a => a.tags && a.tags.includes(tag));
};

// --- Legacy / Hybrid Factories ---

export const createCardFromDefinition = (tmpl: CardDefinition): Card => {
    // Legacy support for hardcoded templates (if still needed)
    
    if (tmpl.type === 'item') {
         return {
            type: 'item',
            id: Math.random().toString(36).substr(2, 9),
            name: tmpl.name,
            tags: [tmpl.type],
            flavor: tmpl.text,
            traits: [],
            defense: tmpl.def,
            resilience: tmpl.res
         } as ItemCard;
    }

    const rules: Rule[] = [];
    if (tmpl.actionDefinition) {
        if (tmpl.actionDefinition.type === 'attack') {
            rules.push({
                type: 'attack',
                data: {
                    power: { source: tmpl.actionDefinition.strengthColor, modifier: tmpl.actionDefinition.modifier },
                    resistedBy: tmpl.actionDefinition.targetDefenseColor || 'Red',
                    effect: null
                }
            });
        } else {
             rules.push({
                type: 'general',
                data: {
                    power: { source: tmpl.actionDefinition.strengthColor, modifier: tmpl.actionDefinition.modifier },
                    cost: null,
                    effect: []
                }
            });
        }
    }

    return {
        type: 'core',
        id: Math.random().toString(36).substr(2, 9),
        name: tmpl.name,
        tags: [tmpl.type],
        stats: { red: tmpl.red || 0, yellow: tmpl.yellow || 0, blue: tmpl.blue || 0 },
        cost: tmpl.playCount,
        rules: rules,
        flavor: tmpl.text,
    } as CoreCard;
};

export const generateStarterDeck = (): { deck: CoreCard[], equipped: ItemCard[] } => {
    const actor = actors.find(a => a.id === 'swashbuckler');
    
    if (!actor) {
        console.warn("Swashbuckler actor not found in generated cards.");
        return { deck: [], equipped: [] };
    }

    const deck = actor.deck.map(convertCoreCard);
    const equipped = actor.items.map(convertItemCard);

    return { deck: shuffle(deck), equipped };
};

export const generateMonsterDeck = (): { deck: CoreCard[], equipped: ItemCard[] } => {
    const monsters = getActorsByTag('monster');
    
    if (monsters.length === 0) {
        console.warn("No monster actors found in generated cards.");
        return { deck: [], equipped: [] };
    }

    // Default to Lizard Warrior if available, otherwise pick the first one
    const actor = monsters.find(a => a.id === 'lizard_warrior') || monsters[0];

    const deck = actor.deck.map(convertCoreCard);
    const equipped = actor.items.map(convertItemCard);

    return { deck: shuffle(deck), equipped };
};
