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
  vetting_notes: "Analytical reading note linking Alexander's casual realism to CardPG's grounded heroism and card economy."
related_files:
  - "design/philosophy/guiding-principles.md"
  - "design/philosophy/design-precepts.md"
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

Alexander’s insights articulate the exact design philosophy that anchors **caRdPG**, while exposing the structural limitations of d20 systems that caRdPG was created to overcome.

| Dimension               | D&D 3e (Alexander's Analysis)                                                                                                                                             | caRdPG Architecture                                                                                                                                                                                                                |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Power Progression**   | **Vertical Escalation (Levels 1–20):** Characters rapidly outgrow the mortal tier; math scales from +1 to +30; HP pools inflate from 6 to 150+.                           | **Permanent Mortal Sweet Spot:** Characters remain grounded in Alexander’s 1st–5th level tier. Progression is **horizontal** (card versatility, tactical stances, deck synergy), never vertical numerical bloat.                   |
| **Lethality & Health**  | **Abstract HP Bloat:** A 10th-level fighter can stand naked and absorb five direct hits from heavy warhammers because HP represents luck/stamina without trauma modeling. | **Deck as Life & Granular Consequences:** Health is tied directly to deck endurance and physical consequence cards (`Bleeding`, `Fracture`, `Concussion`). A clean strike through armor gaps remains immediately life-threatening. |
| **Tabletop Ergonomics** | **Abstracted Away to Avoid Paper Math:** 3e sacrifices gear distribution and awkwardness tracking because manual weight spreadsheets are tedious at the table.            | **Embodied Physical Artifacts:** Cards physically occupy table space, hand capacity, and deck slots. Encumbrance and awkward gear impose tangible card-hand restrictions without written arithmetic.                               |
| **Action Resolution**   | **Unilateral Turn-Based d20:** One combatant acts completely while the other stands static, requiring abstract "Attacks of Opportunity" to simulate reaction.             | **Simultaneous Crisis Time:** Combatants commit cards simultaneously; timing, reach, initiative, and stamina depletion interact dynamically.                                                                                       |
| **Factual Bedrock**     | **Heuristic Calibration:** Rules were derived intuitively and then reverse-engineered to match reality.                                                                   | **Empirical Research Track:** Grounded in peer-reviewed biomechanics (Williams 2003, Askew 2012, USARIEM 2008) and clinical trauma literature.                                                                                     |

### Resolving the "Bookkeeping Compromise" with Card Mechanics

Alexander correctly points out that in pencil-and-paper RPGs, tracking how gear is carried or how fatigue accumulates across hours creates excessive tracking friction.

In caRdPG, we solve this without abstracting away physical verisimilitude:

1. **The Hand as Active Capacity:** You can only wield what you can hold in your hand. Switching from a polearm to a sidearm is governed by card play and tempo, not abstract action-economy menus.
2. **Deck Dilution as Progressive Attrition:** When marching under a heavy load or wearing harness, `Fatigue` cards enter the deck. Every draw brings the tactile weight of exhaustion into the player's fingers.
3. **Casual Realism through Game Artifacts:** The player never computes foot-pounds or metabolic multipliers mid-game. The card mechanics deliver scientifically calibrated outcomes—armor deflection, blunt trauma transference, stamina depletion—simply through the natural rules of card play.

---

## 4. Actionable Directives for caRdPG Design

1. **Enforce the Grounded Heroism Anchor:**
   - Never allow player character progression to scale into Alexander’s "Level 6+ Superhuman" domain.
   - Master duelists and hardened veterans in caRdPG should feel like Aragorn or Miyamoto Musashi: brilliantly skilled, tactically versatile, but capable of being killed by an unlucky slip or an unarmored spear thrust.
2. **Maintain the 24-Card Deck Ceiling:**
   - Keep the deck small and tightly tuned. Power advancement must consist of refining deck composition, upgrading technique cards, and learning specialized stances—not increasing deck size or multiplying card power values.
3. **Preserve System Transparency Without Table Math:**
   - Every rule in `design/rules/` must pass Alexander's "Casual Realism" test: does the system accept real-world inputs (wearing plate armor, sprinting 100 meters, carrying a wounded ally) and produce plausible physical outcomes without forcing players to do arithmetic?
4. **Link to Consequence & Exploration Frameworks:**
   - Align physical consequence cards directly with Alexander's demographic benchmarks: common injuries should impair performance according to clinical reality, and recovery should demand genuine downtime and care.
