
import React from 'react';
import { Token, TokenType, PlayerDeckState } from '../types';
import { Layers, RefreshCw, Shield, Square, Circle, Diamond, Briefcase, User, Skull, AlertOctagon, Activity, Plus, Minus, AlertTriangle, Hand, ArrowUp, Archive, X } from 'lucide-react';
import { CardComponent } from './Card';
import { getAttributeValue, calculateSeverity } from '../services/ruleService';

interface SidebarLeftProps {
  deckState: PlayerDeckState | null;
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
    hasPlannedAction
}) => {
  
  // Empty State / Character Selector
  if (!deckState || !activeToken) {
      return (
          <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl">
               <div className="p-4 border-b border-slate-800 flex items-center gap-2">
                    <Layers className="text-indigo-500" />
                    <h1 className="font-bold text-lg tracking-wider text-slate-100">caRd<span className="text-indigo-500">PG</span></h1>
               </div>
               <div className="p-6 text-center space-y-6">
                  <div className="text-slate-500 text-sm italic">Select an actor to view their hand and deck.</div>
                  <div className="space-y-2">
                      {tokens.map(token => (
                          <button key={token.id} onClick={() => onSelectToken(token.id)} className="w-full flex items-center gap-3 bg-slate-900 hover:bg-slate-800 p-2 rounded border border-slate-800 hover:border-slate-600 transition-all group">
                             <div className="w-8 h-8 rounded-full overflow-hidden bg-slate-800 flex items-center justify-center shrink-0 border border-slate-600">
                                {token.imageUrl ? <img src={token.imageUrl} alt={token.name} className="w-full h-full object-cover" /> : token.type === TokenType.MONSTER ? <Skull size={16} className="text-emerald-400" /> : <User size={16} className="text-indigo-400" />}
                             </div>
                             <div className="text-left">
                                 <div className="font-bold text-slate-200 text-sm group-hover:text-white" style={{ color: token.color }}>{token.name}</div>
                                 <div className="text-[10px] text-slate-500 uppercase">{token.type}</div>
                             </div>
                          </button>
                      ))}
                  </div>
               </div>
          </div>
      );
  }

  const defenseTotal = {
      red: deckState.flippedPile.reduce((sum, c) => sum + (c.red ?? 0), 0),
      yellow: deckState.flippedPile.reduce((sum, c) => sum + (c.yellow ?? 0), 0),
      blue: deckState.flippedPile.reduce((sum, c) => sum + (c.blue ?? 0), 0),
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

  return (
    <div className="w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl">
      <div className="p-4 border-b border-slate-800 flex items-center gap-2">
        <Layers className="text-indigo-500" />
        <h1 className="font-bold text-lg tracking-wider text-slate-100">caRd<span className="text-indigo-500">PG</span></h1>
      </div>

      {/* Active Actor Header */}
      <div className="p-4 border-b border-slate-800 bg-slate-900 flex items-center gap-3">
         <div className="w-10 h-10 rounded-full border-2 border-slate-600 overflow-hidden bg-slate-800 flex items-center justify-center shrink-0">
             {activeToken.imageUrl ? <img src={activeToken.imageUrl} alt={activeToken.name} className="w-full h-full object-cover" /> : <User size={20} className="text-slate-400" />}
         </div>
         <div className="flex-1 overflow-hidden">
             <div className="font-bold text-slate-100 truncate" style={{ color: activeToken.color }}>{activeToken.name}</div>
             <div className="text-xs text-slate-500 uppercase flex items-center gap-2">
                 {activeToken.type}
                 {hasPlannedAction && <span className="text-indigo-400 font-bold flex items-center gap-1 text-[10px] border border-indigo-900 px-1 rounded bg-indigo-950"><Activity size={10} /> Ready</span>}
             </div>
         </div>
      </div>

      <div className="flex-1 overflow-y-auto custom-scrollbar space-y-1">
          
          {/* Deck State */}
          <div className="p-4 border-b border-slate-800">
              <div className="flex items-center justify-between mb-3">
                  <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">Deck & Resources</span>
                  <button 
                    onClick={onReshuffle} 
                    className="flex items-center gap-1 text-[10px] bg-slate-800 hover:bg-blue-900 text-slate-400 hover:text-blue-200 px-2 py-1 rounded border border-slate-700 transition-colors"
                    title="Shuffle Discard into Draw Pile"
                  >
                      <RefreshCw size={10} /> Reshuffle
                  </button>
              </div>
              
              <div className="grid grid-cols-2 gap-2 mb-4">
                  <div className="bg-slate-900 p-2 rounded border border-slate-800 flex flex-col items-center">
                      <span className="text-xs text-slate-500">Draw Pile</span>
                      <span className="text-xl font-bold text-slate-200">{deckState.drawPile.length}</span>
                      <button onClick={() => onDraw(1)} className="mt-1 w-full text-[10px] bg-slate-800 hover:bg-slate-700 py-1 rounded text-slate-300">Draw 1</button>
                  </div>
                  <div className="bg-slate-900 p-2 rounded border border-slate-800 flex flex-col items-center">
                      <span className="text-xs text-slate-500">Discard</span>
                      <span className="text-xl font-bold text-slate-200">{deckState.discardPile.length}</span>
                      <span className="text-[8px] text-slate-600 mt-1 h-5"></span>
                  </div>
              </div>

              {/* Status Cards (Fatigue/Injury) */}
              <div className="bg-slate-900/50 rounded border border-slate-800 p-2">
                  <span className="text-[10px] text-slate-500 font-bold uppercase mb-2 block">Status Cards in Deck</span>
                  
                  {/* Fatigue Row */}
                  <div className="flex items-center justify-between mb-2">
                      <span className="text-xs text-slate-300 flex items-center gap-1"><Activity size={12} className="text-red-400" /> Fatigue</span>
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
                      <span className="text-xs text-slate-300 flex items-center gap-1"><AlertOctagon size={12} className="text-orange-400" /> Injury</span>
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
                      <button onClick={onClearDefense} className="text-[10px] text-slate-400 hover:text-white underline">Clear</button>
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
              
              <button onClick={onDefend} className="w-full bg-indigo-900/40 hover:bg-indigo-800/60 border border-indigo-500/30 text-indigo-200 text-xs font-bold py-2 rounded flex items-center justify-center gap-2 transition-all mb-4">
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
                          <span className="font-bold">{calculatedConsequences > 0 ? calculatedConsequences : '-'}</span>
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
                  <button onClick={onAddConsequence} className="text-[10px] bg-slate-800 hover:bg-red-900 text-slate-400 hover:text-red-200 px-2 py-0.5 rounded border border-slate-700 transition-colors">
                      + Add
                  </button>
              </div>
              
              <div className="mb-3 bg-red-950/20 border border-red-900/30 p-2 rounded text-center">
                  <span className="text-[10px] text-red-400 uppercase tracking-widest block mb-1">Severity Level</span>
                  <span className="text-2xl font-black text-red-500">{currentSeverity}</span>
              </div>

              <div className="space-y-2">
                  {deckState.consequences.length === 0 ? (
                      <div className="text-[10px] text-slate-600 text-center italic py-2">No active consequences.</div>
                  ) : (
                      deckState.consequences.map((c) => (
                          <div key={c.id} className="bg-slate-800 p-2 rounded border-l-2 border-red-500 text-xs text-slate-300 shadow-sm relative group">
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
                                  {c.text[0]?.type === 'text' ? c.text[0].content : ''}
                              </div>
                          </div>
                      ))
                  )}
              </div>
           </div>

           {/* Equipped (Permanent) */}
           <div className="p-4 border-t border-slate-800">
               <span className="text-xs text-slate-500 font-bold uppercase mb-2 block flex items-center gap-1"><Briefcase size={12} /> Equipped</span>
               <div className="space-y-1">
                   {deckState.equipped.map(c => (
                       <div key={c.id} className="bg-slate-900 p-1.5 rounded text-xs text-slate-300 flex justify-between items-center border border-slate-800">
                           <span className="truncate pr-2">{c.name}</span>
                           {(c.def !== undefined || c.res !== undefined) && (
                               <span className="text-[9px] text-slate-500 font-mono bg-slate-950 px-1 rounded">
                                   {c.def !== undefined ? `D:${c.def}` : ''} {c.res !== undefined ? `R:${c.res}` : ''}
                               </span>
                           )}
                       </div>
                   ))}
               </div>
           </div>

      </div>
    </div>
  );
};
