import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { Token, LogEntry, GamePhase, PlannedAction, PlayerDeckState, Card, CardColor, TokenType } from '../types';
import { INITIAL_TOKENS } from '../constants';
import { generateStarterDeck, generateMonsterDeck } from '../services/deckFactory';
import { drawCards, performDefend, shuffle, getAttributeValue, calculateSeverity, calculateStackStrength } from '../services/ruleService';
import { resolveMovement } from '../services/resolutionService';
import { STATUS_CARDS } from '../data/statuses';
import { CONSEQUENCE_DEFINITIONS } from '../data/consequences';

// --- State Definition ---

export interface GameState {
  tokens: Token[];
  logs: LogEntry[];
  phase: GamePhase;
  activeTokenId: string | null;
  plannedActions: Record<string, PlannedAction>;
  decks: Record<string, PlayerDeckState>;
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
  | { type: 'COMMIT_PLAN'; tokenId: string; cards: Card[]; strengthColor: CardColor; modifier: number; actionName?: string; targetDefense?: CardColor }
  | { type: 'CANCEL_PLAN'; tokenId: string }
  | { type: 'PASS_TURN'; tokenId: string }
  | { type: 'REVEAL_AND_RESOLVE' }
  | { type: 'END_ROUND' }
  | { type: 'PLAY_IMMEDIATE'; tokenId: string; cards: Card[]; strengthColor: CardColor; modifier: number; actionName?: string; targetDefense?: CardColor };


interface GameStore extends GameState {
  dispatch: (action: GameAction) => void;
}

// --- Helper Functions ---

const getTokenName = (state: GameState, id: string) => state.tokens.find(t => t.id === id)?.name || 'Unknown';

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
    tokens: INITIAL_TOKENS,
    logs: [createLog('Welcome to caRdPG. Begin Planning Phase.')],
    phase: 'planning',
    activeTokenId: INITIAL_TOKENS[0]?.id || null,
    plannedActions: {},
    decks: {},

    dispatch: (action: GameAction) => set((state) => {
      switch (action.type) {
        
        case 'INITIALIZE_GAME': {
          state.tokens.forEach(token => {
            const { deck, equipped } = token.type === TokenType.MONSTER 
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
            state.decks[token.id] = result.newState;
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
                 state.plannedActions[token.id] = {
                     actorId: token.id,
                     actorName: token.name,
                     cards: [],
                     strengthColor: 'red',
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
          const deck = state.decks[action.tokenId];
          if (!deck) return;
          const { newState, drawn, fatigueTriggered } = drawCards(deck, action.count);
          state.decks[action.tokenId] = newState;
          
          if (fatigueTriggered) {
            state.logs.push(createLog(`Fatigue Cycle triggered for ${getTokenName(state, action.tokenId)}.`, 'System'));
          }
          if (drawn.length > 0) {
            state.logs.push(createLog(`${getTokenName(state, action.tokenId)} drew ${drawn.length} card(s).`, 'System'));
          }
          break;
        }

        case 'DEFEND': {
          const deck = state.decks[action.tokenId];
          if (!deck) return;
          const { newState, flipped } = performDefend(deck, 999, 'red');
          state.decks[action.tokenId] = newState;
          if (flipped.length > 0) {
             state.logs.push(createLog(`${getTokenName(state, action.tokenId)} flipped for Defense: ${flipped[0].name}`, 'Player'));
          }
          break;
        }

        case 'CLEAR_DEFENSE': {
          const deck = state.decks[action.tokenId];
          if (!deck) return;
          deck.discardPile.push(...deck.flippedPile);
          deck.flippedPile = [];
          break;
        }

        case 'RESHUFFLE': {
          const deck = state.decks[action.tokenId];
          if (!deck) return;
          const newDraw = shuffle([...deck.drawPile, ...deck.discardPile]);
          deck.drawPile = newDraw;
          deck.discardPile = [];
          state.logs.push(createLog(`${getTokenName(state, action.tokenId)} reshuffled discard pile into deck.`, 'System'));
          break;
        }

        case 'DISCARD_CARDS': {
           const deck = state.decks[action.tokenId];
           if (!deck) return;
           const cardsToDiscard = deck.hand.filter(c => action.cardIds.includes(c.id));
           deck.hand = deck.hand.filter(c => !action.cardIds.includes(c.id));
           deck.discardPile.push(...cardsToDiscard);
           state.logs.push(createLog(`${getTokenName(state, action.tokenId)} discarded ${cardsToDiscard.length} card(s).`, 'System'));
           break;
        }

        case 'RETURN_TO_DECK': {
            const deck = state.decks[action.tokenId];
            if (!deck) return;
            const cards = deck.hand.filter(c => action.cardIds.includes(c.id));
            deck.hand = deck.hand.filter(c => !action.cardIds.includes(c.id));
            deck.drawPile.push(...cards);
            state.logs.push(createLog(`${getTokenName(state, action.tokenId)} returned ${cards.length} card(s) to top of deck.`, 'System'));
            break;
        }

        // --- Status & Consequences ---

        case 'ADD_CONSEQUENCE': {
            const deck = state.decks[action.tokenId];
            if (!deck) return;
            const resilience = getAttributeValue(deck.equipped, 'res');
            const currentSeverity = calculateSeverity(deck.consequences, resilience);
            const targetSeverity = Math.min(currentSeverity, 3);

            const pool = CONSEQUENCE_DEFINITIONS.filter(c => c.severity === targetSeverity);
            const selection = pool.length > 0 
                ? pool[Math.floor(Math.random() * pool.length)]
                : { name: 'Generic Wound', text: 'You are hurt.', severity: targetSeverity };
            
            const newConsequence: Card = {
                id: Math.random().toString(),
                name: selection.name,
                text: [{ type: 'text', content: selection.text }],
                type: 'wound',
                playCount: undefined
            };

            deck.consequences.push(newConsequence);
            state.logs.push(createLog(`${getTokenName(state, action.tokenId)} takes a Level ${targetSeverity} Consequence: ${selection.name}.`, 'System'));
            break;
        }

        case 'REMOVE_CONSEQUENCE': {
            const deck = state.decks[action.tokenId];
            if (!deck) return;
            const target = deck.consequences.find(c => c.id === action.cardId);
            deck.consequences = deck.consequences.filter(c => c.id !== action.cardId);
            if (target) {
                state.logs.push(createLog(`${getTokenName(state, action.tokenId)} removed consequence: "${target.name}".`, 'System'));
            }
            break;
        }

        case 'ADD_STATUS': {
            const deck = state.decks[action.tokenId];
            if (!deck) return;
            const template = STATUS_CARDS.find(c => c.type === action.statusType);
            if (!template) return;
            
            const newCard: Card = { ...template, id: Math.random().toString() };
            
            if (action.destination === 'discard') deck.discardPile.push(newCard);
            else if (action.destination === 'hand') deck.hand.push(newCard);
            else if (action.destination === 'draw') deck.drawPile.push(newCard);

            const label = action.destination === 'draw' ? 'top of deck' : action.destination === 'hand' ? 'hand' : 'discard pile';
            state.logs.push(createLog(`${getTokenName(state, action.tokenId)} added ${newCard.name} to ${label}.`, 'System'));
            break;
        }

        case 'REMOVE_STATUS': {
            const deck = state.decks[action.tokenId];
            if (!deck) return;
            const removeFirst = (arr: Card[]) => {
                const idx = arr.findIndex(c => c.type === action.statusType);
                if (idx > -1) {
                    const removed = arr.splice(idx, 1)[0];
                    return removed;
                }
                return null;
            }
            
            let removed = removeFirst(deck.discardPile);
            if (!removed) removed = removeFirst(deck.drawPile);
            if (!removed) removed = removeFirst(deck.hand);

            if (removed) {
                state.logs.push(createLog(`Removed ${removed.name} from ${getTokenName(state, action.tokenId)}'s deck.`, 'System'));
            } else {
                state.logs.push(createLog(`No ${action.statusType} cards found to remove.`, 'System'));
            }
            break;
        }

        // --- Planning & Flow ---

        case 'COMMIT_PLAN': {
            const deck = state.decks[action.tokenId];
            if (!deck) return;
            
            // Remove cards from hand
            const cardIds = new Set(action.cards.map(c => c.id));
            deck.hand = deck.hand.filter(c => !cardIds.has(c.id));

            // Set Plan
            state.plannedActions[action.tokenId] = {
                actorId: action.tokenId,
                actorName: getTokenName(state, action.tokenId),
                cards: action.cards,
                strengthColor: action.strengthColor,
                modifier: action.modifier,
                actionName: action.actionName,
                targetDefense: action.targetDefense,
                move: state.plannedActions[action.tokenId]?.move
            };

            state.logs.push(createLog(`${getTokenName(state, action.tokenId)} has prepared an action.`, 'Player'));
            break;
        }

        case 'PASS_TURN': {
            const deck = state.decks[action.tokenId];
            state.plannedActions[action.tokenId] = {
                actorId: action.tokenId,
                actorName: getTokenName(state, action.tokenId),
                cards: [],
                strengthColor: 'red',
                modifier: 0,
                actionName: 'Pass',
                move: state.plannedActions[action.tokenId]?.move
            };
            state.logs.push(createLog(`${getTokenName(state, action.tokenId)} passes and waits.`, 'Player'));
            break;
        }

        case 'CANCEL_PLAN': {
             const plan = state.plannedActions[action.tokenId];
             if (!plan) return;

             // Return cards to hand
             const deck = state.decks[action.tokenId];
             if (deck && plan.cards.length > 0) {
                 deck.hand.push(...plan.cards);
             }

             // Reset Plan (keep move)
             state.plannedActions[action.tokenId] = {
                 ...plan,
                 cards: [],
                 actionName: undefined,
                 modifier: 0
             };
             
             state.logs.push(createLog(`${getTokenName(state, action.tokenId)} is revising their plan.`, 'System'));
             break;
        }

        case 'REVEAL_AND_RESOLVE': {
            state.phase = 'resolution';
            state.logs.push(createLog('All actions revealed! Resolving now...', 'GM'));

            // Note: Movement is deferred to END_ROUND to maintain board state for targeting.

            // Resolve Actions & Discard Played Cards
            Object.values(state.plannedActions).forEach((plan) => {
                const deck = state.decks[plan.actorId];
                
                if (plan.actionName === 'Pass' && plan.cards.length === 0) {
                    state.logs.push(createLog(`${plan.actorName} takes no action.`, 'System'));
                    return;
                }

                if (plan.cards.length > 0) {
                    // Cast to Card[] because plan.cards is a WritableDraft<Card>[]
                    const cards = plan.cards as Card[];
                    const strength = calculateStackStrength(cards, plan.strengthColor, plan.modifier);
                    const cardNames = cards.map((c) => c.name).join(' + ');

                    state.logs.push(createLog(
                        plan.actionName ? `${plan.actorName} resolves ${plan.actionName} (${cardNames})` : `${plan.actorName} resolves Action (${cardNames})`,
                        'System',
                        'action',
                        { total: strength, color: plan.strengthColor, targetColor: plan.targetDefense, label: 'Strength' }
                    ));

                    // Move to discard
                    if (deck) {
                        deck.discardPile.push(...cards);
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
            const defeatedIds = Object.entries(state.decks)
                .filter(([_, d]) => (d as PlayerDeckState).consequences.some(c => c.name === 'Taken Out'))
                .map(([id]) => id);
            
            // Reset Plans (Auto-pass defeated)
            const nextPlans: Record<string, PlannedAction> = {};
            state.tokens.forEach(t => {
                if (defeatedIds.includes(t.id)) {
                    nextPlans[t.id] = {
                        actorId: t.id,
                        actorName: t.name,
                        cards: [],
                        strengthColor: 'red',
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
            
            Object.keys(state.decks).forEach(tokenId => {
                if (defeatedIds.includes(tokenId)) return;

                const { newState, fatigueTriggered } = drawCards(state.decks[tokenId], 2);
                state.decks[tokenId] = newState;
                activeCount++;
                if (fatigueTriggered) fatigueMsg += ` Fatigue for ${getTokenName(state, tokenId)}.`;
            });

            state.logs.push(createLog(`Round Ended. ${activeCount} active actors drew cards.${fatigueMsg}`, 'GM'));
            break;
        }

        case 'PLAY_IMMEDIATE': {
             // Used during Resolution Phase for reactions or unplanned moves
             const deck = state.decks[action.tokenId];
             if (!deck) return;

             // Remove from hand
             const cardIds = new Set(action.cards.map(c => c.id));
             deck.hand = deck.hand.filter(c => !cardIds.has(c.id));
             
             // Discard
             deck.discardPile.push(...action.cards);

             // Log
             const strength = calculateStackStrength(action.cards, action.strengthColor, action.modifier);
             const cardNames = action.cards.map(c => c.name).join(' + ');
             
             state.logs.push(createLog(
                 action.actionName ? `${getTokenName(state, action.tokenId)} used ${action.actionName} (${cardNames})` : `${getTokenName(state, action.tokenId)} performed Action (${cardNames})`,
                 'Player',
                 'action',
                 { total: strength, color: action.strengthColor, targetColor: action.targetDefense, label: 'Strength' }
             ));
             break;
        }
      }
    })
  }))
);