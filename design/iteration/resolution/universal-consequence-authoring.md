---
title: "Universal Guide to Writing Consequence & Condition Cards"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Universal Guide to Writing Consequence & Condition Cards

A comprehensive reference manual and style guide for designers and AI agents authoring Consequence and Condition Cards for **caRdPG**.

These rules apply universally across **all proposed resolution mechanics** and content modules.

---

## 1. Core Philosophy & Golden Rules

Consequence cards are the mechanical engine of caRdPG's **"Default to Success at a Cost"** and **"Telegraphed Downward Spiral"** design precepts. They model physical harm, psychological stress, equipment failure, and tactical disruption as a tangible, multi-stage process rather than abstract hit-point subtraction.

### The Six Golden Rules

1. **Grounded Realism & Verisimilitude**: All consequences must be grounded in clinical medicine, biomechanics, material science, or historical research (refer to `design/research/synthesis/consequence-database.md`).
2. **Never Use the Word "Damage" for Characters/Decks**: caRdPG uses explicit card-engine terminology: **`Expend X from the top of your deck`** or **`Expend X from hand`**. "Damaged" is reserved strictly for item and equipment states.
3. **All Cards Have All Colors**: Every card in the 24-card deck has printed {Red}, {Yellow}, and {Blue} values. Never write "a card with {Blue} stats". Qualify either by **Declared Action Color** (e.g., _"All {Blue} actions..."_) or by **Value Threshold** (e.g., _"Whenever you draw a card whose printed {Blue} value is 3 or greater..."_).
4. **Continual Passives, Not One-Shot Triggers**: Consequences represent persistent conditions on the table. Never write "The next attack..." or "The next round...". Write continual states that apply until the card is actively cleared or mitigated.
5. **No Redundant Turn Wording**: A character takes **1 action per round** in Crisis Time. Never write _"and take no other action this round"_. Declaring an `action:` is already their action for that round.
6. **No Instant Death (Actionable Crisis Clocks)**: Reaching maximum severity triggers an actionable dying or exit condition (`Bleeding Out`, `Unconscious`, `Pinned & Captured`) that acts as an urgent rescue clock or tactical objective for allies.

---

## 2. The `action:` vs. `task:` Removal Duality

Every consequence card must strictly separate **desperate in-combat mitigation** from **calm out-of-combat clinical recovery**:

```
+-----------------------------------------------------------------------------------------+
| IN-COMBAT ACTIONS (action:)                                                             |
| - High friction, card suppression/covering, card taxes, or severe tradeoffs.           |
| - Tier 1: Quick balance resets, eye rubs, or breath catches (spend or tuck cards).      |
| - Tier 2: Platform recovery (struggle to feet) or temporary suppression (compression).  |
| - Tier 3: NO in-combat removal actions. Only desperate temporary suppressions.          |
| - Tier 4: Third-party ally emergency interventions only (e.g. pausing bleedout clock).  |
+-----------------------------------------------------------------------------------------+
| OUT-OF-COMBAT TASKS (task:)                                                             |
| - Calm, methodical, and reliable medical/crafting care during Adventuring/Downtime.     |
| - Calibrated against the GM Guide General Action Difficulty Benchmarks.                 |
| - Represents the unassisted baseline; specialized healer cards/spells provide bonuses.  |
+-----------------------------------------------------------------------------------------+
```

### 2.1. In-Combat Actions (`action:`)

In combat, clearing a condition is hurried and dangerous. Design actions around these patterns based on tier:

- **Tier 1 (Tactical Resets)**:
  - _Card Spends_: e.g., `action: Push Through (Spend {Red} 20) -> Remove this.`
  - _Lingering Tradeoffs (`when removed:`)_: Clearing a condition quickly under fire often leaves lingering wear.
    - _Example_: `action: Force Through Spasm (Spend {Red} 20) -> Remove this.`
    - `when removed (via Action): Place 1 Fatigue card on top of your deck.`
- **Tier 2 (Platform Recovery & Tactile Suppression)**:
  - _Multi-Turn Platform Leverage_:
    - _Example_: `action: Struggle to Feet (Place a card from your hand on top of this. When cards on top of this exceed your Burden, expend them and remove this).`
  - _Tactile Card Suppression ("Covering" the Card)_:
    The player physically places cards from hand on top of the consequence card to cover its passive text and suppress it.
    - _Example_: `action: Hold Direct Compression (Place 1 card from your hand on top of this to cover and suppress its passive. If you declare an Attack or Sprint, expend that card and resume the passive).`
  - _Note on Biological Trauma_: Pure bodily trauma at Tier 2 (`Cracked Ribs`, `Mild Concussion`, `Hamstrung`) has **no in-combat removal action**. It must be endured until downtime.
- **Tier 3 (Zero In-Combat Removal Actions)**:
  - Severe structural trauma (`Broken Arm`, `Sundered Armor`, `Severe Concussion`) **cannot be removed or cured during combat**.
  - Only crisis-delay suppression exists for life-threatening conditions (e.g., `Hold Direct Pressure` on `Arterial Hemorrhage` requiring 2 cards held).
- **Tier 4 (Ally Emergency Intervention Only)**:
  - If a Tier 4 condition features an action (such as `Ally Emergency Hemostasis` on `Mortal Bleedout`), it can **only be performed by an adjacent ally**, not the incapacitated defender.

### 2.2. Out-of-Combat Tasks (`task:`)

Out of combat, treatment is performed with care. Difficulty must strictly align with `design/rules/gamemaster-guide.md`:

- **Routine (Strength 5–10 | Seconds to Minutes)**: _Tier 1_ (eye wash, catching balance, breathing recovery).
- **Challenging to Difficult (Strength 15–35 | Hours to Days)**: _Tier 2_ (rib wraps, dark room rest for mild concussions, tendon suturing).
- **Very Difficult to Severe (Strength 40–60 | Days to Weeks)**: _Tier 3_ (orthopedic bone setting, master forge reconstruction, deep arterial cavity packing).
- **Legendary / Emergency Resuscitation (Strength 80–100+ | Weeks to Months)**: _Tier 4_ (acute trauma resuscitation, planar mind-mending).

---

## 3. Proper Use of `Requires:` vs. `Cost:`

Always maintain the semantic distinction between persistent equipment and consumed resources:

- **`Requires:`** — Used for durable tools, fixtures, kits, workshops, or environments that are _not_ consumed:
  - `Requires Clean Water`, `Requires Repair Tools`, `Requires Splint`, `Requires Surgical Kit`, `Requires Forge & Anvil`, `Requires Darkened Infirmary`.
- **`Cost:`** — Reserved strictly for consumable resources that are _expended/destroyed_ during the check:
  - `Cost Bandage`, `Cost Herbal Purge`, `Cost Burn Salve & Wraps`, `Cost Raw Steel & Rivets`, `Cost Airtight Chest Seal`.

---

## 4. Review Checklist for New Consequence Cards

Before committing any consequence card to `data/cards/consequences/` or an iteration proposal, verify:

- [ ] Is the severity accurately calibrated?
- [ ] Are all passives written as continual states (no "the next...")?
- [ ] Is the word "damage" completely avoided for characters/decks? (Used "expend from deck/hand" instead?)
- [ ] Are color requirements qualified by declared action color or numerical threshold ({Blue} >= 3)?
- [ ] If Tier 2 or 3 bodily trauma, is an in-combat removal `action:` appropriately omitted (or limited strictly to temporary tactile suppression)?
- [ ] Does the out-of-combat `task:` specify realistic time, `Requires:` (tools/facilities), and `Cost:` (consumables)?
- [ ] Is the `task:` check difficulty aligned with GM Guide benchmarks for that tier?
- [ ] Does the `notes:` field articulate the physiological/biomechanical basis?
