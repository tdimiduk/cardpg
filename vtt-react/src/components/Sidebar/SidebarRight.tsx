import React, { useState, useEffect, useRef, useMemo } from 'react';
import { LogEntry, Phase, LogPayload, CoreCard, RealizedAttack } from '../../generated/types';
// TODO: Replace lucide icons if needed, or keep them
import { Send, Bot, Square, ArrowRight, Play, Rewind } from 'lucide-react';
import { useGameStore } from '../../store/gameStore';
import { useGameDispatch } from '../../hooks/useGameDispatch';
import { StackViewerModal } from './StackViewerModal';
import { DefenseModalCard } from './DefenseModal';
import { WithId, selectReadiness } from '../../store/selectors';
import { Card } from '../Card/Card';

// Helper type for cards in stack view - use the same Card type as CardComponent
type StackCard = WithId<Card>;

// --- View ---
// --- View ---
export interface SidebarRightProps {
  logs: LogEntry[];
  phase: Phase;
  onRevealActions: () => void;
  onEndRound: () => void;
  readyCount?: number;
  totalCount?: number;
  onEndDefense: (actorId: string) => void;
  onSendChat: (message: string) => void;
  onResetGame: () => void;
  onOpenDefense: (attack: RealizedAttack, stack: DefenseModalCard[]) => void;
}

const AttackLogItem: React.FC<{
  log: LogEntry;
  payload: Extract<LogPayload, { type: 'logAttack' }>;
  onOpenDefense: (attack: RealizedAttack, stack: DefenseModalCard[]) => void;
}> = ({ log, payload, onOpenDefense }) => {
  // ... (AttackLogItem implementation remains mostly same, just updating context around it if needed)
  const actorId = log.senderId;
  const attack = payload.attack;
  const resourceCardIds = payload.resourceCardIds;

  const actorName = useGameStore((state) =>
    actorId ? state.actors[actorId]?.name || 'Unknown' : 'Unknown',
  );
  // Registry is in coreState now
  const registry = useGameStore((state) =>
    actorId ? state.actors[actorId]?.coreState.registry : {},
  );

  // Resolve cards
  const attackCardDef = attack && registry ? registry[attack.attackCard] : undefined;
  const attackCard: StackCard | undefined =
    attackCardDef && attack ? { ...attackCardDef, id: attack.attackCard } : undefined;

  const stackCards = useMemo(() => {
    const cards: StackCard[] = [];
    if (attackCard) cards.push(attackCard);

    if (resourceCardIds && registry) {
      resourceCardIds.forEach((id) => {
        const def = registry[id];
        if (def) cards.push({ ...def, id });
      });
    }
    return cards;
  }, [attackCard, resourceCardIds, registry]);

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (attack) {
      onOpenDefense(attack, stackCards);
    }
  };

  if (!attack) return null;

  return (
    <div
      onClick={handleClick}
      className="bg-red-950/30 border border-red-900/50 rounded p-3 mb-2 animate-fade-in cursor-pointer hover:bg-red-900/40 hover:shadow-md transition-all group"
    >
      <div className="flex justify-between items-start mb-1">
        <div className="text-xs font-bold text-red-300 flex items-center gap-1">
          <Square size={12} className="fill-red-500 text-red-500" />
          <span>Attack Action</span>
        </div>
      </div>

      <div className="space-y-1 mb-2">
        {stackCards.map((card, idx) => (
          <div
            key={card.id || idx}
            className="text-white font-bold text-sm bg-black/20 rounded px-2 py-1 flex items-center gap-2"
          >
            <span>{card.name}</span>
            {idx === 0 && (
              <span className="text-[10px] text-red-300 uppercase bg-red-950/50 px-1 rounded">
                Core
              </span>
            )}
          </div>
        ))}
      </div>

      <div className="text-xs text-slate-400 mb-2">By: {actorName}</div>

      <div className="flex items-center gap-2 text-sm bg-black/40 rounded p-1 mb-1">
        <span className="font-bold text-red-400">Power: {attack.attackStrength}</span>
        <ArrowRight size={12} className="text-slate-500" />
        <span className="text-slate-300">VS</span>
        <span
          className={`font-bold ${
            attack.defenseColor === 'red'
              ? 'text-red-400'
              : attack.defenseColor === 'blue'
                ? 'text-blue-400'
                : 'text-yellow-400'
          }`}
        >
          {attack.defenseColor.toUpperCase()}
        </span>
      </div>
    </div>
  );
};
// ... (DefenseLogItem is separate, not included in this replacement chunk unless I need to start earlier)

// Skipping DefenseLogItem in replacement to keep it small, targeting SidebarRightProps and after DefenseLogItem.
// The snippet above included AttackLogItem which is bulky.
// Let's try to target just generic props and the wrapper.

const DefenseLogItem: React.FC<{
  log: LogEntry;
  payload: Extract<LogPayload, { type: 'logDefense' }>;
  onEndDefense: () => void;
  onViewStack: (cards: StackCard[], title: string) => void;
}> = ({ payload, onEndDefense, onViewStack }) => {
  const actorId = payload.defenseActorId;
  const isEnded = payload.ended;

  // Registry for resolving snapshotIds and live cards
  const registry = useGameStore((state) =>
    actorId ? state.actors[actorId]?.coreState.registry : {},
  );

  // If active, pull live data (hydrated cards from deck.flippedPile).
  // In generated types, deck is part of coreState.
  const flippedPile = useGameStore(
    (state) => (actorId && !isEnded ? state.actors[actorId]?.coreState.defending : undefined), // defending is the new name for flippedPile in server state? NO, check generated types.
    // generated types: ActorState -> coreState -> defending: CardInstanceId[]
  );

  // flippedPile is string[] (IDs). Need to hydrate.
  const stackCards = useMemo(() => {
    if (!flippedPile || !registry) return undefined;
    return flippedPile
      .map((id) => {
        const card = registry[id];
        return card ? { ...card, id } : undefined;
      })
      .filter((c): c is CoreCard & { id: string } => !!c);
  }, [flippedPile, registry]);

  const liveCards = useMemo(() => (stackCards ? stackCards.map((c) => c.name) : []), [stackCards]);
  const actorName = useGameStore((state) =>
    actorId ? state.actors[actorId]?.name || 'Unknown' : 'Unknown',
  );

  const displayCards = isEnded ? payload.snapshot || [] : liveCards;
  const impact = displayCards.length;

  const handleViewStack = (e: React.MouseEvent) => {
    e.stopPropagation();
    let cardsToView: StackCard[] = [];

    if (!isEnded && stackCards) {
      cardsToView = stackCards;
    } else if (isEnded && payload.snapshot && registry) {
      // Snapshot is strings (names), we cannot resolve full cards easily without IDs.
      // So view stack is disabled or limited for ended defense.
    }

    if (cardsToView.length > 0) {
      onViewStack(cardsToView, `${actorName}'s Defense Stack`);
    }
  };

  return (
    <div
      onClick={handleViewStack}
      className={`border rounded p-3 mb-2 animate-fade-in group cursor-pointer transition-all hover:shadow-md ${
        !isEnded
          ? 'bg-indigo-950/30 border-indigo-900/50 hover:bg-indigo-900/40'
          : 'bg-slate-900/50 border-slate-800 opacity-75 grayscale hover:opacity-100 hover:grayscale-0'
      }`}
    >
      <div className="flex justify-between items-start mb-1">
        <div
          className={`text-xs font-bold flex items-center gap-1 ${
            !isEnded ? 'text-indigo-300' : 'text-slate-500'
          }`}
        >
          <div
            className={`w-2 h-2 rounded-full ${
              !isEnded ? 'bg-indigo-500 animate-pulse' : 'bg-slate-600'
            }`}
          />
          {!isEnded ? 'Active Defense' : 'Defense Ended'}
        </div>
        {!isEnded && (
          <button
            onClick={(e) => {
              e.stopPropagation();
              onEndDefense();
            }}
            className="text-[10px] bg-indigo-900 hover:bg-indigo-800 text-indigo-200 px-2 py-0.5 rounded border border-indigo-700/50 transition-colors z-10 relative"
          >
            End
          </button>
        )}
      </div>

      <div className="text-white font-bold mb-2">{actorName}</div>

      <div className="text-xs space-y-1">
        <div className="flex justify-between text-slate-400">
          <span>Impact (Cards):</span>
          <span className="text-white font-mono">{impact}</span>
        </div>
        {displayCards.length > 0 && (
          <div className="mt-2 text-indigo-200/80 italic border-l-2 border-indigo-500/30 pl-2">
            {displayCards.map((card: string, idx: number) => (
              <div key={idx}>{card}</div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export const SidebarRightView: React.FC<SidebarRightProps> = ({
  logs,
  phase,
  onRevealActions,
  onEndRound,
  readyCount,
  totalCount,
  onEndDefense,
  onSendChat,
  onResetGame,
  onOpenDefense,
}) => {
  const [chatInput, setChatInput] = useState('');
  const endOfLogsRef = useRef<HTMLDivElement>(null);
  const [stackViewer, setStackViewer] = useState<{
    isOpen: boolean;
    cards: StackCard[];
    title: string;
  }>({ isOpen: false, cards: [], title: '' });

  const handleOpenStack = (cards: StackCard[], title: string) => {
    setStackViewer({ isOpen: true, cards, title });
  };

  useEffect(() => {
    endOfLogsRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [logs]);

  const handleSendChat = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!chatInput.trim()) return;

    onSendChat(chatInput);
    setChatInput('');
  };

  const allReady = readyCount !== undefined && totalCount !== undefined && readyCount >= totalCount;

  return (
    <div className="w-80 bg-slate-950 border-l border-slate-800 flex flex-col h-full z-20">
      <StackViewerModal
        isOpen={stackViewer.isOpen}
        onClose={() => setStackViewer((prev) => ({ ...prev, isOpen: false }))}
        cards={stackViewer.cards}
        title={stackViewer.title}
      />

      {/* Phase Control Panel */}
      <div className="p-4 bg-slate-900 border-b border-slate-800">
        <div className="flex justify-between items-center mb-2">
          <span className="text-xs font-bold text-slate-500 uppercase">Phase Control</span>
          <span
            className={`text-xs font-bold px-2 py-0.5 rounded ${phase === 'planning' ? 'bg-blue-900/50 text-blue-300' : 'bg-red-900/50 text-red-300'}`}
          >
            {phase.toUpperCase()}
          </span>
        </div>

        {phase === 'planning' ? (
          <button
            onClick={onRevealActions}
            disabled={!allReady}
            className={`w-full flex items-center justify-center gap-2 font-bold py-2 rounded shadow transition-all
                    ${
                      allReady
                        ? 'bg-blue-600 hover:bg-blue-500 text-white'
                        : 'bg-slate-800 text-slate-500 cursor-not-allowed'
                    }`}
          >
            <Play size={16} fill="currentColor" />
            {allReady ? 'Reveal Actions' : `Reveal (${readyCount ?? 0}/${totalCount ?? 0} Ready)`}
          </button>
        ) : (
          <div className="space-y-2">
            <button
              onClick={onEndRound}
              className="w-full flex items-center justify-center gap-2 bg-slate-700 hover:bg-slate-600 text-slate-200 font-bold py-2 rounded shadow transition-all"
            >
              <Rewind size={16} fill="currentColor" /> End Round
            </button>
          </div>
        )}
      </div>

      {/* Chat Log */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 custom-scrollbar">
        {logs.map((log, index) => {
          const payload = log.payload;

          if (payload.type === 'logDefense') {
            return (
              <DefenseLogItem
                key={`${log.id}-${index}`}
                log={log}
                payload={payload}
                onEndDefense={() => onEndDefense(payload.defenseActorId)}
                onViewStack={handleOpenStack}
              />
            );
          }

          if (payload.type === 'logAttack') {
            return (
              <AttackLogItem
                key={`${log.id}-${index}`}
                log={log}
                payload={payload}
                onOpenDefense={onOpenDefense}
              />
            );
          }

          const content = 'content' in payload ? payload.content : '';
          const isChat = payload.type === 'logChat';
          const isInfo = payload.type === 'logInfo';

          return (
            <div key={`${log.id}-${index}`} className="flex flex-col gap-1 animate-fade-in">
              <div className="flex items-center gap-2">
                <span
                  className={`text-xs font-bold ${
                    log.sender === 'AI'
                      ? 'text-indigo-400'
                      : log.sender === 'System'
                        ? 'text-slate-500'
                        : log.sender === 'GM'
                          ? 'text-yellow-500'
                          : 'text-emerald-400'
                  }`}
                >
                  {log.sender === 'AI' && <Bot size={12} className="inline mr-1" />}
                  {log.sender}
                </span>
                <span className="text-[10px] text-slate-600">
                  {new Date(log.timestamp).toLocaleTimeString()}
                </span>
              </div>

              <div
                className={`text-sm rounded p-2 ${
                  !isInfo && !isChat
                    ? 'bg-slate-800 border border-slate-600'
                    : isInfo
                      ? 'text-slate-500 italic'
                      : log.sender === 'AI'
                        ? 'bg-indigo-950/30 border border-indigo-900/50 text-indigo-100'
                        : 'text-slate-300 bg-slate-900/50'
                }`}
              >
                {content}
              </div>
            </div>
          );
        })}
        <div ref={endOfLogsRef} />
      </div>

      {/* Input Area */}
      <form onSubmit={handleSendChat} className="p-3 bg-slate-900 border-t border-slate-800">
        <div className="relative">
          <input
            type="text"
            value={chatInput}
            onChange={(e) => setChatInput(e.target.value)}
            placeholder="Say something..."
            className="w-full bg-slate-950 text-slate-200 border border-slate-700 rounded pl-3 pr-10 py-2 text-sm focus:outline-none focus:border-indigo-500 transition-colors"
          />
          <button
            type="submit"
            className="absolute right-2 top-1/2 transform -translate-y-1/2 text-slate-500 hover:text-indigo-400"
          >
            <Send size={16} />
          </button>
        </div>
      </form>

      {/* Admin Controls */}
      <div className="p-2 border-t border-slate-800 bg-slate-950/50">
        <button
          onClick={() => {
            if (confirm('Are you sure you want to reset the game? This cannot be undone.')) {
              onResetGame();
            }
          }}
          className="w-full text-xs text-red-500/70 hover:text-red-400 hover:bg-red-950/30 py-1.5 rounded transition-all flex items-center justify-center gap-2"
        >
          <span>⚠ Reset Game (Admin)</span>
        </button>
      </div>
    </div>
  );
};

// --- Container ---

interface SidebarRightContainerProps {
  onOpenDefense: (attack: RealizedAttack, stack: DefenseModalCard[]) => void;
}

const SidebarRightContainer: React.FC<SidebarRightContainerProps> = ({ onOpenDefense }) => {
  const logs = useGameStore((state) => state.logs);
  const phase = useGameStore((state) => state.phase);
  const activeActorId = useGameStore((state) => state.activeActorId);
  const actors = useGameStore((state) => state.actors);

  const { dispatchCommand, dispatchAdmin } = useGameDispatch();

  const readyCount = useGameStore(selectReadiness);
  const totalCount = Object.keys(actors).length;

  // Handlers
  const handleRevealActions = () => {
    if (activeActorId) {
      dispatchCommand({ type: 'startResolutionIntent', actorId: activeActorId });
    } else {
      // Fallback: pick first actor
      const firstId = Object.keys(actors)[0];
      if (firstId) dispatchCommand({ type: 'startResolutionIntent', actorId: firstId });
    }
  };

  const handleEndRound = () => {
    if (activeActorId) {
      dispatchCommand({ type: 'endRoundIntent', actorId: activeActorId });
    } else {
      const firstId = Object.keys(actors)[0];
      if (firstId) dispatchCommand({ type: 'endRoundIntent', actorId: firstId });
    }
  };

  const handleEndDefense = (actorId: string) => {
    dispatchCommand({ type: 'endDefenseIntent', actorId });
  };

  const handleSendChat = (message: string) => {
    dispatchCommand({
      type: 'chatIntent',
      chatSenderId: activeActorId || undefined,
      content: message,
    });
  };

  const handleResetGame = () => {
    dispatchAdmin('resetGame');
  };

  return (
    <SidebarRightView
      logs={logs}
      phase={phase}
      onRevealActions={handleRevealActions}
      onEndRound={handleEndRound}
      readyCount={readyCount}
      totalCount={totalCount}
      onEndDefense={handleEndDefense}
      onSendChat={handleSendChat}
      onResetGame={handleResetGame}
      onOpenDefense={onOpenDefense}
    />
  );
};

export default SidebarRightContainer;
