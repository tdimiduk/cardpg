# Factual Consequence Database Hub

This file serves as the central hub and calibration guide for the structured, rules-independent databases of physical, cognitive, environmental, and social stress states for **caRdPG**, grounded in clinical medicine, biomechanics, wilderness survival, and historical research.

These databases are located in the research directory to prioritize factual verisimilitude. **Do not add card mechanics or game rules here.**

---

## AI Calibration Registry & Anchors

When brainstorming new entries, the AI must align its ratings with the calibration brackets below. Refer to these brackets to ensure consistent severity scaling across all sub-databases.

> [!NOTE]
> While the baseline calibration brackets below are defined in terms of physical trauma, **each domain-specific database contains its own specialized calibration guidelines** (e.g., mapping social ruin, psychological stress, environmental exposure, and crafting/labor accidents to the 1-100 scales). Refer to those files directly when generating entries for those domains.

### Calibration Brackets

#### Onset Impact (1-100) - Severity when it occurs:

- **1–10 (Minor)**: Mild distraction or nuisance pain. Easily ignored under adrenaline; minor stance shifts or temporary disorientation (e.g., Stumbled, Winded, Dust in Eyes).
- **11–30 (Moderate)**: Sharp/throbbing pain; partial impairment of a limb or sensory organ, noticeable bleeding. Noticeably degrades fine motor control and focus (e.g., Sprained Wrist, Shallow Laceration, Ringing Ears).
- **31–60 (Severe)**: Excruciating pain requiring muscle guarding; full impairment of a limb or sensory organ, simple bone fracture, moderate concussion (e.g., Broken Arm, Rib Fracture, Severe Concussion).
- **61–90 (Critical)**: Shock-inducing trauma; life-threatening internal organ damage, severe hemorrhaging, or systemic collapse/unconsciousness (e.g., Ruptured Spleen, Sucking Chest Wound, Compound Leg Fracture).
- **91–100 (Fatal)**: Instant death or permanent total incapacitation (e.g., Decapitation, Crushed Windpipe).

#### Terminal Impact (1-100) - Peak escalation if left untreated:

- **1–10 (Minor)**: Resolves or remains minor; no progressive threat or risk of complications.
- **11–30 (Moderate)**: Escalates to moderate distraction or impairment; low risk of life threat but potential minor secondary issues.
- **31–60 (Severe)**: Escalates to severe structural impairment, localized necrosis, or severe non-fatal systemic illness if neglected.
- **61–90 (Critical)**: Progresses to highly critical status, severe shock, massive infection, or major organ loss; survivable only with extreme luck/hardiness.
- **91–100 (Fatal)**: Guaranteed death if not aggressively treated or magically mitigated (e.g., sepsis, fatal blood loss, asphyxiation).
- **`-` (No Escalation)**: The consequence does not escalate over time. Its peak severity remains at its Onset Impact value.

#### Recovery Difficulty (1-100) - Care, time, and resources needed to clear:

- **1–10 (Trivial)**: Resolves naturally in seconds to minutes with deep breaths or minor adjustments (e.g., Catching Balance, Blinking out Dust).
- **11–30 (Minor)**: Resolves in hours to 1 week with basic field care, bandages, sleep, or rehydration (e.g., Shallow Cut, Muscle Strain, Ringing Ears).
- **31–60 (Moderate)**: Resolves in 1 week to 2 months; requires clinical attention (stitches, splints, casting) and relative rest (e.g., Simple Fracture, Sprained Wrist, Deep Puncture Wound).
- **61–90 (Major)**: Resolves in 2 months to 1 year; requires surgical intervention, intensive physical therapy, or rare active antidotes (e.g., Shattered Joint, Sucking Chest Wound, Compound Fracture).
- **91–100 (Permanent)**: Permanent, irreversible tissue loss, or requires miraculous/magical intervention (e.g., Amputated Limb, Severe Brain Damage).

---

## Domain Databases

To keep file sizes manageable and organize consequences logically by the pillar of play, the database is partitioned into the following registries:

1. **[Combat Consequences](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-combat.md)**
   - _Scope:_ Direct martial engagements, weapon trauma (slashing, piercing, blunt), and tactical posture/movement penalties.
2. **[Exploration Consequences](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-exploration.md)**
   - _Scope:_ Traversing rugged terrain, environmental exposure (hypothermia, heatstroke), survival deprivations (water, food, sleep), and wilderness pathogens.
3. **[Social Consequences](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-social.md)**
   - _Scope:_ Interpersonal failures, psychological stress (panic, paranoia), reputation loss, blackmail, and systemic social exclusion.
4. **[Crafting Consequences](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-crafting.md)**
   - _Scope:_ Industrial accidents (smelting/acid burns, smoke inhalation), tool failures, repetitive strain/ergonomic injury, and labor fatigue.
5. **[Arcane & Alchemical Consequences](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-arcane.md)**
   - _Scope:_ Magical backdrafts, spellcasting feedback, elemental exposure (frost, flame), alchemical toxicity, and runic failures.
6. **[Logistics & Equipment Consequences](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-logistics.md)**
   - _Scope:_ Equipment wear, structural transport breakdowns, supply contamination, and pack animal injuries.
