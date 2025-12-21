import React from 'react';
import { Layers, BookOpen } from 'lucide-react';
import { Link } from 'react-router-dom';

export const SidebarHeader: React.FC = () => {
  return (
    <div className="p-4 border-b border-slate-800 flex items-center justify-between">
      <div className="flex items-center gap-2">
        <Layers className="text-indigo-500" />
        <h1 className="font-bold text-lg tracking-wider text-slate-100">
          caRd<span className="text-indigo-500">PG</span>
        </h1>
      </div>

      <Link
        to="/rules"
        target="_blank"
        rel="noopener noreferrer"
        className="text-slate-500 hover:text-amber-500 transition-colors p-1"
        title="Open Rules"
      >
        <BookOpen className="w-5 h-5" />
      </Link>
    </div>
  );
};
