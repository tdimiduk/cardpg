import React, { useRef, useState, useCallback } from 'react';
import { Token, PlannedAction, Actor } from '../../types';
import { GRID_SIZE } from '../../constants';
import { TokenEntity } from './TokenEntity';

interface MapBoardProps {
  tokens: Token[];
  onUpdateToken: (token: Token) => void;
  activeTokenId: string | null;
  setActiveTokenId: (id: string | null) => void;
  plannedActions?: Record<string, PlannedAction>;
  defeatedTokenIds?: string[];
  actors: Record<string, Actor>;
}

export const MapBoard: React.FC<MapBoardProps> = ({
  tokens,
  onUpdateToken,
  activeTokenId,
  setActiveTokenId,
  plannedActions = {},
  defeatedTokenIds = [],
  actors,
}) => {
  // ... (keep existing refs and state)
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
    setActiveTokenId(token.id);

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
        onUpdateToken({ ...token, x: finalX, y: finalY });
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
        onClick={() => setActiveTokenId(null)}
      >
        {/* SVG Layer for Planned Paths */}
        <svg className="absolute inset-0 w-full h-full pointer-events-none z-20 overflow-visible">
          {tokens.map((token) => {
            const actor = actors[token.actorId];
            if (!actor) return null;

            const plan = plannedActions[token.id];
            if (plan && plan.move && (plan.move.x !== token.x || plan.move.y !== token.y)) {
              const startX = token.x * GRID_SIZE + GRID_SIZE / 2;
              const startY = token.y * GRID_SIZE + GRID_SIZE / 2;
              const endX = plan.move.x * GRID_SIZE + GRID_SIZE / 2;
              const endY = plan.move.y * GRID_SIZE + GRID_SIZE / 2;
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
          const plan = plannedActions[token.id];
          const isDefeated = defeatedTokenIds.includes(token.id);

          // 1. Render Planned "Ghost" Token if it exists and is different from start
          let GhostEntity = null;
          if (plan && plan.move && (plan.move.x !== token.x || plan.move.y !== token.y)) {
            GhostEntity = (
              <div
                style={{
                  position: 'absolute',
                  left: plan.move.x * GRID_SIZE,
                  top: plan.move.y * GRID_SIZE,
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
                  zIndex: activeTokenId === token.id ? 50 : 10,
                }}
                onClick={(e) => e.stopPropagation()}
              >
                <TokenEntity
                  token={token}
                  actor={actor}
                  isSelected={activeTokenId === token.id}
                  onMouseDown={handleMouseDown}
                  isDefeated={isDefeated}
                />
              </div>
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
};
