import React, { useMemo } from 'react';
import { Briefcase } from 'lucide-react';
import { ItemCard, NatureCard, TalentCard, ActorState } from '../../generated/types';

// Union of cards that can be equipped, intersected with ID
export type EquipmentCardWithId = (ItemCard | NatureCard | TalentCard) & { id: string };

interface EquippedListProps {
  activeActor?: ActorState;
}

export const EquippedList: React.FC<EquippedListProps> = ({ activeActor }) => {
  const equipped = useMemo(() => {
    if (!activeActor) return [];

    // Filter assets for type: "equipped" and map direct to content
    return Object.entries(activeActor.tableState.assets)
      .filter(([_, val]) => val && val[1].type === 'equipped')
      .map(([id, val]) => {
        const instance = val![0];
        const wrapper = instance.content;

        if (
          wrapper.type === 'tCItem' ||
          wrapper.type === 'tCNature' ||
          wrapper.type === 'tCTalent'
        ) {
          return { ...wrapper.data, id };
        }
        return undefined;
      })
      .filter((c): c is EquipmentCardWithId => !!c);
  }, [activeActor]);

  return (
    <div className="p-4 border-t border-slate-800">
      <span className="text-xs text-slate-500 font-bold uppercase mb-2 block flex items-center gap-1">
        <Briefcase size={12} /> Equipped
      </span>
      <div className="space-y-1">
        {equipped.map((c) => {
          // Check for defense/resilience safely
          let def: number | undefined;
          let res: number | undefined;

          if ('defense' in c) def = c.defense;
          if ('resilience' in c) res = c.resilience;

          return (
            <div
              key={c.id}
              className="bg-slate-900 p-1.5 rounded text-xs text-slate-300 flex justify-between items-center border border-slate-800"
            >
              <span className="truncate pr-2">{c.name}</span>
              {(def !== undefined || res !== undefined) && (
                <span className="text-[9px] text-slate-500 font-mono bg-slate-950 px-1 rounded">
                  {def !== undefined ? `D:${def}` : ''} {res !== undefined ? `R:${res}` : ''}
                </span>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};
