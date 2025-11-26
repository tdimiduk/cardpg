
import { CardColor, CardTextPart, ActionDefinition } from "../types";

// This file represents the OUTPUT of your export script.
// It contains fully parsed structures, removing the need for runtime parsing.

export interface CardDefinition {
  name: string;
  red?: number;
  yellow?: number;
  blue?: number;
  def?: number;
  res?: number;
  text: CardTextPart[];
  playCount?: number;
  type: 'ability' | 'item' | 'fatigue' | 'wound';
  actionDefinition?: ActionDefinition;
}

// Helper for readability in this file, though the real export script would just output raw objects.
const T = (content: string): CardTextPart => ({ type: 'text', content });
const I = (color: CardColor): CardTextPart => ({ type: 'icon', color });

export const STARTER_DECK_DATA: CardDefinition[] = [
  {
    name: 'Lightning Bolt',
    red: 3, yellow: 3, blue: 3,
    text: [T('Attack '), I('red'), T(': '), I('blue'), T(' + 4')],
    playCount: 3,
    type: 'ability',
    actionDefinition: { type: 'attack', strengthColor: 'blue', targetDefenseColor: 'red', modifier: 4 }
  },
  {
    name: 'Thunderstorm',
    red: 2, yellow: 3, blue: 4,
    text: [T('Attack '), I('red'), T(': '), I('blue'), T(' - 3. Summons clouds.')],
    playCount: 6,
    type: 'ability',
    actionDefinition: { type: 'attack', strengthColor: 'blue', targetDefenseColor: 'red', modifier: -3 }
  },
  {
    name: 'Light Blast',
    red: 3, yellow: 3, blue: 3,
    text: [T('Attack '), I('red'), T(': '), I('blue'), T(' + 2')],
    playCount: 1,
    type: 'ability',
    actionDefinition: { type: 'attack', strengthColor: 'blue', targetDefenseColor: 'red', modifier: 2 }
  },
  {
    name: 'Fireball',
    red: 3, yellow: 1, blue: 4,
    text: [T('Attack '), I('red'), T(': '), I('blue'), T(' + 2. Affects all monsters.')],
    playCount: 5,
    type: 'ability',
    actionDefinition: { type: 'attack', strengthColor: 'blue', targetDefenseColor: 'red', modifier: 2 }
  },
  {
    name: 'Magma Missile',
    red: 2, yellow: 1, blue: 4,
    text: [T('Attack '), I('red'), T(': '), I('blue'), T('. Attacks each round.')],
    playCount: 3,
    type: 'ability',
    actionDefinition: { type: 'attack', strengthColor: 'blue', targetDefenseColor: 'red', modifier: 0 }
  },
  {
    name: 'Banish Darkness',
    red: 4, yellow: 3, blue: 3,
    text: [T('Attack '), I('red'), T(': '), I('blue'), T(' + 6 vs Dark.')],
    playCount: 2,
    type: 'ability',
    actionDefinition: { type: 'attack', strengthColor: 'blue', targetDefenseColor: 'red', modifier: 6 }
  },
  {
    name: 'Sunburn',
    red: 4, yellow: 1, blue: 4,
    text: [T('Attack '), I('red'), T(': '), I('blue'), T('. Debuffs monster.')],
    playCount: 2,
    type: 'ability',
    actionDefinition: { type: 'attack', strengthColor: 'blue', targetDefenseColor: 'red', modifier: 0 }
  },
  {
    name: 'Haste',
    red: 1, yellow: 5, blue: 2,
    text: [T('Action: Put in play. Draw extra card.')],
    playCount: 3,
    type: 'ability',
    actionDefinition: { type: 'utility', strengthColor: 'yellow', modifier: 0 }
  },
  {
    name: 'Lightning Speed',
    red: 2, yellow: 5, blue: 2,
    text: [T('Super fast movement.')],
    type: 'ability',
    playCount: undefined
  },
  {
    name: 'Elvish Footsteps',
    red: 1, yellow: 2, blue: 5,
    text: [T('Sneaking in forests.')],
    type: 'ability',
    playCount: undefined
  },
  {
    name: 'Lightning Dodge',
    red: 2, yellow: 5, blue: 2,
    text: [T('Use '), I('yellow'), T(' + '), I('red'), T(' on Defense.')],
    type: 'ability',
    playCount: undefined
  }
];

export const ITEM_DATA: CardDefinition[] = [
  {
    name: 'Vallhach',
    text: [T('An elf mage.')],
    type: 'item',
    def: 2, res: 2
  },
  {
    name: 'Sun Belt',
    text: [T('A thin belt made of gold. Lets Vallhach use sun spells.')],
    type: 'item',
    def: 1, res: 0
  },
  {
    name: 'Lightning Earrings',
    text: [T('Small pair of earrings. Lets Vallhach use lightning spells.')],
    type: 'item'
  },
  {
    name: 'Elven Staff',
    text: [T('A staff made out of wood and gold.')],
    type: 'item',
    def: 0, res: 1
  },
  {
    name: 'Magical Abilities',
    text: [T('Innate power.')],
    type: 'item'
  }
];

export const MONSTER_DECK_DATA: CardDefinition[] = [
    {
        name: 'Slash',
        red: 3, yellow: 2, blue: 2,
        text: [T('Attack '), I('red'), T(': '), I('red'), T(' + 2. Basic wound.')],
        playCount: 1,
        type: 'ability',
        actionDefinition: { type: 'attack', strengthColor: 'red', targetDefenseColor: 'red', modifier: 2 }
    },
    {
        name: 'Bite',
        red: 3, yellow: 3, blue: 1,
        text: [T('Attack '), I('red'), T(': '), I('red'), T(' + 2. Basic wound.')],
        playCount: 0,
        type: 'ability',
        actionDefinition: { type: 'attack', strengthColor: 'red', targetDefenseColor: 'red', modifier: 2 }
    },
    {
        name: 'Power Attack',
        red: 4, yellow: 2, blue: 2,
        text: [T('Attack '), I('red'), T(': '), I('red'), T(' + 3. Basic wound.')],
        playCount: 2,
        type: 'ability',
        actionDefinition: { type: 'attack', strengthColor: 'red', targetDefenseColor: 'red', modifier: 3 }
    },
    {
        name: 'Hack',
        red: 3, yellow: 2, blue: 1,
        text: [T('Attack '), I('red'), T(': '), I('red'), T(' + 5. Basic wound.')],
        playCount: 3,
        type: 'ability',
        actionDefinition: { type: 'attack', strengthColor: 'red', targetDefenseColor: 'red', modifier: 5 }
    },
    {
        name: 'Chop',
        red: 2, yellow: 3, blue: 1,
        text: [T('Attack '), I('red'), T(': '), I('red'), T(' + 4. Basic wound.')],
        playCount: 1,
        type: 'ability',
        actionDefinition: { type: 'attack', strengthColor: 'red', targetDefenseColor: 'red', modifier: 4 }
    },
    {
        name: 'Monitor',
        red: 3, yellow: 3, blue: 4,
        text: [T('Draw 2 cards, recover 2 from spent.')],
        playCount: 1,
        type: 'ability',
        actionDefinition: { type: 'utility', strengthColor: 'blue', modifier: 0 }
    },
    {
        name: 'Scaly Skin',
        red: 4, yellow: 3, blue: 1,
        text: [T('Defense +2 when spent on defense. Basic wound.')],
        type: 'ability'
    },
    {
        name: 'Lizard Strength',
        red: 5, yellow: 2, blue: 1,
        text: [],
        type: 'ability'
    },
    {
        name: 'Athletics',
        red: 4, yellow: 4, blue: 2,
        text: [],
        type: 'ability'
    },
    {
        name: 'Skitter',
        red: 2, yellow: 5, blue: 2,
        text: [],
        type: 'ability'
    }
];
