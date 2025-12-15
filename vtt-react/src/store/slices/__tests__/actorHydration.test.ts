import { createActorSlice } from '../actorSlice';
import { createLogSlice } from '../logSlice';
import { createStore } from 'zustand';
import { immer } from 'zustand/middleware/immer';

// Combine slices
const createCombinedStore = (set, get, api) => ({
  ...createActorSlice(set, get, api),
  ...createLogSlice(set, get, api),
});

describe('Actor Slice Hydration', () => {
  it('hydrates equipped items correctly from valid server state', () => {
    const useStore = createStore(immer(createCombinedStore));
    useStore.getState();

    const actorId = 'actor-123';
    const cardId = 'card-uuid-1';

    // Mock Server State matching what we confirmed in Haskell
    const serverState = {
      name: 'Test Actor',
      actorType: 'PC',
      coreState: {
        deck: [],
        hand: [],
        discard: [],
        defending: [],
        inPlay: {},
        registry: {},
      },
      tableState: {
        assets: {
          [cardId]: { type: 'equipped', data: 'slotMainHand' },
        },
        registry: {
          [cardId]: {
            type: 'tCItem',
            data: {
              type: 'itemCard',
              name: 'Sword',
              stats: { red: 0, yellow: 0, blue: 0 }, // ItemCard doesn't have stats usually in Haskell def but frontend CoreCard does. ItemCard has flavor etc.
              // Let's match generated/types.ts IItemCard
              // name: string, type: "itemCard"
            },
          },
        },
        consequences: [],
        consequenceRegistry: {},
      },
      spatial: { posX: 0, posY: 0, size: 1 },
      plannedMove: null,
    };

    // Execute Update
    useStore.getState().updateActorState({
      updateActorId: actorId,
      updateActorState: serverState as unknown as import('../../../generated/types').ActorState,
    });

    // Verify
    const updatedActor = useStore.getState().actors[actorId];
    expect(updatedActor).toBeDefined();
    expect(updatedActor.deck.equipped).toHaveLength(1);
    expect(updatedActor.deck.equipped[0].id).toBe(cardId);
    expect(updatedActor.deck.equipped[0].name).toBe('Sword');
    expect(updatedActor.deck.equipped[0].type).toBe('itemCard');
  });

  it('filters equipped and trait items for display, excluding inCollection', () => {
    const useStore = createStore(immer(createCombinedStore));
    useStore.getState();

    const actorId = 'actor-456';
    const cardId1 = 'card-uuid-1';
    const cardId2 = 'card-uuid-2';
    const cardId3 = 'card-uuid-3';

    const serverState = {
      name: 'Mixed Collection Actor',
      actorType: 'PC',
      coreState: {
        deck: [],
        hand: [],
        discard: [],
        defending: [],
        inPlay: {},
        registry: {},
      },
      tableState: {
        assets: {
          [cardId1]: { type: 'inCollection' },
          [cardId2]: { type: 'equipped', data: 'slotMainHand' },
          [cardId3]: { type: 'trait' },
        },
        registry: {
          [cardId1]: {
            type: 'tCItem',
            data: {
              type: 'itemCard',
              name: 'Stashed Sword',
              stats: { red: 0, yellow: 0, blue: 0 },
            },
          },
          [cardId2]: {
            type: 'tCItem',
            data: {
              type: 'itemCard',
              name: 'Equipped Sword',
              stats: { red: 0, yellow: 0, blue: 0 },
            },
          },
          [cardId3]: {
            type: 'tCNature',
            data: { type: 'natureCard', name: 'Elven Heritage' },
          },
        },
        consequences: [],
        consequenceRegistry: {},
      },
      spatial: { posX: 0, posY: 0, size: 1 },
      plannedMove: null,
    };

    useStore.getState().updateActorState({
      updateActorId: actorId,
      updateActorState: serverState as unknown as import('../../../generated/types').ActorState,
    });

    const updatedActor = useStore.getState().actors[actorId];
    expect(updatedActor).toBeDefined();

    // Verification
    const equippedList = updatedActor.deck.equipped;
    const names = equippedList.map((c) => c.name);

    expect(names).toContain('Equipped Sword');
    expect(names).toContain('Elven Heritage');
    expect(names).not.toContain('Stashed Sword');
    expect(equippedList).toHaveLength(2);
  });
});
