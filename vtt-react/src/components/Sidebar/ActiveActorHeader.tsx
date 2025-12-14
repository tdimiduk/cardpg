import React from 'react';
import { Skull, User } from 'lucide-react';
import { TokenType, ActorState } from '../../types';

interface ActiveActorHeaderProps {
  activeActorId: string;
  actor: ActorState;
}

export const ActiveActorHeader: React.FC<ActiveActorHeaderProps> = ({ actor }) => {
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
        <div className="text-xs text-slate-500 uppercase flex items-center gap-2">{actor.type}</div>
      </div>
    </div>
  );
};
