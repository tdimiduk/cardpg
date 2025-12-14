import React, { useState, useEffect, useRef } from 'react';
import { LogEntry, GamePhase } from '../../types';
import { RESOURCE_TYPES } from '../../constants';
import { Send, Bot, Square, Circle, Diamond, ArrowRight, Play, Rewind } from 'lucide-react';

interface SidebarRightProps {
  logs: LogEntry[];
  onAddLog: (log: LogEntry) => void;
  phase: GamePhase;
  onRevealActions: () => void;
  onEndRound: () => void;
  readyCount?: number;
  totalCount?: number;
  currentResolution: {
    actorId: string;
    attack: import('../../types').RealizedAttack;
    actorName?: string;
    attackCardName?: string;
  } | null;
}

export const SidebarRight: React.FC<SidebarRightProps> = ({
  logs,
  onAddLog,
  phase,
  onRevealActions,
  onEndRound,
  readyCount,
  totalCount,
  currentResolution,
}) => {
  const [chatInput, setChatInput] = useState('');
  const endOfLogsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    endOfLogsRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [logs]);

  const handleSendChat = (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!chatInput.trim()) return;

    onAddLog({
      id: Date.now().toString(),
      timestamp: Date.now(),
      sender: 'GM',
      content: chatInput,
      type: 'chat',
    });
    setChatInput('');
  };

  const allReady = readyCount !== undefined && totalCount !== undefined && readyCount >= totalCount;

  return (
    <div className="w-80 bg-slate-950 border-l border-slate-800 flex flex-col h-full z-20">
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
            {currentResolution ? (
              <div className="bg-red-950/30 border border-red-900/50 rounded p-3 animate-fade-in">
                <div className="text-xs text-red-300 mb-1 flex items-center gap-1">
                  <Square size={12} className="fill-red-500 text-red-500" />
                  <strong>Current Attack</strong>
                </div>
                <div className="text-white font-bold">
                  {currentResolution.attackCardName || 'Unknown Attack'}
                </div>
                <div className="text-xs text-slate-400">
                  By: {currentResolution.actorName || currentResolution.actorId}
                </div>
                <div className="mt-2 flex items-center gap-2 text-sm bg-black/40 rounded p-1">
                  <span className="font-bold text-red-400">
                    Power: {currentResolution.attack.attackStrength}
                  </span>
                  <ArrowRight size={12} className="text-slate-500" />
                  <span className="text-slate-300">VS</span>
                  <span
                    className={`font-bold ${
                      currentResolution.attack.defenseColor === RESOURCE_TYPES.RED
                        ? 'text-red-400'
                        : currentResolution.attack.defenseColor === RESOURCE_TYPES.BLUE
                          ? 'text-blue-400'
                          : 'text-yellow-400'
                    }`}
                  >
                    {currentResolution.attack.defenseColor.toUpperCase()}
                  </span>
                </div>
              </div>
            ) : (
              <div className="text-center text-xs text-slate-500 py-2 italic">
                Waiting for resolution...
              </div>
            )}
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
        {logs.map((log) => (
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
                log.type === 'action'
                  ? 'bg-slate-800 border border-slate-600'
                  : log.type === 'info'
                    ? 'text-slate-500 italic'
                    : log.sender === 'AI'
                      ? 'bg-indigo-950/30 border border-indigo-900/50 text-indigo-100'
                      : 'text-slate-300 bg-slate-900/50'
              }`}
            >
              {log.content}
              {log.actionResult && (
                <div className="mt-2 flex items-center justify-between bg-black/40 p-2 rounded border border-white/10">
                  <div className="flex items-center gap-2">
                    {log.actionResult.color === RESOURCE_TYPES.RED && (
                      <Square className="text-red-500 fill-current" size={16} />
                    )}
                    {log.actionResult.color === RESOURCE_TYPES.YELLOW && (
                      <Circle className="text-yellow-500 fill-current" size={16} />
                    )}
                    {log.actionResult.color === RESOURCE_TYPES.BLUE && (
                      <Diamond className="text-blue-500 fill-current" size={16} />
                    )}
                    <span className="font-bold text-lg text-white">{log.actionResult.total}</span>
                  </div>
                  {log.actionResult.targetColor && (
                    <div className="flex items-center gap-1 text-slate-400 text-xs">
                      <ArrowRight size={12} />
                      <span>VS</span>
                      {log.actionResult.targetColor === RESOURCE_TYPES.RED && (
                        <Square className="text-red-800 fill-red-900" size={12} />
                      )}
                      {log.actionResult.targetColor === RESOURCE_TYPES.YELLOW && (
                        <Circle className="text-yellow-800 fill-yellow-900" size={12} />
                      )}
                      {log.actionResult.targetColor === RESOURCE_TYPES.BLUE && (
                        <Diamond className="text-blue-800 fill-blue-900" size={12} />
                      )}
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        ))}
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
