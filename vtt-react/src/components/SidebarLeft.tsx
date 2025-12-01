import React from 'react';
import { Token, TokenType, PlayerDeckState, Actor } from '../types';
import {
  Layers,
  RefreshCw,
  Shield,
  Square,
  Circle,
  Diamond,
  Briefcase,
  User,
  Skull,
  AlertOctagon,
  Activity,
  Plus,
  Minus,
  AlertTriangle,
  Hand,
  ArrowUp,
  Archive,
  X,
} from 'lucide-react';
import { CardComponent } from './Card';
import { getActorTemplates, ActorTemplate } from '../services/deckFactory';
import { getAttributeValue, calculateSeverity } from '../services/ruleService';

interface SidebarLeftProps {
  deckState: PlayerDeckState | null | undefined;
  onDraw: (count: number) => void;
  onDefend: () => void;
  onClearDefense: () => void;
  onReshuffle: () => void;
  onSelectToken: (tokenId: string) => void;
  onAddConsequence: () => void;
  onRemoveConsequence: (cardId: string) => void;
  onAddStatusCard: (type: 'fatigue' | 'wound', destination: 'discard' | 'hand' | 'draw') => void;
  onRemoveStatusCard: (type: 'fatigue' | 'wound') => void;
  tokens: Token[];
  activeToken?: Token;
  activeTokenId: string;
  hasPlannedAction?: boolean;
  actors: Record<string, Actor>;
  onAddActor: (name: string, type: TokenType, color: string, templateId?: string) => void;
  onRemoveActor: (actorId: string) => void;
}

export const SidebarLeft: React.FC<SidebarLeftProps> = ({
  deckState,
  onDraw,
  onDefend,
  onClearDefense,
  onReshuffle,
  onSelectToken,
  onAddConsequence,
  onRemoveConsequence,
  onAddStatusCard,
  onRemoveStatusCard,
  tokens,
  activeToken,
  hasPlannedAction,
  actors,
  onAddActor,
  onRemoveActor,
}) => {
  // Helper to get actor for token
  const getActor = (token: Token) => actors[token.actorId];

  // Empty State / Character Selector
  if (!deckState || !activeToken) {
    return (
      <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl">
        <div className="p-4 border-b border-slate-800 flex items-center gap-2">
          <Layers className="text-indigo-500" />
          <h1 className="font-bold text-lg tracking-wider text-slate-100">
            caRd<span className="text-indigo-500">PG</span>
          </h1>
        </div>
        <div className="p-6 text-center space-y-6">
          <div className="text-slate-500 text-sm italic">
            Select an actor to view their hand and deck.
          </div>
          <div className="space-y-2">
            <div className="space-y-2">
              {tokens.map((token) => {
                const actor = getActor(token);
                if (!actor) return null;
                return (
                  <div key={token.id} className="relative group">
                    <button
                      onClick={() => onSelectToken(token.id)}
                      className="w-full flex items-center gap-3 bg-slate-900 hover:bg-slate-800 p-2 rounded border border-slate-800 hover:border-slate-600 transition-all"
                    >
                      <div className="w-8 h-8 rounded-full overflow-hidden bg-slate-800 flex items-center justify-center shrink-0 border border-slate-600">
                        {actor.type === TokenType.MONSTER ? (
                          <Skull size={16} className="text-emerald-400" />
                        ) : (
                          <User size={16} className="text-indigo-400" />
                        )}
                      </div>
                      <div className="text-left">
                        <div
                          className="font-bold text-slate-200 text-sm group-hover:text-white"
                          style={{ color: actor.color }}
                        >
                          {actor.name}
                        </div>
                        <div className="text-[10px] text-slate-500 uppercase">{actor.type}</div>
                      </div>
                    </button>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onRemoveActor(actor.id);
                      }}
                      className="absolute top-2 right-2 text-slate-600 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
                      title="Remove Actor"
                    >
                      <X size={14} />
                    </button>
                  </div>
                );
              })}
            </div>

            <div className="pt-4 border-t border-slate-800 flex gap-2 justify-center">
              <button
                onClick={() => handleOpenSelector(TokenType.PC)}
                className="flex items-center gap-1 text-xs bg-indigo-900/50 hover:bg-indigo-800 text-indigo-200 px-3 py-2 rounded border border-indigo-700/50 transition-colors"
              >
                <Plus size={12} /> Add Hero
              </button>
              <button
                onClick={() => handleOpenSelector(TokenType.MONSTER)}
                className="flex items-center gap-1 text-xs bg-emerald-900/50 hover:bg-emerald-800 text-emerald-200 px-3 py-2 rounded border border-emerald-700/50 transition-colors"
              >
                <Plus size={12} /> Add Monster
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const defenseTotal = {
    red: deckState.flippedPile.reduce((sum, c) => sum + (c.stats.red ?? 0), 0),
    yellow: deckState.flippedPile.reduce((sum, c) => sum + (c.stats.yellow ?? 0), 0),
    blue: deckState.flippedPile.reduce((sum, c) => sum + (c.stats.blue ?? 0), 0),
  };

  // --- Derived Stats from Equipment ---
  const defenseStat = getAttributeValue(deckState.equipped, 'def');
  const resilienceStat = getAttributeValue(deckState.equipped, 'res');

  // --- Consequence Logic ---
  // Impact = Cards Flipped
  const impact = deckState.flippedPile.length;
  // Consequences = floor(Impact / Defense)
  const calculatedConsequences = Math.floor(impact / defenseStat);

  // Severity Calculation
  const currentSeverity = calculateSeverity(deckState.consequences, resilienceStat);

  const [showDeckModal, setShowDeckModal] = React.useState(false);
  const [showActorSelector, setShowActorSelector] = React.useState(false);
  const [selectorType, setSelectorType] = React.useState<TokenType>(TokenType.PC);

  const handleOpenSelector = (type: TokenType) => {
    setSelectorType(type);
    setShowActorSelector(true);
  };

  const handleSelectTemplate = (template: ActorTemplate) => {
    // Use template name, but append random number if needed or just use it as base
    // We'll use the template name + random number to ensure uniqueness if multiple are added
    const name = `${template.name} ${Math.floor(Math.random() * 100)}`;
    const color = selectorType === TokenType.MONSTER ? '#10b981' : '#3b82f6';
    onAddActor(name, selectorType, color, template.id);
    setShowActorSelector(false);
  };

  const availableTemplates = React.useMemo(() => {
    if (!showActorSelector) return [];
    const typeTag = selectorType === TokenType.MONSTER ? 'monster' : 'pc';
    return getActorTemplates(typeTag);
  }, [showActorSelector, selectorType]);

  return (
    <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl relative">
      {/* Deck Viewer Modal */}
      {showDeckModal && (
        <div
          className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-8 backdrop-blur-sm"
          onClick={() => setShowDeckModal(false)}
        >
          <div
            className="bg-slate-900 border border-slate-700 rounded-xl shadow-2xl w-full max-w-5xl h-full max-h-[90vh] flex flex-col overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-4 border-b border-slate-700 flex justify-between items-center bg-slate-950">
              <h2 className="text-xl font-bold text-slate-100 flex items-center gap-2">
                <Layers className="text-indigo-500" /> Deck Viewer ({deckState.drawPile.length}{' '}
                cards)
              </h2>
              <button
                onClick={() => setShowDeckModal(false)}
                className="p-2 hover:bg-slate-800 rounded-full text-slate-400 hover:text-white transition-colors"
              >
                <X size={24} />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto p-6 bg-slate-900/50">
              <div className="flex flex-wrap gap-4 justify-center">
                {deckState.drawPile.map((card, idx) => (
                  <div key={`${card.id}-${idx}`} className="scale-90 origin-top">
                    <CardComponent card={card} />
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Actor Selector Modal */}
      {showActorSelector && (
        <div
          className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-8 backdrop-blur-sm"
          onClick={() => setShowActorSelector(false)}
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
                onClick={() => setShowActorSelector(false)}
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
                    onClick={() => handleSelectTemplate(tmpl)}
                    className="flex items-center gap-4 p-3 rounded bg-slate-800 hover:bg-slate-700 border border-slate-700 hover:border-indigo-500 transition-all text-left group"
                  >
                    <div
                      className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 border ${selectorType === TokenType.MONSTER ? 'bg-emerald-900/20 border-emerald-700 text-emerald-400' : 'bg-indigo-900/20 border-indigo-700 text-indigo-400'}`}
                    >
                      {selectorType === TokenType.MONSTER ? (
                        <Skull size={20} />
                      ) : (
                        <User size={20} />
                      )}
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
      )}

      <div className="p-4 border-b border-slate-800 flex items-center gap-2">
        <Layers className="text-indigo-500" />
        <h1 className="font-bold text-lg tracking-wider text-slate-100">
          caRd<span className="text-indigo-500">PG</span>
        </h1>
      </div>

      {/* Active Actor Header */}
      {activeToken && actors[activeToken.actorId] && (
        <div className="p-4 border-b border-slate-800 bg-slate-900 flex items-center gap-3">
          <div className="w-10 h-10 rounded-full border-2 border-slate-600 overflow-hidden bg-slate-800 flex items-center justify-center shrink-0">
            {actors[activeToken.actorId].type === TokenType.MONSTER ? (
              <Skull size={20} className="text-emerald-400" />
            ) : (
              <User size={20} className="text-indigo-400" />
            )}
          </div>
          <div className="flex-1 overflow-hidden">
            <div
              className="font-bold text-slate-100 truncate"
              style={{ color: actors[activeToken.actorId].color }}
            >
              {actors[activeToken.actorId].name}
            </div>
            <div className="text-xs text-slate-500 uppercase flex items-center gap-2">
              {actors[activeToken.actorId].type}
              {hasPlannedAction && (
                <span className="text-indigo-400 font-bold flex items-center gap-1 text-[10px] border border-indigo-900 px-1 rounded bg-indigo-950">
                  <Activity size={10} /> Ready
                </span>
              )}
            </div>
          </div>
        </div>
      )}

      <div className="flex-1 overflow-y-auto custom-scrollbar space-y-1">
        {/* Deck State */}
        <div className="p-4 border-b border-slate-800">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">
              Deck & Resources
            </span>
            <button
              onClick={onReshuffle}
              className="flex items-center gap-1 text-[10px] bg-slate-800 hover:bg-blue-900 text-slate-400 hover:text-blue-200 px-2 py-1 rounded border border-slate-700 transition-colors"
              title="Shuffle Discard into Draw Pile"
            >
              <RefreshCw size={10} /> Reshuffle
            </button>
          </div>

          <div className="grid grid-cols-2 gap-2 mb-4">
            <div className="bg-slate-900 p-2 rounded border border-slate-800 flex flex-col items-center relative group">
              <span className="text-xs text-slate-500">Draw Pile</span>
              <span className="text-xl font-bold text-slate-200">{deckState.drawPile.length}</span>
              <button
                onClick={() => onDraw(1)}
                className="mt-1 w-full text-[10px] bg-slate-800 hover:bg-slate-700 py-1 rounded text-slate-300"
              >
                Draw 1
              </button>
              <button
                onClick={() => setShowDeckModal(true)}
                className="absolute top-1 right-1 p-1 text-slate-600 hover:text-indigo-400 transition-opacity"
                title="View Deck"
              >
                <Layers size={12} />
              </button>
            </div>
            <div className="bg-slate-900 p-2 rounded border border-slate-800 flex flex-col items-center">
              <span className="text-xs text-slate-500">Discard</span>
              <span className="text-xl font-bold text-slate-200">
                {deckState.discardPile.length}
              </span>
              <span className="text-[8px] text-slate-600 mt-1 h-5"></span>
            </div>
          </div>

          {/* Status Cards (Fatigue/Injury) */}
          <div className="bg-slate-900/50 rounded border border-slate-800 p-2">
            <span className="text-[10px] text-slate-500 font-bold uppercase mb-2 block">
              Status Cards in Deck
            </span>

            {/* Fatigue Row */}
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs text-slate-300 flex items-center gap-1">
                <Activity size={12} className="text-red-400" /> Fatigue
              </span>
              <div className="flex gap-1">
                <button
                  onClick={() => onRemoveStatusCard('fatigue')}
                  className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-red-900/50 text-slate-400 hover:text-red-300 border border-slate-700"
                  title="Remove 1 Fatigue from Game"
                >
                  <Minus size={10} />
                </button>
                <button
                  onClick={() => onAddStatusCard('fatigue', 'hand')}
                  className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
                  title="Add Fatigue to Hand"
                >
                  <Hand size={10} />
                </button>
                <button
                  onClick={() => onAddStatusCard('fatigue', 'draw')}
                  className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
                  title="Add Fatigue to Top of Deck"
                >
                  <ArrowUp size={10} />
                </button>
                <button
                  onClick={() => onAddStatusCard('fatigue', 'discard')}
                  className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
                  title="Add Fatigue to Discard"
                >
                  <Archive size={10} />
                </button>
              </div>
            </div>

            {/* Injury Row */}
            <div className="flex items-center justify-between">
              <span className="text-xs text-slate-300 flex items-center gap-1">
                <AlertOctagon size={12} className="text-orange-400" /> Injury
              </span>
              <div className="flex gap-1">
                <button
                  onClick={() => onRemoveStatusCard('wound')}
                  className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-orange-900/50 text-slate-400 hover:text-orange-300 border border-slate-700"
                  title="Remove 1 Injury from Game"
                >
                  <Minus size={10} />
                </button>
                <button
                  onClick={() => onAddStatusCard('wound', 'hand')}
                  className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
                  title="Add Injury to Hand"
                >
                  <Hand size={10} />
                </button>
                <button
                  onClick={() => onAddStatusCard('wound', 'draw')}
                  className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
                  title="Add Injury to Top of Deck"
                >
                  <ArrowUp size={10} />
                </button>
                <button
                  onClick={() => onAddStatusCard('wound', 'discard')}
                  className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
                  title="Add Injury to Discard"
                >
                  <Archive size={10} />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Defense Section */}
        <div className="p-4 border-b border-slate-800 bg-slate-900/20">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs text-slate-500 font-bold uppercase tracking-wider flex items-center gap-1">
              <Shield size={12} /> Defense & Impact
            </span>
            {deckState.flippedPile.length > 0 && (
              <button
                onClick={onClearDefense}
                className="text-[10px] text-slate-400 hover:text-white underline"
              >
                Clear
              </button>
            )}
          </div>

          {/* Active Defense Stats */}
          <div className="grid grid-cols-3 gap-2 text-center mb-3">
            <div className="bg-red-950/30 p-1 rounded border border-red-900/50">
              <Square size={12} className="mx-auto mb-1 text-red-500" />
              <span className="text-sm font-bold text-red-200">{defenseTotal.red}</span>
            </div>
            <div className="bg-yellow-950/30 p-1 rounded border border-yellow-900/50">
              <Circle size={12} className="mx-auto mb-1 text-yellow-500" />
              <span className="text-sm font-bold text-yellow-200">{defenseTotal.yellow}</span>
            </div>
            <div className="bg-blue-950/30 p-1 rounded border border-blue-900/50">
              <Diamond size={12} className="mx-auto mb-1 text-blue-500" />
              <span className="text-sm font-bold text-blue-200">{defenseTotal.blue}</span>
            </div>
          </div>

          <button
            onClick={onDefend}
            className="w-full bg-indigo-900/40 hover:bg-indigo-800/60 border border-indigo-500/30 text-indigo-200 text-xs font-bold py-2 rounded flex items-center justify-center gap-2 transition-all mb-4"
          >
            <Shield size={14} /> Flip for Defense
          </button>

          {/* Derived Stats */}
          <div className="space-y-3 text-xs border-t border-slate-800 pt-3">
            <div className="flex justify-between items-center">
              <span className="text-slate-400">Defense (From Items):</span>
              <span className="text-white font-mono font-bold">{defenseStat}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-400">Resilience:</span>
              <span className="text-white font-mono font-bold">{resilienceStat}</span>
            </div>

            <div className="bg-slate-800 p-2 rounded space-y-1">
              <div className="flex justify-between text-slate-300">
                <span>Impact (Cards Flipped):</span>
                <span className="font-bold">{impact}</span>
              </div>
              <div className="flex justify-between text-orange-300 border-t border-slate-700 pt-1 mt-1">
                <span>Consequences:</span>
                <span className="font-bold">
                  {calculatedConsequences > 0 ? calculatedConsequences : '-'}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Consequences (Conditions on Table) */}
        <div className="p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs text-slate-500 font-bold uppercase flex items-center gap-1">
              <AlertTriangle size={12} /> Consequences
            </span>
            <button
              onClick={onAddConsequence}
              className="text-[10px] bg-slate-800 hover:bg-red-900 text-slate-400 hover:text-red-200 px-2 py-0.5 rounded border border-slate-700 transition-colors"
            >
              + Add
            </button>
          </div>

          <div className="mb-3 bg-red-950/20 border border-red-900/30 p-2 rounded text-center">
            <span className="text-[10px] text-red-400 uppercase tracking-widest block mb-1">
              Severity Level
            </span>
            <span className="text-2xl font-black text-red-500">{currentSeverity}</span>
          </div>

          <div className="space-y-2">
            {deckState.consequences.length === 0 ? (
              <div className="text-[10px] text-slate-600 text-center italic py-2">
                No active consequences.
              </div>
            ) : (
              deckState.consequences.map((c) => (
                <div
                  key={c.id}
                  className="bg-slate-800 p-2 rounded border-l-2 border-red-500 text-xs text-slate-300 shadow-sm relative group"
                >
                  <div className="font-bold text-red-200 mb-1 flex justify-between items-start pr-4">
                    <span>{c.name}</span>
                    <button
                      onClick={() => onRemoveConsequence(c.id)}
                      className="absolute top-1 right-1 text-slate-600 hover:text-slate-300 p-0.5 rounded transition-colors"
                      title="Remove Consequence"
                    >
                      <X size={12} />
                    </button>
                  </div>
                  <div className="text-[10px] text-slate-400 whitespace-normal leading-normal">
                    {c.flavor && c.flavor[0]?.type === 'textRun' ? c.flavor[0].content : ''}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Equipped (Permanent) */}
        <div className="p-4 border-t border-slate-800">
          <span className="text-xs text-slate-500 font-bold uppercase mb-2 block flex items-center gap-1">
            <Briefcase size={12} /> Equipped
          </span>
          <div className="space-y-1">
            {deckState.equipped.map((c) => {
              const isItem = c.type === 'item';
              const def = isItem ? c.defense : undefined;
              const res = isItem ? c.resilience : undefined;

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
      </div>
    </div>
  );
};
