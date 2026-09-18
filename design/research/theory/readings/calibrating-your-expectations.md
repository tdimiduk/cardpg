---
title: "Literature Note: Calibrating Your Expectations"
doc_type: "literature-note"
track: "ludology"
source:
  title: "D&D: Calibrating Your Expectations"
  author: "Justin Alexander (The Alexandrian)"
  url: "https://thealexandrian.net/wordpress/587/roleplaying-games/dd-calibrating-your-expectations"
  published_date: "2007-03-13"
origin: "Gemini 3.8 Flash (Antigravity)"
epistemic_status:
  confidence: "high"
  vetted_by_human: false
  vetting_notes: "Initial draft in review. Sections 3 and 4 updated to reflect scale-invariance, numerical card advancement, and macro-scale decks."
related_files:
  - "design/philosophy/guiding-principles.md"
  - "design/philosophy/design-precepts.md"
  - "design/philosophy/game-settings.md"
  - "design/methodology/paradigm-shifts.md"
  - "design/rules/gamemaster-guide.md"
  - "design/research/theory/readings/exploration-is-logistics.md"
  - "design/research/ludology-sources.yaml"
---

# Literature Note: Calibrating Your Expectations

## 1. Source Overview

- **Source:** _The Alexandrian_ (March 13, 2007)
- **Author:** Justin Alexander
- **Archived Copy:** `design/research/sources/ludology/alexander-2007-calibrating-expectations.md`
- **Core Premise:** D&D 3rd Edition demonstrates remarkable mechanical fidelity to real-world physical and historical performance when analyzed through actual system demographics and benchmarked against real-world tasks, rather than assuming that level 20 represents earthly mastery. Alexander defines **"Casual Realism"** as the capacity of a tabletop ruleset to accept real-world inputs and generate plausible physical outcomes without forcing players or GMs into cumbersome table-side physics calculations.

---

## 2. Key Theses from the Essay

### 1. The Definition of "Casual Realism"

A tabletop game is not an academic physics treatise; its mechanics must prioritize playability, flow, and drama. However, an effective ruleset achieves casual realism when the underlying mathematical abstractions mirror reality:

> _"One of the most impressive things about 3rd Edition is the casual realism of the system. You can plug real world values into it, process them through the system, and get back a result with remarkable fidelity to what would happen in the real world... It doesn’t make you do the math. It’s worked the math into the system. All you’ve got to do is roll the dice and handle some basic arithmetic."_

### 2. Demographics of Ability & Competence

In standard d20 demographics, the overwhelming majority of the human population has straight 10–11 ability scores with no class levels (or 1st-level commoners). The "Elite Array" (15, 14, 13, 12, 10, 8) represents roughly the top 5% of humanity.

- Breaking down a standard interior door (DC 13 Strength check) is achievable by an average person in one or two kicks (40% per try).
- A heavy deadbolted exterior door (DC 18) takes several concerted kicks (~10% per try).
- A barred, heavy reinforced door (DC 25) is completely impossible for an unassisted average human without tools.
  The system naturally maps to common physical intuition without special case-by-case rules.

### 3. The Mortal Sweet Spot (Levels 1–5 as Real-World Ceiling)

Alexander debunks the common fallacy that legendary historical figures must be 15th-to-20th level characters:

- **Albert Einstein:** Modeled not as a 20th-level demigod with hundreds of hit points, but as a **5th-level Expert** with Knowledge (Physics) +15. Taking 10, he routinely solves DC 25 questions ("the hardest known to man") and with research bonuses tackles DC 40+ unsolvable frontiers. As an elderly scholar, he possesses 5 to 10 hit points; a single dagger strike remains lethal.
- **Village Blacksmiths vs. Master Artisans:** A typical blacksmith is 1st level (Craft +10 with apprentice assistance), reliably producing masterwork items by taking 10. The greatest blacksmiths in human history (such as Amakuni) peak at 5th level (+19 bonus).
- **Olympic Athletes:** World-record long jumpers jump 24–29 feet. In 3.0 rules, a 4th–5th level athletic specialist with Skill Focus and high Strength achieves exactly 24–29 feet on competitive attempts.
- **Literary Archetypes (Aragorn):** In _The Lord of the Rings_, Aragorn tracks hobbits (Survival DC 15), treats mortal wounds (Heal DC 15), and defeats six or seven goblins in Moria. He achieves nothing requiring more than a **5th-level build** (Rgr1/Ftr1/Pal3).

### 4. The Superhuman Threshold (Level 6+)

Beyond 5th level, characters transcend mortal biological constraints:

- They survive terminal-velocity falls from cliffs.
- They outrun galloping warhorses on foot.
- They kill dozens of trained soldiers single-handedly without sustaining disabling trauma.
  Alexander emphasizes that ludonarrative dissonance arises when campaigns fail to recognize that 6th+ level characters are mythic demigods rather than grounded heroes.

### 5. Playable Compromise vs. Tracking Friction

Alexander highlights where 3e made deliberate design compromises:

- It modeled weight without tracking _how_ an item is carried (ignoring whether a 25-lb load is strapped symmetrically in a backpack or held awkwardly in one hand).
- Adding complex sub-systems for container volume, awkwardness coefficients, and item distribution would create an unplayable "spreadsheet nightmare" that groups simply ignore.

---

## 3. Comparative Analysis & Application to CardPG

Alexander’s insights articulate the design philosophy that anchors **caRdPG**, while highlighting the structural traps that d20 systems encounter when handling scaling.

| Dimension                       | D&D 3e (Alexander's Analysis)                                                                                                                                                                                                               | caRdPG Architecture                                                                                                                                                                                                                                                                                                                                                                 |
| :------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Power Progression & Scaling** | **Disjointed Vertical Escalation:** Separate subsystems inflate at radically different rates (HP multiplies 25x while AC barely changes). Combat devolves into damage-sponge attrition slogs that shatter early-level demographic fidelity. | **Scale-Invariant Card Advancement:** Characters advance by **numerically scaling their cards** and upgrading action options. Because defense `Impact` equals the count of cards flipped to meet incoming `Strength`, resolution math functions identically whether card numbers are single digits, double digits, or triple digits—preserving crisp round pacing across all tiers. |
| **Lethality & Health**          | **Abstract HP Bloat:** A 10th-level fighter can stand unarmored and absorb multiple direct warhammer blows because HP represents luck/stamina without anatomical or trauma modeling.                                                        | **Deck as Life & Granular Consequences:** Health is governed by deck endurance and physical consequence cards (`Bleeding`, `Fracture`, `Concussion`). A clean strike through armor gaps remains immediately life-threatening regardless of power scale.                                                                                                                             |
| **Tabletop Ergonomics**         | **Abstracted Away to Avoid Paper Math:** 3e sacrifices gear distribution and awkwardness tracking because manual weight spreadsheets are tedious at the table.                                                                              | **Embodied Physical Artifacts:** Cards physically occupy table space, hand capacity, and deck slots. Encumbrance and awkward gear impose tangible card-hand restrictions without written arithmetic.                                                                                                                                                                                |
| **Action Resolution**           | **Unilateral Turn-Based d20:** One combatant acts completely while the other stands static, requiring abstract "Attacks of Opportunity" to simulate reaction.                                                                               | **Simultaneous Crisis Time:** Combatants commit cards simultaneously; timing, reach, initiative, and stamina depletion interact dynamically.                                                                                                                                                                                                                                        |
| **Factual Bedrock**             | **Heuristic Calibration:** Rules were derived intuitively and then reverse-engineered to match reality.                                                                                                                                     | **Empirical Research Track:** Grounded in peer-reviewed biomechanics (Williams 2003, Askew 2012, USARIEM 2008) and clinical trauma literature.                                                                                                                                                                                                                                      |

### Casual Realism at the Baseline vs. Scale-Invariant Growth

Alexander's essay is vital for calibrating our **starting, low-level characters**. The current playtest cards in the repository feature numbers in the single digits (1–5) because playtests have deliberately focused on grounded, low-level mortals. At this baseline tier, caRdPG embraces Alexander’s demographic reality: a novice fighter has real biological limits, an unarmored spear strike is lethal, and tasks are calibrated directly against empirical physics without cumbersome table math.

However, caRdPG diverges fundamentally from the assumption that a game must choose between "grounded realism" and "numerical advancement":

1. **Advancement via Numerical Card Scaling:** Progression in caRdPG has always been intended to scale cards numerically. When characters advance, they upgrade existing cards in their 24-card deck to higher values (or replace them with higher-tier cards) alongside acquiring versatile new stances and techniques.
2. **Mathematical Scale Invariance:** Unlike d20 systems where high numbers break math (e.g., d20 roll variance becoming trivial against +30 modifiers, or HP pools dragging battles out over dozens of rounds), caRdPG's core loop is scale-invariant:
   - An attack of `Strength 8` against single-digit cards (values 2–3) flips ~3 cards.
   - An attack of `Strength 80` against double-digit cards (values 20–30) flips ~3 cards.
   - An attack of `Strength 800` against triple-digit cards (values 200–300) flips ~3 cards.
     In every tier, the resolution remains fast, tactile, and mathematically identical.
3. **The Campaign Power Dial:** How much characters advance numerically is a setting and campaign choice. A gritty survival game can keep cards tightly bounded in single digits, while heroic or epic campaigns can scale into double digits, and Exalted/anime-styled sagas can push characters into triple digits.
4. **Macro-Scale Resolution (Armies, Provinces, Kingdoms):** Because the engine is scale-invariant, a deck is not limited to an individual human. In high-level or strategic play, a deck can represent an **army**, a **province**, or an entire **kingdom**. Giant numbers on cards represent the pooled manpower, logistical capacity, and coordinated efforts of thousands of individuals, allowing mass warfare and realm-level crises to be resolved seamlessly using the exact same Crisis Time and General Action mechanics as a street duel.

### Resolving the "Bookkeeping Compromise" with Card Mechanics

Alexander correctly points out that in pencil-and-paper RPGs, tracking how gear is carried or how fatigue accumulates across hours creates excessive tracking friction, forcing systems like 3e to make abstract compromises.

In caRdPG, we solve this without sacrificing physical verisimilitude:

1. **The Hand as Active Capacity:** You can only wield what you can hold in your hand. Switching from a polearm to a sidearm is governed by card play and tempo, not abstract action-economy menus.
2. **Deck Dilution as Progressive Attrition:** When marching under a heavy load or wearing harness, `Fatigue` cards enter the deck. Every draw brings the tactile weight of exhaustion into the player's fingers.
3. **Casual Realism through Physical Game Artifacts:** The player never computes foot-pounds or metabolic multipliers mid-game. The card mechanics deliver scientifically calibrated outcomes—armor deflection, blunt trauma transference, stamina depletion—simply through the natural rules of card play.

---

## 4. Actionable Directives for caRdPG Design

1. **Ground the Baseline Demographics:**
   - Use Alexander’s demographic benchmarks and our empirical research track to calibrate low-level (single-digit) cards and challenges so they mirror authentic physical human limits.
2. **Design Core Mechanics for Scale Invariance:**
   - Ensure every core rule (Strength generation, Defend flips, Impact, Defense, Resilience, and Consequence acquisition) operates smoothly whether card values are single digits (1–9), double digits (10–99), or triple digits (100–999). Never introduce formulas or mechanics that assume numbers will always remain single digits.
3. **Support Numerical Card Upgrades in Advancement:**
   - Implement character advancement through the numerical scaling of cards (higher color values, increased defense/resilience thresholds) paired with tangible tactical tools (new keywords, stances, and specialized action stacks), maintaining the fixed 24-card deck size.
4. **Architect for Macro-Scale Decks:**
   - Ensure that encounter, faction, and campaign frameworks support collective entities (armies, settlements, kingdoms) as single deck engines whose high-magnitude numbers abstract large-scale coordinated effort into intuitive card play.
