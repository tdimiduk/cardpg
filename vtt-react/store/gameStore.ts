import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { Token, LogEntry, GamePhase, PlannedAction, PlayerDeckState, CoreCard, ResourceType, TokenType, Actor } from '../types';
import { INITIAL_TOKENS, INITIAL_ACTORS } from '../constants';
import { generateStarterDeck, generateMonsterDeck, createCardFromDefinition } from '../services/deckFactory';
import { drawCards, performDefend, getAttributeValue, calculateSeverity, calculateStackStrength } from '../services/ruleService';
import { shuffle } from '../utils';
import { resolveMovement } from '../services/resolutionService';
import { STATUS_CARDS } from '../data/statuses';
import { CONSEQUENCE_DEFINITIONS } from '../data/consequences';

// --- State Definition ---

export interface GameState {
  actors: Record<string, Actor>;
  tokens: Token[];
  logs: LogEntry[];
  phase: GamePhase;
  activeTokenId: string | null;
  plannedActions: Record<string, PlannedAction>;
}

// --- Action Definitions ---

export type GameAction = 
  | { type: 'INITIALIZE_GAME' }
  | { type: 'SET_ACTIVE_TOKEN'; tokenId: string | null }
  | { type: 'UPDATE_TOKEN_POSITION'; token: Token }
  | { type: 'ADD_LOG'; message: string; sender: LogEntry['sender']; logType?: LogEntry['type']; actionResult?: LogEntry['actionResult'] }
  // Deck Actions
  | { type: 'DRAW_CARDS'; tokenId: string; count: number }
  | { type: 'DEFEND'; tokenId: string }
  | { type: 'CLEAR_DEFENSE'; tokenId: string }
  | { type: 'RESHUFFLE'; tokenId: string }
  | { type: 'DISCARD_CARDS'; tokenId: string; cardIds: string[] }
  | { type: 'RETURN_TO_DECK'; tokenId: string; cardIds: string[] }
  // Status & Consequences
  | { type: 'ADD_CONSEQUENCE'; tokenId: string }
  | { type: 'REMOVE_CONSEQUENCE'; tokenId: string; cardId: string }
  | { type: 'ADD_STATUS'; tokenId: string; statusType: 'fatigue' | 'wound'; destination: 'discard' | 'hand' | 'draw' }
  | { type: 'REMOVE_STATUS'; tokenId: string; statusType: 'fatigue' | 'wound' }
  // Planning & Flow
  | { type: 'COMMIT_PLAN'; tokenId: string; cards: CoreCard[]; strengthColor: ResourceType; modifier: number; actionName?: string; targetDefense?: ResourceType }
  | { type: 'CANCEL_PLAN'; tokenId: string }
  | { type: 'PASS_TURN'; tokenId: string }
  | { type: 'REVEAL_AND_RESOLVE' }
  | { type: 'END_ROUND' }
  | { type: 'PLAY_IMMEDIATE'; tokenId: string; cards: CoreCard[]; strengthColor: ResourceType; modifier: number; actionName?: string; targetDefense?: ResourceType }
  | { type: 'ADD_ACTOR'; name: string; actorType: TokenType; templateId?: string; x?: number; y?: number; color?: string }
  | { type: 'REMOVE_ACTOR'; actorId: string }
  | { type: 'SPAWN_TOKEN'; actorId: string; x: number; y: number }
  | { type: 'DESPAWN_TOKEN'; tokenId: string };


interface GameStore extends GameState {
  dispatch: (action: GameAction) => void;
}

// --- Helper Functions ---

const getActor = (state: GameState, tokenId: string): Actor | undefined => {
    const token = state.tokens.find(t => t.id === tokenId);
    if (!token) return undefined;
    return state.actors[token.actorId];
}

const getTokenName = (state: GameState, id: string) => getActor(state, id)?.name || 'Unknown';

const createLog = (content: string, sender: LogEntry['sender'] = 'System', type: LogEntry['type'] = 'info', actionResult?: LogEntry['actionResult']): LogEntry => ({
  id: Math.random().toString(36),
  timestamp: Date.now(),
  sender,
  content,
  type,
  actionResult
});

// --- Store Implementation ---

export const useGameStore = create<GameStore>()(
  immer((set, get) => ({
    // Initial State
    actors: INITIAL_ACTORS,
    tokens: INITIAL_TOKENS,
    logs: [createLog('Welcome to caRdPG. Begin Planning Phase.')],
    phase: 'planning',
    activeTokenId: INITIAL_TOKENS[0]?.id || null,
    plannedActions: {},

    dispatch: (action: GameAction) => set((state) => {
      switch (action.type) {
        
        case 'INITIALIZE_GAME': {
          Object.values(state.actors).forEach(actor => {
            const { deck, equipped } = actor.type === TokenType.MONSTER 
              ? generateMonsterDeck() 
              : generateStarterDeck();
            
            // Initial State structure
            let deckState: PlayerDeckState = {
                drawPile: deck,
                hand: [],
                discardPile: [],
                flippedPile: [],
                equipped: equipped,
                consequences: []
            };

            // Initial Draw (4 cards)
            const result = drawCards(deckState, 4);
            actor.deck = result.newState;
          });
          break;
        }

        case 'SET_ACTIVE_TOKEN': {
          state.activeTokenId = action.tokenId;
          break;
        }

        case 'UPDATE_TOKEN_POSITION': {
          const { token } = action;
          // Resolution: Move immediately
          if (state.phase === 'resolution') {
             const idx = state.tokens.findIndex(t => t.id === token.id);
             if (idx !== -1) state.tokens[idx] = token;
          } 
          // Planning: Update Move Plan
          else {
             if (!state.plannedActions[token.id]) {
                 const actor = state.actors[token.actorId];
                 state.plannedActions[token.id] = {
                     actorId: token.id, // Keeping tokenId as the key for plans for now, or should it be actorId? 
                     // The plan is associated with the token on the map.
                     // But the actor executes it.
                     // Let's keep using tokenId for plannedActions key to match activeTokenId.
                     actorName: actor?.name || 'Unknown',
                     cards: [],
                     strengthColor: 'Red',
                     modifier: 0,
                     actionName: undefined
                 };
             }
             state.plannedActions[token.id].move = { x: token.x, y: token.y };
          }
          break;
        }

        case 'ADD_LOG': {
          state.logs.push(createLog(action.message, action.sender, action.logType, action.actionResult));
          break;
        }

        // --- Deck Actions ---

        case 'DRAW_CARDS': {
          const actor = getActor(state, action.tokenId);
          if (!actor) return;
          const { newState, drawn, fatigueTriggered } = drawCards(actor.deck, action.count);
          actor.deck = newState;
          
          if (fatigueTriggered) {
            state.logs.push(createLog(`Fatigue Cycle triggered for ${actor.name}.`, 'System'));
          }
          if (drawn.length > 0) {
            state.logs.push(createLog(`${actor.name} drew ${drawn.length} card(s).`, 'System'));
          }
          break;
        }

        case 'DEFEND': {
          const actor = getActor(state, action.tokenId);
          if (!actor) return;
          const { newState, flipped } = performDefend(actor.deck, 999, 'Red');
          actor.deck = newState;
          if (flipped.length > 0) {
             state.logs.push(createLog(`${actor.name} flipped for Defense: ${flipped[0].name}`, 'Player'));
          }
          break;
        }

        case 'CLEAR_DEFENSE': {
          const actor = getActor(state, action.tokenId);
          if (!actor) return;
          actor.deck.discardPile.push(...actor.deck.flippedPile);
          actor.deck.flippedPile = [];
          break;
        }

        case 'RESHUFFLE': {
          const actor = getActor(state, action.tokenId);
          if (!actor) return;
          const newDraw = shuffle([...actor.deck.drawPile, ...actor.deck.discardPile]);
          actor.deck.drawPile = newDraw;
          actor.deck.discardPile = [];
          state.logs.push(createLog(`${actor.name} reshuffled discard pile into deck.`, 'System'));
          break;
        }

        case 'DISCARD_CARDS': {
           const actor = getActor(state, action.tokenId);
           if (!actor) return;
           const cardsToDiscard = actor.deck.hand.filter(c => action.cardIds.includes(c.id));
           actor.deck.hand = actor.deck.hand.filter(c => !action.cardIds.includes(c.id));
           actor.deck.discardPile.push(...cardsToDiscard);
           state.logs.push(createLog(`${actor.name} discarded ${cardsToDiscard.length} card(s).`, 'System'));
           break;
        }

        case 'RETURN_TO_DECK': {
            const actor = getActor(state, action.tokenId);
            if (!actor) return;
            const cards = actor.deck.hand.filter(c => action.cardIds.includes(c.id));
            actor.deck.hand = actor.deck.hand.filter(c => !action.cardIds.includes(c.id));
            actor.deck.drawPile.push(...cards);
            state.logs.push(createLog(`${actor.name} returned ${cards.length} card(s) to top of deck.`, 'System'));
            break;
        }

        // --- Status & Consequences ---

        case 'ADD_CONSEQUENCE': {
            const actor = getActor(state, action.tokenId);
            if (!actor) return;
            const resilience = getAttributeValue(actor.deck.equipped, 'res');
            const currentSeverity = calculateSeverity(actor.deck.consequences, resilience);
            const targetSeverity = Math.min(currentSeverity, 3);

            const pool = CONSEQUENCE_DEFINITIONS.filter(c => c.severity === targetSeverity);
            const selection = pool.length > 0 
                ? pool[Math.floor(Math.random() * pool.length)]
                : { name: 'Generic Wound', text: 'You are hurt.', severity: targetSeverity };
            
            const newConsequence = {
                type: 'core' as const,
                id: Math.random().toString(),
                name: selection.name,
                flavor: [{ type: 'textRun' as const, content: selection.text }],
                tags: ['wound'],
                stats: { red: 0, yellow: 0, blue: 0 },
                rules: [],
                cost: undefined
            };

            actor.deck.consequences.push(newConsequence as CoreCard);
            state.logs.push(createLog(`${actor.name} takes a Level ${targetSeverity} Consequence: ${selection.name}.`, 'System'));
            break;
        }

        case 'REMOVE_CONSEQUENCE': {
            const actor = getActor(state, action.tokenId);
            if (!actor) return;
            const target = actor.deck.consequences.find(c => c.id === action.cardId);
            actor.deck.consequences = actor.deck.consequences.filter(c => c.id !== action.cardId);
            if (target) {
                state.logs.push(createLog(`${actor.name} removed consequence: "${target.name}".`, 'System'));
            }
            break;
        }

        case 'ADD_STATUS': {
            const actor = getActor(state, action.tokenId);
            if (!actor) return;
            const template = STATUS_CARDS.find(c => c.tags?.includes(action.statusType));
            if (!template) return;
            
            // Clone the template
            const newCard: CoreCard = { ...template, id: Math.random().toString() };
            
            if (action.destination === 'discard') actor.deck.discardPile.push(newCard);
            else if (action.destination === 'draw') actor.deck.drawPile.push(newCard);

            const label = action.destination === 'draw' ? 'top of deck' : 'discard pile';
            state.logs.push(createLog(`${actor.name} added ${newCard.name} to ${label}.`, 'System'));
            break;
        }

        case 'REMOVE_STATUS': {
            const actor = getActor(state, action.tokenId);
            if (!actor) return;
            const removeFirst = (arr: CoreCard[]) => {
                const idx = arr.findIndex(c => c.tags?.includes(action.statusType));
                if (idx > -1) {
                    const removed = arr.splice(idx, 1)[0];
                    return removed;
                }
                return null;
            }
            
            let removed = removeFirst(actor.deck.discardPile);
            if (!removed) removed = removeFirst(actor.deck.drawPile);
            if (!removed) removed = removeFirst(actor.deck.hand);

            if (removed) {
                state.logs.push(createLog(`Removed ${removed.name} from ${actor.name}'s deck.`, 'System'));
            } else {
                state.logs.push(createLog(`No ${action.statusType} cards found to remove.`, 'System'));
            }
            break;
        }

        // --- Planning & Flow ---

        case 'COMMIT_PLAN': {
            const actor = getActor(state, action.tokenId);
            if (!actor) return;
            
            // Remove cards from hand
            const cardIds = new Set(action.cards.map(c => c.id));
            actor.deck.hand = actor.deck.hand.filter(c => !cardIds.has(c.id));

            // Set Plan
            state.plannedActions[action.tokenId] = {
                actorId: action.tokenId,
                actorName: actor.name,
                cards: action.cards,
                strengthColor: action.strengthColor,
                modifier: action.modifier,
                actionName: action.actionName,
                targetDefense: action.targetDefense,
                move: state.plannedActions[action.tokenId]?.move
            };

            state.logs.push(createLog(`${actor.name} has prepared an action.`, 'Player'));
            break;
        }

        case 'PASS_TURN': {
            const actor = getActor(state, action.tokenId);
            state.plannedActions[action.tokenId] = {
                actorId: action.tokenId,
                actorName: actor?.name || 'Unknown',
                cards: [],
                strengthColor: 'Red',
                modifier: 0,
                actionName: 'Pass',
                move: state.plannedActions[action.tokenId]?.move
            };
            state.logs.push(createLog(`${actor?.name || 'Unknown'} passes and waits.`, 'Player'));
            break;
        }

        case 'CANCEL_PLAN': {
             const plan = state.plannedActions[action.tokenId];
             if (!plan) return;

             // Return cards to hand
             const actor = getActor(state, action.tokenId);
             if (actor && plan.cards.length > 0) {
                 actor.deck.hand.push(...plan.cards);
             }

             // Reset Plan (keep move)
             state.plannedActions[action.tokenId] = {
                 ...plan,
                 cards: [],
                 actionName: undefined,
                 modifier: 0
             };
             
             state.logs.push(createLog(`${actor?.name || 'Unknown'} is revising their plan.`, 'System'));
             break;
        }

        case 'REVEAL_AND_RESOLVE': {
            state.phase = 'resolution';
            state.logs.push(createLog('All actions revealed! Resolving now...', 'GM'));

            // Note: Movement is deferred to END_ROUND to maintain board state for targeting.

            // Resolve Actions & Discard Played Cards
            Object.entries(state.plannedActions).forEach(([tokenId, plan]) => {
                const actor = getActor(state, tokenId);
                
                if (plan.actionName === 'Pass' && plan.cards.length === 0) {
                    state.logs.push(createLog(`${plan.actorName} takes no action.`, 'System'));
                    return;
                }

                if (plan.cards.length > 0) {
                    // Cast to CoreCard[] because plan.cards is a WritableDraft<CoreCard>[]
                    const cards = plan.cards as CoreCard[];
                    const strength = calculateStackStrength(cards, plan.strengthColor, plan.modifier);
                    const cardNames = cards.map((c) => c.name).join(' + ');

                    state.logs.push(createLog(
                        plan.actionName ? `${plan.actorName} resolves ${plan.actionName} (${cardNames})` : `${plan.actorName} resolves Action (${cardNames})`,
                        'System',
                        'action',
                        { total: strength, color: plan.strengthColor, targetColor: plan.targetDefense, label: 'Strength' }
                    ));

                    // Move to discard
                    if (actor) {
                        actor.deck.discardPile.push(...cards);
                    }
                }
            });
            break;
        }

        case 'END_ROUND': {
            // 1. Resolve Movement (Deferred from Reveal)
            // We use casts here because Immer Draft types can sometimes conflict with strict function signatures
            const { movedTokens, logs: moveLogs } = resolveMovement(
                state.tokens as Token[], 
                state.plannedActions as unknown as Record<string, PlannedAction>
            );
            state.tokens = movedTokens;
            if (moveLogs.length > 0) {
                state.logs.push(createLog(moveLogs.join(' '), 'System'));
            }

            // Identify defeated
            const defeatedIds = Object.values(state.actors)
                .filter(a => a.deck.consequences.some(c => c.name === 'Taken Out'))
                .map(a => a.id);
            
            // Reset Plans (Auto-pass defeated)
            const nextPlans: Record<string, PlannedAction> = {};
            state.tokens.forEach(t => {
                const actor = state.actors[t.actorId];
                if (actor && defeatedIds.includes(actor.id)) {
                    nextPlans[t.id] = {
                        actorId: t.id,
                        actorName: actor.name,
                        cards: [],
                        strengthColor: 'Red',
                        modifier: 0,
                        actionName: 'Pass'
                    };
                }
            });
            state.plannedActions = nextPlans;
            state.phase = 'planning';

            // Draw Cards
            let activeCount = 0;
            let fatigueMsg = '';
            
            Object.values(state.actors).forEach(actor => {
                if (defeatedIds.includes(actor.id)) return;

                const { newState, fatigueTriggered } = drawCards(actor.deck, 2);
                actor.deck = newState;
                activeCount++;
                if (fatigueTriggered) fatigueMsg += ` Fatigue for ${actor.name}.`;
            });

            state.logs.push(createLog(`Round Ended. ${activeCount} active actors drew cards.${fatigueMsg}`, 'GM'));
            break;
        }

        case 'PLAY_IMMEDIATE': {
             // Used during Resolution Phase for reactions or unplanned moves
             const actor = getActor(state, action.tokenId);
             if (!actor) return;

             // Remove from hand
             const cardIds = new Set(action.cards.map(c => c.id));
             actor.deck.hand = actor.deck.hand.filter(c => !cardIds.has(c.id));
             
             // Discard
             actor.deck.discardPile.push(...action.cards);

             // Log
             const strength = calculateStackStrength(action.cards, action.strengthColor, action.modifier);
             const cardNames = action.cards.map(c => c.name).join(' + ');
             
             state.logs.push(createLog(
                 action.actionName ? `${actor.name} used ${action.actionName} (${cardNames})` : `${actor.name} performed Action (${cardNames})`,
                 'Player',
                 'action',
                 { total: strength, color: action.strengthColor, targetColor: action.targetDefense, label: 'Strength' }
             ));
             break;
        }

        case 'ADD_ACTOR': {
            const { name, actorType, templateId, x, y, color } = action;
            const id = Math.random().toString(36).substr(2, 9);
            
            let deckRes;
            if (actorType === TokenType.MONSTER) {
                deckRes = generateMonsterDeck(); 
            } else {
                deckRes = generateStarterDeck();
            }
            
            const newActor: Actor = {
                id,
                name,
                type: actorType,
                color: color || '#999',
                deck: {
                    drawPile: deckRes.deck,
                    hand: [],
                    discardPile: [],
                    flippedPile: [],
                    equipped: deckRes.equipped,
                    consequences: []
                }
            };
            
            // Initial Draw
            const drawRes = drawCards(newActor.deck, 4);
            newActor.deck = drawRes.newState;
            
            state.actors[id] = newActor;
            
            // Default to 0,0 if not specified
            const spawnX = x ?? 0;
            const spawnY = y ?? 0;
            
            state.tokens.push({
                id: `token-${id}`,
                actorId: id,
                x: spawnX,
                y: spawnY,
                size: 1
            });
            
            state.logs.push(createLog(`Added actor: ${name}`, 'GM'));
            break;
        }

        case 'REMOVE_ACTOR': {
            const { actorId } = action;
            if (!state.actors[actorId]) return;
            
            // Find tokens to remove
            const tokensToRemove = state.tokens.filter(t => t.actorId === actorId);
            const tokenIds = new Set(tokensToRemove.map(t => t.id));
            
            // Remove tokens
            state.tokens = state.tokens.filter(t => t.actorId !== actorId);
            
            // Remove actor
            delete state.actors[actorId];
            
            // Remove plans
            Object.keys(state.plannedActions).forEach(tid => {
                if (tokenIds.has(tid)) {
                    delete state.plannedActions[tid];
                }
            });
            
            state.logs.push(createLog(`Removed actor ${actorId}`, 'GM'));
            break;
        }

        case 'SPAWN_TOKEN': {
            const { actorId, x, y } = action;
            if (!state.actors[actorId]) return;
            
            state.tokens.push({
                id: `token-${Math.random().toString(36).substr(2, 9)}`,
                actorId,
                x,
                y,
                size: 1
            });
            break;
        }

        case 'DESPAWN_TOKEN': {
            const { tokenId } = action;
            state.tokens = state.tokens.filter(t => t.id !== tokenId);
            delete state.plannedActions[tokenId];
            if (state.activeTokenId === tokenId) {
                state.activeTokenId = null;
            }
            break;
        }
      }
    })
  }))
);