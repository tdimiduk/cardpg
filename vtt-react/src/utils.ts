import {
  ResourceType,
  Inline,
  CoreCard,
  ActiveChallenge,
  PlannedAction,
  ActorState,
} from './generated/types';

export const T = (content: string): Inline => ({ type: 'textRun', content });
export const I = (color: ResourceType): Inline => ({
  type: 'colorValue',
  value: { source: color, modifier: 0, conditional: undefined },
});

export const shuffle = <T>(array: T[]): T[] => {
  const newArray = [...array];
  for (let i = newArray.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
  }
  return newArray;
};

export const findCardInActor = (actor: ActorState, cardId: string): CoreCard | undefined => {
  const { coreState } = actor;
  const findInList = (list: CoreCard[], id: string) => list.find((c) => c.id === id);

  if (coreState.inPlay && coreState.inPlay[cardId]) {
    return coreState.inPlay[cardId]![0];
  }

  return (
    findInList(coreState.hand, cardId) ||
    findInList(coreState.deck, cardId) ||
    findInList(coreState.discard, cardId) ||
    (coreState.defending ? findInList(coreState.defending.cards, cardId) : undefined)
  );
};

export const resolveChallengeStack = (
  challenge: ActiveChallenge,
  plannedAction: PlannedAction | undefined,
  logId: string,
  actor: ActorState | undefined,
): CoreCard[] => {
  const cards: CoreCard[] = [];
  const sourceCardId = challenge.source.type === 'cSCard' ? challenge.source.data : '';

  let sourceCard: CoreCard | undefined;
  if (actor && sourceCardId) {
    const found = findCardInActor(actor, sourceCardId);
    if (found) sourceCard = { ...found, id: sourceCardId };
  }

  // Ad-Hoc Source handling
  if (challenge.source.type === 'cSAdHoc') {
    const adhoc = challenge.source;
    cards.push({
      id: `adhoc-${logId}`,
      name: adhoc.name,
      stats: {
        red: challenge.challengeColor === 'red' ? challenge.challengeStrength : 0,
        yellow: challenge.challengeColor === 'yellow' ? challenge.challengeStrength : 0,
        blue: challenge.challengeColor === 'blue' ? challenge.challengeStrength : 0,
      },
      flavor: adhoc.description ? [{ type: 'textRun', content: adhoc.description }] : undefined,
    });
  } else if (sourceCard) {
    cards.push(sourceCard);
  }

  // Planned Action Cards (Directly from Wire payload)
  if (plannedAction) {
    if (plannedAction.type === 'pStandard') {
      cards.push(plannedAction.data.actionCard);
      cards.push(...plannedAction.data.resources);
    } else if (plannedAction.type === 'pNarrative') {
      cards.push(...plannedAction.data.cards);
    }
  }

  return cards;
};
