import React from 'react';
import { Skull, User, X, Plus } from 'lucide-react';
import { Token, TokenType, Actor } from '../../types';
import { ACTOR_COLORS } from '../../theme';

interface ActorListProps {
  tokens: Token[];
  actors: Record<string, Actor>;
  onSelectToken: (tokenId: string) => void;
  onRemoveActor: (actorId: string) => void;
  onAddActor: (type: TokenType) => void;
}

export const ActorList: React.FC<ActorListProps> = ({
  tokens,
  actors,
  onSelectToken,
  onRemoveActor,
  onAddActor,
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
            return (
              <div key={token.id} className="relative group">
                <button
                  onClick={() => onSelectToken(token.id)}
                  className="w-full flex items-center gap-3 bg-slate-900 hover:bg-slate-800 p-2 rounded border border-slate-800 hover:border-slate-600 transition-all"
                >
                  <div className="w-8 h-8 rounded-full overflow-hidden bg-slate-800 flex items-center justify-center shrink-0 border border-slate-600">
                    {actor.type === TokenType.MONSTER ? (
                      <Skull size={16} style={{ color: ACTOR_COLORS.MONSTER }} />
                    ) : (
                      <User size={16} style={{ color: ACTOR_COLORS.PC }} />
                    )}
                  </div>
                  <div className="text-left">
                    <div
                      className="font-bold text-slate-200 text-sm group-hover:text-white"
                      style={{ color: actor.color }}
                    >
                      {actor.name}
                    </div>
                    <div className="text-[10px] text-slate-500 uppercase">{actor.type}</div>
                  </div>
                </button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    onRemoveActor(actor.id);
                  }}
                  className="absolute top-2 right-2 text-slate-600 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
                  title="Remove Actor"
                >
                  <X size={14} />
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
