---
title: "Design Brief: Exploration Procedures, Dungeon Clocks, and Location Decks"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# Design Brief: Exploration Procedures, Dungeon Clocks, and Location Decks

## Purpose of this Working Session Track

To design and formalize the table procedures for **Adventuring Time**, specifically defining how **Location Decks**, **Clock/Encounter Decks**, and environmental pressure govern the pacing of exploration and trigger **Effort Cycles**.

While [core-rules.md](../rules/core-rules.md) now provides the mechanical engine for the Ready Hand and flushing (the 0–4 Vigilance Dial, Face-Up Guard, and Effort Cycle flushes), the practical tabletop triggers currently rely on either an ad-hoc guideline (_"once per hour"_) or an undefined promise of _"pre-designed Location and Clock Decks"_ in [gamemaster-guide.md](../rules/gamemaster-guide.md#151). This brief seeds the working session to transform those abstract ideas into concrete, playable procedures.

---

## 1. The Core Design Vision

In _caRdPG_, physical and mental stamina are tracked symmetrically through each character's 24-card deck. Outside of Crisis Time, the deck acts as the party's expedition clock:

- Walking at high vigilance (4 cards ready) steadily burns cards on each Effort Cycle ($\approx 1$ Fatigue Cycle every 6 flushes).
- Marching at ease (0 cards ready) burns 0 cards, but leaves the party vulnerable to ambushes.
- Taking [The Breather](../rules/modules/the-breather.md) recovers cards at the cost of 10–15 minutes of in-game time.

For this engine to generate genuine tension rather than arbitrary book-keeping, **time and distance must have physical representation on the table**.

The envisioned table structure uses modular physical decks:

1. **Location Decks:** Represent the physical space being traversed (dungeon rooms, wilderness hexes, city districts).
2. **Clock / Encounter Decks:** Represent external pressure, wandering threats, environmental decay, and time passing.

---

## 2. Key Tensions and Architectural Questions

### Tension 1: Stochastic Effort vs. Telegraphing & Player Agency

- In a location or encounter deck, certain cards will directly call for an **Effort Cycle** (representing a difficult traverse, extended search, or exhausting obstacle).
- **The Problem:** If flipping a card simply says _"Effort Cycle: All players flush Ready Hands"_, players who kept a 4-card guard may feel punished by pure RNG rather than making a tactical choice.
- **The Design Question:** How do we telegraphed effort demands so players can make meaningful choices?
  - _Option A (Direct Obstacle Choice):_ The card presents a dilemma: _"Collapsed Hallway: Spend 10 minutes clearing rubble (triggers Effort Cycle) OR attempt a Strength 18 Red General Action to force through immediately."_
  - _Option B (Paced Clock Pulse):_ Effort Cycles are triggered predictably by a Clock Deck counter (e.g. every 3rd room or every turn of the clock), allowing players to anticipate when their guard will flush.
  - _Option C (Environmental Strain):_ Hazards or rooms with specific tags (`[Flooded]`, `[Miasma]`, `[Steep]`) impose an Effort Cycle upon entry unless mitigated by gear (e.g. climbing harnesses, lanterns, rebreathers).

### Tension 2: Exploration Timescales (Dungeons vs. Overland Marches)

- [gamemaster-guide.md](../rules/gamemaster-guide.md#L150) currently suggests calling an Effort Cycle _"about once per hour of in-game time."_
- In an overland trek, 1 hour per Effort Cycle produces a clean, thematic rhythm: 6 hours of forced march at high vigilance induces 1 Fatigue Cycle.
- In a dungeon crawl, however, rooms and encounters resolve in 5–15 minute increments. A full dungeon raid might take only 45 minutes of in-game narrative time! If Effort Cycles only trigger once per in-game hour, the dungeon crawl would almost never trigger an Effort Cycle.
- **The Design Question:** What is the exploration unit of currency?
  - Should the dungeon crawl use a **Dungeon Turn** (~10 minutes) where specific activities (searching a room, picking a complex vault, picking up your Ready Hand for a General Action, resting) advance the clock?

### Tension 3: Dial Adjustment Ergonomics

- The Ready Hand is a dial from 0 to 4 cards.
- If players can change their dial at any second for free, table play devolves into constant fiddly adjustments: _"I drop to 0 to look at the statue, now I raise to 4 to step through the door."_
- **The Design Question:** When is a player allowed to adjust their chosen Ready Hand size?
  - Only when entering a new room/location?
  - Only when an Effort Cycle flushes?
  - Anytime, but increasing it requires drawing from the top of the deck, while lowering it leaves cards in hand until the next flush?

### Tension 4: Pacing Breathers Against Clock Pressure

- [The Breather](../rules/modules/the-breather.md) allows players to pause for 10–15 minutes, unbuckle armor, and recover cards with proportional fatigue.
- If there is no clock pressure, players will take a Breather after every single minor obstacle.
- How do Location and Clock Decks enforce the cost of a 15-minute pause (e.g. advancing a Front Clock, drawing an Encounter Card, or exhausting light sources)?

---

## 3. Evaluated Exploration Procedures & Candidate Baseline

### Model A: The 6-Tick Dungeon Clock (The "Turn Wheel") — [ACTIVE PROPOSAL]

- The GM maintains a small 6-tick tracker (d6 die or 6-card Clock Deck).
- Every major exploratory activity (traversing/searching a room, resolving a General Action, picking a vault lock, or taking a Breather) ticks the clock by 1.
- **At Tick 6:**
  1. An **Effort Cycle** triggers: all players flush their Ready Hands (paying 2 cards if retaining a Face-Up Guard).
  2. The GM checks for a Wandering Threat / Hazard.
  3. The clock resets to Tick 1.
- **Advantage:** Predictable, transparent pacing. Players see Tick 5 approaching and make tactical choices about vigilance dials.

### Secondary Modules (Modular Expansions)

- **Model B (Integrated Location Cards):** Rooms printed on physical cards with embedded `[Taxing: Effort Cycle]` or `[Peril]` tags.
- **Model C (Encounter Decks with Time Cards):** Randomized event decks for wilderness exploration.

---

## 4. Session Track Deliverables

- [ ] **1. Rulebook Section:** Formalize the 6-Tick Turn Wheel and exploration procedures in [gamemaster-guide.md](../rules/gamemaster-guide.md#21-running-adventuring-time).
- [ ] **2. Card Anatomy Prototype:** Define standard card layouts and keywords for a physical **Location Card** and a **Clock/Encounter Card**.
- [ ] **3. Pacing Benchmark Walkthrough:** Validate exploration pacing and clock mechanisms via verified gameplay traces.
