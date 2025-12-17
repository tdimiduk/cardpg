import { describe, it, expect } from 'vitest';
import { hydrateActor } from './hydration';
import { ActorState as ServerActorState } from '../generated/types';

describe('Hydration Reproduction', () => {
  it('should hydrate actor from server state correctly', () => {
    const updateActorId = '52022f18-9047-4a17-b2c9-74b0988d0b4e';
    const serverStatePayload = {
      name: 'Wolf',
      actorType: 'Monster',
      coreState: {
        deck: ['0662156a-af11-4ae6-aab2-91246656d75c'],
        hand: [],
        discard: [],
        planned: {
          type: 'pStandard',
          data: {
            actionCard: '1d8e5b7f-86b2-4792-9a6a-5fe2370581c9',
            resources: ['57a16d4a-2f66-4878-bb6a-1ecdda3fa691'],
          },
        },
        defending: [],
        inPlay: {},
        registry: {
          '0662156a-af11-4ae6-aab2-91246656d75c': {
            type: 'coreCard',
            name: 'Bite',
            stats: { red: 2, yellow: 2, blue: 2 },
            cost: 2,
            rules: [
              {
                type: 'attack',
                data: {
                  power: { source: 'red', modifier: 4 },
                  resistedBy: 'red',
                  effect: [{ type: 'textRun', content: 'basic wound' }],
                },
              },
            ],
          },
        },
      },
      tableState: {
        assets: {},
        registry: {},
        consequences: [],
        consequenceRegistry: {},
      },
      spatial: { posX: 1, posY: 1, size: 1 },
    };

    // Cast to ServerActorState as the JSON structure matches
    const serverState = serverStatePayload as unknown as ServerActorState;

    const hydrated = hydrateActor(serverState, updateActorId);

    expect(hydrated).toBeDefined();
    expect(hydrated.id).toBe(updateActorId);
    expect(hydrated.name).toBe('Wolf');
    // Check deck hydration
    expect(hydrated.deck.drawPile.length).toBe(1);
    expect(hydrated.deck.drawPile[0].name).toBe('Bite');
    expect(hydrated.deck.drawPile[0].id).toBe('0662156a-af11-4ae6-aab2-91246656d75c');
  });
});
