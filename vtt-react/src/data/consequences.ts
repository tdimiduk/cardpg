export interface ConsequenceDefinition {
  name: string;
  text: string;
  severity: number;
}

export const CONSEQUENCE_DEFINITIONS: ConsequenceDefinition[] = [
  { name: 'Minor Scratch', text: 'A shallow cut.', severity: 1 },
  { name: 'Bruised', text: 'Painful to the touch.', severity: 1 },
  { name: 'Winded', text: 'Hard to catch breath.', severity: 1 },
  { name: 'Deep Cut', text: 'Bleeding profusely.', severity: 2 },
  { name: 'Concussed', text: 'Vision is blurry.', severity: 2 },
  { name: 'Sprained Ankle', text: 'Movement is difficult.', severity: 2 },
  { name: 'Broken Bone', text: 'Something snapped.', severity: 3 },
  { name: 'Internal Bleeding', text: 'Feeling cold.', severity: 3 },
  { name: 'Unconscious', text: 'Blacked out.', severity: 3 },
  { name: 'Taken Out', text: 'Defeated.', severity: 4 },
];
