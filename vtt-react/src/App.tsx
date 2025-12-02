import React, { useEffect } from 'react';
import { CoreCard, ResourceType } from './types';
import { MapBoard } from './components/Game/MapBoard';
import { SidebarLeft } from './components/Sidebar/SidebarLeft';
import { SidebarRight } from './components/Sidebar/SidebarRight';
import { PlayerHand } from './components/Player/PlayerHand';
import { useGameStore } from './store/gameStore';
import { useWebSocket } from './contexts/WebSocketContext';
import { useGameSync } from './hooks/useGameSync';

const App: React.FC = () => {
  // --- Store Hooks ---
  const actors = useGameStore((state) => state.actors);
  const tokens = useGameStore((state) => state.tokens);
  const logs = useGameStore((state) => state.logs);
  const phase = useGameStore((state) => state.phase);
  const activeTokenId = useGameStore((state) => state.activeTokenId);
  const plannedActions = useGameStore((state) => state.plannedActions);

  // Actions
  const initializeGame = useGameStore((state) => state.initializeGame);
  const setActiveToken = useGameStore((state) => state.setActiveToken);
  const updateTokenPosition = useGameStore((state) => state.updateTokenPosition);
  const addLog = useGameStore((state) => state.addLog);

  // Actor Actions
  const addActor = useGameStore((state) => state.addActor);
  const removeActor = useGameStore((state) => state.removeActor);
  const drawCards = useGameStore((state) => state.drawCards);
  const defend = useGameStore((state) => state.defend);
  const clearDefense = useGameStore((state) => state.clearDefense);
  const reshuffle = useGameStore((state) => state.reshuffle);
  const discardCards = useGameStore((state) => state.discardCards);
  const returnToDeck = useGameStore((state) => state.returnToDeck);
  const addConsequence = useGameStore((state) => state.addConsequence);
  const removeConsequence = useGameStore((state) => state.removeConsequence);
  const addStatus = useGameStore((state) => state.addStatus);
  const removeStatus = useGameStore((state) => state.removeStatus);

  // Game Actions
  const commitPlan = useGameStore((state) => state.commitPlan);
  const cancelPlan = useGameStore((state) => state.cancelPlan);
  const passTurn = useGameStore((state) => state.passTurn);
  const revealAndResolve = useGameStore((state) => state.revealAndResolve);
  const endRound = useGameStore((state) => state.endRound);
  const playImmediate = useGameStore((state) => state.playImmediate);

  // Initialize Game on Mount
  useEffect(() => {
    // Check if game needs initialization (if first actor has no cards)
    const needsInit = Object.values(actors).some(
      (a) =>
        a.deck.drawPile.length === 0 &&
        a.deck.hand.length === 0 &&
        a.deck.discardPile.length === 0 &&
        a.deck.equipped.length === 0,
    );

    if (needsInit) {
      initializeGame();
    }
  }, []);

  const activeToken = activeTokenId ? tokens.find((t) => t.id === activeTokenId) : null;
  const activeActor = activeToken ? actors[activeToken.actorId] : null;
  const currentDeck = activeActor?.deck;

  // --- Helpers ---

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
  // --- WebSocket Integration ---
  const { sendMessage, clientId } = useWebSocket();
  useGameSync();

  // --- Handlers ---

  const handlePlayStack = (
    selectedCards: CoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
  ) => {
    if (!activeTokenId) return;

    // Send to server
    sendMessage({
      tag: 'Broadcast',
      payload: {
        type: 'PLAY_STACK',
        activeTokenId,
        selectedCards,
        strengthColor,
        modifier,
        targetDefense,
        actionName,
        phase,
      },
    });

    if (phase === 'planning') {
      commitPlan(activeTokenId, selectedCards, strengthColor, modifier, actionName, targetDefense);
    } else {
      playImmediate(
        activeTokenId,
        selectedCards,
        strengthColor,
        modifier,
        actionName,
        targetDefense,
      );
    }
  };

  const handlePass = () => {
    if (!activeTokenId || phase !== 'planning') return;

    sendMessage({
      tag: 'Broadcast',
      payload: {
        type: 'PASS',
        activeTokenId,
      },
    });

    passTurn(activeTokenId);
  };

  return (
    <div className="flex h-screen w-screen bg-slate-950 text-slate-200 font-sans overflow-hidden">
      <SidebarLeft
        deckState={currentDeck}
        onDraw={(count) => {
          if (!activeTokenId) return;
          sendMessage({ tag: 'Broadcast', payload: { type: 'DRAW_CARDS', activeTokenId, count } });
          drawCards(activeTokenId, count);
        }}
        onDefend={() => {
          if (!activeTokenId) return;
          sendMessage({ tag: 'Broadcast', payload: { type: 'DEFEND', activeTokenId } });
          defend(activeTokenId);
        }}
        onClearDefense={() => {
          if (!activeTokenId) return;
          sendMessage({ tag: 'Broadcast', payload: { type: 'CLEAR_DEFENSE', activeTokenId } });
          clearDefense(activeTokenId);
        }}
        onReshuffle={() => {
          if (!activeTokenId) return;
          sendMessage({ tag: 'Broadcast', payload: { type: 'RESHUFFLE', activeTokenId } });
          reshuffle(activeTokenId);
        }}
        onSelectToken={(id) => setActiveToken(id)}
        onAddConsequence={() => {
          if (!activeTokenId) return;
          sendMessage({ tag: 'Broadcast', payload: { type: 'ADD_CONSEQUENCE', activeTokenId } });
          addConsequence(activeTokenId);
        }}
        onRemoveConsequence={(cardId) => {
          if (!activeTokenId) return;
          sendMessage({
            tag: 'Broadcast',
            payload: { type: 'REMOVE_CONSEQUENCE', activeTokenId, cardId },
          });
          removeConsequence(activeTokenId, cardId);
        }}
        onAddStatusCard={(statusType, destination) => {
          if (!activeTokenId) return;
          sendMessage({
            tag: 'Broadcast',
            payload: { type: 'ADD_STATUS', activeTokenId, statusType, destination },
          });
          addStatus(activeTokenId, statusType, destination);
        }}
        onRemoveStatusCard={(statusType) => {
          if (!activeTokenId) return;
          sendMessage({
            tag: 'Broadcast',
            payload: { type: 'REMOVE_STATUS', activeTokenId, statusType },
          });
          removeStatus(activeTokenId, statusType);
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
            sendMessage({ tag: 'Broadcast', payload: { type: 'MOVE_TOKEN', token } });
            updateTokenPosition(token);
          }}
          activeTokenId={activeTokenId}
          setActiveTokenId={(id) => setActiveToken(id)}
          plannedActions={plannedActions}
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
              discardCards(
                activeTokenId,
                cards.map((c) => c.id),
              )
            }
            onPass={handlePass}
            onCancelPlan={() => activeTokenId && cancelPlan(activeTokenId)}
            onReturnToDeck={(cards) =>
              activeTokenId &&
              returnToDeck(
                activeTokenId,
                cards.map((c) => c.id),
              )
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
          sendMessage({ tag: 'Broadcast', payload: { type: 'REVEAL' } });
          revealAndResolve();
        }}
        onEndRound={() => {
          sendMessage({ tag: 'Broadcast', payload: { type: 'END_ROUND' } });
          endRound();
        }}
        readyCount={readyCount}
        totalCount={tokens.length}
      />
    </div>
  );
};

export default App;
