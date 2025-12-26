import {
  ActorState,
  CoreCard,
  ItemCard,
  NatureCard,
  TalentCard,
  ConsequenceCard,
  ResourceType,
} from '../../generated/types';

// --- Type Helpers ---

export type ClientActor = ActorState & {
  id: string;
  // Derived / Convenience properties can go here
  isPC: boolean;
};

export type ClientCard = CoreCard | ItemCard | NatureCard | TalentCard | ConsequenceCard;

export type ClientCoreCard = CoreCard;

// --- Selectors ---

/**
 * Selects all actors with their IDs injected.
 */
export const selectActors = (state: { actors: Record<string, ActorState> }): ClientActor[] => {
  return Object.entries(state.actors).map(([id, actor]) => ({
    ...actor,
    id, // ActorState doesn't technically have 'id' field in Haskell, but key is ID. Frontend adds it here.
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
  return core.hand;
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
  return actor.coreState.deck;
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
  return actor.coreState.discard;
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
  return actor.coreState.defending?.cards ?? [];
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
      actionCard: planned.data.actionCard,
      resources: planned.data.resources,
    };
  }

  if (planned.type === 'pNarrative') {
    return {
      type: 'narrative',
      color: planned.data.color,
      cards: planned.data.cards,
    };
  }

  if (planned.type === 'pPass') {
    return { type: 'pass' };
  }

  return undefined;
};
