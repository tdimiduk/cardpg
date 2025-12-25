import React, { useState } from 'react';
import { ActionStack, CoreCard } from '../../generated/types';
import { flattenInstance } from '../../store/selectors';
import { useGameDispatch } from '../../hooks/useGameDispatch';
import { ActorState, CardLocation } from '../../generated/types';

import { ActiveActorHeader } from './ActiveActorHeader';
import { DeckStats } from './DeckStats';
import { StatusManager } from './StatusManager';
import { ConsequenceList } from './ConsequenceList';
import { EquippedList } from './EquippedList';
import { DeckViewerModal } from './DeckViewerModal';

interface ActorDetailsProps {
  actor: ActorState & { id: string };
  onResumeDefense: () => void;
}

export const ActorDetails: React.FC<ActorDetailsProps> = ({ actor, onResumeDefense }) => {
  const [showDeckModal, setShowDeckModal] = useState(false);
  const [showDiscardModal, setShowDiscardModal] = useState(false);

  const { dispatchCommand } = useGameDispatch();

  // Derived Values
  const defense = actor.defense ?? 1;
  const resilience = actor.resilience ?? 1;

  // Resolve piles directly (since they are now instances)
  const drawPile = actor.coreState.deck.map(flattenInstance);
  const discardPile = actor.coreState.discard.map(flattenInstance);
  const flippedPile = actor.coreState.defending.map(flattenInstance);

  // Handlers
  const handleDraw = (_count: number) => {
    dispatchCommand({ type: 'drawIntent', actorId: actor.id });
  };

  const handleReshuffle = () => {
    dispatchCommand({ type: 'reshuffleIntent', actorId: actor.id });
  };

  const handleAddConsequence = (severity?: number) => {
    dispatchCommand({
      type: 'addConsequenceIntent',
      actorId: actor.id,
      severity: severity,
    });
  };

  const handleRemoveConsequence = (cardId: string) => {
    dispatchCommand({
      type: 'destroyConsequenceIntent',
      actorId: actor.id,
      cardId,
    });
  };

  const handleAddStatusCard = (type: string, destination: CardLocation) => {
    dispatchCommand({
      type: 'addStatusIntent',
      actorId: actor.id,
      statusType: type,
      destination,
    });
  };

  const handleRemoveStatusCard = (type: string) => {
    dispatchCommand({
      type: 'destroyStatusIntent',
      actorId: actor.id,
      statusType: type,
    });
  };

  return (
    <>
      <DeckViewerModal
        isOpen={showDeckModal}
        onClose={() => setShowDeckModal(false)}
        cards={drawPile}
      />
      <DeckViewerModal
        isOpen={showDiscardModal}
        onClose={() => setShowDiscardModal(false)}
        cards={discardPile}
      />

      <ActiveActorHeader activeActorId={actor.id} actor={actor} />

      <div className="flex-1 overflow-y-auto custom-scrollbar space-y-1">
        <DeckStats
          actor={actor}
          onDraw={handleDraw}
          onReshuffle={handleReshuffle}
          onViewDeck={() => setShowDeckModal(true)}
          onViewDiscard={() => setShowDiscardModal(true)}
        />

        <StatusManager
          onAddStatusCard={handleAddStatusCard}
          onRemoveStatusCard={handleRemoveStatusCard}
        />

        {/* Compact Stats & Active Defense */}
        <div className="px-4 py-2 border-b border-slate-800 bg-slate-900/10 flex flex-col gap-2">
          <div className="flex justify-between items-center text-sm font-bold opacity-90">
            <span className="text-blue-300 flex items-center gap-1">🛡 Defense: {defense}</span>
            <span className="text-red-300 flex items-center gap-1">
              💖 Resilience: {resilience}
            </span>
          </div>

          {flippedPile.length > 0 && (
            <button
              onClick={onResumeDefense}
              className="w-full text-xs bg-indigo-900/80 hover:bg-indigo-800 text-indigo-200 border border-indigo-700/50 rounded py-1 px-2 animate-pulse font-bold transition-all shadow-sm flex items-center justify-center gap-2"
            >
              <span className="w-2 h-2 rounded-full bg-indigo-400 animate-ping" />
              Resume Active Defense
            </button>
          )}
        </div>

        <ConsequenceList
          activeActor={actor}
          onAddConsequence={handleAddConsequence}
          onRemoveConsequence={handleRemoveConsequence}
        />

        <EquippedList activeActor={actor} />
      </div>
    </>
  );
};
