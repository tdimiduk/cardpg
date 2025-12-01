import { Card, CoreCard, ItemCard, Rule, Stats, ResourceType, Inline } from '../types';
import { T } from '../data/cardData';
import { CardDefinition } from '../data/cardDefinitions';
import { shuffle } from '../utils';
import generatedCards from '../data/generated_cards.json';

// --- Loader Logic ---

// Helper to convert JSON rules to internal Rule objects
const convertJsonRule = (r: any): Rule => {
    if (r.type === 'attack') {
        const expr = r.data.power.expression || ""; // Fallback if still using old format, but new format is structured
        // Actually, the new JSON has structured power.
        // { type: "attack", data: { power: { source: "Red", modifier: 2 }, ... } }
        // So we can just pass it through if it matches, or map it if needed.
        // The generated JSON should match the Rule type exactly if we did our job right.
        // But let's be safe and map it explicitly or cast it.
        return r as Rule;
    } 
    return r as Rule;
};

export const loadCard = (id: string): Card | null => {
    const cardData = (generatedCards as any[]).find(c => c.id === id);
    if (!cardData) return null;

    if (cardData.type === 'core') {
        return {
            type: 'core',
            id: cardData.id,
            name: cardData.name,
            tags: cardData.tags || [],
            stats: cardData.stats || { red: 0, yellow: 0, blue: 0 },
            cost: cardData.cost,
            rules: (cardData.rules || []).map(convertJsonRule),
            flavor: cardData.flavor,
        } as CoreCard;
    } else if (cardData.type === 'item') {
        return {
            type: 'item',
            id: cardData.id,
            name: cardData.name,
            tags: cardData.tags || [],
            flavor: cardData.flavor,
            weight: cardData.weight,
            value: cardData.value,
            traits: cardData.traits || [],
            passive: cardData.passive,
            defense: cardData.defense,
            resilience: cardData.resilience
        } as ItemCard;
    }
    return null;
};

// --- Legacy / Hybrid Factories ---

export const createCardFromDefinition = (tmpl: CardDefinition): Card => {
    // Legacy support for hardcoded templates (if still needed)
    // We try to map them to the new structure.
    
    if (tmpl.type === 'item') {
         return {
            type: 'item',
            id: Math.random().toString(36).substr(2, 9),
            name: tmpl.name,
            tags: [tmpl.type],
            flavor: tmpl.text,
            traits: [], // Legacy didn't have traits array in definition?
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
    // Swashbuckler Deck (from generated cards)
    const deckIds = [
        'feint', 'footwork', 'false-charge', 'fence', 'mind-games', 
        'inspire', 'trick', 'precise-strike', 'parry', 'athletics', 
        'trip', 'efficient-attack', 'bouy-spirits', 'stop-thrust', 
        "i've-got-a-plan", 'not-there-anymore', 'flashing-blade', 
        'quick-attack', 'make-opportunity', 'reliable-attack', 
        'patter', 'tales-of-heroics', 'gymnastics', 'disarming-humor'
    ];
    
    const equippedIds = ['leather-armor', 'rapier', 'throwing-knives'];

    const deck: CoreCard[] = [];
    deckIds.forEach(id => {
        const c = loadCard(id);
        if (c && c.type === 'core') deck.push(c);
    });

    const equipped: ItemCard[] = [];
    equippedIds.forEach(id => {
        const c = loadCard(id);
        if (c && c.type === 'item') equipped.push(c);
    });

    // Fallback to legacy if generated cards are missing (e.g. during dev)
    if (deck.length === 0) {
        console.warn("Generated cards not found. Please run the pipeline to generate cards.");
        // TODO: UI for indicating missing deck
        return { deck: [], equipped: [] };
    }

    return { deck: shuffle(deck), equipped };
};

export const generateMonsterDeck = (): { deck: CoreCard[], equipped: ItemCard[] } => {
    const deck: CoreCard[] = [];
    
    // Map of card names to count in the deck
    const countMap: Record<string, number> = {
        'Slash': 4, 'Bite': 2, 'Power Attack': 2, 'Hack': 2, 'Chop': 3,
        'Monitor': 1, 'Scaly Skin': 2, 'Lizard Strength': 3, 'Athletics': 2, 'Skitter': 2
    };

    // Load cards from generated JSON by name
    Object.entries(countMap).forEach(([name, count]) => {
        // Find card by name (case-insensitive search might be safer but exact match for now)
        // The generated cards have names like "Slash", "Bite" etc.
        const cardData = (generatedCards as any[]).find(c => c.name === name && c.type === 'core');
        if (cardData) {
            const card = loadCard(cardData.id);
            if (card && card.type === 'core') {
                for(let i=0; i<count; i++) {
                    deck.push(card);
                }
            }
        } else {
            console.warn(`Monster card '${name}' not found in generated cards.`);
        }
    });
    
    // Load equipped item
    const equipped: ItemCard[] = [];
    const lizardWarrior = (generatedCards as any[]).find(c => c.name === 'Lizard Warrior' && c.type === 'item');
    if (lizardWarrior) {
        const card = loadCard(lizardWarrior.id);
        if (card && card.type === 'item') {
            equipped.push(card);
        }
    } else {
        console.warn("Lizard Warrior item not found in generated cards.");
    }

    return { deck: shuffle(deck), equipped };
};
