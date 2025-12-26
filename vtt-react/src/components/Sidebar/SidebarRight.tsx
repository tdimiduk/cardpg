import React, { useState, useEffect, useRef, useMemo } from 'react';
import { LogEntry, Phase, LogPayload, CoreCard, ActiveChallenge } from '../../generated/types';
// TODO: Replace lucide icons if needed, or keep them
import { Send, Bot, Square, ArrowRight, Play, Rewind, Shield } from 'lucide-react';
import { useGameStore } from '../../store/gameStore';
import { useGameDispatch } from '../../hooks/useGameDispatch';
import { DefenseModalCard } from './DefenseModal';

// --- View ---
export interface SidebarRightProps {
  logs: LogEntry[];
  phase: Phase;
  onRevealActions: () => void;
  onEndRound: () => void;
  readyCount?: number;
  totalCount?: number;
  onSendChat: (message: string) => void;
  onResetGame: () => void;
  onOpenDefense: (attack: ActiveChallenge, stack: DefenseModalCard[]) => void;
}

const ChallengeLogItem: React.FC<{
  log: LogEntry;
  payload: Extract<LogPayload, { type: 'logChallenge' }>;
  onOpenDefense: (attack: ActiveChallenge, stack: DefenseModalCard[]) => void;
}> = ({ log, payload, onOpenDefense }) => {
  const actorId = log.senderId;
  const challenge = payload.challenge;
  const plannedAction = payload.plannedAction;

  const actorName = useGameStore((state) =>
    actorId ? state.actors[actorId]?.name || 'Unknown' : 'Unknown',
  );
  // Resolve source card if applicable
  const sourceCardId = challenge.source.type === 'cSCard' ? challenge.source.data : '';

  // Inline Lookup (replacement for useActorCoreCard)
  const resolvedSourceCard = useGameStore((state) => {
    if (!actorId || !sourceCardId) return undefined;
    const actor = state.actors[actorId];
    if (!actor) return undefined;
    const { coreState } = actor;

    const findInList = (list: CoreCard[], id: string) => list.find((c) => c.id === id);

    // Check Map first
    if (coreState.inPlay && coreState.inPlay[sourceCardId]) {
      return coreState.inPlay[sourceCardId]![0];
    }

    // Check Lists
    return (
      findInList(coreState.hand, sourceCardId) ||
      findInList(coreState.deck, sourceCardId) ||
      findInList(coreState.discard, sourceCardId) ||
      (coreState.defending ? findInList(coreState.defending.cards, sourceCardId) : undefined)
    );
  });

  const sourceCard = resolvedSourceCard ? { ...resolvedSourceCard, id: sourceCardId } : undefined;

  const stackCards = useMemo(() => {
    const cards: CoreCard[] = [];

    // Ad-Hoc Source handling
    if (challenge.source.type === 'cSAdHoc') {
      const adhoc = challenge.source;
      cards.push({
        id: `adhoc-${log.id}`,
        name: adhoc.name,
        stats: {
          red: challenge.challengeColor === 'red' ? challenge.challengeStrength : 0,
          yellow: challenge.challengeColor === 'yellow' ? challenge.challengeStrength : 0,
          blue: challenge.challengeColor === 'blue' ? challenge.challengeStrength : 0,
        },
        flavor: adhoc.description ? [{ type: 'textRun', content: adhoc.description }] : undefined,
      });
    } else if (sourceCard) {
      cards.push(sourceCard);
    }

    // Planned Action Cards (Directly from Wire payload)
    if (plannedAction) {
      if (plannedAction.type === 'pStandard') {
        cards.push(plannedAction.data.actionCard);
        cards.push(...plannedAction.data.resources);
      } else if (plannedAction.type === 'pNarrative') {
        cards.push(...plannedAction.data.cards);
      }
    }

    return cards;
  }, [log.id, challenge, plannedAction, sourceCard]);

  const handleClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (challenge) {
      onOpenDefense(challenge, stackCards);
    }
  };

  if (!challenge) return null;

  return (
    <div
      onClick={handleClick}
      className="bg-red-950/30 border border-red-900/50 rounded p-3 mb-2 animate-fade-in cursor-pointer hover:bg-red-900/40 hover:shadow-md transition-all group"
    >
      <div className="flex justify-between items-start mb-1">
        <div className="text-xs font-bold text-red-300 flex items-center gap-1">
          <Square size={12} className="fill-red-500 text-red-500" />
          <span>Challenge Action</span>
        </div>
      </div>

      <div className="space-y-1 mb-2">
        {stackCards.map((card, idx) => (
          <div
            key={`${card.id}-${idx}`}
            className="text-white font-bold text-sm bg-black/20 rounded px-2 py-1 flex items-center gap-2"
          >
            <span>{card.name}</span>
            {idx === 0 && (
              <span className="text-[10px] text-red-300 uppercase bg-red-950/50 px-1 rounded">
                Core
              </span>
            )}
            {/* Show 'Ad-Hoc' badge if source is adhoc and this is the first card */}
            {idx === 0 && challenge.source.type === 'cSAdHoc' && (
              <span className="text-[10px] text-yellow-300 uppercase bg-yellow-950/50 px-1 rounded">
                GM
              </span>
            )}
          </div>
        ))}
      </div>

      <div className="text-xs text-slate-400 mb-2">By: {actorName}</div>

      <div className="flex items-center gap-2 text-sm bg-black/40 rounded p-1 mb-1">
        <span className="font-bold text-red-400">Power: {challenge.challengeStrength}</span>
        <ArrowRight size={12} className="text-slate-500" />
        <span className="capitalize text-slate-300">{challenge.challengeColor}</span>
      </div>

      <div className="text-[10px] text-slate-500 text-right opacity-0 group-hover:opacity-100 transition-opacity">
        Click to Defend
      </div>
    </div>
  );
};

const LogItem: React.FC<{
  log: LogEntry;
  onOpenDefense: (attack: ActiveChallenge, stack: DefenseModalCard[]) => void;
}> = ({ log, onOpenDefense }) => {
  // TODO: Use CardViewById for inline cards if we want to do that in chat?

  if (log.payload.type === 'logChallenge') {
    return <ChallengeLogItem log={log} payload={log.payload} onOpenDefense={onOpenDefense} />;
  }

  if (log.payload.type === 'logDefense') {
    // Defense log logic
    const payload = log.payload;
    return (
      <div className="bg-blue-950/30 border border-blue-900/50 rounded p-3 mb-2 animate-fade-in">
        <div className="text-xs font-bold text-blue-300 flex items-center gap-1 mb-1">
          <Shield size={12} className="fill-blue-500 text-blue-500" />
          <span>Defense Resolution</span>
        </div>
        <div className="text-sm text-slate-300">
          {payload.ended ? 'Defense Ended' : 'Defending...'}
        </div>
        {/* Could show defense cards played here if snapshot available */}
      </div>
    );
  }

  if (log.payload.type === 'logError') {
    return (
      <div className="bg-red-950/20 border-l-2 border-red-500 p-2 mb-2 animate-pulse-once">
        <div className="text-xs font-bold text-red-500 mb-1">Error</div>
        <div className="text-sm text-red-300">{log.payload.content}</div>
      </div>
    );
  }

  if (log.payload.type === 'logChat') {
    return (
      <div className="bg-slate-800/50 rounded p-2 mb-2 animate-fade-in flex gap-2">
        <div className="w-6 h-6 rounded-full bg-slate-700 flex items-center justify-center shrink-0">
          <Bot size={14} className="text-slate-400" />
        </div>
        <div className="flex-1">
          <div className="text-[10px] font-bold text-slate-500 mb-0.5">{log.sender}</div>
          <div className="text-sm text-slate-200">{log.payload.content}</div>
        </div>
      </div>
    );
  }

  // Info / Generic
  return (
    <div className="text-xs text-slate-500 italic p-2 border-b border-slate-800/50">
      {log.payload.type === 'logInfo' ? log.payload.content : 'Unknown Log Type'}
    </div>
  );
};

export const SidebarRightView: React.FC<SidebarRightProps> = ({
  logs,
  phase,
  onRevealActions,
  onEndRound,
  readyCount = 0,
  totalCount = 0,
  onSendChat,
  onResetGame,
  onOpenDefense,
}) => {
  const [chatInput, setChatInput] = useState('');
  const logsEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom of logs
  useEffect(() => {
    if (logsEndRef.current) {
      logsEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [logs]);

  const handleSendChat = (e: React.FormEvent) => {
    e.preventDefault();
    if (!chatInput.trim()) return;
    onSendChat(chatInput);
    setChatInput('');
  };

  return (
    <div className="w-80 h-full bg-slate-900 border-l border-slate-800 flex flex-col shadow-2xl z-20 shrink-0">
      <div className="bg-slate-950 border-b border-slate-800 p-4 shrink-0">
        <div className="flex justify-between items-center mb-3">
          <span className="text-xs font-bold text-slate-300 uppercase tracking-wider">
            Phase: {phase}
          </span>
          {phase === 'planning' && (
            <div className="flex items-center gap-1 text-[10px] text-slate-500"></div>
          )}
        </div>

        {phase === 'planning' ? (
          <button
            onClick={onRevealActions}
            disabled={readyCount < totalCount}
            className="w-full bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold py-2 rounded shadow-lg shadow-indigo-900/20 flex items-center justify-center gap-2 transition-all disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none"
          >
            {readyCount < totalCount ? (
              <span className="text-sm">
                {readyCount}/{totalCount} Ready
              </span>
            ) : (
              <>
                <Play size={14} fill="currentColor" /> Reveal Actions
              </>
            )}
          </button>
        ) : (
          <button
            onClick={onEndRound}
            className="w-full bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold py-2 rounded shadow-lg shadow-emerald-900/20 flex items-center justify-center gap-2 transition-all"
          >
            <Rewind size={14} fill="currentColor" /> New Round
          </button>
        )}
      </div>

      {/* Game Log Header */}
      <div className="px-4 py-2 bg-slate-900 border-b border-slate-800 shrink-0 flex justify-between items-center shadow-sm">
        <h2 className="text-xs font-bold text-slate-500 uppercase tracking-widest">Game Log</h2>
        <div className="text-[10px] text-slate-600 font-mono">{logs.length} Entries</div>
      </div>

      {/* Logs Scroll Area */}
      <div className="flex-1 overflow-y-auto p-4 custom-scrollbar">
        {logs.length === 0 && (
          <div className="text-center text-slate-700 italic text-xs mt-10">No logs yet.</div>
        )}

        {logs.map((log) => (
          <LogItem key={log.id} log={log} onOpenDefense={onOpenDefense} />
        ))}
        <div ref={logsEndRef} />
      </div>

      {/* Chat Input */}
      <form
        onSubmit={handleSendChat}
        className="p-3 bg-slate-950 border-t border-slate-800 shrink-0 flex gap-2"
      >
        <input
          type="text"
          value={chatInput}
          onChange={(e) => setChatInput(e.target.value)}
          placeholder="Type a message..."
          className="flex-1 bg-slate-900 border border-slate-700 rounded px-3 py-1.5 text-xs text-white focus:outline-none focus:border-indigo-500 transition-colors"
        />
        <button
          type="submit"
          className="bg-indigo-600 hover:bg-indigo-500 text-white p-1.5 rounded transition-colors"
        >
          <Send size={14} />
        </button>
      </form>
      <button
        type="button"
        onClick={onResetGame}
        className="shrink-0 p-2 text-[10px] text-red-900/30 hover:text-red-500 transition-colors text-center border-t border-slate-800"
      >
        Reset Game
      </button>
    </div>
  );
};

// --- Container ---

const SidebarRight: React.FC<{
  onOpenDefense: (attack: ActiveChallenge, stack: DefenseModalCard[]) => void;
}> = ({ onOpenDefense }) => {
  const logs = useGameStore((state) => state.logs);
  const phase = useGameStore((state) => state.phase);
  // const actors = useGameStore((state) => state.actors); // Unused
  const { dispatchCommand, dispatchAdmin } = useGameDispatch();

  // Calculate readiness
  const totalCount = useGameStore((state) => state.totalCount);
  const readyCount = useGameStore((state) => state.readyCount);

  const handleReveal = () => {
    // Trigger resolution phase via specific intent.
    const activeId = useGameStore.getState().activeActorId; // Or system
    if (activeId) dispatchCommand({ type: 'startResolutionIntent', actorId: activeId });
  };

  const handleEndRound = () => {
    const activeId = useGameStore.getState().activeActorId;
    if (activeId) dispatchCommand({ type: 'endRoundIntent', actorId: activeId });
  };

  const handleSendChat = (msg: string) => {
    dispatchCommand({ type: 'chatIntent', content: msg });
  };

  const handleReset = () => {
    // Corrected dispatchAdmin usage
    dispatchAdmin('resetGame');
  };

  return (
    <SidebarRightView
      logs={logs}
      phase={phase}
      onRevealActions={handleReveal}
      onEndRound={handleEndRound}
      readyCount={readyCount}
      totalCount={totalCount}
      onSendChat={handleSendChat}
      onResetGame={handleReset}
      onOpenDefense={onOpenDefense}
    />
  );
};

export default SidebarRight;
