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
  // Rule: You need exactly cost cards as resources (total cards = cost + 1 action card)
  // Wait, legacy logic was: "requiredTotal = cost + 1" (total cards involved)
  // So resources needed = cost.
  // diff = requiredTotal - currentCount (where currentCount was total cards).
  // New logic:
  // resources needed = cost.
  // resources have = currentCount.
  const isReady = !!stagedActionCard && currentCount === currentCost;
  const missingCount = currentCost - currentCount;

  // Actions
  const stageAction = useCallback((cardId: string) => {
    // If we already have resources selected but no action, keep them?
    // Design decision: Clear resources when switching actions to avoid confusion?
    // Or keep them if possible?
    // Let's keep them, but filter out the new action card if it was a resource.
    setStagedResourceIds((prev) => {
      const next = new Set(prev);
      if (next.has(cardId)) next.delete(cardId);
      return next;
    });
    setStagedActionId(cardId);
  }, []);

  const unstageAction = useCallback(() => {
    setStagedActionId(null);
    // Keep resources? Or clear all? "Cmd+Z" feeling implies stepping back.
    // Let's keep resources as "selected resources" generally doesn't make sense without an action?
    // Actually, if we unstage action, we just go back to "nothing staged".
    // Resources without an action are just... cards in hand.
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
          // Prevent adding more than cost?
          // User might want to overpay or change selection.
          // Let's allow adding, but UI will show if it's too many.
          // Wait, logic says strictly equal?
          // "isValid = diff === 0". Previous code didn't strictly forbid > cost but button disabled if diff != 0.
          // Let's allow selecting freely, let isReady determine if commit is allowed.
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
