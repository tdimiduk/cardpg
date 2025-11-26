export interface ConsequenceDefinition {
  id: string;
  name: string;
  text: string;
  severity: number;
}

export const CONSEQUENCE_DEFINITIONS: ConsequenceDefinition[] = [
  {
    id: "cons-sev1-strain-attack",
    name: "Strained Offense",
    text: "Passive: You must discard a card to perform an Attack Action.",
    severity: 1
  },
  {
    id: "cons-sev1-strain-defense",
    name: "Rattled Guard",
    text: "Passive: Impact of Defense +1.",
    severity: 1
  },
  {
    id: "cons-sev1-minor-trauma",
    name: "Minor Trauma",
    text: "Effect: Put 2 Injury cards on top of your deck.",
    severity: 1
  },
  {
    id: "cons-sev2-fumbled-strike",
    name: "Compromised Leverage",
    text: "Passive: When calculating Attack Strength, treat the highest value card in your stack as 0.",
    severity: 2
  },
  {
    id: "cons-sev2-guard-breach",
    name: "Breached Guard",
    text: "Passive: When calculating Defense Strength, treat the highest value card in your stack as 0.",
    severity: 2
  },
  {
    id: "cons-sev2-major-trauma",
    name: "Major Trauma",
    text: "Effect: Expend 4 cards from hand and replace them with Injury cards. For each card you cannot expend, put the Injury on top of your deck instead.",
    severity: 2
  },
  {
    id: "cons-sev3-taken-out",
    name: "Taken Out",
    text: "Effect: You are unconscious or dying and no longer a meaningful participant in this fight",
    severity: 3
  },
];