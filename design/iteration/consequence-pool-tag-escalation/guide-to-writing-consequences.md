# Guide to Writing Consequence Cards

A comprehensive reference manual and style guide for designers and AI agents authoring Consequence Cards for **caRdPG**.

---

## 1. Core Design Philosophy

Consequence cards are the mechanical engine of caRdPG's **"Default to Success at a Cost"** and **"Telegraphed Downward Spiral"** design precepts. They model physical harm, psychological stress, equipment failure, and tactical disruption as a tangible, multi-stage process rather than abstract hit-point subtraction.

### Golden Rules

1. **Grounded Realism & Verisimilitude**: All consequences must be grounded in clinical medicine, biomechanics, material science, or historical research (refer to [consequence-database.md](../../research/synthesis/consequence-database.md)).
2. **Never Use the Word "Damage" for Characters/Decks**: caRdPG uses explicit card-engine terminology: **`Expend X from the top of your deck`** or **`Expend X from hand`**. "Damaged" is reserved strictly for item and equipment states.
3. **All Cards Have All Colors**: Every card has printed {Red}, {Yellow}, and {Blue} values. Never write "a card with {Blue} stats". Qualify either by **Declared Action Color** (e.g., _"All {Blue} actions..."_) or by **Value Threshold** (e.g., _"Whenever you draw a card whose printed {Blue} value is 3 or greater..."_).
4. **Continual Passives, Not One-Shot Triggers**: Consequences represent persistent conditions on the table. Never write "The next attack..." or "The next round...". Write continual states that apply until the card is actively cleared or mitigated.
5. **No Redundant Turn Wording**: A character takes **1 action per round** in Crisis Time. Never write _"and take no other action this round"_. Declaring an `action:` is already their action for that round.

---

## 2. The 6-Tier Severity Scale

caRdPG uses a 6-tier severity scale calibrated against the **Consequence Pool Drafting Engine** ($\text{Impact Required} = \text{Pool Size} \times \text{Severity}$).

| Severity | Category                    | Typical In-Combat Effect                                                                    | Narrative & Recovery Scope                                                               |
| :------: | :-------------------------- | :------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------------- |
|  **1**   | **Minor Friction / Wear**   | Small stance slip, footing penalty, blinded hand defense, momentary singe.                  | Easily shaken off; Routine out-of-combat fixes (seconds to minutes).                     |
|  **2**   | **Tactical Constraint**     | Card tax to swing/advance, loosened armor straps, fear, alchemical nausea.                  | Forces tactical adjustments; Challenging field care (minutes to hours).                  |
|  **3**   | **Significant Impediment**  | Concussion (mill on large hands), hamstring (no moves), pyric burn, knocked prone.          | Severe combat hindrance; Difficult clinical treatment (hours to days).                   |
|  **4**   | **Major Structural Trauma** | Broken limb (drop items), sundered armor, acute panic, deep puncture, dislocated joint.     | Structural bodily failure; Very Difficult surgery/orthopedics (weeks).                   |
|  **5**   | **Critical Trauma**         | Severe contusion, pneumothorax (deck bleed), compound fracture (Pool Size 1), mana burnout. | Life-threatening trauma; Near-Legendary intensive care (weeks to months).                |
|  **6**   | **Taken Out / Mortal**      | Traumatic coma, arterial bleedout, catatonic mind void, surrender/subdued.                  | Incapacitating; character is removed from the fight or requires emergency resuscitation. |

---

## 3. The `action:` vs. `task:` Removal Duality

Every consequence card should strictly separate **desperate in-combat mitigation** from **calm out-of-combat clinical recovery**.

```
+-----------------------------------------------------------------------------------------+
| IN-COMBAT ACTIONS (action:)                                                             |
| - High friction, high spend, card taxes, or severe tradeoffs.                           |
| - Used in the heat of melee to survive the next round.                                  |
| - Severe wounds (Sev 4-6) generally cannot be cured mid-combat, only suppressed/delayed.|
+-----------------------------------------------------------------------------------------+
| OUT-OF-COMBAT TASKS (task:)                                                             |
| - Calm, methodical, and reliable medical/crafting care during Adventuring/Downtime.     |
| - Calibrated against the GM Guide General Action Difficulty Benchmarks.                 |
| - Represents the unassisted baseline; specialized healer cards/spells provide bonuses.  |
+-----------------------------------------------------------------------------------------+
```

### 3.1. In-Combat Actions (`action:`)

In combat, clearing a condition is hurried and dangerous. Design actions around these patterns:

- **High Attribute Spends**: e.g., `Spend {Red} 20`, `Spend {Yellow} 25`.
- **Lingering Tradeoffs (`when removed:`)**: Clearing a condition quickly under fire often leaves lingering wear.
  - _Example_: `action: Force Through Spasm (Spend {Red} 20) -> Remove this.`
  - `when removed (via Action): Place 1 Fatigue card on top of your deck.`
- **Tactile Card Suppression ("Covering" the Card)**:
  Instead of discarding cards, the player physically places cards from hand on top of the consequence card to cover its passive text and suppress it.
  - _Example_: `action: Hold Direct Pressure (Place 2 cards from your hand on top of this to cover and suppress its passive. If you declare an Attack or Sprint, expend those cards and resume the passive).`
- **Multi-Turn Leverage**:
  - _Example_: `action: Struggle to Feet (Place a card from your hand on top of this. When cards on top of this exceed your Burden, expend them and remove this).`

### 3.2. Out-of-Combat Tasks (`task:`)

Out of combat, treatment is performed with care. Difficulty must strictly align with [gamemaster-guide.md](../../rules/gamemaster-guide.md):

- **Routine (Strength 5–10 | Seconds to Minutes)**: _Severity 1_ (e.g., eye wash, catching balance).
- **Challenging (Strength 15–25 | Minutes to Hours)**: _Severity 2_ (e.g., first-aid splints, harness tightening, centering breath).
- **Difficult (Strength 30–45 | Hours to Days)**: _Severity 3_ (e.g., tendon suturing, burn dressing, pastoral counseling).
- **Very Difficult (Strength 50–75 | Weeks to Months)**: _Severity 4_ (e.g., orthopedic bone setting, master forge reconstruction, deep cavity packing).
- **Near-Legendary (Strength 75–100 | Months)**: _Severity 5_ (e.g., thoracic decompression, complex bone traction, ley-line cleansing).
- **Legendary (Strength 100+ | Multi-Stage / Quest)**: _Severity 6_ (e.g., trauma resuscitation, arterial clamping, planar mind mending).

> [!NOTE]
> The printed `task:` difficulty is the **unassisted General Action baseline**. In actual play, players will use specialized doctor/healer cards, medical toolkits (+20–30 Blue), or restorative magic to bypass or assist these checks.

---

## 4. Proper Use of `Requires:` vs. `Cost:`

Always maintain the semantic distinction between persistent equipment and consumed resources:

- **`Requires:`** — Used for durable tools, fixtures, kits, workshops, or environments that are _not_ consumed:
  - `Requires Clean Water`, `Requires Repair Tools`, `Requires Splint`, `Requires Surgical Kit`, `Requires Forge & Anvil`, `Requires Darkened Infirmary`, `Requires Sanctified Temple`.
- **`Cost:`** — Reserved strictly for consumable resources that are _expended/destroyed_ during the check:
  - `Cost Bandage`, `Cost Herbal Purge`, `Cost Burn Salve & Wraps`, `Cost Raw Steel & Rivets`, `Cost Airtight Chest Seal`, `Cost Blood/Plasma Transfusion`.

---

## 5. Equipment & Armor Modification Rules

Consequence cards must **never** narrate standalone modifications to a character's consequence pool size directly. Instead, they interact with the character's equipped gear:

1. **Armor Cards are Two-Sided**:
   Equipped armor on the table has an **Intact** side and a **Damaged** side (see [equipment.yaml](equipment.yaml)). The Intact side defines the pool size and Pierce thresholds; the Damaged side defines the degraded pool size and higher Burden.
2. **Consequences Modify the Armor Item**:
   - _Severity 2 (Rattled Guard)_: _"Place this card on your equipped armor. While on your armor, your armor's first Pierce threshold is ignored by all incoming attacks."_
   - _Severity 4 (Sundered Armor)_: _"Flip your equipped armor to its Damaged side. (If your armor is already Damaged, expend it). Place this card on your armor."_

---

## 6. Condition Escalation & Upgrade Rules

Escalation is the mechanical engine of the downward spiral and dynamic pool curation. Escalation occurs **when the defender selects and suffers a consequence** that matches an **active condition already in play** in front of them.

### 6.1. The Three Strict Escalation Criteria

To preserve grounded verisimilitude and mechanical integrity, a condition card should only have an explicit `escalate:` path if **all three** of the following conditions are met:

1. **Narratively Worse:** The upgraded condition represents a direct, progressive worsening of the exact same physiological or psychological state.
2. **Hit-Triggered Realism:** Narratively, it makes clear sense that taking another hit/trauma of that type causes the existing injury to worsen (e.g., striking an off-balance foe knocks them prone; re-hitting a concussed head causes a severe cranial contusion; striking damaged armor sunders it).
3. **Mechanically Subsuming:** The upgraded condition's passive effect must **strictly subsume (be strictly worse than)** the active condition's passive effect. Discarding the active card upon upgrade must never accidentally grant the character a mechanical reprieve.

### 6.2. Transient vs. Persistent Consequences

- **Transient Consequences (Many Severity 1s)**:
  - Small slips, superficial capillary nicks, and breathlessness (e.g. `Near Miss`, `Out of Breath`, `Shallow Laceration`) resolve immediately: they pollute the deck (`Fatigue`), add cards to the expended pile (`Minor Wound`), or absorb a minimum pool spend, and are then **immediately discarded**.
  - They leave no persistent card on the table and have no `escalate:` paths. This prevents table bloat.
- **Persistent Conditions**:
  - Tactical constraints, ongoing injuries, and fears remain in play in front of the defender until cleared via an in-combat `action:` or out-of-combat `task:`.
  - While in play, they expose explicit escalation triggers.

### 6.3. Table Escalation Resolution

When a consequence card is selected by the defender from the curated pool:

1. **Novel Condition**: If no active condition on the table matches the chosen card's tags, place the chosen card into play as a new active condition.
2. **Explicit Escalation Trigger**: If an active condition has an `escalate:` clause matching an incoming consequence tag:
   - Discard the lower-tier active condition.
   - Put the upgraded condition specified in `replace_with:` into play.
   - _Nuance_: If the consequence chosen from the pool is already equal to or higher severity than the upgrade target, simply discard the lower active card and put the chosen higher-tier card into play.

---

## 7. Canonical YAML Card Template

When authoring cards in `consequences.yaml`, use the following exact structure:

```yaml
- name: Example Persistent Condition
  severity: 2 # Integer 1 to 6
  tags:
    - physical
    - arms
    - combat
  rules:
    # 1. Continual passive effect (must subsume lower tiers on the same track)
    - passive: You must expend 1 card from hand whenever you declare an Attack action.

    # 2. In-combat Action (Difficult spend, card covering, or tradeoff)
    - action: Force Through Spasm (Spend {Red} 20) -> Remove this.
    - when removed (via Action): Place 1 Fatigue card on top of your deck.

    # 3. Out-of-combat Task (Calibrated check, time, tools)
    - task: First Aid & Muscle Wrap (Check {Blue} 15; Time 1 hour; Cost Bandage; Requires Splint) -> Remove this.
    - when removed: Place 1 Minor Wound in your expended pile.

  # Explicit on-suffer escalation triggers (omit entirely for transient cards or peak-of-track conditions)
  escalate:
    - if_suffer: arms
      replace_with: Broken Arm (Colles' Fracture)

  notes: >
    Physiological / Biomechanical Basis: Deep clinical description explaining why this tissue trauma
    or cognitive shock produces the specific card taxes and passive constraints above.
    Detail both the in-combat tactical urgency and out-of-combat recovery rationale.
```

---

## 8. Checklist for Reviewing New Consequence Cards

Before committing any consequence card, verify:

- [ ] Is the severity accurately calibrated (1 to 6)?
- [ ] Are all passives written as continual states (no "the next...")?
- [ ] Is the word "damage" completely avoided for characters/decks? (Used "expend from deck/hand" instead?)
- [ ] Are color requirements qualified by declared action color or numerical threshold ({Blue} >= 3)?
- [ ] Is the in-combat `action:` sufficiently difficult, card-taxing, or trade-off heavy?
- [ ] Does the out-of-combat `task:` specify realistic time, `Requires:` (tools/facilities), and `Cost:` (consumables)?
- [ ] Is the `task:` check difficulty aligned with the GM Guide (Routine 5-10 through Legendary 100+)?
- [ ] If the card has an `escalate:` block, does it meet all 3 criteria (Narratively worse, Hit-triggered, Mechanically subsuming)?
- [ ] If the card is a transient Sev 1, does it resolve and return/discard immediately without leaving table clutter?
- [ ] Does the `notes:` field articulate the physiological/biomechanical basis?
