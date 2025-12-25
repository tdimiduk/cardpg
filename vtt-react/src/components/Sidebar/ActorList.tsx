import React from 'react';
import { ActorState, Phase } from '../../generated/types';

interface ActorListProps {
  actors: Record<string, ActorState>;
  onSelectActor: (actorId: string) => void;
  onRemoveActor: (actorId: string, e: React.MouseEvent) => void;

  phase: Phase;
}

export const ActorList: React.FC<ActorListProps> = ({
  actors,
  onSelectActor: _onSelectActor,
  onRemoveActor: _onRemoveActor,
}) => {
  const actorList = Object.entries(actors);

  return (
    <div className="p-6 text-center space-y-6">
      <div className="text-slate-500 text-sm italic">
        Select an actor to view their hand and deck.
      </div>
      <div className="space-y-2">
        {actorList.map(([actorId, actor]) => (
          <div key={actorId} className="relative group">
            <button
              onClick={() => _onSelectActor(actorId)}
              className="w-full text-left px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded transition-colors"
            >
              {actor.name}
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};
