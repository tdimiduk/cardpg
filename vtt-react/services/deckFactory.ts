import { DeckCard, Rule, Stats, ResourceType, Inline } from '../types';
import { STARTER_DECK_TEMPLATES, PERMANENT_CARDS, LIZARD_DECK_TEMPLATES, T } from '../data/cardData';
import { CardDefinition, LegacyActionDefinition } from '../data/cardDefinitions';
import { shuffle } from '../utils';
import generatedCards from '../data/generated_cards.json';

// --- Loader Logic ---

// Helper to convert JSON rules to internal Rule objects
const convertJsonRule = (r: any): Rule => {
    if (r.type === 'attack') {
        const expr = r.power.expression || "";
        const sourceMatch = expr.match(/{(\w+)}/);
        const modMatch = expr.match(/[+-]\s*(\d+)/);
        
        const source = sourceMatch ? sourceMatch[1] : 'Red';
        const modifier = modMatch ? parseInt(modMatch[0].replace(/\s/g, '')) : 0;

        return {
            type: 'attack',
            data: {
                power: { source: source as ResourceType, modifier },
                resistedBy: r.resistedBy || 'defense',
                effect: r.effect
            }
        };
    } else if (r.type === 'defend') {
        const expr = r.power.expression || "";
        const sourceMatch = expr.match(/{(\w+)}/);
        const modMatch = expr.match(/[+-]\s*(\d+)/);
        
        const source = sourceMatch ? sourceMatch[1] : 'Red';
        const modifier = modMatch ? parseInt(modMatch[0].replace(/\s/g, '')) : 0;

        return {
            type: 'defend',
            data: {
                power: { source: source as ResourceType, modifier },
                resists: r.resists || ['Red'],
                effect: r.effect
            }
        };
    } else if (r.type === 'narrative') {
        // Fallback for narrative rules
        return {
            type: 'general', // Map to general for now so it shows up
            data: {
                power: null,
                cost: null,
                effect: [{ type: 'textRun', content: r.text }]
            }
        };
    } else if (r.type === 'general') {
        return {
            type: 'general',
            data: {
                power: null,
                cost: null,
                effect: [{ type: 'textRun', content: r.effect }]
            }
        };
    }
    return { type: 'passive', data: { bonus: { source: 'Red', modifier: 0 }, condition: 'Unknown' } };
};

export const loadCard = (id: string): DeckCard | null => {
    const cardData = (generatedCards as any[]).find(c => c.id === id);
    if (!cardData) return null;

    return {
        id: cardData.id,
        name: cardData.name,
        tags: cardData.tags || [],
        stats: cardData.stats || { red: 0, yellow: 0, blue: 0 },
        cost: cardData.cost,
        rules: (cardData.rules || []).map(convertJsonRule),
        flavor: cardData.flavor ? [{ type: 'textRun', content: cardData.flavor }] : undefined,
        // Legacy support for items (Table Cards)
        def: cardData.defense,
        res: cardData.resilience
    };
};

// --- Legacy / Hybrid Factories ---

export const createCardFromDefinition = (tmpl: CardDefinition): DeckCard => {
    // ... (Keep legacy logic for now if needed, or deprecate)
    // For now, we'll just use the old logic for non-generated cards
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
        id: Math.random().toString(36).substr(2, 9),
        name: tmpl.name,
        tags: [tmpl.type],
        stats: { red: tmpl.red || 0, yellow: tmpl.yellow || 0, blue: tmpl.blue || 0 },
        cost: tmpl.playCount,
        rules: rules,
        flavor: tmpl.text,
        def: tmpl.def,
        res: tmpl.res
    };
};

export const generateStarterDeck = (): { deck: DeckCard[], equipped: DeckCard[] } => {
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

    const deck: DeckCard[] = [];
    deckIds.forEach(id => {
        const c = loadCard(id);
        if (c) deck.push(c);
    });

    const equipped: DeckCard[] = [];
    equippedIds.forEach(id => {
        const c = loadCard(id);
        if (c) equipped.push(c);
    });

    // Fallback to legacy if generated cards are missing (e.g. during dev)
    if (deck.length === 0) {
        console.warn("Generated cards not found, falling back to legacy starter deck.");
        return { 
            deck: shuffle(STARTER_DECK_TEMPLATES.map(createCardFromDefinition)), 
            equipped: PERMANENT_CARDS.map(createCardFromDefinition) 
        };
    }

    return { deck: shuffle(deck), equipped };
};

export const generateMonsterDeck = (): { deck: DeckCard[], equipped: DeckCard[] } => {
    // Keep legacy monster deck for now until we migrate monsters
    const deck: DeckCard[] = [];
    const countMap: Record<string, number> = {
        'Slash': 4, 'Bite': 2, 'Power Attack': 2, 'Hack': 2, 'Chop': 3,
        'Monitor': 1, 'Scaly Skin': 2, 'Lizard Strength': 3, 'Athletics': 2, 'Skitter': 2
    };

    LIZARD_DECK_TEMPLATES.forEach(tmpl => {
        const count = countMap[tmpl.name!] || 1;
        for(let i=0; i<count; i++) {
             deck.push(createCardFromDefinition(tmpl));
        }
    });
    
    const equipped = [
        createCardFromDefinition({
            name: 'Lizard Warrior',
            text: [T('A fierce reptile.')],
            type: 'item',
            def: 3,
            res: 2
        } as any)
    ];

    return { deck: shuffle(deck), equipped };
};
