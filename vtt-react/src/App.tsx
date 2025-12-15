import React, { useEffect } from 'react';
import { ActorState, CoreCard, ResourceType } from './types';
import { MapBoard } from './components/Game/MapBoard';
import { SidebarLeft } from './components/Sidebar/SidebarLeft';
import { SidebarRight } from './components/Sidebar/SidebarRight';
import { PlayerHand } from './components/Player/PlayerHand';
import { useGameStore } from './store/gameStore';
import { useWebSocket } from './contexts/WebSocketContext';
import { useGameSync } from './hooks/useGameSync';
import { useGameDispatch } from './hooks/useGameDispatch';

const App: React.FC = () => {
  // --- Store Hooks ---
  const phase = useGameStore((state) => state.phase);
  const plannedActions = useGameStore((state) => state.plannedActions);
  const tokens = useGameStore((state) => state.tokens);
  const actors = useGameStore((state) => state.actors);
  const logs = useGameStore((state) => state.logs);
  const activeActorId = useGameStore((state) => state.activeActorId);
  const currentResolution = useGameStore((state) => state.currentResolution);

  // Actions
  const setActiveActor = useGameStore((state) => state.setActiveActor);
  const addActor = useGameStore((state) => state.addActor);
  const removeActor = useGameStore((state) => state.removeActor);
  const addLog = useGameStore((state) => state.addLog);
  const initializeGame = useGameStore((state) => state.initializeGame);

  // Initialize Game on Mount
  useEffect(() => {
    // Only initialize if we have no actors (fresh load)
    // Actually, INITIAL_ACTORS populates actors, so this check might be false if constants exist.
    // But initializeGame populates decks.
    // Check if decks are empty (need initialization)
    const needsInit = Object.values(actors).some(
      (a: ActorState) => a.deck.hand.length === 0 && a.deck.drawPile.length === 0,
    );

    if (needsInit) {
      initializeGame();
    }
  }, []);

  // --- Helpers ---
  const activeToken = activeActorId ? tokens.find((t) => t.actorId === activeActorId) : null;
  const activeActor = activeActorId ? actors[activeActorId] : null;
  const currentDeck = activeActor?.deck;

  // Calculate defeated for visualization
  const defeatedTokenIds = Object.values(actors)
    .filter((actor) => actor.deck.consequences.some((c) => c.name === 'Taken Out'))
    .flatMap((actor) => tokens.filter((t) => t.actorId === actor.id).map((t) => t.id));

  const activeAction = activeActorId && activeToken ? plannedActions[activeActorId] : undefined;
  const isActionPlanned = (action?: { cards: CoreCard[]; actionName?: string }) =>
    !!action && (action.cards.length > 0 || action.actionName === 'Pass');
  const userHasPlannedAction = isActionPlanned(activeAction);
  const readyCount = Object.values(plannedActions).filter(isActionPlanned).length;

  // --- WebSocket Integration ---
  useWebSocket();
  useGameSync();
  const { dispatchCommand } = useGameDispatch();

  // --- Handlers ---

  const handlePlayStack = (
    selectedCards: CoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
    actionCardId?: string,
  ) => {
    if (!activeActorId) return;

    if (phase === 'planning') {
      if (selectedCards.length === 0) return;

      // If actionCardId provided, use it. Otherwise try to infer or fallback (e.g. improvise)
      if (actionCardId) {
        const resourceIds = selectedCards.filter((c) => c.id !== actionCardId).map((c) => c.id);
        dispatchCommand({
          type: 'planAction',
          actorId: activeActorId,
          actionCardId: actionCardId,
          resourceCardIds: resourceIds,
        });
      } else {
        // Narrative Action / Improvise
        dispatchCommand({
          type: 'planNarrative',
          actorId: activeActorId,
          cardIds: selectedCards.map((c) => c.id),
          color: strengthColor,
        });
      }
      return;
    }

    // Legacy immediate play dispatch removed.
    // In Server Authoritative mode, actions are Planned then Resolved.
    // If in Resolution phase, manual play is likely disabled or should use PlanAction if supported (e.g. Improvise).
    console.warn('Attempted to play stack in non-planning phase or fallback.');
  };

  return (
    <div className="flex h-screen w-screen bg-slate-950 text-slate-200 font-sans overflow-hidden">
      <SidebarLeft
        deckState={currentDeck}
        onDraw={(_count) => {
          if (!activeActorId) return;
          dispatchCommand({ type: 'drawIntent', actorId: activeActorId });
        }}
        onDefend={() => {
          if (!activeActorId) return;
          dispatchCommand({ type: 'defendIntent', actorId: activeActorId });
        }}
        onClearDefense={() => {
          if (!activeActorId) return;
          dispatchCommand({ type: 'endDefenseIntent', actorId: activeActorId });
        }}
        onReshuffle={() => {
          if (!activeActorId) return;
          dispatchCommand({ type: 'reshuffleIntent', actorId: activeActorId });
        }}
        onSelectToken={(id) => {
          const token = tokens.find((t) => t.id === id);
          if (token) setActiveActor(token.actorId);
        }}
        onAddConsequence={(severity) => {
          if (!activeActorId) return;
          dispatchCommand({
            type: 'addConsequenceIntent',
            actorId: activeActorId,
            severity: severity,
          });
        }}
        onRemoveConsequence={(cardId) => {
          if (!activeActorId) return;
          dispatchCommand({
            type: 'removeConsequenceIntent',
            actorId: activeActorId,
            cardId,
          });
        }}
        onAddStatusCard={(statusType, destination) => {
          if (!activeActorId) return;
          dispatchCommand({
            type: 'addStatusIntent',
            actorId: activeActorId,
            statusType,
            destination,
          });
        }}
        onRemoveStatusCard={(statusType) => {
          if (!activeActorId) return;
          // removeStatusIntent with targetCardId undefined implies remove by type
          dispatchCommand({ type: 'removeStatusIntent', actorId: activeActorId, statusType });
        }}
        tokens={tokens}
        activeToken={activeToken ?? undefined}
        activeActorId={activeActorId || ''}
        hasPlannedAction={userHasPlannedAction}
        actors={actors}
        onAddActor={(name, type, color, templateId) => addActor(name, type, color, templateId)}
        onRemoveActor={(actorId) => removeActor(actorId)}
      />

      <main className="flex-1 flex flex-col relative overflow-hidden shadow-inner bg-slate-900">
        <div className="absolute top-4 left-4 z-10 pointer-events-none">
          <div className="bg-slate-900/80 backdrop-blur border border-slate-700 px-4 py-2 rounded-full text-xs text-slate-400 shadow-lg flex items-center gap-4">
            <span>Grid: 64px</span>
            <span
              className={`font-bold ${phase === 'planning' ? 'text-blue-400' : 'text-red-400'}`}
            >
              Phase: {phase.toUpperCase()}
            </span>
          </div>
        </div>

        <MapBoard
          tokens={tokens}
          onUpdateToken={(token) => {
            if (token.actorId) {
              dispatchCommand({ type: 'planMove', actorId: token.actorId, x: token.x, y: token.y });
            }
          }}
          activeActorId={activeActorId}
          setActiveActorId={(id) => setActiveActor(id)}
          defeatedTokenIds={defeatedTokenIds}
          actors={actors}
        />

        {currentDeck && (
          <PlayerHand
            key={activeActorId}
            hand={currentDeck.hand}
            onPlayStack={handlePlayStack}
            onDiscard={(cards) =>
              activeActorId &&
              dispatchCommand({
                type: 'discardCardsIntent',
                actorId: activeActorId,
                cardIds: cards.map((c) => c.id),
              })
            }
            onPass={() => {
              if (!activeActorId) return;
              dispatchCommand({ type: 'passIntent', actorId: activeActorId });
            }}
            onCancelPlan={() =>
              activeActorId && dispatchCommand({ type: 'cancelPlanIntent', actorId: activeActorId })
            }
            onReturnToDeck={(cards) =>
              activeActorId &&
              dispatchCommand({
                type: 'returnToDeckIntent',
                actorId: activeActorId,
                cardIds: cards.map((c) => c.id),
              })
            }
            phase={phase}
            hasPlanned={userHasPlannedAction}
            plannedAction={activeAction}
          />
        )}
      </main>

      <SidebarRight
        logs={logs}
        onAddLog={(log) => addLog(log.content, log.sender, log.type)}
        phase={phase}
        onRevealActions={() => {
          // Assuming activeActorId is the "Actor" triggering this, or any valid ID.
          // If no active token, we might need a fallback or block.
          if (activeActorId) {
            dispatchCommand({ type: 'startResolutionIntent', actorId: activeActorId });
          } else {
            // Fallback: pick first token? or just fail gracefully?
            const first = tokens[0];
            if (first) dispatchCommand({ type: 'startResolutionIntent', actorId: first.actorId });
          }
        }}
        onEndRound={() => {
          if (activeActorId) {
            dispatchCommand({ type: 'endRoundIntent', actorId: activeActorId });
          } else {
            const first = tokens[0];
            if (first) dispatchCommand({ type: 'endRoundIntent', actorId: first.actorId });
          }
        }}
        readyCount={readyCount}
        totalCount={tokens.length}
        currentResolution={
          currentResolution
            ? {
                ...currentResolution,
                actorName: actors[currentResolution.actorId]?.name || currentResolution.actorId,
                attackCardName: (() => {
                  const actor = actors[currentResolution.actorId];
                  if (!actor) return 'Unknown Card';
                  const cardId = currentResolution.attack.attackCard;
                  const def = actor.registry[cardId];
                  return def?.name || 'Unknown Card';
                })(),
              }
            : null
        }
      />
    </div>
  );
};

export default App;
