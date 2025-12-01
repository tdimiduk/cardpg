import { useState, useMemo } from 'react';
import { CoreCard, ResourceType, Rule } from '../types';

export interface UseHandSelectionProps {
  hand: CoreCard[];
  onPlayStack: (
    selectedCards: CoreCard[],
    strengthColor: ResourceType,
    modifier: number,
    targetDefense?: ResourceType,
    actionName?: string,
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
    [hand, selectedIds]
  );

  // Filter for cards that are strictly Actions (have a cost and a rule)
  // We look for the first Attack or General rule to define the action.
  const getActionRule = (card: CoreCard): Rule | undefined => {
    return card.rules?.find((r) => r.type === 'attack' || r.type === 'general');
  };

  const actionCards = useMemo(
    () =>
      selectedCards.filter(
        (c) => c.cost !== undefined && c.cost !== null && getActionRule(c)
      ),
    [selectedCards]
  );

  const handleImprovise = (color: ResourceType) => {
    if (selectedCards.length === 0) return;
    onPlayStack(selectedCards, color, 0, undefined, 'Improvised Action');
    clearSelection();
  };

  const handleSpecificAction = (card: CoreCard) => {
    const rule = getActionRule(card);
    if (!rule) return;

    if (rule.type === 'attack') {
      onPlayStack(
        selectedCards,
        rule.data.power.source,
        rule.data.power.modifier,
        rule.data.resistedBy,
        card.name
      );
    } else if (rule.type === 'general') {
      const source = rule.data.power?.source || 'Red';
      const modifier = rule.data.power?.modifier || 0;
      onPlayStack(selectedCards, source, modifier, undefined, card.name);
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
