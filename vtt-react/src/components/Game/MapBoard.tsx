import React, { useRef, useState, useCallback } from 'react';
import { ActorState, GamePhase, UIPlannedAction } from '../../types';
import { GRID_SIZE } from '../../constants';
import { TokenEntity } from './TokenEntity';

interface MapBoardProps {
  // tokens prop removed
  onUpdateToken: (actorId: string, x: number, y: number) => void;
  activeActorId: string | null;
  setActiveActorId: (id: string | null) => void;
  defeatedTokenIds?: string[];
  actors: Record<string, ActorState>;
  phase: GamePhase;
  plannedActions: Record<string, UIPlannedAction>;
}

export const MapBoard: React.FC<MapBoardProps> = ({
  onUpdateToken,
  activeActorId,
  setActiveActorId,
  defeatedTokenIds = [],
  actors,
  phase,
  plannedActions,
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

  const actorList = Object.values(actors);

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
      if (actor) {
        const finalX = Math.max(0, newGridX);
        const finalY = Math.max(0, newGridY);
        // Only update if position changed
        if (finalX !== actor.x || finalY !== actor.y) {
          onUpdateToken(actor.id, finalX, finalY);
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
          {actorList.map((actor) => {
            if (!actor.plannedMove) return null;

            const { x: targetX, y: targetY } = actor.plannedMove;
            if (targetX !== actor.x || targetY !== actor.y) {
              const startX = actor.x * GRID_SIZE + GRID_SIZE / 2;
              const startY = actor.y * GRID_SIZE + GRID_SIZE / 2;
              const endX = targetX * GRID_SIZE + GRID_SIZE / 2;
              const endY = targetY * GRID_SIZE + GRID_SIZE / 2;
              return (
                <g key={`path-${actor.id}`}>
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
        {actorList.map((actor) => {
          const isDragging = draggingActorId?.id === actor.id;
          const isDefeated = defeatedTokenIds.includes(`token-${actor.id}`); // Assuming ID convention for now or we should check if defeated uses ActorID

          // Construct temporary token object for TokenEntity compatibility
          const token = {
            id: `token-${actor.id}`,
            actorId: actor.id,
            x: actor.x,
            y: actor.y,
            size: actor.size,
          };

          // Indicator Logic
          const deck = actor.deck;
          const plan = plannedActions[actor.id];
          const rawHandSize = deck?.hand.length || 0;
          const plannedCount = plan ? plan.cards.length : 0;

          const displayHandSize = phase === 'planning' ? rawHandSize + plannedCount : rawHandSize;
          const hasPlan = !!plan;

          // 1. Render Planned "Ghost" Token if it exists and is different from start
          let GhostEntity = null;
          if (actor.plannedMove) {
            const { x: planX, y: planY } = actor.plannedMove;
            if (planX !== actor.x || planY !== actor.y) {
              // Ghost token object
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
          let renderX = actor.x * GRID_SIZE;
          let renderY = actor.y * GRID_SIZE;
          if (isDragging && dragPreview) {
            renderX = dragPreview.x;
            renderY = dragPreview.y;
          }

          return (
            <React.Fragment key={actor.id}>
              {GhostEntity}
              <div
                style={{
                  position: 'absolute',
                  left: renderX,
                  top: renderY,
                  transition: isDragging ? 'none' : 'all 0.2s ease-out',
                  zIndex: activeActorId === actor.id ? 50 : 10,
                }}
                onClick={(e) => e.stopPropagation()}
              >
                <TokenEntity
                  token={token}
                  actor={actor}
                  isSelected={activeActorId === actor.id}
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
