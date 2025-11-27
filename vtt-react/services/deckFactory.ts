import { DeckCard, Rule, Stats, ResourceType, Inline } from '../types';
import { STARTER_DECK_TEMPLATES, PERMANENT_CARDS, LIZARD_DECK_TEMPLATES, T } from '../data/cardData';
import { CardDefinition, LegacyActionDefinition } from '../data/cardDefinitions';
import { shuffle } from '../utils';

const convertAction = (def: LegacyActionDefinition): Rule => {
  if (def.type === 'attack') {
    return {
      type: 'attack',
      data: {
        power: { source: def.strengthColor, modifier: def.modifier },
        resistedBy: def.targetDefenseColor || 'Red', // Default to Red if undefined
        effect: null
      }
    };
  } else {
    // Utility -> General
    return {
      type: 'general',
      data: {
        power: { source: def.strengthColor, modifier: def.modifier },
        cost: null,
        effect: [] // Placeholder
      }
    };
  }
};

export const createCardFromDefinition = (tmpl: CardDefinition): DeckCard => {
  const rules: Rule[] = [];
  
  if (tmpl.actionDefinition) {
    rules.push(convertAction(tmpl.actionDefinition));
  }

  // If it's an item with stats, maybe add a passive rule? 
  // For now, we just ignore def/res as they don't map cleanly to the new system 
  // without a specific RulePassive definition for them.
  
  return {
    id: Math.random().toString(36).substr(2, 9),
    name: tmpl.name,
    tags: [tmpl.type], // Map type to tag
    stats: {
      red: tmpl.red || 0,
      yellow: tmpl.yellow || 0,
      blue: tmpl.blue || 0
    },
    cost: tmpl.playCount,
    rules: rules,
    flavor: tmpl.text,
    // Legacy support
    def: tmpl.def,
    res: tmpl.res
  };
};

export const createCard = (
    name: string, 
    r: number | undefined, y: number | undefined, b: number | undefined, 
    textParts: Inline[], 
    playCount?: number, 
    actionDef?: LegacyActionDefinition,
    type: string = 'ability',
    stats?: { def?: number, res?: number }
): DeckCard => {
    return createCardFromDefinition({
        name,
        red: r, yellow: y, blue: b,
        text: textParts,
        playCount,
        actionDefinition: actionDef,
        type: type as any, // Cast to match CardDefinition type union
        def: stats?.def,
        res: stats?.res
    });
};

export const generateStarterDeck = (): { deck: DeckCard[], equipped: DeckCard[] } => {
  const deck: DeckCard[] = [];
  const equipped: DeckCard[] = PERMANENT_CARDS.map(createCardFromDefinition);

  // Duplicating to reach ~24 cards
  [...STARTER_DECK_TEMPLATES, ...STARTER_DECK_TEMPLATES].forEach(tmpl => {
    deck.push(createCardFromDefinition(tmpl));
  });
  return { deck: shuffle(deck), equipped };
};

export const generateMonsterDeck = (): { deck: DeckCard[], equipped: DeckCard[] } => {
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
    
    // Add a character card for the table with defense stats
    const equipped = [
        createCard('Lizard Warrior', undefined, undefined, undefined, [T('A fierce reptile.')], undefined, undefined, 'item', { def: 3, res: 2 })
    ];

    return { deck: shuffle(deck), equipped };
};
