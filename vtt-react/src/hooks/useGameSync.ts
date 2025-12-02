import { useEffect } from 'react';
import { useWebSocket } from '../contexts/WebSocketContext';
import { useGameStore } from '../store/gameStore';
import { BroadcastAction } from '../types/sync';
import { CoreCard, ResourceType, Token } from '../types';

function assertUnreachable(x: never): never {
  throw new Error("Didn't expect to get here");
}

export const useGameSync = () => {
  const { lastMessage, clientId } = useWebSocket();
  
  // Store actions
  const commitPlan = useGameStore((state) => state.commitPlan);
  const playImmediate = useGameStore((state) => state.playImmediate);
  const passTurn = useGameStore((state) => state.passTurn);
  const revealAndResolve = useGameStore((state) => state.revealAndResolve);
  const endRound = useGameStore((state) => state.endRound);
  const updateTokenPosition = useGameStore((state) => state.updateTokenPosition);
  const drawCards = useGameStore((state) => state.drawCards);
  const defend = useGameStore((state) => state.defend);
  const clearDefense = useGameStore((state) => state.clearDefense);
  const reshuffle = useGameStore((state) => state.reshuffle);
  const addConsequence = useGameStore((state) => state.addConsequence);
  const removeConsequence = useGameStore((state) => state.removeConsequence);
  const addStatus = useGameStore((state) => state.addStatus);
  const removeStatus = useGameStore((state) => state.removeStatus);

  useEffect(() => {
    if (lastMessage && lastMessage.tag === 'BroadcastMessage') {
      // Ignore our own messages (we apply them optimistically)
      if (lastMessage.fromClientId === clientId) return;

      const action = lastMessage.payload;
      console.log('Received broadcast:', action);

      switch (action.type) {
        case 'PLAY_STACK':
          if (action.phase === 'planning') {
            commitPlan(
              action.activeTokenId,
              action.selectedCards,
              action.strengthColor,
              action.modifier,
              action.actionName,
              action.targetDefense,
            );
          } else {
            playImmediate(
              action.activeTokenId,
              action.selectedCards,
              action.strengthColor,
              action.modifier,
              action.actionName,
              action.targetDefense,
            );
          }
          break;
        case 'PASS':
          passTurn(action.activeTokenId);
          break;
        case 'REVEAL':
          revealAndResolve();
          break;
        case 'END_ROUND':
          endRound();
          break;
        case 'MOVE_TOKEN':
          updateTokenPosition(action.token);
          break;
        case 'DRAW_CARDS':
          drawCards(action.activeTokenId, action.count);
          break;
        case 'DEFEND':
          defend(action.activeTokenId);
          break;
        case 'CLEAR_DEFENSE':
          clearDefense(action.activeTokenId);
          break;
        case 'RESHUFFLE':
          reshuffle(action.activeTokenId);
          break;
        case 'ADD_CONSEQUENCE':
          addConsequence(action.activeTokenId);
          break;
        case 'REMOVE_CONSEQUENCE':
          removeConsequence(action.activeTokenId, action.cardId);
          break;
        case 'ADD_STATUS':
          // Cast statusType to the expected union type if needed, or update store to accept string
          // Ideally, BroadcastAction should use the specific union type.
          // For now, we cast to any to avoid strict type mismatch if store expects specific string literals
          addStatus(action.activeTokenId, action.statusType as any, action.destination);
          break;
        case 'REMOVE_STATUS':
          removeStatus(action.activeTokenId, action.statusType as any);
          break;
        default:
          assertUnreachable(action);
      }
    }
  }, [lastMessage, clientId, commitPlan, playImmediate, passTurn, revealAndResolve, endRound, updateTokenPosition, drawCards, defend, clearDefense, reshuffle, addConsequence, removeConsequence, addStatus, removeStatus]);
};
