import React from 'react';
import { Link, Outlet } from 'react-router-dom';
import { BookOpen, ArrowLeft } from 'lucide-react';

export default function RulesLayout() {
  return (
    <div className="h-screen overflow-y-auto bg-slate-900 text-slate-200 font-sans custom-scrollbar">
      <header className="sticky top-0 z-10 border-b border-slate-700 bg-slate-900/95 backdrop-blur supports-[backdrop-filter]:bg-slate-900/75">
        <div className="container mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              to="/"
              className="flex items-center gap-2 text-slate-400 hover:text-white transition-colors"
              title="Back to Game"
            >
              <ArrowLeft className="w-5 h-5" />
              <span className="hidden sm:inline">Back to Game</span>
            </Link>
            <div className="h-6 w-px bg-slate-700 mx-2" />
            <div className="flex items-center gap-2 font-semibold text-lg text-amber-500">
              <BookOpen className="w-5 h-5" />
              <span>CardPG Rules</span>
            </div>
          </div>

          <nav className="flex items-center gap-4 text-sm font-medium">
            <Link
              to="/rules"
              className="text-slate-400 hover:text-amber-400 transition-colors ui-active:text-amber-500"
            >
              Core Rules
            </Link>
            <Link
              to="/glossary"
              className="text-slate-400 hover:text-amber-400 transition-colors ui-active:text-amber-500"
            >
              Glossary
            </Link>
            <Link
              to="/colors"
              className="text-slate-400 hover:text-amber-400 transition-colors ui-active:text-amber-500"
            >
              Colors of Action
            </Link>
          </nav>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <Outlet />
      </main>
    </div>
  );
}
