import React from 'react';
import { Activity, Minus, Hand, ArrowUp, Archive, AlertOctagon } from 'lucide-react';
import { CardLocation } from '../../generated/types';

interface StatusManagerProps {
  onAddStatusCard: (type: string, destination: CardLocation) => void;
  onRemoveStatusCard: (type: string) => void;
}

const AVAILABLE_STATUSES = [
  { id: 'Fatigue', name: 'Fatigue', type: 'Fatigue' },
  { id: 'Injury', name: 'Injury', type: 'Injury' },
];

export const StatusManager: React.FC<StatusManagerProps> = ({
  onAddStatusCard,
  onRemoveStatusCard,
}) => {
  return (
    <div className="bg-slate-900/50 rounded border border-slate-800 p-2 mx-4 mb-4">
      <span className="text-[10px] text-slate-500 font-bold uppercase mb-2 block">
        Status Cards in Deck
      </span>

      {AVAILABLE_STATUSES.map((status) => (
        <div key={status.id} className="flex items-center justify-between mb-2 last:mb-0">
          <span className="text-xs text-slate-300 flex items-center gap-1">
            {status.type === 'Fatigue' ? (
              <Activity size={12} className="text-red-400" />
            ) : (
              <AlertOctagon size={12} className="text-orange-400" />
            )}
            {status.name}
          </span>
          <div className="flex gap-1">
            <button
              onClick={() => onRemoveStatusCard(status.id)}
              className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-red-900/50 text-slate-400 hover:text-red-300 border border-slate-700"
              title={`Remove 1 ${status.name} from Game`}
            >
              <Minus size={10} />
            </button>
            <button
              onClick={() => onAddStatusCard(status.id, 'hand')}
              className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
              title={`Add ${status.name} to Hand`}
            >
              <Hand size={10} />
            </button>
            <button
              onClick={() => onAddStatusCard(status.id, 'deck')}
              className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
              title={`Add ${status.name} to Top of Deck`}
            >
              <ArrowUp size={10} />
            </button>
            <button
              onClick={() => onAddStatusCard(status.id, 'discard')}
              className="w-6 h-6 flex items-center justify-center rounded bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-slate-200 border border-slate-700"
              title={`Add ${status.name} to Discard`}
            >
              <Archive size={10} />
            </button>
          </div>
        </div>
      ))}
    </div>
  );
};
