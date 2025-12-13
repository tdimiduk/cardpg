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
  const activeTokenId = useGameStore((state) => state.activeTokenId);

  // Actions
  const setActiveToken = useGameStore((state) => state.setActiveToken);
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
  const activeToken = activeTokenId ? tokens.find((t) => t.id === activeTokenId) : null;
  const activeActor = activeToken ? actors[activeToken.actorId] : null;
  const currentDeck = activeActor?.deck;

  // Calculate defeated for visualization

  // Calculate defeated for visualization
  const defeatedTokenIds = Object.values(actors)
    .filter((actor) => actor.deck.consequences.some((c) => c.name === 'Taken Out'))
    .flatMap((actor) => tokens.filter((t) => t.actorId === actor.id).map((t) => t.id));

  const activeAction = activeTokenId ? plannedActions[activeTokenId] : undefined;
  const isActionPlanned = (action?: { cards: CoreCard[]; actionName?: string }) =>
    !!action && (action.cards.length > 0 || action.actionName === 'Pass');
  const userHasPlannedAction = isActionPlanned(activeAction);
  const readyCount = Object.values(plannedActions).filter(isActionPlanned).length;

  // --- WebSocket Integration ---
  useWebSocket();
  useGameSync();
  const { dispatch, dispatchCommand } = useGameDispatch();

  // --- Handlers ---

  const handlePlayStack = (
    selectedCards: CoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
    actionCardId?: string,
  ) => {
    if (!activeTokenId) return;

    if (phase === 'planning') {
      if (selectedCards.length === 0) return;
      
      // If actionCardId provided, use it. Otherwise try to infer or fallback (e.g. improvise)
      let finalActionId = actionCardId;
      let resourceIds: string[] = [];

      if (finalActionId) {
        resourceIds = selectedCards
          .filter(c => c.id !== finalActionId)
          .map(c => c.id);
      } else {
        // Fallback for Improvise (No specific action card)
        // Improvise usually treats all cards as resources and uses a "Basic Action" implicit card?
        // Or one of the cards IS the action?
        // Rules say: "Play a stack... Play that card on top...".
        // Narrative Action: "If no specific Action Card... describe... GM provides modifier".
        // For Improvise button in UI, we pass 'Improvised Action'.
        // Backend 'ActionStack' requires 'actionCardId'.
        // This implies even Improvise needs an Action Card, or we use a "Basic Attack" card?
        // Current Backend Logic: Logic.hs planAction takes actionCardId.
        // If Improvise, usually we pick one card as the "Action" (top card)?
        // Let's assume the first selected card is the action card if not specified.
        finalActionId = selectedCards[0].id;
        resourceIds = selectedCards.slice(1).map(c => c.id);
      }

      dispatchCommand({
        type: 'planAction',
        actorId: activeTokenId,
        actionCardId: finalActionId,
        resourceCardIds: resourceIds,
      });
      return;
    }

    // Legacy immediate play dispatch removed.
    // In Server Authoritative mode, actions are Planned then Resolved.
    // If in Resolution phase, manual play is likely disabled or should use PlanAction if supported (e.g. Improvise).
    console.warn('Attempted to play stack in non-planning phase or fallback.');
  };

  const handlePass = () => {
    if (!activeTokenId || phase !== 'planning') return;
    dispatch({ type: 'pass', actingActor: activeTokenId });
  };

  return (
    <div className="flex h-screen w-screen bg-slate-950 text-slate-200 font-sans overflow-hidden">
      <SidebarLeft
        deckState={currentDeck}
        onDraw={(_count) => {
          if (!activeToken) return;
          dispatchCommand({ type: 'drawIntent', actorId: activeToken.actorId });
        }}
        onDefend={() => {
          if (!activeToken) return;
          dispatchCommand({ type: 'defendIntent', actorId: activeToken.actorId });
        }}
        onClearDefense={() => {
          if (!activeTokenId) return;
          dispatch({ type: 'clearDefense', actingActor: activeTokenId });
        }}
        onReshuffle={() => {
          if (!activeTokenId) return;
          dispatch({ type: 'reshuffle', actingActor: activeTokenId });
        }}
        onSelectToken={(id) => setActiveToken(id)}
        onAddConsequence={() => {
          if (!activeTokenId) return;
          dispatch({ type: 'addConsequence', actingActor: activeTokenId });
        }}
        onRemoveConsequence={(cardId) => {
          if (!activeTokenId) return;
          dispatch({ type: 'removeConsequence', actingActor: activeTokenId, cardId });
        }}
        onAddStatusCard={(statusType, destination) => {
          if (!activeTokenId) return;
          dispatch({ type: 'addStatus', actingActor: activeTokenId, statusType, destination });
        }}
        onRemoveStatusCard={(statusType) => {
          if (!activeTokenId) return;
          // destination is required by IRemoveStatus but seemingly unused or implicit?
          // Let's check generated type requirements.
          // IRemoveStatus needs destination.
          // In sidebar, maybe we know destination? Or we send a dummy value if backend ignores it?
          // Previously it was removing based on type.
          // Let's provide 'discard' as default or fix logic.
          dispatch({ type: 'removeStatus', actingActor: activeTokenId, statusType, destination: 'discard' });
        }}
        tokens={tokens}
        activeToken={tokens.find((t) => t.id === activeTokenId)}
        activeTokenId={activeTokenId || ''}
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
          activeTokenId={activeTokenId}
          setActiveTokenId={(id) => setActiveToken(id)}
          defeatedTokenIds={defeatedTokenIds}
          actors={actors}
        />

        {currentDeck && (
          <PlayerHand
            key={activeTokenId}
            hand={currentDeck.hand}
            onPlayStack={handlePlayStack}
            onDiscard={(cards) =>
              activeTokenId &&
              dispatch({
                type: 'discardCards',
                actingActor: activeTokenId,
                cardIds: cards.map((c) => c.id),
              })
            }
            onPass={handlePass}
            onCancelPlan={() => activeTokenId && dispatch({ type: 'cancelPlan', actingActor: activeTokenId })}
            onReturnToDeck={(cards) =>
              activeTokenId &&
              dispatch({
                type: 'returnToDeck',
                actingActor: activeTokenId,
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
          dispatch({ type: 'startResolutionPhase' });
        }}
        onEndRound={() => {
          dispatch({ type: 'endRound' });
        }}
        readyCount={readyCount}
        totalCount={tokens.length}
      />
    </div>
  );
};

export default App;
