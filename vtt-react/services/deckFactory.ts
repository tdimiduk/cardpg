
import { Card, ActionDefinition, CardTextPart } from '../types';
import { STARTER_DECK_TEMPLATES, PERMANENT_CARDS, LIZARD_DECK_TEMPLATES, T } from '../data/cardData';
import { CardDefinition } from '../data/cardDefinitions';
import { shuffle } from './ruleService';

export const createCard = (
    name: string, 
    r: number | undefined, y: number | undefined, b: number | undefined, 
    textParts: CardTextPart[], 
    playCount?: number, 
    actionDef?: ActionDefinition,
    type: Card['type'] = 'ability',
    stats?: { def?: number, res?: number }
): Card => ({
  id: Math.random().toString(36).substr(2, 9),
  name,
  red: r,
  yellow: y,
  blue: b,
  text: textParts,
  playCount,
  type: type,
  actionDefinition: actionDef,
  def: stats?.def,
  res: stats?.res
});

// The data is now already in the correct format, we just need to give it an instance ID.
const instantiate = (tmpl: CardDefinition): Card => ({
    ...tmpl,
    id: Math.random().toString(36).substr(2, 9)
});

export const generateStarterDeck = (): { deck: Card[], equipped: Card[] } => {
  const deck: Card[] = [];
  const equipped: Card[] = PERMANENT_CARDS.map(instantiate);

  // Duplicating to reach ~24 cards
  [...STARTER_DECK_TEMPLATES, ...STARTER_DECK_TEMPLATES].forEach(tmpl => {
    deck.push(instantiate(tmpl));
  });
  return { deck: shuffle(deck), equipped };
};

export const generateMonsterDeck = (): { deck: Card[], equipped: Card[] } => {
    const deck: Card[] = [];
    const countMap: Record<string, number> = {
        'Slash': 4, 'Bite': 2, 'Power Attack': 2, 'Hack': 2, 'Chop': 3,
        'Monitor': 1, 'Scaly Skin': 2, 'Lizard Strength': 3, 'Athletics': 2, 'Skitter': 2
    };

    LIZARD_DECK_TEMPLATES.forEach(tmpl => {
        const count = countMap[tmpl.name!] || 1;
        for(let i=0; i<count; i++) {
             deck.push(instantiate(tmpl));
        }
    });
    
    // Add a character card for the table with defense stats
    const equipped = [
        createCard('Lizard Warrior', undefined, undefined, undefined, [T('A fierce reptile.')], undefined, undefined, 'item', { def: 3, res: 2 })
    ];

    return { deck: shuffle(deck), equipped };
};
