import { StateCreator } from 'zustand';
import {
  ActorState,
  PlayerDeckState,
  TokenType,
  CoreCard,
  PlannedAction,
  StateUpdate,
  Token,
  ResourceType,
} from '../../types';
import {
  ActorState as ServerActorState,
  CoreCard as GenCoreCard,
} from '../../generated/types';

import { ACTOR_COLORS } from '../../theme';
import { INITIAL_ACTORS, RESOURCE_TYPES } from '../../constants';
import { LogSlice, createLog } from './logSlice';
import { createActor } from '../../services/actorFactory';

export interface ActorSlice {
  actors: Record<string, ActorState>;
  tokens: Token[];
  plannedActions: Record<string, PlannedAction>;

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

  // Deck Actions (Legacy/Optimistic - now just log or no-op)
  drawCards: (tokenId: string, count: number) => void;
  defend: (tokenId: string) => void;
  clearDefense: (tokenId: string) => void;
  reshuffle: (tokenId: string) => void;
  discardCards: (tokenId: string, cardIds: string[]) => void;
  returnToDeck: (tokenId: string, cardIds: string[]) => void;

  // Status & Consequences
  addConsequence: (tokenId: string) => void;
  removeConsequence: (tokenId: string, cardId: string) => void;
  addStatus: (
    tokenId: string,
    statusType: string,
    destination: 'discard' | 'hand' | 'draw',
  ) => void;
  removeStatus: (tokenId: string, statusType: string) => void;
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
        };

        // Recursively call addActor-like logic or just push token
        state.tokens.push({
          id: `token-${targetId}`,
          actorId: targetId,
          x: 0,
          y: 0,
          size: 1,
        });

        state.logs.push(createLog(`Synced new actor: ${targetId}`, 'System'));
      }

      const currentActor = state.actors[targetId];
      const core = serverState.coreState;
      const registry = core.registry;

      // Sync Spatial State to Token
      const token = state.tokens.find((t: Token) => t.actorId === targetId);
      if (token && serverState.spatial) {
        token.x = serverState.spatial.posX;
        token.y = serverState.spatial.posY;
        token.size = serverState.spatial.size ?? 1;
      }

      // Sync Planned Move
      if (serverState.plannedMove) {
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
        // Preserve equipped/consequences if server doesn't manage them yet?
        // Server ActorState SHOULD manage them.
        // Assuming coreState has them or they are separate?
        // Current Haskell CoreState has: registry, deck, hand, discard, flipped.
        // It DOES NOT yet have equipped/consequences fully integrated in types possibly?
        // Checking Haskell: ActorState has `equipped :: [CardInstanceId]`?
        // CardPG.Core.State: data ActorState = ActorState { deck, hand, discard, flipped, registry ... }
        // It seems `equipped` and `consequences` might be missing from CoreState in Main branch?
        // If so, we must preserve them from current state or default.
        equipped: currentActor.deck.equipped,
        consequences: currentActor.deck.consequences,
      };

      state.actors[targetId].deck = newDeckState;

      // Sync Planned Actions (Authoritative)
      // core.planned is ActionStack { actionCard: string, resources: string[] }
      // Casting to any because of generated type confusion
      const planned = core.planned as any;

      if (planned) {
        const actionCardId = planned.actionCard;
        const resourceIds = planned.resources as string[];
        
        const actionDef = registry[actionCardId];
        if (actionDef) {
           const actionCard = { ...actionDef, id: actionCardId };
           const resources = resourceIds.map(id => {
               const def = registry[id];
               return def ? { ...def, id } : { ...actionDef, id, name: 'Unknown', type: 'coreCard' } as CoreCard; 
               // Fallback is quick hack, ideally hydrate properly using hydrateCards
           });
           
           // Re-hydrate strictly using hydrateCards helper
           const allCards = hydrateCards([actionCardId, ...resourceIds], registry);

           // Infer Action logic for UI
           let color: ResourceType = RESOURCE_TYPES.RED; // Default
           let modifier = 0;
           let targetDefense: ResourceType | undefined = undefined;
           
           const rules = actionCard.rules || [];
           const attackRule = rules.find(r => r.type === 'attack');
           const generalRule = rules.find(r => r.type === 'general');
           
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
      } else {
        // If server says no plan, ensure we don't have one (unless we are locally optimistically planning? 
        // Syncing strictly is safer to avoid desync state sticking around).
        delete state.plannedActions[targetId];
      }
      // state.logs.push(createLog(`Updated state for ${currentActor.name}`, 'System'));
    }),

  drawCards: (_tokenId: string, _count: number) =>
    set((_state) => {
      // Deprecated: Command sent via PlayerHand/DeckStats
      console.log('local drawCards called (deprecated)');
    }),

  defend: (_tokenId: string) =>
    set((_state) => {
      console.log('local defend called (deprecated)');
    }),

  clearDefense: (_tokenId: string) =>
    set((_state) => {
      console.log('local clearDefense called (deprecated)');
    }),

  reshuffle: (_tokenId: string) =>
    set((_state) => {
      console.log('local reshuffle called (deprecated)');
    }),

  discardCards: (_tokenId: string, _cardIds: string[]) =>
    set((_state) => {
      console.log('local discardCards called (deprecated)');
    }),

  returnToDeck: (_tokenId: string, _cardIds: string[]) =>
    set((_state) => {
      console.log('local returnToDeck called (deprecated)');
    }),

  addConsequence: (_tokenId: string) =>
    set((_state) => {
      console.log('local addConsequence called (deprecated)');
    }),

  removeConsequence: (_tokenId: string, _cardId: string) =>
    set((_state) => {
      console.log('local removeConsequence called (deprecated)');
    }),

  addStatus: (_tokenId: string, _statusType: string, _destination: 'discard' | 'hand' | 'draw') =>
    set((_state) => {
      console.log('local addStatus called (deprecated)');
    }),

  removeStatus: (_tokenId: string, _statusType: string) =>
    set((_state) => {
      console.log('local removeStatus called (deprecated)');
    }),
});
