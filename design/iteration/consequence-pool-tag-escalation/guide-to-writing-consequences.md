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

## 2. The 5-Tier Severity Scale

caRdPG uses a 5-tier severity scale calibrated against the **Consequence Pool Drafting Engine** ($\text{Impact Required} = \text{Pool Size} \times \text{Severity}$).

| Severity | Category                                | Typical In-Combat Effect                                                        | Narrative & Recovery Scope                                                               |
| :------: | :-------------------------------------- | :------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------------- |
|  **1**   | **Fleeting Friction & Wear**            | Small stance slip, footing penalty, blinded hand defense, momentary singe.      | Easily shaken off; Routine out-of-combat fixes (seconds to minutes).                     |
|  **2**   | **Tactical Impairment / Minor Injury**  | Card tax to swing/advance, loosened armor straps, fear, bleeding cut, nausea.   | Forces tactical adjustments; Challenging field care (minutes to hours).                  |
|  **3**   | **Platform Ceilings & Moderate Trauma** | Loss of stance (prone), mild concussive fog, cracked ribs, deep lacerations.    | Major tactical crisis; Difficult field or clinical treatment (hours to days).            |
|  **4**   | **Severe Structural Trauma**            | Complete bone fractures, severe concussions, sundered armor, arterial bleeding. | Catastrophic structural bodily/gear failure; Very Difficult clinical surgery (weeks).    |
|  **5**   | **Taken Out / Incapacitation**          | Traumatic coma, arterial bleedout, catatonic panic, surrender/subdued.          | Incapacitating; removed from combat or dying on a crisis clock. Legendary care (months). |

---

## 3. The `action:` vs. `task:` Removal Duality

Every consequence card should strictly separate **desperate in-combat mitigation** from **calm out-of-combat clinical recovery**.

```
+-----------------------------------------------------------------------------------------+
| IN-COMBAT ACTIONS (action:)                                                             |
| - High friction, high spend, card taxes, or severe tradeoffs.                           |
| - Used in the heat of melee to survive the next round.                                  |
| - Severe wounds (Sev 3-4) generally cannot be cured mid-combat, only suppressed/delayed.|
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

- **Routine (Strength 5–10 | Seconds to Minutes)**: _Severity 1_ (e.g., eye wash, catching balance, breathing recovery).
- **Challenging (Strength 15–25 | Minutes to Hours)**: _Severity 2_ (e.g., first-aid splints, harness tightening, centering breath, bandaging minor cuts).
- **Difficult (Strength 30–45 | Hours to Days)**: _Severity 3_ (e.g., rib wraps, dark room rest for mild concussions, tendon suturing).
- **Very Difficult to Severe (Strength 50–70 | Days to Weeks)**: _Severity 4_ (e.g., orthopedic bone setting, master forge reconstruction, deep arterial cavity packing, severe concussion management).
- **Legendary / Emergency Resuscitation (Strength 80–100+ | Weeks to Months)**: _Severity 5_ (e.g., acute trauma resuscitation, planar mind-mending, life-support stabilization).

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

## 6. Condition Escalation & Harm Archetypes

Escalation is the mechanical engine of the downward spiral and dynamic pool curation. Escalation occurs **when the defender selects and suffers a consequence** that interacts with an **active condition already in play** in front of them.

### 6.1. The Three Harm Archetypes

Consequences do not all behave as simple single-track state machines. Tabletop harm falls into three distinct archetypes:

1. **Platform Vulnerabilities (Finite Ceilings)**:
   - _Scope:_ Positional stability and physical armor integrity (`positioning`, `armor`).
   - _Natural Ceilings:_ These tracks have distinct tactical floors: `positioning` peaks at Severity 3 (`Knocked Prone`), while `armor` peaks at Severity 4 (`Sundered Armor`). Taking another positioning hit cannot make a person "more prone."
   - _External Escalation:_ The escalation of being prone or unarmored is not an artificial surrender clause—it is the **severe mechanical vulnerability it confers to other attacks** (doubled Pierce, $+1$ Impact on defenses, action taxes). Attackers exploit these vulnerabilities with standard weapon strikes to flip massive Impact and inflict lethal physical trauma.
2. **Progressive Pathologies (Compounding Cascades)**:
   - _Scope:_ Neurological trauma and acute psychological stress (`head`, `fear`).
   - _Natural Cascade:_ Re-injuring the exact same physiological or cognitive system triggers compounding systemic breakdown:
     - _Head Trauma:_ `Dazed` (Sev 2) $\to$ `Mild Concussion` (Sev 3) $\to$ `Severe Concussion` (Sev 4) $\to$ `Unconscious (Traumatic Coma)` (Sev 5).
     - _Panic:_ `Rattled Nerves` (Sev 1) $\to$ `Afraid` (Sev 2) $\to$ `Terrified` (Sev 3) $\to$ `Mind Void` (Sev 5).
3. **Cumulative & Attritional Harm (Flesh & Blood)**:
   - _Scope:_ Lacerations, punctures, contusions, and soft-tissue wear (`bleeding`, `injury`).
   - _Independent Coexistence:_ Cuts to different limbs exist in parallel; getting cut on the arm and cut on the leg does not morph into a puncture wound in the torso. Escalation occurs through **hemodynamic volume loss** (Class I $\to$ Class II $\to$ Class III $\to$ Class IV Hemorrhage) and deck saturation (`Minor Wound` and `Blood Loss` cards).

---

### 6.2. The Three Inviolable Rules of Escalation Design

To prevent degenerate mechanics, all `escalate:` clauses must satisfy three strict criteria:

1. **The Organic Asymmetry Standard (Ban on Forced Symmetry)**:
   Escalation should **only occur if it makes sense mechanically and narratively**. It is completely fine for cards to have no printed escalation, or for chains to be different lengths.
   > **A card track that mechanically forces a neat 1 $\to$ 2 $\to$ 3 $\to$ 4 $\to$ 5 progression is suspicious.**
   > Human physiology and tabletop tactics are inherently asymmetric. Some tracks peak early (posture at Sev 3); some jump directly to emergency states upon re-injury; others exist purely as parallel symptoms.
2. **The Narrative Continuity Standard**:
   An escalation must represent a direct progression of the **exact same underlying pathology**.
   - _Forbidden:_ Morphing wound categories (e.g., a cut turning into a puncture; bruised ribs turning into a strained arm).
   - _Forbidden:_ Anatomical teleportation (e.g., an arm injury causing a head coma).
3. **The Mechanical Superset Standard**:
   When a condition card escalates, the active card is discarded and replaced by the upgraded card. Therefore:
   > **The upgraded card MUST mechanically include or strictly obsolete every restriction and penalty on the card it replaces.**
   > If a lower card imposes $+1$ Impact on defenses, the upgraded card must either explicitly retain $+1$ Impact (as `Knocked Prone` does) or impose an absolute lockout (like `Unconscious` forbidding defense entirely). Upgrading must never grant a mechanical reprieve or cure a defensive penalty.

---

### 6.3. Leaf Tags Only (Banning Root Taxonomic Triggers)

Root tags (`physical`, `combat`, `injury`, `mental`, `sensory`) exist strictly for deck classification, domain filtration, and gear resistances.

- **`escalate:` blocks may only match specific Leaf Tags**: `head`, `fear`, `bleeding`, `positioning`, `armor`, `burn`, `arms`, `legs`.
- **Never** write `if_suffer: injury` or `if_suffer: physical` in an escalation block. Doing so causes unrelated weapon strikes (e.g. an arrow to the hip) to trigger localized trauma (e.g. an arm fracture).

---

### 6.4. The Anvil Principle & Resolution-Time Wildcards (Platform Ceilings)

When a defender suffers a consequence whose track is already at its ceiling (e.g., suffering a Severity 3 `Knocked Prone` while already prone, or Severity 4 `Sundered Armor` while armor is destroyed), the kinetic energy transfers directly into raw bodily trauma:

- **`Knocked Prone` (Severity 3):**
  ```yaml
  - if_suffer: positioning (Severity 3):
      text: >
        You are already prone. The kinetic force slams you against the unyielding ground:
        Draw and suffer 1 Severity 3 Physical Injury card from the deck.
  ```
- **`Sundered Armor` (Severity 4):**
  ```yaml
  - if_suffer: armor (Severity 4):
      text: >
        Your armor is already ruined. The blow punches straight through the wreckage into bare flesh:
        Draw and suffer 1 Severity 4 Physical Injury card from the deck.
  ```
  This makes redundant platform curation a high-stakes resolution-time gamble rather than a "free pick" exploit for the defender.

---

### 6.5. Resetting Mitigation Progress (The Setback Pattern)

When a condition card uses multi-turn in-combat mitigation (such as tucking cards to regain footing or suppress bleeding), minor incoming disruptions (Severity 1–2) reset active progress:

- **On `Knocked Prone`:**
  ```yaml
  - if_suffer: positioning (Severity 1-2):
      text: >
        You are kicked and pinned in the dirt:
        Expend 1 card from hand, and discard all cards currently tucked under this card.
  ```
- **On `Arterial Hemorrhage`:**
  ```yaml
  - if_suffer: positioning or physical:
      text: >
        Jarring impact breaks your compress:
        Expend all cards currently tucked under this card and resume the bleeding passive immediately.
  ```

---

### 6.6. The "Parallel Second One" Engine (Head Trauma & Bleeding)

For conditions where lesser symptoms realistically coexist with major trauma, the lesser condition **enters play in parallel** rather than triggering an instant terminal collapse:

- If a defender holds `Mild Concussion` (Sev 3) and suffers `Dazed` (Sev 2, `head`), `Dazed` enters play **alongside** `Mild Concussion`. The defender suffers both the card-cost cap and the draw degradation.
- A terminal catastrophe (Severity 5) only triggers when **two major traumas of that track accumulate**:
  - `Mild Concussion` escalates to `Severe Concussion` (Sev 4). If the defender _already_ has an active `Severe Concussion`, compounding trauma triggers Second Impact Syndrome: discard both and put `Unconscious (Traumatic Coma)` (Severity 5) into play.
  - Similarly, multiple cuts exist in parallel; if a second bleed escalates to `Arterial Hemorrhage` (Sev 4) while one is already active, systemic volume loss triggers `Mortal Bleedout (Exsanguination)` (Severity 5).

---

### 6.7. Transient Consequences Must Never Escalate

Transient consequences (e.g. `Near Miss`, `Out of Breath`, `Shallow Laceration`) resolve immediately upon being selected: they inject status cards into the deck or expended pile and are immediately returned.

- Transient cards **must never have an `escalate:` block**. If a card is not persistent on the table, it cannot be triggered by subsequent attacks.

---

## 7. The `priority:` Metric (Within-Tier Threat Ranking)

Every consequence card includes an integer `priority:` rating (typically **1 to 5**). This number represents the designer's calibrated estimate of the consequence's **aggregate "badness" or tactical lethality within its severity tier**.

### 7.1. Purpose & Use Cases

1. **Fast-Paced GM Adjudication ("Without an Opinion")**:
   When a GM draws several candidate cards within a tier (e.g., three Severity 1 cards) and has no strong narrative or tactical preference, the GM simply compares the printed priority numbers. Selecting the highest-priority cards ensures the most threatening options enter the pool in seconds, without requiring the GM to read and compare paragraphs of rules text under fire.
2. **VTT, Digital Tools, and Solo AI Automation**:
   Virtual tabletop software and automated enemy scripts can execute deterministic, high-quality "I Cut" pool curation using a simple sorting rule:
   - _Step 1_: Check for matching active condition tags on the defender (top priority to trigger escalations).
   - _Step 2_: For remaining pool slots, sort candidate cards by `severity` descending, then `priority` descending.
   - _Step 3_: Present the top $N$ cards to the defender.

### 7.2. Calibration Scale (Within-Tier Priority 1–5)

- **Priority 1 (Soft / Fleeting)**: Harmless slips, clean blanks, or negligible friction that is easily ignored or quickly cleared (e.g., `Near Miss`).
- **Priority 2 (Mild Lingering Wear)**: Superficial wounds or delayed deck pollution added to the expended pile rather than the active hand/draw deck (e.g., `Shallow Laceration`).
- **Priority 3 (Active Resource Drain)**: Injects immediate dead cards onto the top of the draw deck, or imposes mild ongoing resource taxes on common actions (e.g., `Out of Breath`).
- **Priority 4 (Tactical Vulnerability / Broad Penalty)**: Increases the Impact of all future defenses, penalizes primary attacks, or restricts movement/engagement (e.g., `Poor Footing`, `Strained Offense`, `Afraid`).
- **Priority 5 (Severe Lockout / Critical Vulnerability)**: Completely shuts down core defensive avenues (like hand defense), strips armor Pierce thresholds, or exposes lethal escalation tracks (e.g., `Dust in Eyes`, `Rattled Guard`, `Sundered Armor`).

---

## 8. Canonical YAML Card Template

When authoring cards in `consequences.yaml`, use the following exact structure:

```yaml
- name: Example Persistent Condition
  severity: 2 # Integer 1 to 5
  priority: 4 # Integer 1 to 5 (aggregate threat/badness within tier)
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

## 9. Checklist for Reviewing New Consequence Cards

Before committing any consequence card, verify:

- [ ] Is the severity accurately calibrated (1 to 5)?
- [ ] Is the `priority:` rating (1 to 5) assigned, reflecting its aggregate threat within its severity tier?
- [ ] Are all passives written as continual states (no "the next...")?
- [ ] Is the word "damage" completely avoided for characters/decks? (Used "expend from deck/hand" instead?)
- [ ] Are color requirements qualified by declared action color or numerical threshold ({Blue} >= 3)?
- [ ] Is the in-combat `action:` sufficiently difficult, card-taxing, or trade-off heavy?
- [ ] Does the out-of-combat `task:` specify realistic time, `Requires:` (tools/facilities), and `Cost:` (consumables)?
- [ ] Is the `task:` check difficulty aligned with the GM Guide (Routine 5-10 through Legendary 100+)?
- [ ] If the card has an `escalate:` block, does it meet all 3 criteria (Narratively worse, Hit-triggered, Mechanically subsuming)?
- [ ] Are `escalate:` triggers restricted strictly to Leaf Tags (e.g. `head`, `fear`, `bleeding`, `positioning`, `armor`), completely banning root tags (`injury`, `physical`, `combat`)?
- [ ] If the card is a platform condition at its ceiling (e.g. `Knocked Prone`, `Sundered Armor`), does it define an Anvil Principle wildcard (e.g. draw and suffer Sev 3 Physical Injury) and a progress setback clause?
- [ ] If the card is a transient Sev 1, does it resolve and return/discard immediately with NO `escalate:` block?
- [ ] Does the `notes:` field articulate the physiological/biomechanical basis?
