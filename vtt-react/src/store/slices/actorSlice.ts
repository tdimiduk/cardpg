import { StateCreator } from 'zustand';
import {
  ActorState,
  PlayerDeckState,
  TokenType,
  CoreCard,
  UIPlannedAction,
  StateUpdate,
  Token,
  ResourceType,
} from '../../types';
import { ActorState as ServerActorState, CoreCard as GenCoreCard } from '../../generated/types';

import { ACTOR_COLORS } from '../../theme';
import { INITIAL_ACTORS, RESOURCE_TYPES } from '../../constants';
import { LogSlice, createLog } from './logSlice';
import { createActor } from '../../services/actorFactory';

export interface ActorSlice {
  actors: Record<string, ActorState>;
  tokens: Token[];
  plannedActions: Record<string, UIPlannedAction>;

  initializeGame: () => void;
  addActor: (
    name: string,
    type: import('../../types').TokenType,
    color: string,
    templateId?: string,
  ) => void;
  removeActor: (actorId: string) => void;

  // Server Sync
  updateActorState: (update: StateUpdate) => void;
}

const hydrateCards = (
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

export const createActorSlice: StateCreator<
  ActorSlice & LogSlice, // removed explicit tokens requirement as it's part of ActorSlice now
  [['zustand/immer', never]],
  [],
  ActorSlice
> = (set) => ({
  actors: INITIAL_ACTORS,
  tokens: [],
  plannedActions: {},

  initializeGame: () =>
    set((_state) => {
      // No-op for now, waiting for server?
      // Or keep local for standalone dev
      console.log('Initialize Game called - expecting server state.');
    }),

  addActor: (name, actorType, color, templateId) =>
    set((state) => {
      const newActor = createActor(name, actorType, color, templateId);
      state.actors[newActor.id] = newActor;

      state.tokens.push({
        id: `token-${newActor.id}`,
        actorId: newActor.id,
        x: 0,
        y: 0,
        size: 1,
      });

      state.logs.push(createLog(`Added actor: ${name}`, 'GM'));
    }),

  removeActor: (actorId: string) =>
    set((state) => {
      if (!state.actors[actorId]) return;
      state.tokens = state.tokens.filter((t) => t.actorId !== actorId);
      delete state.actors[actorId];
      state.logs.push(createLog(`Removed actor ${actorId}`, 'GM'));
    }),

  updateActorState: (update: StateUpdate) =>
    set((state) => {
      const targetId = update.updateActorId; // UUID
      const serverState = update.updateActorState as unknown as ServerActorState;
      // Cast needed if types mismatch structurally due to imports

      if (!state.actors[targetId]) {
        console.log('Received update for new actor:', targetId);

        // Create a placeholder/new actor
        // We'll trust the server state mainly, but we need to init the object structure
        const actorType = serverState.actorType === 'PC' ? TokenType.PC : TokenType.MONSTER;

        state.actors[targetId] = {
          id: targetId,
          name: serverState.name,
          type: actorType,
          color: actorType === TokenType.PC ? ACTOR_COLORS.PC : ACTOR_COLORS.MONSTER,
          deck: {
            drawPile: [],
            hand: [],
            discardPile: [],
            flippedPile: [],
            equipped: [],
            consequences: [],
          },
          registry: {},
        };

        // Recursively call addActor-like logic or just push token
        state.tokens.push({
          id: `token-${targetId}`,
          actorId: targetId,
          x: 0,
          y: 0,
          size: 1,
        });

        state.logs.push(createLog(`Synced new actor: ${serverState.name}`, 'System'));
      }

      const core = serverState.coreState;
      const registry = core.registry;

      // Sync Registry
      state.actors[targetId].registry = registry as Record<
        string,
        import('../../generated/types').CoreCard
      >;

      // Sync Spatial State to Token
      const token = state.tokens.find((t: Token) => t.actorId === targetId);
      if (token && serverState.spatial) {
        token.x = serverState.spatial.posX;
        token.y = serverState.spatial.posY;
        token.size = serverState.spatial.size ?? 1;
      }

      // Sync Planned Move
      if (serverState.plannedMove) {
        if (!state.actors[targetId].plannedMove) {
          console.log('Sync: setting plannedMove for', targetId, serverState.plannedMove);
        }
        state.actors[targetId].plannedMove = {
          x: serverState.plannedMove[0],
          y: serverState.plannedMove[1],
        };
      } else {
        state.actors[targetId].plannedMove = undefined;
      }

      // Hydrate Deck State
      const newDeckState: PlayerDeckState = {
        drawPile: hydrateCards(core.deck, registry),
        hand: hydrateCards(core.hand, registry),
        discardPile: hydrateCards(core.discard, registry),
        flippedPile: hydrateCards(core.defending, registry),

        // Hydrate Equipped
        equipped: Object.entries(serverState.tableState.assets || {})
          .filter((entry) => entry[1]?.type === 'equipped')
          .map(([id, _]) => {
            const wrapper = serverState.tableState.registry[id];
            if (!wrapper) return undefined;
            const data = wrapper.data;
            return { ...data, id } as any;
          })
          .filter((c): c is import('../../types').Card => !!c),

        // Hydrate Consequences
        consequences: (serverState.tableState.consequences || []).map((id) => {
          const def = serverState.tableState.consequenceRegistry[id];
          if (!def) {
            return {
              id,
              name: 'Unknown Consequence',
              type: 'consequenceCard',
              severity: 1,
            } as any;
          }
          return { ...def, id };
        }),
      };

      state.actors[targetId].deck = newDeckState;

      // Sync Planned Actions (Authoritative)
      const planned = core.planned;

      if (planned) {
        if (planned.type === 'pStandard') {
          console.log('Sync: setting PStandard for', targetId);
          const stack = planned.data; // ActionStack
          const actionCardId = stack.actionCard;
          const resourceIds = stack.resources;

          const actionDef = registry[actionCardId];
          if (actionDef) {
            const actionCard = { ...actionDef, id: actionCardId };
            const allCards = hydrateCards([actionCardId, ...resourceIds], registry);

            // Infer Action logic for UI
            let color: ResourceType = RESOURCE_TYPES.RED;
            let modifier = 0;
            let targetDefense: ResourceType | undefined = undefined;

            const rules = actionCard.rules || [];
            const attackRule = rules.find((r) => r.type === 'attack');
            const generalRule = rules.find((r) => r.type === 'general');

            if (attackRule && attackRule.type === 'attack') {
              color = attackRule.data.power.source;
              modifier = attackRule.data.power.modifier;
              targetDefense = attackRule.data.resistedBy;
            } else if (generalRule && generalRule.type === 'general') {
              color = generalRule.data.difficulty?.attribute || RESOURCE_TYPES.RED;
            }

            state.plannedActions[targetId] = {
              actorId: targetId,
              actorName: serverState.name,
              cards: allCards,
              strengthColor: color,
              modifier: modifier,
              actionName: actionCard.name,
              targetDefense,
            };
          }
        }
        // Handle PNarrative
        else if (planned.type === 'pNarrative') {
          const stack = planned.data; // NarrativeStack
          const cardIds = stack.cards;
          const color = stack.color;

          const allCards = hydrateCards(cardIds, registry);

          state.plannedActions[targetId] = {
            actorId: targetId,
            actorName: serverState.name,
            cards: allCards,
            strengthColor: color,
            modifier: 0,
            actionName: 'Improvise', // Narrative action name
          };
        }
        // Handle PPass
        else if (planned.type === 'pPass') {
          state.plannedActions[targetId] = {
            actorId: targetId,
            actorName: serverState.name,
            cards: [],
            strengthColor: RESOURCE_TYPES.RED, // Dummy color
            modifier: 0,
            actionName: 'Pass',
          };
        }
      } else {
        // If server says no plan, ensure we don't have one
        delete state.plannedActions[targetId];
      }
    }),
});
