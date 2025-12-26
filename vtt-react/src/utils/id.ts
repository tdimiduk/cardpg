/**
 * ID Generation Utilities
 *
 * Provides a standard way to generate unique identifiers across the React application.
 * Uses crypto.randomUUID() when available (most modern environments) with a robust fallback.
 */

/**
 * Generates a UUID v4 string.
 * This is the preferred method for generating unique entity IDs.
 */
export const generateId = (): string => {
  // Use native crypto API if available
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }

  // Fallback for environments without crypto.randomUUID
  // Based on UUID v4 template
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
};

/**
 * Generates a short random ID (base36).
 * Useful for non-critical, ephemeral UI keys or short reference codes.
 * NOT guaranteed to be unique across large datasets.
 */
export const generateShortId = (prefix?: string): string => {
  const random = Math.random().toString(36).substring(2, 9);
  return prefix ? `${prefix}-${random}` : random;
};
