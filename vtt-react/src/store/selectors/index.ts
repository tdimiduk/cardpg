import {
  ActorState,
  CoreCard,
  ItemCard,
  NatureCard,
  TalentCard,
  EncounterCard,
  ConsequenceCard,
  ResourceType,
  CoreCardInstance,
} from '../../generated/types';

// --- Type Helpers ---

// The "WithId" pattern bridges the gap between Backend (Record<Id, Obj>) and Frontend (Obj.id)
export type WithId<T> = T & { id: string };

export type ClientActor = WithId<ActorState> & {
  // Derived / Convenience properties can go here
  isPC: boolean;
};

export type ClientCard = WithId<
  CoreCard | ItemCard | NatureCard | TalentCard | EncounterCard | ConsequenceCard
>;

export type ClientCoreCard = WithId<CoreCard>;

// --- Selectors ---

/**
 * Selects all actors with their IDs injected.
 */
export const selectActors = (state: { actors: Record<string, ActorState> }): ClientActor[] => {
  return Object.entries(state.actors).map(([id, actor]) => ({
    ...actor,
    id,
    isPC: actor.actorType === 'PC',
  }));
};

/**
 * Selects a specific actor by ID.
 */
export const selectActor = (
  state: { actors: Record<string, ActorState> },
  actorId: string | undefined,
): ClientActor | undefined => {
  if (!actorId) return undefined;
  const actor = state.actors[actorId];
  if (!actor) return undefined;
  return {
    ...actor,
    id: actorId,
    isPC: actor.actorType === 'PC',
  };
};

// -- Card Hydration Helpers --

export const flattenInstance = (inst: CoreCardInstance): ClientCoreCard => {
  return { ...inst.content, id: inst.id };
};

/**
 * Selects the player's Hand cards with IDs.
 */
export const selectHand = (
  state: { actors: Record<string, ActorState> },
  actorId: string,
): ClientCoreCard[] => {
  const actor = state.actors[actorId];
  if (!actor) return [];
  const core = actor.coreState;

  // The hand is directly available as instances in the new Wire Wire model
  return core.hand.map(flattenInstance);
};

/**
 * Selects the player's Deck cards (just checking count/ids often sufficient, but full hydration provided).
 */
export const selectDeck = (
  state: { actors: Record<string, ActorState> },
  actorId: string,
): ClientCoreCard[] => {
  const actor = state.actors[actorId];
  if (!actor) return [];
  if (!actor) return [];
  return actor.coreState.deck.map(flattenInstance);
};

/**
 * Selects the player's Discard cards.
 */
export const selectDiscard = (
  state: { actors: Record<string, ActorState> },
  actorId: string,
): ClientCoreCard[] => {
  const actor = state.actors[actorId];
  if (!actor) return [];
  if (!actor) return [];
  return actor.coreState.discard.map(flattenInstance);
};

/**
 * Selects cards currently in the "Defending" slot (flipped pile).
 */
export const selectDefending = (
  state: { actors: Record<string, ActorState> },
  actorId: string,
): ClientCoreCard[] => {
  const actor = state.actors[actorId];
  if (!actor) return [];
  if (!actor) return [];
  return actor.coreState.defending.map(flattenInstance);
};

// -- Planned Action Selectors --

/**
 * Selects the "Readiness" count (how many actors have submitted a plan).
 */
export const selectReadiness = (state: { actors: Record<string, ActorState> }): number => {
  return Object.values(state.actors).filter((actor) => !!actor.coreState.planned).length;
};

export type UIPlannedAction =
  | { type: 'standard'; actionCard: ClientCoreCard; resources: ClientCoreCard[] }
  | { type: 'narrative'; cards: ClientCoreCard[]; color: ResourceType }
  | { type: 'pass' };

/**
 * Selects and hydrates the planned action for a specific actor.
 */
export const selectPlannedAction = (
  state: { actors: Record<string, ActorState> },
  actorId: string,
): UIPlannedAction | undefined => {
  const actor = state.actors[actorId];
  if (!actor || !actor.coreState.planned) return undefined;

  const planned = actor.coreState.planned;

  if (planned.type === 'pStandard') {
    return {
      type: 'standard',
      actionCard: flattenInstance(planned.data.actionCard),
      resources: planned.data.resources.map(flattenInstance),
    };
  }

  if (planned.type === 'pNarrative') {
    return {
      type: 'narrative',
      color: planned.data.color,
      cards: planned.data.cards.map(flattenInstance),
    };
  }

  if (planned.type === 'pPass') {
    return { type: 'pass' };
  }

  return undefined;
};
