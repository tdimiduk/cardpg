export const ACTOR_COLORS = {
  PC: '#3b82f6', // blue-500
  MONSTER: '#10b981', // emerald-500
} as const;

export const TOKEN_COLORS = {
  ...ACTOR_COLORS,
} as const;
