import React, { useMemo } from 'react';
import { Token, TokenType, ActorState } from '../../types';
import { GRID_SIZE } from '../../constants';
import { User, Skull, Sword, X, StickyNote, CheckCircle2 } from 'lucide-react';

interface TokenEntityProps {
  token: Token;
  actor: ActorState;
  isSelected: boolean;
  onMouseDown: (e: React.MouseEvent, token: Token) => void;
  isDefeated?: boolean;
  handSize?: number;
  hasPlan?: boolean;
  isGhost?: boolean;
}

export const TokenEntity: React.FC<TokenEntityProps> = ({
  token,
  actor,
  isSelected,
  onMouseDown,
  isDefeated,
  handSize = 0,
  hasPlan = false,
  isGhost = false,
}) => {
  const style: React.CSSProperties = {
    // Position is handled by the parent container in MapBoard
    width: token.size * GRID_SIZE,
    height: token.size * GRID_SIZE,
    cursor: isGhost ? 'default' : 'grab', // Always interactive per request
  };

  const Icon = useMemo(() => {
    switch (actor.type) {
      case TokenType.MONSTER:
        return Skull;
      case TokenType.NPC:
        return User;
      case TokenType.PC:
        return Sword;
      default:
        return User;
    }
  }, [actor.type]);

  const containerClasses = [
    'group flex items-center justify-center relative',
    isDefeated ? 'grayscale opacity-70' : '',
    isGhost ? 'grayscale opacity-50' : '', // Removed pointer-events-none
  ].join(' ');

  return (
    <div
      style={style}
      onMouseDown={(e) => onMouseDown(e, token)} // Removed !isGhost check
      className={containerClasses}
      data-testid={isGhost ? 'token-ghost' : 'token-entity'}
      // aria-hidden={isGhost} // Removed to allow interaction semantics (or keep? It's interactive now, so shouldn't be hidden)
    >
      {/* Selection/Active Indicator Ring */}
      {isSelected && !isDefeated && !isGhost && (
        <div className="absolute -inset-1 rounded-full border-2 border-yellow-400 border-dashed animate-spin-slow pointer-events-none z-0"></div>
      )}
      {/* Defeated Selection Ring (Red/static) */}
      {isSelected && isDefeated && !isGhost && (
        <div className="absolute -inset-1 rounded-full border-2 border-red-900 border-dashed pointer-events-none z-0"></div>
      )}

      <div
        className={`
            w-full h-full rounded-full overflow-hidden relative border-2 z-10 transition-all
            ${
              isDefeated
                ? 'bg-slate-900 border-slate-700'
                : isSelected && !isGhost
                  ? 'bg-slate-800 border-yellow-400 shadow-[0_0_15px_rgba(250,204,21,0.5)] scale-105'
                  : 'bg-slate-800 border-white/20 hover:border-white/50'
            }
        `}
        style={{ backgroundColor: isDefeated ? '#334155' : actor.color }}
      >
        <Icon className="w-1/2 h-1/2 text-white opacity-80 m-auto mt-[25%]" />

        {isDefeated && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/50 backdrop-blur-sm">
            <X size={GRID_SIZE / 2} className="text-red-500 font-bold" strokeWidth={4} />
          </div>
        )}

        {/* Name Tag */}
        {!isGhost && (
          <div className="absolute -bottom-6 left-1/2 transform -translate-x-1/2 bg-black/70 text-white text-xs px-2 py-0.5 rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-50">
            {actor.name} {isDefeated ? '(Defeated)' : ''}
          </div>
        )}
      </div>

      {/* Status Indicators (Top Layer, outside the round overflow) */}
      {!isDefeated && !isGhost && (
        <>
          {/* Planned Action Indicator */}
          {hasPlan && (
            <div className="absolute -top-1 -right-1 z-30 bg-green-500 text-white rounded-full p-0.5 border border-slate-900 shadow-sm animate-bounce-short">
              <CheckCircle2 size={14} />
            </div>
          )}

          {/* Hand Size Indicator */}
          <div className="absolute -bottom-1 -right-1 z-30 flex items-center justify-center bg-slate-800 border border-slate-600 rounded bg-opacity-90 shadow py-0.5 px-1 min-w-[20px]">
            <StickyNote size={10} className="text-slate-400 mr-0.5" />
            <span className="text-[10px] font-bold text-white leading-none">{handSize}</span>
          </div>
        </>
      )}
    </div>
  );
};
