import { ActorState, TokenType, PlayerDeckState } from '../types';
import { generateDeck, getActorTemplate } from './deckFactory';
import { drawCards } from './ruleService';
import { ACTOR_COLORS } from '../theme';

export const createActor = (
  name: string,
  type: TokenType,
  color?: string,
  templateId?: string,
): ActorState => {
  const id = Math.random().toString(36).substr(2, 9);
  let finalTemplateId = templateId;

  if (!finalTemplateId) {
    const derivedId = name.toLowerCase().replace(/\s+/g, '-');
    if (getActorTemplate(derivedId)) {
      finalTemplateId = derivedId;
    } else {
      finalTemplateId = type === TokenType.MONSTER ? 'lizard-warrior' : 'swashbuckler';
    }
  }

  const { deck, equipped } = generateDeck(finalTemplateId);

  const initialDeckState: PlayerDeckState = {
    drawPile: deck,
    hand: [],
    discardPile: [],
    flippedPile: [],
    equipped: equipped,
    consequences: [],
  };

  // Draw initial hand
  const drawRes = drawCards(initialDeckState, 4);

  return {
    id,
    name,
    type,
    color: color || (type === TokenType.MONSTER ? ACTOR_COLORS.MONSTER : ACTOR_COLORS.PC),
    deck: drawRes.newState,
  };
};
