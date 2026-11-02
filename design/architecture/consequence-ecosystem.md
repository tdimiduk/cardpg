---
title: "The Consequence Ecosystem: Multi-Deck Library, Active Decks & Verisimilitude"
doc_type: "architecture"
track: "ludology"
origin: "Gemini 3.8 Flash (Antigravity)"
epistemic_status:
  confidence: "high"
  vetted_by_human: false
---

# The Consequence Ecosystem: Multi-Deck Library, Active Decks & Verisimilitude

## 1. Executive Summary: The "Card-Table Rolemaster" Vision

In _caRdPG_, harm is not an abstract hit-point pool, nor is it a generic, one-size-fits-all penalty. Harm represents grounded biomechanical, cognitive, and environmental trauma.

In legacy tabletop roleplaying games with deep verisimilitude (such as _Rolemaster_ or _GURPS_), achieving realistic, differentiated injury requires consulting sprawling books of lookup tables: rolling percentile dice, cross-referencing columns for weapon type (Slash, Crush, Puncture, Heat, Cold), looking up critical severity ranks (A through E), and parsing dense text entries.

_caRdPG_ achieves that exact same level of tactile, evocative verisimilitude through **Physical Cards**, adhering to the **[10x Rule of Core Complexity](file:///home/tdimiduk/cardpg/cardpg/design/philosophy/design-precepts.md#L9-L18)**:

- **The Core Rulebook stays lean (~1–2 pages):** The core engine does not contain hundreds of rules or tables for arterial spurts, concussive amnesia, armor denting, frostbite, or panic.
- **The Nuance Lives on Cards:** When a hero is struck by a warhammer, slashed by a sabre, scorched by dragonfire, or shaken by a social scandal, the specific narrative, physical, and recovery friction is carried entirely on the drawn **Consequence Card**.

To fulfill this vision, _caRdPG_ uses a **Multi-Deck Consequence Ecosystem**.

---

## 2. The Library vs. Active Scene Decks

A central tabletop concern of having distinct consequence decks for every damage type and hazard is **combinatorial table clutter**. Ten damage types across four severity tiers would suggest up to 40 separate physical stacks of cards.

_caRdPG_ resolves this through a clear separation of scope:

```
+------------------------------------------------------------------------------------+
|                             THE CONSEQUENCE LIBRARY                                |
|                        (Stored in Game Box / Master Tray)                          |
|                                                                                    |
|  [Slashing]   [Crushing]   [Piercing]   [Fire/Heat]   [Cold/Frost]   [Lightning]   |
|  [Falling]    [Poison]     [Travel]     [Social]      [Arcane]       [Logistics]   |
+------------------------------------------------------------------------------------+
                                         |
                                         | GM deploys 2 to 5 relevant decks
                                         v
+------------------------------------------------------------------------------------+
|                               ACTIVE SCENE DECKS                                   |
|                         (Present on the Tabletop)                                  |
|                                                                                    |
|    Example: Bandit Ambush                Example: Frozen Mountain Pass             |
|    - [Slashing Deck]                     - [Travel & Exposure Deck]                |
|    - [Crushing Deck]                     - [Cold & Frostbite Deck]                 |
|    - [Piercing Deck]                     - [Falling & Impact Deck]                 |
|    - [General / Fatigue]                 - [General / Fatigue]                     |
+------------------------------------------------------------------------------------+
```

### 2.1. The Consequence Library (The Box)

The master game box contains 10+ granular, specialized consequence decks. Each deck models a specific physical trauma mechanism, environmental exposure, or conflict domain:

- **Martial Trauma:** `Cutting / Slashing`, `Crushing / Bludgeoning`, `Piercing / Puncture`.
- **Elemental & Energy:** `Fire / Thermal Burn`, `Cold / Frostbite`, `Lightning / Electrical Shock`, `Corrosive / Acid`.
- **Survival & Environment:** `Travel & Exposure` (dehydration, blistered feet, exhaustion), `Falling / Kinetic Impact`, `Poison / Sepsis`.
- **Mind & Reputation:** `Social & Relational` (scandal, broken trust, blackmail), `Acute Fear & Psychological Strain`.
- **Exotic Domains:** `Arcane Backdraft`, `Alchemical Overload`, `Logistics & Vehicle Wear`.

### 2.2. Active Scene Decks (The Table)

At no point do all 40 decks sit on the tabletop.

- During any given scene or encounter, the GM keeps only the decks matching the active threats and enemy loadouts on the table.
- **Spontaneous Threats:** If an unexpected hazard or damage type enters the scene mid-fight (e.g., a player kicks a brazier over to deal fire damage, or a lightning spell is cast), the GM simply pulls that deck from the box.

---

## 3. Damage Tags on Attacks & Weapons

Rather than hardcoding explicit consequence deck names onto weapons (e.g., _"Arming Sword: Draw from Slashing Deck"_), weapons, spells, and environmental hazards declare **Damage Tags**:

```yaml
Arming Sword:
  tags: [Cut, Pierce]
Morningstar:
  tags: [Blunt, Pierce]
Flaming Greatsword:
  tags: [Cut, Burn]
Icy Crevasse:
  tags: [Cold, Fall]
```

### Advantages of Tag-Driven Routing

1. **Multi-Tag Versatility & Hybrid Draws:**
   - When an attack with a multi-tag weapon generates multiple candidate cards, the attacker can split their candidate draws across the matching active decks.
   - _Example:_ A strike from a Morningstar (`[Blunt, Pierce]`) drawing 2 candidates can draw **1 candidate from Crushing** and **1 candidate from Piercing**. In an _"I Cut, You Choose"_ drafting engine, this presents the defender with an authentic tactical dilemma: accept a cracked rib or a punctured arm.
2. **Graceful Degradation & Box Substitution:**
   - If a GM runs an encounter involving an alchemical acid attack (`[Corrosive]`), but does not have a dedicated `Corrosive` deck at hand, the tag system allows instant substitution with `[Burn]` or `[Chemical]` without rules breakage.
3. **Player Narrative & Improvised Actions:**
   - When a player takes an improvised narrative action (e.g., shoving a foe into a roaring hearth or throwing a mug of boiling ale), the GM simply assigns the tag `[Burn]` or `[Blunt]`, immediately identifying which active deck to draw from.

---

## 4. Interaction with Maneuvers & Printed Attack Stakes

In legacy content, certain action cards featured hardcoded consequences (e.g., an attack explicitly stating _"Target is Knocked Prone"_ or _"Inflicts Rattled Guard"_).

In an impact-scaled, multi-deck resolution engine, hardcoded bypasses create severe design pitfalls (either bypassing armor entirely or creating parallel rule tracks). Instead, attack-printed stakes integrate through two clean patterns:

### Pattern A: "Guaranteed Candidates" (Seeding the Pool)

If a specialized martial maneuver guarantees a specific tactical outcome (e.g., _Leg Sweep_ or _Shield Bash_), the card specifies:

> _"If this attack draws Tier 2 candidates, one guaranteed candidate is **Knocked Prone**."_

- The specific condition enters the candidate pool alongside other drawn cards.
- The attacker curates it into the presented pool. The core defensive math (Impact vs. Pool Size) is fully respected, but the maneuver achieves its signature outcome whenever it penetrates defense.

### Pattern B: Non-Injurious Tactical Riders vs. Bodily Trauma

- **Tactical Riders:** Minor, fleeting positional changes (e.g. _Push 1 Zone_, _Force 1 Step Disengage_, _Target Expends 1 Card from Hand_) can exist directly as rules text on Action Cards.
- **Persistent Bodily & Psychological Trauma:** Any condition that remains on the table as a persistent impediment or enters the deck as status cards **must** flow through the Consequence Ecosystem.

---

## 5. Tabletop Mediums: Digital VTT vs. Physical Production

| Medium                          | Tabletop Footprint                                                                 | Ergonomics & Automation                                                                                                                                   |
| :------------------------------ | :--------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Digital VTT (Custom Engine)** | **Zero Footprint:** All 10+ decks exist in software.                               | Automated tag filtering, instant candidate pooling, automated vulnerability chaining. Digital playtesting allows unconstrained exploration of deck depth. |
| **Physical Tabletop**           | **2–5 Active Decks (Small Trays):** 6–15 mini-stacks or a multi-tabbed card caddy. | Fast physical draws (reach for Tier 1 tab in Slashing tray). Zero mid-fight tutoring or book lookup.                                                      |

---

## 6. Summary Invariants for Designers & AI Subagents

1. **Never assume a single generic consequence deck.** Consequences are organized into domain- and damage-specific decks.
2. **Never assume all decks are on the table.** Scenes operate with 2 to 5 Active Scene Decks.
3. **Severity is drawn by sub-stack.** Decks are partitioned by Tier (1–4) so draws by Impact are immediate and require no filtering or redraws.
4. **Attacks specify tags, not hardcoded decks.** Multi-tag attacks allow hybrid draws across matching active decks.
5. **Tier 1 sub-stacks must maintain depth (12–16 cards).** High-volume simultaneous rounds must not exhaust the deck or produce repetitive draws.
6. **Maneuver stakes seed candidate pools.** Never bypass armor or defensive math; use guaranteed candidates to deliver signature maneuver outcomes.
