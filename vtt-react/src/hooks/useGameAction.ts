import { useCallback } from 'react';
import { useGameStore } from '../store/gameStore';
import { ActorGameEvent, RealizedAttack } from '../generated/types';



/**
 * Hook to apply game actions to the local store.
 *
 * @internal DO NOT USE DIRECTLY. Use useGameDispatch instead to ensure synchronization.
 */
export const useGameAction = () => {
  // Store actions
  const commitPlan = useGameStore((state) => state.commitPlan);
  const cancelPlan = useGameStore((state) => state.cancelPlan);
  const playImmediate = useGameStore((state) => state.playImmediate);
  const passTurn = useGameStore((state) => state.passTurn);
  const revealAndResolve = useGameStore((state) => state.revealAndResolve);
  const endRound = useGameStore((state) => state.endRound);
  const updateTokenPosition = useGameStore((state) => state.updateTokenPosition);
  const addLog = useGameStore((state) => state.addLog);
  const setResolutionPhase = useGameStore((state) => state.setResolutionPhase);
  const setAttackResolution = useGameStore((state) => state.setAttackResolution);

  const _applyAction = useCallback(
    (actorEvent: ActorGameEvent) => {
      const { actorId, event } = actorEvent;

      const resolveName = (id: string) => {
        const state = useGameStore.getState();
        const actors = state.actors || {}; // Safety check
        // Check if actor
        if (actors[id]) return actors[id].name;
        // Check registries
        for (const actor of Object.values(actors)) {
          if (actor.registry && actor.registry[id]) {
            return actor.registry[id].name;
          }
        }
        return id;
      };

      const actorName = actorId ? resolveName(actorId) : 'System';

      switch (event.type) {
        case 'actionRevealed': {
          if (!event.data) break;
          // Haskell tuple/data structure mapping:
          // ActionRevealed PlannedAction RevealedEffect
          // Based on codegen, this might be an array or object?
          // Default codegen for multi-arg constructors usually uses an array if not record syntax?
          // BUT GameEvent uses Record syntax no?
          // data GameEvent = ... | ActionRevealed PlannedAction RevealedEffect
          // This is positional.
          // Typescript will likely generate: { type: 'ActionRevealed', data: [PlannedAction, RevealedEffect] } ??
          // OR if use `genericToJSON`, it might be: { type: 'ActionRevealed', contents: [ ... ] } ??
          // Wait, `cardpgJsonOptions` has `contentsFieldName = "data"`.
          // And `unwrapUnaryRecords = False`.
          // For positional arguments, aeson usually produces an array.
          // Let's assume `event.data` is `[plan, effect]`.
          // I need to verify what `event.data` looks like.
          // If I used Record Syntax in `State.hs` for `ActionRevealed`, it would be an object.
          // But I didn't: `| ActionRevealed PlannedAction RevealedEffect`. This is Positional.
          // So `event.data` is `[plan, effect]`.

          // Correction: `GameEvent` has `cardpgJsonDef`.
          // `ActionRevealed` is a constructor with 2 arguments.
          // `aeson` encodes this as `[arg1, arg2]`.
          // So `event.data` should be `[PlannedAction, RevealedEffect]`.
          
          // However, Typescript generation might generate a tuple type.
          
          // Let's assume safe access.
          const effect = Array.isArray(event.data) ? event.data[1] : undefined;
          
          if (effect && effect.type === 'rEAttack') {
             // Effect data is RealizedAttack
             const attack = effect.data as RealizedAttack;
             setAttackResolution(actorId, attack);
          } else if (effect && effect.type === 'rEPass') {
             passTurn(actorId);
          } else if (effect && effect.type === 'rEInvalid') {
             const msg = effect.data as string;
             addLog(`Invalid Action for ${actorName}: ${msg}`, 'System', 'info');
          }
          
          revealAndResolve(); // Trigger global reveal UI if needed?
          break;
        }
        case 'illegalAction': {
             // data is [plan, maybeReason] or similar?
             // | IllegalAction PlannedAction (Maybe Text)
             const reason = Array.isArray(event.data) ? event.data[1] : 'Unknown reason';
             addLog(`Illegal Action for ${actorName}: ${reason}`, 'System', 'info');
             break;
        }
        case 'cardDrawn':
          addLog(`${actorName} drew a card.`, 'System', 'info');
          break;
        case 'cardDefended':
          addLog(`${actorName} is defending.`, 'System', 'info');
          break;
        case 'defenseEnded':
          addLog(`${actorName} cleared defense.`, 'System', 'info');
          break;
        case 'deckShuffled':
          addLog(`${actorName} reshuffled their deck.`, 'System', 'info');
          break;
        case 'consequenceAdded':
          addLog(`${actorName} gained a consequence.`, 'System', 'info');
          break;
        case 'consequenceRemoved':
             // ConsequenceRemoved Text
             // data is String (Card ID)
          addLog(
            `${actorName} removed consequence "${resolveName(event.data as string)}".`,
            'System',
            'info',
          );
          break;
        case 'statusAdded':
             // StatusAdded Text Text
             // data is [type, destination]
             if (Array.isArray(event.data)) {
                 const [sType, dest] = event.data;
                 addLog(
                    `${actorName} added status "${sType}" to ${resolveName(dest)}.`,
                    'System',
                    'info',
                 );
             }
          break;
        case 'statusRemoved':
             if (Array.isArray(event.data)) {
                 const [sType, dest] = event.data;
                 addLog(
                    `${actorName} removed status "${sType}" from ${resolveName(dest)}.`,
                    'System',
                    'info',
                 );
             }
          break;
        case 'planCanceled':
           // PlanCanceled PlannedAction (from Cancel button or server)
           cancelPlan(actorId);
           break;
        case 'cardsCreated':
        case 'movePlanned':
        case 'actorMoved':
        case 'actionPlanned':
           // Ignore
           break;
        default:
          console.warn('Unhandled event:', event);
      }
    },
    [
      commitPlan,
      playImmediate,
      passTurn,
      revealAndResolve,
      endRound,
      updateTokenPosition,
      cancelPlan,
      addLog,
      setResolutionPhase,
      setAttackResolution,
    ],
  );

  return { _applyAction };
};
