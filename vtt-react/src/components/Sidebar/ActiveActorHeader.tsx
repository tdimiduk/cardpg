import React from 'react';
import { Skull, User, Activity } from 'lucide-react';
import { Token, TokenType, Actor } from '../../types';

interface ActiveActorHeaderProps {
  activeToken: Token;
  actor: Actor;
  hasPlannedAction?: boolean;
}

export const ActiveActorHeader: React.FC<ActiveActorHeaderProps> = ({
  activeToken,
  actor,
  hasPlannedAction,
}) => {
  return (
    <div className="p-4 border-b border-slate-800 bg-slate-900 flex items-center gap-3">
      <div className="w-10 h-10 rounded-full border-2 border-slate-600 overflow-hidden bg-slate-800 flex items-center justify-center shrink-0">
        {actor.type === TokenType.MONSTER ? (
          <Skull size={20} className="text-emerald-400" />
        ) : (
          <User size={20} className="text-indigo-400" />
        )}
      </div>
      <div className="flex-1 overflow-hidden">
        <div className="font-bold text-slate-100 truncate" style={{ color: actor.color }}>
          {actor.name}
        </div>
        <div className="text-xs text-slate-500 uppercase flex items-center gap-2">
          {actor.type}
          {hasPlannedAction && (
            <span className="text-indigo-400 font-bold flex items-center gap-1 text-[10px] border border-indigo-900 px-1 rounded bg-indigo-950">
              <Activity size={10} /> Ready
            </span>
          )}
        </div>
      </div>
    </div>
  );
};
