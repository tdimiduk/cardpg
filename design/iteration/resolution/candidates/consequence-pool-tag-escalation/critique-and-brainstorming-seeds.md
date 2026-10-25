---
title: "Consequence Pool & Tag Escalation: Active Critiques & Brainstorming Seeds"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# Consequence Pool & Tag Escalation: Active Critiques & Brainstorming Seeds

## Document Purpose

This document outlines the active mechanical critiques, tabletop ergonomics tensions, and targeted design seeds for the **Consequence Pool & Tag Escalation Engine** ([proposal.md](proposal.md)). It serves as an architectural brief for exploring alternative candidate resolution mechanics.

---

## 1. Active Systemic Critiques

While the Consequence Pool engine successfully decouples harm from global hit points and introduces high player agency via "I Cut, You Choose" drafting, two mechanical and ergonomic friction points remain under the multi-deck model. _(Note: Per [resolution-design-constraints.md](../resolution-design-constraints.md) §2.5, physical table ergonomics is a "nice to have" during near-term VTT playtesting, but streamlining table footprint remains a valuable long-term goal)._

### A. Physical Tabletop Ergonomics & Multi-Deck Drafting (VTT vs. Table)

1. **Table Footprint (Improved but Persistent):** Consolidating down to 4 tiers—with Tier 4 handled narratively as Taken Out—successfully shrinks the table footprint from 5 physical decks down to **3 physical decks** (Severity 1: Tactical Impairments, Severity 2: Platform Ceilings/Moderate Trauma, Severity 3: Severe Structural Trauma). However, hosting 3 distinct trauma decks alongside character decks, hand cards, tableaus, and potential domain decks still occupies substantial table space.
2. **The Draw-Read-Tuck Cycle:** Resolving an attack with Impact requires the attacker to calculate currency spending, draw 2–4 cards across up to 3 physical decks, read the rules text on all candidates, curate $N$ cards, and tuck unchosen cards back into their respective decks. The defender then reads the $N$ cards, chooses 1, and tucks the remaining $N-1$ cards back into the decks.
3. **The "Phantom Card" Drafting Anomaly:** Because Tier 4 (Taken Out) has no physical card deck in the baseline rules, allocating a Tier 4 candidate when spending 4 Impact creates a physical disconnect: the attacker must introduce a proxy token, index card, or verbal declaration into an otherwise physical hand of drafted cards.
4. **Pacing Drag:** Performing this multi-card reading, evaluating, and deck-sorting procedure multiple times per round violates the 10x Rule of Core Complexity and slows the tactile momentum of Crisis Time.

### B. Tag Dilution & Mid-Combat Deck Tutoring

1. **Tag Dilution:** Severity 1 contains 12 cards with 18 distinct tags, and Severity 2 contains 7 cards with 15 tags. When drawing 1 or 2 random candidates, the probability of drawing a tag that matches an active condition already on the defender remains low (~15–20%). The intended downward spiral of contextual tag escalation frequently stalls due to draw variance unless candidate pools are exceptionally large.
2. **Mid-Combat Deck Tutoring:** While treating Tier 4 as narrative Taken Out successfully eliminates deck-searching for final death/defeat, escalating conditions between Tiers 1, 2, and 3 still requires mid-fight deck tutoring:
   - Intra-tier escalations in Tier 1 (e.g., `Poor Footing` $\to$ `Off Balance`, `Dust in Eyes` $\to$ `Dazed`) require searching through the 12-card Severity 1 deck.
   - Cross-tier escalations (e.g., `Off Balance` $\to$ `Knocked Prone` in Severity 2; `Mild Concussion` $\to$ `Severe Concussion` or `Rattled Guard` $\to$ `Sundered Armor` in Severity 3) require players to halt the game, pick up the higher severity deck, rifle through it to find the specific named card, place it in play, and reshuffle.

---

## 2. Targeted Seeds for New Brainstorming

The following seeds explore ways to preserve the core strengths of the engine (localized tag escalation, defender agency, and armor soak thresholds) while resolving the physical and cognitive bottlenecks.

---

### Seed 1: The Consolidated "Tiered Consequence Deck"

#### Concept

Replace the separate physical severity decks with a **single Consequence Deck**.

- Because Tier 4 is handled narratively as Taken Out, every card in the deck only needs to display **3 printed severity tiers** on its face (Severity 1 / Severity 2 / Severity 3), followed by a terminal Taken Out trigger.
- When an attack lands, candidate cards are drawn from this **single deck**.
- The Severity applied is determined by the Impact threshold achieved or the current escalation state of that card.

```
+-----------------------------------------------------+
| SHATTERED BALANCE                 [Tag: positioning] |
+-----------------------------------------------------+
| Sev 1: Poor Footing                                 |
|   Passive: The Impact of your defenses is +1.       |
|   Action: Regain Footing (Tuck 2 cards from hand)   |
+-----------------------------------------------------+
| Sev 2: Off Balance                                  |
|   Passive: Cannot play Defend cards from hand.      |
|   Action: Recover Stance (Tuck 3 cards from hand)   |
+-----------------------------------------------------+
| Sev 3: Knocked Prone                                |
|   Passive: Attacks against you gain +2 Impact.      |
|   Action: Stand Up (Spend 1 Card + Suffer 1 Fatigue)|
+-----------------------------------------------------+
| Terminal: If escalated further -> Taken Out / Crisis Clock |
+-----------------------------------------------------+
```

#### Mechanical & Ergonomic Benefits under 4 Tiers

1. **High Graphical Feasibility (Enabled by Seed 3):** Fitting 3 tiers with full out-of-combat surgical tasks, tools, and convalescence rules is impossible on a standard poker card. However, by decoupling in-combat conditions from post-combat prognosis (detailed in Seed 3), each tier requires only 1–2 lines of passive/action text. At ~50–60 words total, fitting **3 tiers** on a single card is graphically clean, highly legible, and spacious.
2. **Single Deck on Table:** Reduces physical deck clutter to exactly **one 15–20 card deck** for physical trauma.
3. **Zero Mid-Combat Tutoring:** Escalating `Poor Footing` does not require searching any deck for `Off Balance` or `Knocked Prone`. The entire progression chain is already on the table in front of the player; the player simply advances an **escalation marker** (cube or clip) to the next printed tier.
4. **Natural Tag Synergies:** Every card drawn inherently carries its full narrative and mechanical escalation arc without requiring cross-deck tag matching.

---

### Seed 2: Persistent Condition Cards with Pip/Slider Tracks

#### Concept

Condition cards feature printed multi-pip escalation tracks (tracked with a wooden cube, paperclip slider, or tucking card) that map 1:1 to the 4-tier model:

- **Pip 1 (Severity 1):** Minor setback or clearable tactical impairment.
- **Pip 2 (Severity 2):** Platform ceiling or moderate trauma.
- **Pip 3 (Severity 3):** Severe structural trauma (broken limb, sundered armor, severe concussion).
- **Pip 4 / Terminal:** Immediate **Narrative Taken Out** clause printed on the card (e.g., _"Unconscious / Slain / Pinned"_).

When subsequent attacks target an active condition's tag, the card simply **ticks up +1 Pip**, unlocking the next harsher passive rule printed on the card.

#### Mechanical Benefits

1. **Completely Eliminates Deck Searching:** No cards are swapped out or fetched mid-fight; conditions evolve in place.
2. **Perfect Harmony with Narrative Tier 4:** Reaching the end of the 3-pip track naturally triggers the narrative defeat state without requiring a physical Tier 4 card.
3. **Clean Table State & Low Cognitive Load:** Players and GM can look across the table and instantly assess character vulnerability by glancing at pip positions.

---

### Seed 3: Decoupled Crisis Conditions & Post-Combat Prognosis Triage

#### Concept

Separate the mechanical and narrative lifecycle of harm into two distinct, dedicated phases matching caRdPG's core modes of play: **Crisis Time (In-Combat Tactical Friction)** and **Downtime (Post-Combat Clinical Triage)**.

1. **In-Combat Condition Cards (Crisis Time):**
   - Contain **strictly in-combat information**: Title, Leaf Tag, immediate passive penalties across Tiers 1–3, desperate in-combat mitigation/suppression actions, and terminal defeat triggers.
   - Out-of-combat medical tasks (`task:`), clinic/tool requirements (`Requires:`), consumable costs (`Cost:`), and convalescence times are **completely stripped from combat cards**.
   - With an average word count of only 50–60 words per card, all 3 tiers fit comfortably on a single poker card with generous margins and clear typography (directly enabling Seed 1 and Seed 3).

2. **The Post-Combat Triage Ritual (Downtime / Triage Phase):**
   - When combat ends (Transition out of Crisis Time), the table enters a relaxed **Triage & Recovery Phase**.
   - **Tier 1 Impairments Clear Automatically:** Mild setbacks (`Poor Footing`, `Dust in Eyes`, `Winded`) represent transient physical friction and evaporate with 60 seconds of catching breath after the fight.
   - **Triage for Severe Trauma (Tiers 2 & 3):** Characters holding conditions at Tier 2 or Tier 3 consult the **Prognosis & Treatment System** to diagnose the injury, determine required medical checks, and identify tools, surgery, or convalescence time.
   - Because combatants rarely suffer more than 1–2 severe wounds across an entire encounter, the table only looks up 1–2 prognoses total after the fight.

#### Candidate Implementation Formats for Prognosis

| Format                                                                     | Mechanics & Table Procedure                                                                                                                                                                                   | Tabletop Strengths & Tradeoffs                                                                                                                                                        |
| :------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Option A: The "Outlook & Prognosis" Card Deck**                          | A dedicated box/deck of clinical downtime cards kept off the combat table. After battle, players pull the matching prognosis card (e.g., `Mild Concussion (Prognosis)`) and tuck it by their character sheet. | **High Tangibility:** Prognosis cards hold physical progress cubes, track doctor attachments, and flip or discard when healed. Preserves the caRdPG "cards as game state" philosophy. |
| **Option B: The Chirurgeon's Field Manual (Reference Chart)**              | A 2-page reference spread in the rulebook / GM screen. A lookup table: `[Condition Tag] × [Severity Tier]` $\to$ `[Check Difficulty, Required Tools, Rest Time, Permanent Scars]`.                            | **Zero Card Clutter:** Eliminates an entire extra deck of cards from the box. Fast lookup during camp or downtime; players note treatment on character sheets.                        |
| **Option C: Reversible / Two-Sided Cards (Combat Front / Prognosis Back)** | Combat side features the 3-tier escalation track. Once combat concludes, the player flips the card over to read the downtime clinical treatment and surgery rules.                                            | **Self-Contained:** Zero tutoring or lookups ever. Requires either opaque card sleeves or an open-market drafting method (cannot be drawn blindly from face-down decks).              |

#### Mechanical & Ludonarrative Benefits

1. **Ergonomic Pacing Alignment:** Moving deck searching out of Crisis Time and into Downtime transforms an annoying pacing bottleneck into an immersive narrative ritual. Players and GMs roleplay post-battle first aid, inspecting wounds and assessing surgical options when adrenaline has faded.
2. **Drastically Reduces In-Combat Cognitive Load:** Attacking and defending players during "I Cut, You Choose" only read 1-line tactical passives. They never have to parse irrelevant downtime surgical checks while deciding which card to draft under fire.
3. **Graphically Unlocks Consolidated Cards:** Stripping 60+ words of downtime medical rules allows 3 full tiers to fit comfortably on standard-sized cards with large, accessible fonts and clear layout bands.

---

### Synthesis: The Unified Alternative Architecture

When combined with **Layered Pool Filling**, Seeds 1, 2, and 3 form a coherent, highly streamlined evolution of the engine:

1. **Single Combat Deck (Seed 1 & 3):** Exactly one deck of ~15–20 cards on the table, containing lean 3-tier escalation tracks (~55 words per card).
2. **In-Place Pip Escalation (Seed 2):** Matching tags advance a tracker cube on active cards, completely eliminating mid-combat deck tutoring.
3. **Post-Combat Triage (Seed 3):** Clinical surgery, convalescence, and permanent traits are resolved calmly after the fight via the Prognosis & Trauma system.
