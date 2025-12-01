import React from 'react';
import { Layers } from 'lucide-react';

export const SidebarHeader: React.FC = () => {
  return (
    <div className="p-4 border-b border-slate-800 flex items-center gap-2">
      <Layers className="text-indigo-500" />
      <h1 className="font-bold text-lg tracking-wider text-slate-100">
        caRd<span className="text-indigo-500">PG</span>
      </h1>
    </div>
  );
};
