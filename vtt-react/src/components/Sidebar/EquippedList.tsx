import React from 'react';
import { Briefcase } from 'lucide-react';
import { Card } from '../../types';

interface EquippedListProps {
  equipped: Card[];
}

export const EquippedList: React.FC<EquippedListProps> = ({ equipped }) => {
  return (
    <div className="p-4 border-t border-slate-800">
      <span className="text-xs text-slate-500 font-bold uppercase mb-2 block flex items-center gap-1">
        <Briefcase size={12} /> Equipped
      </span>
      <div className="space-y-1">
        {equipped.map((c) => {
          const hasStats = c.type === 'itemCard' || c.type === 'natureCard';
          // Cast to any to access optional properties safely or rely on discriminated union if TS is smart enough
          // But since we are iterating Card[], TS knows c.type.
          // We can just access properties if we check type or if we cast.
          // Simpler: Just check if 'defense' in c
          const def = hasStats ? (c as any).defense : undefined;
          const res = hasStats ? (c as any).resilience : undefined;

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
