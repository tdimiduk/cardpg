import {
  ActorState,
  CoreCard,
  CoreCardState,
  ItemCard,
  NatureCard,
  TalentCard,
  EncounterCard,
  ConsequenceCard,
  CardLocation,
  ResourceType,
  AssetState,
  TableCard,
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

const hydrateCoreCards = (
  ids: string[],
  registry: Record<string, CoreCard | undefined>,
): ClientCoreCard[] => {
  return ids.map((id) => {
    const card = registry[id];
    if (!card) {
      // Fallback for missing cards (shouldn't happen with correct server sync)
      return {
        id,
        type: 'coreCard',
        name: 'Unknown Card',
        stats: { red: 0, yellow: 0, blue: 0 },
      } as ClientCoreCard;
    }
    return { ...card, id };
  });
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

  // The registry in CoreCardState is Record<string, CoreCard>
  // However generated types might imply optional lookup, so we handle undefined.
  return hydrateCoreCards(core.hand, core.registry || {});
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
  return hydrateCoreCards(actor.coreState.deck, actor.coreState.registry || {});
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
  return hydrateCoreCards(actor.coreState.discard, actor.coreState.registry || {});
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
  return hydrateCoreCards(actor.coreState.defending, actor.coreState.registry || {});
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
  const registry = actor.coreState.registry || {};

  // Helper to hydrate a single ID safe-ishly
  const getCard = (id: string): ClientCoreCard => {
    const card = registry[id];
    if (!card) {
      return {
        id,
        type: 'coreCard',
        name: 'Unknown Card',
        stats: { red: 0, yellow: 0, blue: 0 },
      } as ClientCoreCard;
    }
    return { ...card, id };
  };

  if (planned.type === 'pStandard') {
    return {
      type: 'standard',
      actionCard: getCard(planned.data.actionCard),
      resources: planned.data.resources.map(getCard),
    };
  }

  if (planned.type === 'pNarrative') {
    return {
      type: 'narrative',
      color: planned.data.color,
      cards: planned.data.cards.map(getCard),
    };
  }

  if (planned.type === 'pPass') {
    return { type: 'pass' };
  }

  return undefined;
};
