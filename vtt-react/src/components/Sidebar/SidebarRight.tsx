import React, { useState, useEffect, useRef, useMemo } from 'react';
import { LogEntry, Phase, ILogAttack, ILogDefense, Card, CoreCard } from '../../types';
import { RESOURCE_TYPES } from '../../constants';
import { Send, Bot, Square, ArrowRight, Play, Rewind } from 'lucide-react';

import { useGameStore } from '../../store/gameStore';
import { StackViewerModal } from './StackViewerModal';

// Helper type for cards in stack view
type StackCard = Card & { id: string };

interface SidebarRightProps {
  logs: LogEntry[];
  phase: Phase;
  onRevealActions: () => void;
  onEndRound: () => void;
  readyCount?: number;
  totalCount?: number;
  onEndDefense: (actorId: string) => void;
  onSendChat: (message: string) => void;
}

const AttackLogItem: React.FC<{
  log: LogEntry;
  payload: ILogAttack;
  onViewStack: (cards: StackCard[], title: string) => void;
}> = ({ log, payload, onViewStack }) => {
  const actorId = log.senderId;
  const attack = payload.attack;
  const resourceCardIds = payload.resourceCardIds;

  const actorName = useGameStore((state) =>
    actorId ? state.actors[actorId]?.name || 'Unknown' : 'Unknown',
  );
  const registry = useGameStore((state) => (actorId ? state.actors[actorId]?.registry : {}));

  // Resolve cards
  const attackCardDef = attack ? registry[attack.attackCard] : undefined;
  const attackCardName = attackCardDef?.name || 'Unknown Attack';
  const attackCard = attackCardDef ? { ...attackCardDef, id: attack!.attackCard } : undefined;

  const handleViewStack = (e: React.MouseEvent) => {
    e.stopPropagation();
    const cards: StackCard[] = [];
    if (attackCard) cards.push(attackCard);

    if (resourceCardIds) {
      resourceCardIds.forEach((id) => {
        const def = registry[id];
        if (def) cards.push({ ...def, id });
      });
    }

    if (cards.length > 0) {
      onViewStack(cards, `${actorName}'s Attack Stack`);
    }
  };

  if (!attack) return null;

  return (
    <div
      onClick={handleViewStack}
      className="bg-red-950/30 border border-red-900/50 rounded p-3 mb-2 animate-fade-in cursor-pointer hover:bg-red-900/40 hover:shadow-md transition-all group"
    >
      <div className="flex justify-between items-start mb-1">
        <div className="text-xs font-bold text-red-300 flex items-center gap-1">
          <Square size={12} className="fill-red-500 text-red-500" />
          <span>Attack Action</span>
        </div>
      </div>

      <div className="text-white font-bold mb-1">{attackCardName}</div>
      <div className="text-xs text-slate-400 mb-2">By: {actorName}</div>

      <div className="flex items-center gap-2 text-sm bg-black/40 rounded p-1 mb-1">
        <span className="font-bold text-red-400">Power: {attack.attackStrength}</span>
        <ArrowRight size={12} className="text-slate-500" />
        <span className="text-slate-300">VS</span>
        <span
          className={`font-bold ${
            attack.defenseColor === RESOURCE_TYPES.RED
              ? 'text-red-400'
              : attack.defenseColor === RESOURCE_TYPES.BLUE
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

const DefenseLogItem: React.FC<{
  log: LogEntry;
  payload: ILogDefense;
  onEndDefense: () => void;
  onViewStack: (cards: StackCard[], title: string) => void;
}> = ({ payload, onEndDefense, onViewStack }) => {
  const actorId = payload.defenseActorId;
  const isEnded = payload.ended;

  // Registry for resolving snapshotIds and live cards
  const registry = useGameStore((state) => (actorId ? state.actors[actorId]?.registry : {}));

  // If active, pull live data (hydrated cards from deck.flippedPile).
  const flippedPile = useGameStore((state) =>
    actorId && !isEnded ? state.actors[actorId]?.deck.flippedPile : undefined,
  );

  // flippedPile is already CoreCard[], so we just filter for safety
  const stackCards = useMemo(() => {
    if (!flippedPile) return undefined;
    return flippedPile.filter((c) => !!c && !!c.id);
  }, [flippedPile]);

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

export const SidebarRight: React.FC<SidebarRightProps> = ({
  logs,
  phase,
  onRevealActions,
  onEndRound,
  readyCount,
  totalCount,
  onEndDefense,
  onSendChat,
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
        {logs.map((log) => {
          const payload = log.payload;

          if (payload.type === 'logDefense') {
            return (
              <DefenseLogItem
                key={log.id}
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
                key={log.id}
                log={log}
                payload={payload}
                onViewStack={handleOpenStack}
              />
            );
          }

          const content = 'content' in payload ? payload.content : '';
          const isChat = payload.type === 'logChat';
          const isInfo = payload.type === 'logInfo';

          return (
            <div key={log.id} className="flex flex-col gap-1 animate-fade-in">
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
    </div>
  );
};
