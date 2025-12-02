import React, { useMemo } from 'react';
import { Token, TokenType, Actor } from '../../types';
import { GRID_SIZE } from '../../constants';
import { User, Skull, Sword, X } from 'lucide-react';

interface TokenEntityProps {
  token: Token;
  actor: Actor;
  isSelected: boolean;
  onMouseDown: (e: React.MouseEvent, token: Token) => void;
  isDefeated?: boolean;
}

export const TokenEntity: React.FC<TokenEntityProps> = ({
  token,
  actor,
  isSelected,
  onMouseDown,
  isDefeated,
}) => {
  const style: React.CSSProperties = {
    // Position is handled by the parent container in MapBoard
    width: token.size * GRID_SIZE,
    height: token.size * GRID_SIZE,
    cursor: 'grab', // Always interactive per request
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

  return (
    <div
      style={style}
      onMouseDown={(e) => onMouseDown(e, token)}
      className={`group flex items-center justify-center relative ${isDefeated ? 'grayscale opacity-70' : ''}`}
    >
      {/* Selection/Active Indicator Ring */}
      {isSelected && !isDefeated && (
        <div className="absolute -inset-1 rounded-full border-2 border-yellow-400 border-dashed animate-spin-slow pointer-events-none z-0"></div>
      )}
      {/* Defeated Selection Ring (Red/static) */}
      {isSelected && isDefeated && (
        <div className="absolute -inset-1 rounded-full border-2 border-red-900 border-dashed pointer-events-none z-0"></div>
      )}

      <div
        className={`
            w-full h-full rounded-full overflow-hidden relative border-2 z-10 transition-all
            ${
              isDefeated
                ? 'bg-slate-900 border-slate-700'
                : isSelected
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
        <div className="absolute -bottom-6 left-1/2 transform -translate-x-1/2 bg-black/70 text-white text-xs px-2 py-0.5 rounded whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-50">
          {actor.name} {isDefeated ? '(Defeated)' : ''}
        </div>
      </div>
    </div>
  );
};
