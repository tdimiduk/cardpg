import React from 'react';
import { useGameStore } from '../../store/gameStore';
import { ActorState, Phase } from '../../generated/types';

import { SidebarHeader } from './SidebarHeader';
import { ActorList } from './ActorList';
import { ActorDetails } from './ActorDetails';

// --- View ---

export interface SidebarLeftProps {
  activeActorId?: string;
  activeActor?: ActorState;
  actors: Record<string, ActorState>;
  onSelectActor: (actorId: string) => void;
  onRemoveActor: (actorId: string) => void;
  onResumeDefense: () => void;
  phase: Phase;
  plannedActions: Record<string, unknown>; // Legacy stub
}

export const SidebarLeftView: React.FC<SidebarLeftProps> = ({
  activeActorId,
  activeActor,
  actors,
  onSelectActor,
  onRemoveActor,
  onResumeDefense,
  phase,
  plannedActions,
}) => {
  // Empty State / Character Selector
  if (!activeActorId || !activeActor) {
    return (
      <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl">
        <SidebarHeader />
        <ActorList
          actors={actors}
          onSelectActor={onSelectActor}
          onRemoveActor={onRemoveActor}
          phase={phase}
          plannedActions={plannedActions}
        />
        <div className="p-4 border-t border-slate-800 mt-auto">
          <button
            onClick={() => {
              if (window.confirm('Reset Identity? This will create a new user ID.')) {
                localStorage.removeItem('cardpg_client_id');
                window.location.reload();
              }
            }}
            className="text-xs text-slate-500 hover:text-slate-300 w-full text-center"
          >
            Debug: Reset Identity
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl relative">
      <SidebarHeader />
      <ActorDetails
        actor={{ ...activeActor, id: activeActorId }}
        onResumeDefense={onResumeDefense}
      />
    </div>
  );
};

// --- Container ---

interface SidebarLeftContainerProps {
  onResumeDefense: () => void;
}

const SidebarLeftContainer: React.FC<SidebarLeftContainerProps> = ({ onResumeDefense }) => {
  const actors = useGameStore((state) => state.actors);
  const activeActorId = useGameStore((state) => state.activeActorId);
  const phase = useGameStore((state) => state.phase);
  const plannedActions = {}; // Stub

  const setActiveActor = useGameStore((state) => state.setActiveActor);

  const removeActor = (_id: string) => console.log('Remove actor not implemented');

  // Derived State
  const activeActor = activeActorId ? actors[activeActorId] : undefined;

  // Handlers
  const handleSelectToken = (id: string) => {
    // If id has "token-" prefix, strip it (legacy handling fallback)
    const actorId = id.replace(/^token-/, '');
    if (actors[actorId]) setActiveActor(actorId);
  };

  return (
    <SidebarLeftView
      activeActorId={activeActorId || undefined}
      activeActor={activeActor}
      actors={actors}
      onSelectActor={handleSelectToken}
      onRemoveActor={removeActor}
      onResumeDefense={onResumeDefense}
      phase={phase}
      plannedActions={plannedActions}
    />
  );
};

export default SidebarLeftContainer;
