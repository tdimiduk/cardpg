import { useState, useMemo } from 'react';
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
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  const toggleSelection = (id: string) => {
    setSelectedIds((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(id)) {
        newSet.delete(id);
      } else {
        newSet.add(id);
      }
      return newSet;
    });
  };

  const clearSelection = () => {
    setSelectedIds(new Set());
  };

  const selectedCards = useMemo(
    () => hand.filter((c) => selectedIds.has(c.id)),
    [hand, selectedIds],
  );

  // Filter for cards that are strictly Actions (have a cost and a rule)
  // We look for the first Attack or General rule to define the action.
  const getActionRule = (card: ClientCoreCard): Rule | undefined => {
    return card.rules?.find((r) => r.type === 'attack' || r.type === 'general');
  };

  const actionCards = useMemo(
    () => selectedCards.filter((c) => c.cost !== undefined && c.cost !== null && getActionRule(c)),
    [selectedCards],
  );

  const handleImprovise = (color: ResourceType) => {
    if (selectedCards.length === 0) return;
    onPlayStack(selectedCards, color, 0, undefined, 'Improvised Action');
    clearSelection();
  };

  const handleSpecificAction = (card: ClientCoreCard) => {
    const rule = getActionRule(card);
    if (!rule) return;

    if (rule.type === 'attack') {
      onPlayStack(
        selectedCards,
        rule.data.power.source,
        rule.data.power.modifier,
        rule.data.resistedBy,
        card.name,
        card.id,
      );
    } else if (rule.type === 'general') {
      const source = rule.data.difficulty?.attribute || RESOURCE_TYPES.RED;
      const modifier = 0;
      onPlayStack(selectedCards, source, modifier, undefined, card.name, card.id);
    }
    clearSelection();
  };

  return {
    selectedIds,
    selectedCards,
    actionCards,
    toggleSelection,
    clearSelection,
    handleImprovise,
    handleSpecificAction,
    getActionRule,
  };
};
