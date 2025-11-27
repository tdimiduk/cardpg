import React, { useEffect } from 'react';
import { DeckCard, ResourceType, PlayerDeckState } from './types';
import { MapBoard } from './components/MapBoard';
import { SidebarLeft } from './components/SidebarLeft';
import { SidebarRight } from './components/SidebarRight';
import { PlayerHand } from './components/PlayerHand';
import { useGameStore } from './store/gameStore';

const App: React.FC = () => {
  // --- Store Hooks ---
  const { 
      tokens, 
      logs, 
      phase, 
      activeTokenId, 
      plannedActions, 
      decks, 
      dispatch 
  } = useGameStore();

  // Initialize Game on Mount
  useEffect(() => {
      // Only initialize if decks are empty (prevents double init in strict mode dev)
      if (Object.keys(decks).length === 0) {
          dispatch({ type: 'INITIALIZE_GAME' });
      }
  }, []);

  const currentDeck = activeTokenId ? decks[activeTokenId] : null;

  // --- Helpers ---
  
  // Calculate defeated for visualization
  const defeatedTokenIds = Object.entries(decks)
      .filter(([_, deck]) => (deck as PlayerDeckState).consequences.some(c => c.name === 'Taken Out'))
      .map(([id, _]) => id);

  const activeAction = activeTokenId ? plannedActions[activeTokenId] : undefined;
  const isActionPlanned = (action?: { cards: DeckCard[], actionName?: string }) => !!action && (action.cards.length > 0 || action.actionName === 'Pass');
  const userHasPlannedAction = isActionPlanned(activeAction);
  const readyCount = Object.values(plannedActions).filter(isActionPlanned).length;

  // --- Handlers (Dispatches) ---

  const handlePlayStack = (selectedCards: DeckCard[], strengthColor: ResourceType, modifier: number, targetDefense?: ResourceType, actionName?: string) => {
      if (!activeTokenId) return;
      
      if (phase === 'planning') {
          dispatch({ 
              type: 'COMMIT_PLAN', 
              tokenId: activeTokenId, 
              cards: selectedCards, 
              strengthColor, 
              modifier, 
              actionName, 
              targetDefense 
          });
      } else {
          dispatch({ 
              type: 'PLAY_IMMEDIATE', 
              tokenId: activeTokenId, 
              cards: selectedCards, 
              strengthColor, 
              modifier, 
              actionName, 
              targetDefense 
          });
      }
  };

  const handlePass = () => {
      if (!activeTokenId || phase !== 'planning') return;
      dispatch({ type: 'PASS_TURN', tokenId: activeTokenId });
  };

  return (
    <div className="flex h-screen w-screen bg-slate-950 text-slate-200 font-sans overflow-hidden">
      <SidebarLeft 
        deckState={currentDeck}
        onDraw={(count) => activeTokenId && dispatch({ type: 'DRAW_CARDS', tokenId: activeTokenId, count })}
        onDefend={() => activeTokenId && dispatch({ type: 'DEFEND', tokenId: activeTokenId })}
        onClearDefense={() => activeTokenId && dispatch({ type: 'CLEAR_DEFENSE', tokenId: activeTokenId })}
        onReshuffle={() => activeTokenId && dispatch({ type: 'RESHUFFLE', tokenId: activeTokenId })}
        onSelectToken={(id) => dispatch({ type: 'SET_ACTIVE_TOKEN', tokenId: id })}
        onAddConsequence={() => activeTokenId && dispatch({ type: 'ADD_CONSEQUENCE', tokenId: activeTokenId })}
        onRemoveConsequence={(cardId) => activeTokenId && dispatch({ type: 'REMOVE_CONSEQUENCE', tokenId: activeTokenId, cardId })}
        onAddStatusCard={(statusType, destination) => activeTokenId && dispatch({ type: 'ADD_STATUS', tokenId: activeTokenId, statusType, destination })}
        onRemoveStatusCard={(statusType) => activeTokenId && dispatch({ type: 'REMOVE_STATUS', tokenId: activeTokenId, statusType })}
        tokens={tokens}
        activeToken={tokens.find(t => t.id === activeTokenId)}
        activeTokenId={activeTokenId || ''}
        hasPlannedAction={userHasPlannedAction}
      />

      <main className="flex-1 flex flex-col relative overflow-hidden shadow-inner bg-slate-900">
        <div className="absolute top-4 left-4 z-10 pointer-events-none">
            <div className="bg-slate-900/80 backdrop-blur border border-slate-700 px-4 py-2 rounded-full text-xs text-slate-400 shadow-lg flex items-center gap-4">
                <span>Grid: 64px</span>
                <span className={`font-bold ${phase === 'planning' ? 'text-blue-400' : 'text-red-400'}`}>
                    Phase: {phase.toUpperCase()}
                </span>
            </div>
        </div>

        <MapBoard 
            tokens={tokens} 
            onUpdateToken={(token) => dispatch({ type: 'UPDATE_TOKEN_POSITION', token })}
            activeTokenId={activeTokenId}
            setActiveTokenId={(id) => dispatch({ type: 'SET_ACTIVE_TOKEN', tokenId: id })}
            plannedActions={plannedActions}
            defeatedTokenIds={defeatedTokenIds}
        />

        {currentDeck && (
            <PlayerHand 
                hand={currentDeck.hand}
                onPlayStack={handlePlayStack}
                onDiscard={(cards) => activeTokenId && dispatch({ type: 'DISCARD_CARDS', tokenId: activeTokenId, cardIds: cards.map(c => c.id) })}
                onPass={handlePass}
                onCancelPlan={() => activeTokenId && dispatch({ type: 'CANCEL_PLAN', tokenId: activeTokenId })}
                onReturnToDeck={(cards) => activeTokenId && dispatch({ type: 'RETURN_TO_DECK', tokenId: activeTokenId, cardIds: cards.map(c => c.id) })}
                phase={phase}
                hasPlanned={userHasPlannedAction}
                plannedAction={activeAction}
            />
        )}
      </main>

      <SidebarRight 
        logs={logs} 
        onAddLog={(log) => dispatch({ type: 'ADD_LOG', message: log.content, sender: log.sender, logType: log.type })}
        tokens={tokens}
        phase={phase}
        onRevealActions={() => dispatch({ type: 'REVEAL_AND_RESOLVE' })}
        onEndRound={() => dispatch({ type: 'END_ROUND' })}
        readyCount={readyCount}
        totalCount={tokens.length}
      />
    </div>
  );
};

export default App;