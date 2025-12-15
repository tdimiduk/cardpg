import React, { useRef, useState, useCallback } from 'react';
import { Token, ActorState, GamePhase, UIPlannedAction } from '../../types';
import { GRID_SIZE } from '../../constants';
import { TokenEntity } from './TokenEntity';

interface MapBoardProps {
  tokens: Token[];
  onUpdateToken: (token: Token) => void;
  activeActorId: string | null;
  setActiveActorId: (id: string | null) => void;
  defeatedTokenIds?: string[];
  actors: Record<string, ActorState>;
  phase: GamePhase;
  plannedActions: Record<string, UIPlannedAction>;
}

export const MapBoard: React.FC<MapBoardProps> = ({
  tokens,
  onUpdateToken,
  activeActorId,
  setActiveActorId,
  defeatedTokenIds = [],
  actors,
  phase,
  plannedActions,
}) => {
  const boardRef = useRef<HTMLDivElement>(null);
  const [draggingToken, setDraggingToken] = useState<{
    id: string;
    startX: number;
    startY: number;
    initialTokenX: number;
    initialTokenY: number;
  } | null>(null);
  const [dragPreview, setDragPreview] = useState<{ x: number; y: number } | null>(null);

  const handleMouseDown = (e: React.MouseEvent, token: Token) => {
    // ... (keep existing logic)
    e.stopPropagation();
    setActiveActorId(token.actorId);

    setDraggingToken({
      id: token.id,
      startX: e.clientX,
      startY: e.clientY,
      initialTokenX: token.x,
      initialTokenY: token.y,
    });
    setDragPreview({ x: token.x * GRID_SIZE, y: token.y * GRID_SIZE });
  };

  const handleMouseMove = useCallback(
    (e: React.MouseEvent) => {
      // ... (keep existing logic)
      if (!draggingToken || !boardRef.current) return;
      const deltaX = e.clientX - draggingToken.startX;
      const deltaY = e.clientY - draggingToken.startY;
      setDragPreview({
        x: draggingToken.initialTokenX * GRID_SIZE + deltaX,
        y: draggingToken.initialTokenY * GRID_SIZE + deltaY,
      });
    },
    [draggingToken],
  );

  const handleMouseUp = useCallback(() => {
    // ... (keep existing logic)
    if (draggingToken && dragPreview) {
      const newGridX = Math.round(dragPreview.x / GRID_SIZE);
      const newGridY = Math.round(dragPreview.y / GRID_SIZE);
      const token = tokens.find((t) => t.id === draggingToken.id);
      if (token) {
        const finalX = Math.max(0, newGridX);
        const finalY = Math.max(0, newGridY);
        // Only update if position changed
        if (finalX !== token.x || finalY !== token.y) {
          onUpdateToken({ ...token, x: finalX, y: finalY });
        }
      }
    }
    setDraggingToken(null);
    setDragPreview(null);
  }, [draggingToken, dragPreview, tokens, onUpdateToken]);

  return (
    <div
      className="relative flex-1 bg-slate-900 overflow-auto custom-scrollbar cursor-crosshair select-none"
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
    >
      <div
        ref={boardRef}
        className="relative min-w-[2000px] min-h-[2000px] bg-grid-pattern bg-slate-800"
        style={{ backgroundSize: `${GRID_SIZE}px ${GRID_SIZE}px` }}
        onClick={() => setActiveActorId(null)}
      >
        {/* SVG Layer for Planned Paths */}
        <svg className="absolute inset-0 w-full h-full pointer-events-none z-20 overflow-visible">
          {tokens.map((token) => {
            const actor = actors[token.actorId];
            if (!actor || !actor.plannedMove) return null;

            const { x: targetX, y: targetY } = actor.plannedMove;
            if (targetX !== token.x || targetY !== token.y) {
              const startX = token.x * GRID_SIZE + GRID_SIZE / 2;
              const startY = token.y * GRID_SIZE + GRID_SIZE / 2;
              const endX = targetX * GRID_SIZE + GRID_SIZE / 2;
              const endY = targetY * GRID_SIZE + GRID_SIZE / 2;
              return (
                <g key={`path-${token.id}`}>
                  <line
                    x1={startX}
                    y1={startY}
                    x2={endX}
                    y2={endY}
                    stroke={actor.color}
                    strokeWidth="2"
                    strokeDasharray="5,5"
                    opacity="0.6"
                  />
                  <circle cx={endX} cy={endY} r="3" fill={actor.color} />
                </g>
              );
            }
            return null;
          })}
        </svg>

        {/* Tokens & Ghosts */}
        {tokens.map((token) => {
          const actor = actors[token.actorId];
          if (!actor) return null;

          const isDragging = draggingToken?.id === token.id;
          const isDefeated = defeatedTokenIds.includes(token.id);

          // Indicator Logic
          const deck = actor.deck;
          const plan = plannedActions[token.actorId];
          const rawHandSize = deck?.hand.length || 0;
          const plannedCount = plan ? plan.cards.length : 0;

          // If in planning phase, we sum hand + planned to hide information
          const displayHandSize = phase === 'planning' ? rawHandSize + plannedCount : rawHandSize;

          // We show 'hasPlan' indicator if there is a plan AND we are in planning/resolution
          // Actually, purely existing plan is enough.
          const hasPlan = !!plan;

          // 1. Render Planned "Ghost" Token if it exists and is different from start
          let GhostEntity = null;
          if (actor.plannedMove) {
            const { x: planX, y: planY } = actor.plannedMove;
            if (planX !== token.x || planY !== token.y) {
              GhostEntity = (
                <div
                  style={{
                    position: 'absolute',
                    left: planX * GRID_SIZE,
                    top: planY * GRID_SIZE,
                    zIndex: 40,
                    opacity: 0.5,
                  }}
                  className="pointer-events-none grayscale"
                >
                  <TokenEntity
                    token={token}
                    actor={actor}
                    isSelected={false}
                    onMouseDown={() => {}}
                  />
                </div>
              );
            }
          }

          // 2. Render Real Token
          let renderX = token.x * GRID_SIZE;
          let renderY = token.y * GRID_SIZE;
          if (isDragging && dragPreview) {
            renderX = dragPreview.x;
            renderY = dragPreview.y;
          }

          return (
            <React.Fragment key={token.id}>
              {GhostEntity}
              <div
                style={{
                  position: 'absolute',
                  left: renderX,
                  top: renderY,
                  transition: isDragging ? 'none' : 'all 0.2s ease-out',
                  zIndex: activeActorId === token.actorId ? 50 : 10,
                }}
                onClick={(e) => e.stopPropagation()}
              >
                <TokenEntity
                  token={token}
                  actor={actor}
                  isSelected={activeActorId === token.actorId}
                  onMouseDown={handleMouseDown}
                  isDefeated={isDefeated}
                  handSize={displayHandSize}
                  hasPlan={hasPlan}
                />
              </div>
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
};
