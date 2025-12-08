import React from 'react';
import { Skull, User, X, Plus } from 'lucide-react';
import { TokenType, ActorData } from '../../types';

interface ActorSelectorModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectTemplate: (template: ActorData) => void;
  selectorType: TokenType;
  availableTemplates: ActorData[];
}

export const ActorSelectorModal: React.FC<ActorSelectorModalProps> = ({
  isOpen,
  onClose,
  onSelectTemplate,
  selectorType,
  availableTemplates,
}) => {
  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-8 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="bg-slate-900 border border-slate-700 rounded-xl shadow-2xl w-full max-w-2xl h-full max-h-[80vh] flex flex-col overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="p-4 border-b border-slate-700 flex justify-between items-center bg-slate-950">
          <h2 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            {selectorType === TokenType.MONSTER ? (
              <Skull className="text-emerald-500" />
            ) : (
              <User className="text-indigo-500" />
            )}
            Select {selectorType === TokenType.MONSTER ? 'Monster' : 'Hero'}
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-slate-800 rounded-full text-slate-400 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>
        <div className="flex-1 overflow-y-auto p-4 bg-slate-900/50">
          <div className="grid grid-cols-1 gap-2">
            {availableTemplates.map((tmpl) => (
              <button
                key={tmpl.id}
                onClick={() => onSelectTemplate(tmpl)}
                className="flex items-center gap-4 p-3 rounded bg-slate-800 hover:bg-slate-700 border border-slate-700 hover:border-indigo-500 transition-all text-left group"
              >
                <div
                  className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 border ${selectorType === TokenType.MONSTER ? 'bg-emerald-900/20 border-emerald-700 text-emerald-400' : 'bg-indigo-900/20 border-indigo-700 text-indigo-400'}`}
                >
                  {selectorType === TokenType.MONSTER ? <Skull size={20} /> : <User size={20} />}
                </div>
                <div className="flex-1">
                  <div className="font-bold text-slate-200 group-hover:text-white text-lg">
                    {tmpl.name}
                  </div>
                  <div className="text-xs text-slate-500 flex gap-2">
                    <span>Deck: {tmpl.deck.length} cards</span>
                    <span>•</span>
                    <span>Items: {tmpl.items.length}</span>
                  </div>
                </div>
                <Plus
                  size={20}
                  className="text-slate-600 group-hover:text-white opacity-0 group-hover:opacity-100 transition-all"
                />
              </button>
            ))}
            {availableTemplates.length === 0 && (
              <div className="text-center text-slate-500 py-8 italic">
                No templates found for this type.
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
