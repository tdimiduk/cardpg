import { useMemo } from 'react';

export type WithId<T> = T & { id: string };

/**
 * generic hook to resolve a list of IDs against a registry.
 * Returns an array of objects with the 'id' property injected.
 */
export function useResolvedCards<T>(
  ids: string[] | undefined,
  registry: Record<string, T> | undefined,
): WithId<T>[] {
  return useMemo(() => {
    if (!ids || !registry) return [];

    return ids
      .map((id) => {
        const item = registry[id];
        if (!item) return undefined;
        return { ...item, id };
      })
      .filter((item): item is WithId<T> => !!item);
  }, [ids, registry]);
}
