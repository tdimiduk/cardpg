import React from 'react';
import { Skull, User, X, StickyNote, CheckCircle2 } from 'lucide-react';
import { ActorState, Phase } from '../../generated/types';
import { ACTOR_COLORS } from '../../theme';

interface ActorListProps {
  actors: Record<string, ActorState>;
  onSelectActor: (actorId: string) => void;
  onRemoveActor: (actorId: string, e: React.MouseEvent) => void; // Updated signature
  phase: Phase;
  plannedActions: any; // Stub/Legacy
}

export const ActorList: React.FC<ActorListProps> = ({
  actors,
  onSelectActor,
  onRemoveActor,
  phase,
  plannedActions,
}) => {
  const actorList = Object.values(actors);

  return (
    <div className="p-6 text-center space-y-6">
      <div className="text-slate-500 text-sm italic">
        Select an actor to view their hand and deck.
      </div>
      <div className="space-y-2">
        <div className="space-y-2">
          {actorList.map((actor) => {
            // Indicator Logic
            // ActorState has coreState
            const handSize = actor.coreState.hand.length;
            // Planned actions stub
            const plannedCount = 0;

            // If in planning phase, we sum hand + planned to hide information (mock logic for now)
            const displayHandSize = phase === 'planning' ? handSize + plannedCount : handSize;

            const hasPlan = false; // Stub

            // Determine if monster or PC. 'monster' vs 'character' presumably.
            // Using loose check or default to PC if not monster.
            const isMonster = actor.actorType === 'monster';

            // ActorState doesn't have 'color' property in generated types.
            // We might need to derive it or use inline styles/classes based on type.
            // For now, removing dynamic color or using legacy fallback if it exists on runtime object (untyped)
            const actorColor = isMonster ? ACTOR_COLORS.MONSTER : ACTOR_COLORS.PC;

            return (
              <div key={actor.name} className="relative group">
                {/* Using name as key if ID missing on ActorState, but sidebar uses ID record keys. 
                     Wait, ActorList iterates values. ActorState values don't have ID property in generated types!
                     They are keyed in the record.
                     I need to pass [id, state] tuples or inject ID.
                 */}
                {/* SidebarLeft passes actors={actors}. Map entries instead of values. */}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
