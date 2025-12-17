import { ActorState as ServerActorState, CoreCard as GenCoreCard } from '../generated/types';
import {
  ActorState,
  PlayerDeckState,
  TokenType,
  CoreCard,
  UIPlannedAction,
  Card,
  ResourceType,
  ConsequenceCard,
} from '../types';
import { ACTOR_COLORS } from '../theme';
import { RESOURCE_TYPES } from '../constants';

export const hydrateCards = (
  ids: string[],
  registry: Record<string, GenCoreCard | undefined>,
): CoreCard[] => {
  return ids.map((id) => {
    const def = registry[id];
    if (!def) {
      console.warn('Missing card definition for ID:', id);
      return {
        id,
        type: 'coreCard',
        name: 'Unknown',
        stats: { red: 0, yellow: 0, blue: 0 },
        flavor: [{ type: 'textRun', content: 'Missing Definition' }],
      } as CoreCard;
    }
    return { ...def, id };
  });
};

export const hydrateActor = (
  serverState: ServerActorState,
  id: string,
  existingActor?: ActorState,
): ActorState => {
  // Determine Actor Type
  const actorType = serverState.actorType === 'PC' ? TokenType.PC : TokenType.MONSTER;
  const color = actorType === TokenType.PC ? ACTOR_COLORS.PC : ACTOR_COLORS.MONSTER;

  const core = serverState.coreState;
  const registry = core.registry;

  // Sync Registry
  // We must manually map the registry to inject IDs, as the generated types don't include it in the object
  const mappedRegistry: Record<string, Card> = {};
  if (registry) {
    Object.entries(registry).forEach(([key, card]) => {
      if (card) {
        mappedRegistry[key] = { ...card, id: key } as CoreCard;
      }
    });
  }

  // Hydrate Deck State
  const newDeckState: PlayerDeckState = {
    drawPile: hydrateCards(core.deck, registry),
    hand: hydrateCards(core.hand, registry),
    discardPile: hydrateCards(core.discard, registry),
    flippedPile: hydrateCards(core.defending, registry),

    // Hydrate Equipped
    equipped: Object.entries(serverState.tableState.assets || {})
      .filter((entry) => entry[1]?.type === 'equipped' || entry[1]?.type === 'trait')
      .map(([assetId, _]) => {
        const wrapper = serverState.tableState.registry[assetId];
        if (!wrapper) return undefined;
        // wrapper is TableCard which has a 'data' field containing the actual card
        const data = wrapper.data;
        return { ...data, id: assetId } as Card;
      })
      .filter((c): c is Card => !!c),

    // Hydrate Consequences
    consequences: (serverState.tableState.consequences || []).map((cId) => {
      const def = serverState.tableState.consequenceRegistry[cId];
      if (!def) {
        return {
          id: cId,
          name: 'Unknown Consequence',
          type: 'consequenceCard',
          severity: 1,
        } as ConsequenceCard;
      }
      return { ...def, id: cId };
    }),
  };

  // Hydrate Planned Move
  let plannedMove: { x: number; y: number } | undefined;
  if (serverState.plannedMove) {
    plannedMove = {
      x: serverState.plannedMove[0],
      y: serverState.plannedMove[1],
    };
  }

  return {
    id,
    name: serverState.name,
    type: actorType,
    color: existingActor?.color || color,
    deck: newDeckState,
    registry: mappedRegistry,
    revealed: core.revealed,
    plannedMove,
  };
};

export const hydratePlannedAction = (
  serverState: ServerActorState,
  id: string,
  registry: Record<string, GenCoreCard | undefined>,
): UIPlannedAction | undefined => {
  const planned = serverState.coreState.planned;

  if (!planned) return undefined;

  if (planned.type === 'pStandard') {
    const stack = planned.data;
    const actionCardId = stack.actionCard;
    const resourceIds = stack.resources;

    const actionDef = registry[actionCardId];
    if (actionDef) {
      const actionCard = { ...actionDef, id: actionCardId };
      const allCards = hydrateCards([actionCardId, ...resourceIds], registry);

      // Infer Action logic for UI
      let strengthColor: ResourceType = RESOURCE_TYPES.RED;
      let modifier = 0;
      let targetDefense: ResourceType | undefined = undefined;

      const rules = actionCard.rules || [];
      const attackRule = rules.find((r) => r.type === 'attack');
      const generalRule = rules.find((r) => r.type === 'general');

      if (attackRule && attackRule.type === 'attack') {
        strengthColor = attackRule.data.power.source;
        modifier = attackRule.data.power.modifier;
        targetDefense = attackRule.data.resistedBy;
      } else if (generalRule && generalRule.type === 'general') {
        strengthColor = generalRule.data.difficulty?.attribute || RESOURCE_TYPES.RED;
      }

      return {
        actorId: id,
        actorName: serverState.name,
        cards: allCards,
        strengthColor,
        modifier,
        actionName: actionCard.name,
        targetDefense,
      };
    }
  } else if (planned.type === 'pNarrative') {
    const stack = planned.data;
    const cardIds = stack.cards;
    const color = stack.color;

    const allCards = hydrateCards(cardIds, registry);

    return {
      actorId: id,
      actorName: serverState.name,
      cards: allCards,
      strengthColor: color,
      modifier: 0,
      actionName: 'Improvise',
    };
  } else if (planned.type === 'pPass') {
    return {
      actorId: id,
      actorName: serverState.name,
      cards: [],
      strengthColor: RESOURCE_TYPES.RED,
      modifier: 0,
      actionName: 'Pass',
    };
  }

  return undefined;
};
