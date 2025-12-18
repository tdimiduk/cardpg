import React, { useRef, useState, useCallback } from 'react';
import { ActorState, Phase } from '../../generated/types';
import { GRID_SIZE } from '../../constants';
import { TokenEntity, TokenSpatial } from './TokenEntity';

interface MapBoardProps {
  onUpdateToken: (actorId: string, x: number, y: number) => void;
  activeActorId: string | null;
  setActiveActorId: (id: string | null) => void;
  defeatedTokenIds?: string[];
  actors: Record<string, ActorState>;
  phase: Phase;
}

export const MapBoard: React.FC<MapBoardProps> = ({
  onUpdateToken,
  activeActorId,
  setActiveActorId,
  defeatedTokenIds = [],
  actors,
  phase,
}) => {
  const boardRef = useRef<HTMLDivElement>(null);
  const [draggingActorId, setDraggingActorId] = useState<{
    id: string;
    startX: number;
    startY: number;
    initialX: number;
    initialY: number;
  } | null>(null);
  const [dragPreview, setDragPreview] = useState<{ x: number; y: number } | null>(null);

  const handleMouseDown = (e: React.MouseEvent, actorId: string, x: number, y: number) => {
    e.stopPropagation();
    setActiveActorId(actorId);

    setDraggingActorId({
      id: actorId,
      startX: e.clientX,
      startY: e.clientY,
      initialX: x,
      initialY: y,
    });
    setDragPreview({ x: x * GRID_SIZE, y: y * GRID_SIZE });
  };

  const handleMouseMove = useCallback(
    (e: React.MouseEvent) => {
      if (!draggingActorId || !boardRef.current) return;
      const deltaX = e.clientX - draggingActorId.startX;
      const deltaY = e.clientY - draggingActorId.startY;
      setDragPreview({
        x: draggingActorId.initialX * GRID_SIZE + deltaX,
        y: draggingActorId.initialY * GRID_SIZE + deltaY,
      });
    },
    [draggingActorId],
  );

  const handleMouseUp = useCallback(() => {
    if (draggingActorId && dragPreview) {
      const newGridX = Math.round(dragPreview.x / GRID_SIZE);
      const newGridY = Math.round(dragPreview.y / GRID_SIZE);

      const actor = actors[draggingActorId.id];

      if (actor && actor.spatial) {
        const finalX = Math.max(0, newGridX);
        const finalY = Math.max(0, newGridY);
        // Only update if position changed
        if (finalX !== actor.spatial.posX || finalY !== actor.spatial.posY) {
          onUpdateToken(draggingActorId.id, finalX, finalY);
        }
      }
    }
    setDraggingActorId(null);
    setDragPreview(null);
  }, [draggingActorId, dragPreview, actors, onUpdateToken]);

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
          {Object.entries(actors).map(([actorId, actor]) => {
            if (!actor.plannedMove) return null;

            const [targetX, targetY] = actor.plannedMove;

            if (targetX !== actor.spatial.posX || targetY !== actor.spatial.posY) {
              const startX = actor.spatial.posX * GRID_SIZE + GRID_SIZE / 2;
              const startY = actor.spatial.posY * GRID_SIZE + GRID_SIZE / 2;
              const endX = targetX * GRID_SIZE + GRID_SIZE / 2;
              const endY = targetY * GRID_SIZE + GRID_SIZE / 2;

              const color = (actor as unknown as { color?: string }).color || '#ccc';

              return (
                <g key={`path-${actorId}`}>
                  <line
                    x1={startX}
                    y1={startY}
                    x2={endX}
                    y2={endY}
                    stroke={color}
                    strokeWidth="2"
                    strokeDasharray="5,5"
                    opacity="0.6"
                  />
                  <circle cx={endX} cy={endY} r="3" fill={color} />
                </g>
              );
            }
            return null;
          })}
        </svg>

        {/* Tokens & Ghosts */}
        {Object.entries(actors).map(([actorId, actor]) => {
          const isDragging = draggingActorId?.id === actorId;
          const isDefeated = defeatedTokenIds.includes(`token-${actorId}`);

          // Construct TokenSpatial
          const token: TokenSpatial = {
            id: `token-${actorId}`,
            actorId: actorId,
            x: actor.spatial.posX,
            y: actor.spatial.posY,
            size: actor.spatial.size,
          };

          // Indicator Logic
          const handSize = actor.coreState.hand.length;
          // Calculate planned card count based on planned action type
          const planned = actor.coreState.planned;
          let plannedCount = 0;
          if (planned) {
            if (planned.type === 'pStandard') {
              plannedCount = 1 + planned.data.resources.length; // 1 action card + resources
            } else if (planned.type === 'pNarrative') {
              plannedCount = planned.data.cards.length;
            }
            // pPass has no cards
          }

          const displayHandSize = phase === 'planning' ? handSize + plannedCount : handSize;
          const hasPlan = !!actor.plannedMove;

          // 1. Render Planned "Ghost" Token
          let GhostEntity = null;
          if (actor.plannedMove) {
            const [planX, planY] = actor.plannedMove;
            if (planX !== actor.spatial.posX || planY !== actor.spatial.posY) {
              const ghostToken = { ...token, x: planX, y: planY };
              GhostEntity = (
                <div
                  style={{
                    position: 'absolute',
                    left: planX * GRID_SIZE,
                    top: planY * GRID_SIZE,
                    zIndex: 40,
                  }}
                >
                  <TokenEntity
                    token={ghostToken}
                    actor={actor}
                    isSelected={false}
                    onMouseDown={(e, t) => handleMouseDown(e, t.actorId, t.x, t.y)}
                    isGhost={true}
                  />
                </div>
              );
            }
          }

          // 2. Render Real Token
          let renderX = actor.spatial.posX * GRID_SIZE;
          let renderY = actor.spatial.posY * GRID_SIZE;
          if (isDragging && dragPreview) {
            renderX = dragPreview.x;
            renderY = dragPreview.y;
          }

          return (
            <React.Fragment key={actorId}>
              {GhostEntity}
              <div
                style={{
                  position: 'absolute',
                  left: renderX,
                  top: renderY,
                  transition: isDragging ? 'none' : 'all 0.2s ease-out',
                  zIndex: activeActorId === actorId ? 50 : 10,
                }}
                onClick={(e) => e.stopPropagation()}
              >
                <TokenEntity
                  token={token}
                  actor={actor}
                  isSelected={activeActorId === actorId}
                  onMouseDown={(e, t) => handleMouseDown(e, t.actorId, t.x, t.y)}
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
