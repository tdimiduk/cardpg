import { describe, it, expect, beforeEach } from 'vitest';
import { createGameStore } from '../store/gameStore';
import { CoreCard, TokenType } from '../types';

describe('Game Flow Scenarios', () => {
    let useTestStore: ReturnType<typeof createGameStore>;

    beforeEach(() => {
        useTestStore = createGameStore();
        // Initialize game
        useTestStore.getState().dispatch({ type: 'INITIALIZE_GAME' });
    });

    it('Scenario 1: Find a playable action', () => {
        const store = useTestStore.getState();
        const actorId = Object.keys(store.actors)[0];
        const actor = store.actors[actorId];
        
        // Ensure hand is populated
        expect(actor.deck.hand.length).toBeGreaterThan(0);

        // Find a card with cost and attack rule (playable action)
        const actionCard = actor.deck.hand.find(c => 
            c.cost !== undefined && 
            c.rules?.some(r => r.type === 'attack')
        );

        if (actionCard) {
            expect(actionCard.cost).toBeGreaterThanOrEqual(0);
            expect(actionCard.rules).toBeDefined();
            const attackRule = actionCard.rules?.find(r => r.type === 'attack');
            expect(attackRule).toBeDefined();
            expect(attackRule?.data.power).toBeDefined();
        }
    });

    it('Scenario 2 & 3: Plan Move and Action', () => {
        const store = useTestStore.getState();
        const token = store.tokens[0];
        const actor = store.actors[token.actorId];
        
        // 1. Plan Move
        const newX = token.x + 1;
        const newY = token.y + 1;
        useTestStore.getState().dispatch({ 
            type: 'UPDATE_TOKEN_POSITION', 
            token: { ...token, x: newX, y: newY } 
        });

        let state = useTestStore.getState();
        expect(state.plannedActions[token.id]).toBeDefined();
        expect(state.plannedActions[token.id].move).toEqual({ x: newX, y: newY });

        // 2. Plan Action
        const cardToPlay = actor.deck.hand[0];
        useTestStore.getState().dispatch({
            type: 'COMMIT_PLAN',
            tokenId: token.id,
            cards: [cardToPlay],
            strengthColor: 'Red',
            modifier: 0,
            actionName: 'Test Attack'
        });

        state = useTestStore.getState();
        expect(state.plannedActions[token.id].cards.length).toBe(1);
        expect(state.plannedActions[token.id].cards[0].id).toBe(cardToPlay.id);
        expect(state.plannedActions[token.id].actionName).toBe('Test Attack');
        
        const updatedActor = state.actors[token.actorId];
        expect(updatedActor.deck.hand.find(c => c.id === cardToPlay.id)).toBeUndefined();
    });

    it('Scenario 4: Resolve Actions', () => {
        const store = useTestStore.getState();
        const token = store.tokens[0];
        const actor = store.actors[token.actorId];
        const cardToPlay = actor.deck.hand[0];

        useTestStore.getState().dispatch({
            type: 'COMMIT_PLAN',
            tokenId: token.id,
            cards: [cardToPlay],
            strengthColor: 'Red',
            modifier: 0,
            actionName: 'Test Resolution'
        });

        useTestStore.getState().dispatch({ type: 'REVEAL_AND_RESOLVE' });

        const state = useTestStore.getState();
        expect(state.phase).toBe('resolution');
        
        const resolutionLog = state.logs.find(l => l.content.includes('Test Resolution'));
        expect(resolutionLog).toBeDefined();
        expect(resolutionLog?.type).toBe('action');
    });

    it('Scenario 5: Flip for Defense', () => {
        const store = useTestStore.getState();
        const token = store.tokens[0];
        const actor = store.actors[token.actorId];
        const initialFlipped = actor.deck.flippedPile.length;

        useTestStore.getState().dispatch({ type: 'DEFEND', tokenId: token.id });

        const state = useTestStore.getState();
        const updatedActor = state.actors[token.actorId];
        
        expect(updatedActor.deck.flippedPile.length).toBeGreaterThan(initialFlipped);
        
        const log = state.logs.find(l => l.content.includes('flipped for Defense'));
        expect(log).toBeDefined();
    });

    it('Scenario 6: Add Consequence', () => {
        const store = useTestStore.getState();
        const token = store.tokens[0];
        const actor = store.actors[token.actorId];
        const initialConsequences = actor.deck.consequences.length;

        useTestStore.getState().dispatch({ type: 'ADD_CONSEQUENCE', tokenId: token.id });

        const state = useTestStore.getState();
        const updatedActor = state.actors[token.actorId];
        
        expect(updatedActor.deck.consequences.length).toBe(initialConsequences + 1);
        
        const log = state.logs.find(l => l.content.includes('Consequence'));
        expect(log).toBeDefined();
    });

    it('Scenario 7: Next Round (Move Realization)', () => {
        const store = useTestStore.getState();
        const token = store.tokens[0];
        
        const targetX = token.x + 2;
        const targetY = token.y + 2;
        useTestStore.getState().dispatch({ 
            type: 'UPDATE_TOKEN_POSITION', 
            token: { ...token, x: targetX, y: targetY } 
        });

        useTestStore.getState().dispatch({ type: 'END_ROUND' });

        const state = useTestStore.getState();
        const updatedToken = state.tokens.find(t => t.id === token.id);
        
        expect(updatedToken?.x).toBe(targetX);
        expect(updatedToken?.y).toBe(targetY);
        
        expect(state.phase).toBe('planning');
        
        const moveLog = state.logs.find(l => l.content.includes('moved'));
        expect(moveLog).toBeDefined();
    });
});
