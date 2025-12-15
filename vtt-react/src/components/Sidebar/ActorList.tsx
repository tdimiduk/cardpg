import React from 'react';
import { Skull, User, X, Plus, StickyNote, CheckCircle2 } from 'lucide-react';
import { Token, TokenType, ActorState, GamePhase, UIPlannedAction } from '../../types';
import { ACTOR_COLORS } from '../../theme';

interface ActorListProps {
  tokens: Token[];
  actors: Record<string, ActorState>;
  onSelectToken: (tokenId: string) => void;
  onRemoveActor: (actorId: string) => void;
  onAddActor: (type: TokenType) => void;
  phase: GamePhase;
  plannedActions: Record<string, UIPlannedAction>;
}

export const ActorList: React.FC<ActorListProps> = ({
  tokens,
  actors,
  onSelectToken,
  onRemoveActor,
  onAddActor,
  phase,
  plannedActions,
}) => {
  const getActor = (token: Token) => actors[token.actorId];

  return (
    <div className="p-6 text-center space-y-6">
      <div className="text-slate-500 text-sm italic">
        Select an actor to view their hand and deck.
      </div>
      <div className="space-y-2">
        <div className="space-y-2">
          {tokens.map((token) => {
            const actor = getActor(token);
            if (!actor) return null;

            // Indicator Logic
            const deck = actor.deck;
            const plan = plannedActions[token.actorId];
            const rawHandSize = deck?.hand.length || 0;
            const plannedCount = plan ? plan.cards.length : 0;

            // If in planning phase, we sum hand + planned to hide information
            const displayHandSize = phase === 'planning' ? rawHandSize + plannedCount : rawHandSize;

            const hasPlan = !!plan;

            return (
              <div key={token.id} className="relative group">
                <button
                  onClick={() => onSelectToken(token.id)}
                  className="w-full flex items-center gap-3 bg-slate-900 hover:bg-slate-800 p-2 rounded border border-slate-800 hover:border-slate-600 transition-all relative overflow-hidden"
                >
                  <div className="w-8 h-8 rounded-full overflow-hidden bg-slate-800 flex items-center justify-center shrink-0 border border-slate-600 relative">
                    {actor.type === TokenType.MONSTER ? (
                      <Skull size={16} style={{ color: ACTOR_COLORS.MONSTER }} />
                    ) : (
                      <User size={16} style={{ color: ACTOR_COLORS.PC }} />
                    )}
                  </div>
                  <div className="text-left flex-1 min-w-0">
                    <div
                      className="font-bold text-slate-200 text-sm group-hover:text-white truncate"
                      style={{ color: actor.color }}
                    >
                      {actor.name}
                    </div>
                    <div className="text-[10px] text-slate-500 uppercase">{actor.type}</div>
                  </div>

                  {/* Indicators */}
                  <div className="flex items-center gap-1 shrink-0">
                    {hasPlan && (
                      <div
                        className="bg-green-500/20 text-green-400 p-1 rounded-full border border-green-500/50 animate-pulse"
                        title="Action Planned"
                      >
                        <CheckCircle2 size={14} />
                      </div>
                    )}
                    <div
                      className="flex items-center gap-1 bg-slate-800 border border-slate-700 px-1.5 py-0.5 rounded text-xs font-mono text-slate-400"
                      title="Hand Size"
                    >
                      <StickyNote size={12} />
                      <span>{displayHandSize}</span>
                    </div>
                  </div>
                </button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    onRemoveActor(actor.id);
                  }}
                  className="absolute -top-1 -right-1 z-10 bg-slate-900 border border-slate-700 rounded-full p-0.5 text-slate-500 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
                  title="Remove Actor"
                >
                  <X size={12} />
                </button>
              </div>
            );
          })}
        </div>

        <div className="pt-4 border-t border-slate-800 flex gap-2 justify-center">
          <button
            onClick={() => onAddActor(TokenType.PC)}
            className="flex items-center gap-1 text-xs bg-indigo-900/50 hover:bg-indigo-800 text-indigo-200 px-3 py-2 rounded border border-indigo-700/50 transition-colors"
          >
            <Plus size={12} /> Add Hero
          </button>
          <button
            onClick={() => onAddActor(TokenType.MONSTER)}
            className="flex items-center gap-1 text-xs bg-emerald-900/50 hover:bg-emerald-800 text-emerald-200 px-3 py-2 rounded border border-emerald-700/50 transition-colors"
          >
            <Plus size={12} /> Add Monster
          </button>
        </div>
      </div>
    </div>
  );
};
