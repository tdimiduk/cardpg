import { useState, useMemo, useCallback } from 'react';
import { ResourceType, Rule } from '../generated/types';
import { ClientCoreCard } from '../store/selectors';
import { RESOURCE_TYPES } from '../constants';

export interface UseHandSelectionProps {
  hand: ClientCoreCard[];
  onPlayStack: (
    selectedCards: ClientCoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
    actionCardId?: string,
  ) => void;
}

export const useHandSelection = ({ hand, onPlayStack }: UseHandSelectionProps) => {
  // Staging state
  const [stagedActionId, setStagedActionId] = useState<string | null>(null);
  const [stagedResourceIds, setStagedResourceIds] = useState<Set<string>>(new Set());

  // Reset all selection state
  const clearStaging = useCallback(() => {
    setStagedActionId(null);
    setStagedResourceIds(new Set());
  }, []);

  // Filter for cards that are strictly Actions (have a cost and a rule)
  const getActionRule = (card: ClientCoreCard): Rule | undefined => {
    return card.rules?.find((r) => r.type === 'attack' || r.type === 'general');
  };

  // Identify cards that CAN be actions (have cost + rule)
  // Computed entirely from props, not state
  const actionCandidates = useMemo(() => {
    return new Set(
      hand
        .filter((c) => c.cost !== undefined && c.cost !== null && getActionRule(c))
        .map((c) => c.id),
    );
  }, [hand]);

  // Derived state
  const stagedActionCard = useMemo(
    () => (stagedActionId ? hand.find((c) => c.id === stagedActionId) : null),
    [hand, stagedActionId],
  );

  const stagedResourceCards = useMemo(
    () => hand.filter((c) => stagedResourceIds.has(c.id)),
    [hand, stagedResourceIds],
  );

  // Validation
  const currentCost = stagedActionCard?.cost ?? 0;
  const currentCount = stagedResourceCards.length;
  // Validation: Resources needed must equal the action cost.
  const isReady = !!stagedActionCard && currentCount === currentCost;
  const missingCount = currentCost - currentCount;

  // Actions
  const stageAction = useCallback((cardId: string) => {
    // Clear resources when switching actions, unless the new action card was previously a resource.
    setStagedResourceIds((prev) => {
      const next = new Set(prev);
      if (next.has(cardId)) next.delete(cardId);
      return next;
    });
    setStagedActionId(cardId);
  }, []);

  const unstageAction = useCallback(() => {
    setStagedActionId(null);
    // Unstaging action clears resources as well.
    setStagedResourceIds(new Set());
  }, []);

  const toggleResource = useCallback(
    (cardId: string) => {
      // Can't toggle the action card itself
      if (cardId === stagedActionId) return;

      setStagedResourceIds((prev) => {
        const next = new Set(prev);
        if (next.has(cardId)) {
          next.delete(cardId);
        } else {
          // Allow toggle. Validation happens at commit time.
          next.add(cardId);
        }
        return next;
      });
    },
    [stagedActionId],
  );

  const commitAction = useCallback(() => {
    if (!stagedActionCard || !isReady) return;

    const rule = getActionRule(stagedActionCard);
    if (!rule) return;

    // Construct the selection list: [ActionCard, ...ResourceCards]
    // The previous logic passed `selectedCards` which included the action card itself.
    const allCards = [stagedActionCard, ...stagedResourceCards];

    if (rule.type === 'attack') {
      onPlayStack(
        allCards,
        rule.data.power.source,
        rule.data.power.modifier,
        rule.data.resistedBy,
        stagedActionCard.name,
        stagedActionCard.id,
      );
    } else if (rule.type === 'general') {
      const source = rule.data.difficulty?.attribute || RESOURCE_TYPES.RED;
      const modifier = 0;
      onPlayStack(
        allCards,
        source,
        modifier,
        undefined,
        stagedActionCard.name,
        stagedActionCard.id,
      );
    }

    clearStaging();
  }, [stagedActionCard, stagedResourceCards, isReady, onPlayStack, clearStaging]);

  // Improvise / Narrative (Fallback for "Force/Speed/Mind" buttons)
  // Currently unused until we define Improvise flow in new model
  const handleImprovise = useCallback((_color: ResourceType) => {
    // Placeholder
  }, []);

  return {
    stagedActionId,
    stagedResourceIds,
    stagedActionCard,
    stagedResourceCards,
    actionCandidates,

    isReady,
    currentCost,
    currentCount,
    missingCount,

    stageAction,
    unstageAction,
    toggleResource,
    clearStaging,
    commitAction,
    getActionRule,
    // Export improviser for future use or if we decide to wire it up
    handleImprovise,
  };
};
