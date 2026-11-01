# Guide to Writing Consequence Cards

A comprehensive reference manual and style guide for designers authoring Consequence Cards for **caRdPG**.

---

## 1. Core Design Philosophy

Consequence cards are the mechanical engine of caRdPG's **"Default to Success at a Cost"** and **"Telegraphed Downward Spiral"** design precepts. They model physical harm, psychological stress, equipment failure, and tactical disruption as a tangible, multi-stage process rather than abstract hit-point subtraction.

### Golden Rules

1. **Grounded Realism & Verisimilitude**: All consequences must be grounded in clinical medicine, biomechanics, material science, or historical research (refer to [consequence-database.md](../../research/synthesis/consequence-database.md)).
2. **Never Use the Word "Damage" for Characters/Decks**: caRdPG uses explicit card-engine terminology: **`Expend X from the top of your deck`** or **`Expend X from hand`**.
3. **All Cards Have All Colors**: Every card has printed {Red}, {Yellow}, and {Blue} values. Never write "a card with {Blue} stats". Qualify either by **Declared Action Color** (e.g., _"All {Blue} actions..."_) or by **Value Threshold** (e.g., _"Whenever you draw a card whose printed {Blue} value is 3 or greater..."_).
4. **Continual Passives, Not One-Shot Triggers**: Consequences represent persistent conditions on the table. Never write "The next attack..." or "The next round...". Write continual states that apply until the card is actively cleared or mitigated.
5. **No Redundant Turn Wording**: A character takes **1 action per round** in Crisis Time. Never write _"and take no other action this round"_. Declaring an `action:` is already their action for that round.

---

## 2. The 4-Tier Severity Scale

caRdPG uses a 4-tier severity scale calibrated against the **Consequence Pool Drafting Engine** ($\text{Impact Required} = \text{Pool Size} \times \text{Severity}$).

| Tier  | Category                              | Typical In-Combat Effect                                                               | Narrative & Recovery Scope                                                               |
| :---: | :------------------------------------ | :------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------- |
| **1** | **Tactical Impairments & Setbacks**   | Sparring band: clearable footing slips (P1–3) to stiff tactical locks (P4–5).          | Easily shaken off; Routine out-of-combat fixes (seconds to minutes).                     |
| **2** | **Moderate Trauma & Severe setbacks** | Loss of stance (prone), mild concussive fog, cracked ribs, deep lacerations.           | Major tactical crisis; Challenging to Difficult clinical treatment (hours to days).      |
| **3** | **Severe Structural Trauma**          | Complete bone fractures, severe concussions, thoracic/chest trauma, arterial bleeding. | Catastrophic structural bodily failure; Very Difficult clinical surgery (weeks).         |
| **4** | **Taken Out / Incapacitation**        | Traumatic coma, arterial bleedout, catatonic panic, surrender/subdued.                 | Incapacitating; removed from combat or dying on a crisis clock. Legendary care (months). |

---

## 3. The `action:` vs. `task:` Removal Duality

Every consequence card should strictly separate **desperate in-combat mitigation** from **calm out-of-combat clinical recovery**.

```
+-----------------------------------------------------------------------------------------+
| IN-COMBAT ACTIONS (action:)                                                             |
| - High friction, card suppression/covering, card taxes, or severe tradeoffs.           |
| - Tier 1: Quick balance resets, eye rubs, or breath catches (spend 15–20 or tuck 1–2). |
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

### 3.1. In-Combat Actions (`action:`)

In combat, clearing a condition is hurried and dangerous. Design actions around these patterns based on tier:

- **Tier 1 (Tactical Reset)**:
  - _High Attribute Spends_: e.g., `Spend {Red} 20`, `Spend {Yellow} 25`.
  - _Lingering Tradeoffs (`when removed:`)_: Clearing a condition quickly under fire often leaves lingering wear.
    - _Example_: `action: Force Through Spasm (Spend {Red} 20) -> Remove this.`
    - `when removed (via Action): Place 1 Fatigue card on top of your deck.`
- **Tier 2 (Platform Recovery & Tactile Suppression)**:
  - _Multi-Turn Platform Leverage_:
    - _Example_: `action: Struggle to Feet (Place a card from your hand on top of this. When cards on top of this exceed your Burden, expend them and remove this).`
  - _Tactile Card Suppression ("Covering" the Card)_:
    Instead of discarding cards, the player physically places cards from hand on top of the consequence card to cover its passive text and suppress it.
    - _Example_: `action: Hold Direct Compression (Place 1 card from your hand on top of this to cover and suppress its passive. If you declare an Attack or Sprint, expend that card and resume the passive).`
  - _Note on Biological Trauma_: Pure bodily trauma at Tier 2 (`Cracked Ribs`, `Mild Concussion`, `Hamstrung`) has **no in-combat removal action**. It must be endured until downtime.
- **Tier 3 (Zero Removal Actions)**:
  - Severe structural trauma (`Broken Arm`, `Sucking Chest Wound`, `Severe Concussion`) **cannot be removed or cured during combat**.
  - Only crisis-delay suppression exists for life-threatening conditions (e.g., `Hold Direct Pressure` on `Arterial Hemorrhage` requiring 2 cards held).
- **Tier 4 (Ally Emergency Intervention Only)**:
  - If a Tier 4 condition features an action (such as `Ally Emergency Hemostasis` on `Mortal Bleedout`), it can **only be performed by an adjacent ally**, not the incapacitated defender.

### 3.2. Out-of-Combat Tasks (`task:`)

Out of combat, treatment is performed with care. Difficulty must strictly align with [gamemaster-guide.md](../../rules/gamemaster-guide.md):

- **Tier 1 (Tactical Setbacks & Friction)**:
  - **Default: Time & Resources (No Check Required):** Transient physical or postural friction (`Poor Footing`, `Winded`, `Dust in Eyes`) clears with seconds to minutes of undisturbed time (`Time 1 min`) or simple supplies (`Requires Clean Water`). Do not require a check unless performing actual tissue treatment (such as `Bleeding Cut` or `Strained Offense`).
  - **The "Paced vs. Pushed" Dual-Task Pattern:** For conditions where a character can naturally recover with calm composure or push through under immediate pressure (especially fear, cognitive shock, or disorientation), print **separate task lines** on the card:
    - _Example:_
      ```yaml
      - task: Center Yourself (Time 5 min) -> Remove this.
      - task: Shake Off Panic (Check {Blue} 15; Time 30 sec) -> Remove this.
      ```
    - _Why on the card? (10x Rule):_ By printing separate explicit task lines directly on the card, the table gets immediate, concrete operational choices without needing universal rules or GM adjudications for "rushing a task."
- **Tier 2 (Moderate Trauma & Platform Collapse)**:
  - **Mandatory Checks (Strength 20–35 | Hours to Days):** Rib wraps, tendon sutures, concussion observation. All Tier 2 physical conditions require a formal check, dedicated downtime, and tools/facilities (`Requires Splint`, `Requires Darkened Room`).
- **Tier 3 (Severe Structural Trauma)**:
  - **Severe Checks (Strength 45–60 | Days to Weeks):** Orthopedic surgery, arterial vessel repair, deep cavity packing. Requires master medical care, surgery kits, and clinical infirmaries.
- **Tier 4 (Legendary / Incapacitation / Terminal)**:
  - **Legendary Checks (Strength 80–100+ | Weeks to Months):** Acute trauma resuscitation, planar mind-mending, life-support stabilization.

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

## 5. Vulnerability Promotion Web & Harm Archetypes

CaRdPG drives the downward spiral through a **Tag Vulnerability Exploitation Web** during the Consequence Pool draw.

### 5.1. How Vulnerability Exploitation Works

1. **Card Tags (`tags:`) vs. Compromised Tags (`vulnerable:`)**:
   - **`tags:`** define what the consequence _is_ (e.g., `Winded` has `exertion`; `Dust in Eyes` has `sensory, eyes`; `Cracked Ribs` has `torso`).
   - **`vulnerable:`** lists **2 to 4 Leaf Tags** representing the anatomical, positional, or psychological openings that this active condition exposes on the defender.
2. **Tier-Scoped Exploitation ($\text{Tier } K \le S$) — "Place to Draw, Scoop to Curate"**:
   - During Step 4 of resolution (after base candidates are drawn and pools are formed), an active condition of **Severity $S$** may exploit **at most 1** unplaced candidate card in the pool of **Severity $K \le S$** whose `tags:` match one of the active condition's `vulnerable:` tags.
   - **Tactile Exploitation (+1 Candidate at Tier $K+1$):** The attacker places the matching Tier $K$ candidate **onto the exploited active condition** (marking both the condition and that candidate as spent for Step 4) and **draws 1 additional candidate from the Severity $K+1$ deck** into their hand/pool (drawing from the **Severity 4 deck** when a Tier 3 card exploits an active Tier 3 condition).
   - **Scoop to Curate (Step 5):** Once Step 4 finishes for the pool, the attacker scoops the placed candidate cards back off the defender's active conditions into the pool and curates any $N$ cards. Because each exploitation adds $+1$ net card at Tier $K+1$ while preserving the triggering Tier $K$ card, this builds the Consequence Pyramid by squeezing out soft lower-tier options when $I \ge N$.
3. **The Consequence Pyramid & Shell-Cracking**:
   - Because a newly drawn Tier $K+1$ candidate enters the hand unplaced, it can itself be placed onto _another_ unexploited active condition of Tier $\ge K+1$ with a matching `vulnerable:` tag to chain into Tier $K+2$.
   - This prevents lucky Turn 1 draw cascades while allowing attackers to systematically dismantle heavily armored foes ($N=4\text{–}5$): bonus draws escalate the pool into Tier 2 candidates, which in turn allow subsequent hits to draw Tier 3 structural trauma.

---

### 5.2. The Four Harm Archetypes Under the Vulnerability Web

1. **Discrete Anatomical & Structural Point-Failures (Standalone Traumas)**:
   - _Scope:_ `Cracked Ribs` (T2), `Hamstrung` (T2), `Broken Arm` (T3), `Sucking Chest Wound` (T3), `Gut Wound` (T3), `Ringing Ears` (T1), `Stiff Neck` (T1).
   - _Behavior:_ These injuries enter play directly when drawn (natively or via promotion) rather than evolving from lower-tier prerequisites. They expose realistic `vulnerable:` tags (e.g., `Cracked Ribs` exposes `torso, exertion, positioning`).
2. **Platform & Posture States (Broad Vulnerability Multipliers)**:
   - _Scope:_ `Poor Footing` (T1), `Off Balance` (T1), `Knocked Prone` (T2).
   - _Behavior:_ Losing dynamic posture compromises multiple anatomical zones at once. `Knocked Prone` (Tier 2) lists a wide vulnerability web (`vulnerable: [positioning, limbs, torso, head]`), promoting matching Tier 2 draws into the **Tier 3** deck.
   - _Superseding Lower States:_ When a stricter state on the same binary track enters play (e.g., `Off Balance` replacing `Poor Footing`, or `Knocked Prone` replacing `Poor Footing`/`Off Balance`), its rules text instructs the defender to discard the weaker state.
3. **Cumulative Hemodynamic Loss (Bleeding & Vascular Trauma)**:
   - _Scope:_ `Bleeding Cut` (T1), `Deep Laceration` (T2), `Arterial Hemorrhage` (T3).
   - _Behavior:_ Separate cuts on different parts of the body coexist in parallel rather than morphing into one another. Each exposes `bleeding` and related tags (`exertion`, `limbs`, `torso`) under `vulnerable:`, naturally promoting follow-up bleeding draws into higher severity tiers through the Vulnerability Promotion Web.
   - _Ongoing Mechanics Tuning:_ The specific tracking mechanics for systemic volume loss (e.g., diluting the draw deck with unspendable stamina/fatigue cards vs. tactile suppression vs. crisis clocks) are being designed to avoid sudden-death hand-counting anomalies.
4. **Progressive Neurotrauma & Acute Panic**:
   - _Scope:_ `Dazed` (T1) / `Mild Concussion` (T2) / `Severe Concussion` (T3); `Rattled Nerves` (T1) / `Afraid` (T1) / `Terrified` (T2).
   - _Behavior:_ Each condition exposes `head, sensory, positioning` or `fear, mental, positioning` in its `vulnerable:` list, naturally promoting subsequent hits to higher tiers and superseding lower states on the same track when a higher state enters play.

---

### 5.3. Canonical Leaf Tags & Sample Vulnerability Wiring

Root tags (`physical`, `combat`, `injury`) are used strictly for domain classification. Both `tags:` (for matching) and `vulnerable:` must use the canonical Leaf Tags (`positioning`, `exertion`, `head`, `torso`, `limbs`, `bleeding`, `sensory`, `fear`, `mental`):

| Consequence Card    | Tier | Card's Leaf Tags    | `vulnerable:` (Promotes Tier $\le S$ draws with these tags) | State / Redraw Rule                         |
| :------------------ | :--: | :------------------ | :---------------------------------------------------------- | :------------------------------------------ |
| **Poor Footing**    |  1   | `positioning`       | `positioning`, `limbs`                                      | Non-stackable (redraw duplicate)            |
| **Off Balance**     |  1   | `positioning`       | `positioning`, `limbs`, `torso`                             | Replaces `Poor Footing`; redraw duplicate   |
| **Winded**          |  1   | `exertion`          | `exertion`, `positioning`, `torso`                          | Non-stackable (redraw duplicate)            |
| **Dust in Eyes**    |  1   | `sensory`           | `sensory`, `head`, `positioning`                            | Non-stackable (redraw duplicate)            |
| **Afraid**          |  1   | `fear`, `mental`    | `fear`, `mental`, `positioning`                             | Replaces `Rattled Nerves`; redraw duplicate |
| **Bleeding Cut**    |  1   | `bleeding`          | `bleeding`, `exertion`                                      | Stacks in parallel                          |
| **Knocked Prone**   |  2   | `positioning`       | `positioning`, `limbs`, `torso`, `head`                     | Replaces T1 `positioning`; redraw duplicate |
| **Cracked Ribs**    |  2   | `torso`             | `torso`, `exertion`, `positioning`                          | Stacks in parallel                          |
| **Mild Concussion** |  2   | `head`, `sensory`   | `head`, `sensory`, `positioning`, `mental`                  | Non-stackable (redraw duplicate)            |
| **Hamstrung**       |  2   | `limbs`, `bleeding` | `limbs`, `positioning`                                      | Stacks in parallel (per leg)                |

---

### 5.4. Non-Stackable States & Same-Tier Redraws

Most physical injuries (`Bleeding Cut`, `Cracked Ribs`, `Strained Offense`) can be suffered more than once in parallel without issue. However, binary posture or mental states (`Knocked Prone`, `Off Balance`, `Poor Footing`, `Afraid`, `Terrified`) cannot logically stack with themselves.

- **Normally Promoted:** If a duplicate of an active binary state is drawn, the attacker will usually place it onto that active condition to draw 1 candidate from Tier $K+1$.
- **Fallback Redraw Rule (When Promotion Already Used):** For binary state cards, include a concise redraw clause so they never become "free blank" picks if drawn after that condition's promotion was already spent:
  - _Standard Binary State:_ `redraw: If you already have this condition (or a higher positioning/fear state) in play, the attacker may redraw this candidate at the same tier.`

---

### 5.5. Resetting Mitigation Progress (The Setback Pattern)

When a condition card uses multi-turn in-combat mitigation (such as tucking cards to regain footing or holding cards on `Arterial Hemorrhage` to suppress bleeding), jarring impacts can disrupt active progress:

- **On `Arterial Hemorrhage`:**
  ```yaml
  - setback: "If you suffer a positioning or physical consequence while cards are on top of this, jarring impact breaks your compress: expend those cards and resume the passive immediately."
  ```

---

### 5.6. Transient Consequences

Transient consequences (if used in specialized domain decks) resolve immediately upon being selected and are returned to the deck. Because they do not remain in play as active conditions, they **never** have a `vulnerable:` list.

---

## 6. The `priority:` Metric & The Tapering Funnel

Every consequence card includes an integer `priority:` rating (**1 to 5**). This number represents the designer's calibrated estimate of the consequence's **aggregate "badness" or tactical lethality within its severity tier**.

### 6.1. Purpose & Use Cases

1. **Fast-Paced GM Adjudication ("Without an Opinion")**:
   When a GM draws several candidate cards within a tier and has no strong narrative or tactical preference, the GM first performs any available **Vulnerability Exploitations** (placing matching Tier $K \le S$ candidates onto active Tier $S$ conditions to draw $+1$ candidate from Tier $K+1$), scoops all candidates back into the pool, and then simply compares printed `severity` and `priority` numbers to select the highest-priority cards in seconds.
2. **VTT, Digital Tools, and Solo AI Automation**:
   Automated curation scripts can execute deterministic, high-quality "I Cut" pool curation:
   - _Step 1 (Vulnerability Exploitation)_: Check drawn candidates against active conditions (highest tier first). For each matching condition, place a matching unplaced candidate (Tier $K \le S$) on the condition and draw 1 additional candidate from Tier $K+1$.
   - _Step 2 (Scoop & Curation)_: Scoop all placed candidates back into the pool, and sort all candidates by `severity` descending, then `priority` descending.
   - _Step 3_: Present the top $N$ cards to the defender.

### 6.2. The Tapering Funnel Guidelines by Tier

The dynamic range within a tier narrows as severity climbs:

- **Tier 1 (The Sparring Band - Full Priority 1–5 Range)**:
  - _Priority 1–2 (Softer / Clearable)_: Footing slips, minor breath loss, transient singes. Easily cleared in 1 action or via card-tucking; exposes `vulnerable:` tags for future promotions.
  - _Priority 3 (Resource Friction)_: Moderate card taxes, minor status injections.
  - _Priority 4–5 (Sharp Tactical Locks)_: Stiff action restrictions, fear lockouts (`Off Balance`, `Afraid`, `Strained Offense`).
- **Tier 2 (Operational Divergence - Priority 3–5 Only)**:
  - All Tier 2 cards are serious; there are no "soft outs."
  - _Priority 3–4 (Chronic Biological Drag)_: Persistent neuro/tissue trauma (`Mild Concussion`, `Cracked Ribs`, `Deep Laceration`). Cannot be removed in combat; exposes Tier 2 `vulnerable:` tags that can promote Tier 2 draws into Tier 3.
  - _Priority 5 (Platform Crisis)_: `Knocked Prone` (crippled movement, $+1$ Impact on defenses, broad `vulnerable:` list; has active recovery pathways).
- **Tier 3 (Orthogonal Pillar Collapse - Priority 4–5 Only)**:
  - Zero soft options. Every card is an existential collapse of one core character pillar (`Broken Arm`, `Sucking Chest Wound`, `Severe Concussion`, `Arterial Hemorrhage`) and exposes Tier 3 `vulnerable:` tags that promote matching Tier 3 draws directly to **Tier 4 (Taken Out)**.
- **Tier 4 (Climax & Terminal Trauma Deck)**:
  - Physical cards representing traumatic coma, arterial bleedout clocks, or limb amputation. Cards define immediate exit rules, emergency ally stabilization actions (e.g., pausing a bleedout timer), and long-term resuscitation tasks.

---

## 7. Canonical YAML Card Template

When authoring cards in `consequences.yaml`, use the following exact structure:

```yaml
- name: Example Persistent Condition
  severity: 2 # Integer 1 to 4 (Physical Decks)
  priority: 4 # Integer 1 to 5 (threat ranking within tier)
  tags:
    - physical
    - limbs
    - combat
  vulnerable:
    - limbs
    - positioning
    - exertion
  rules:
    # 1. Continual passive effect (plus any superseded lower state or non-stackable redraw rule)
    - passive: You must expend 1 card from hand whenever you declare an Attack action.

    # 2. In-combat Action (Platform recovery, suppression, or tradeoff; omit for unfixable bodily trauma)
    - action: Force Through Spasm (Spend {Red} 20) -> Remove this.
    - when removed (via Action): Place 1 Fatigue card on top of your deck.

    # 3. Out-of-combat Task (Calibrated check, time, tools)
    - task: First Aid & Muscle Wrap (Check {Blue} 25; Time 1 hour; Cost Bandage; Requires Splint) -> Remove this.
    - when removed: Place 1 Minor Wound in your expended pile.

  notes: >
    Physiological / Biomechanical Basis: Deep clinical description explaining why this tissue trauma
    or cognitive shock produces the specific card taxes, passive constraints, and anatomical/tactical
    vulnerabilities (`vulnerable:`) listed above.
```

---

## 8. Checklist for Reviewing New Consequence Cards

Before committing any consequence card, verify:

- [ ] Is the severity accurately calibrated (Tier 1, 2, 3, or 4)?
- [ ] Is the `priority:` rating (1 to 5) assigned according to the Tapering Funnel guidelines?
- [ ] Are all passives written as continual states (no "the next...")?
- [ ] Is the word "damage" completely avoided for characters/decks? (Used "expend from deck/hand" instead?)
- [ ] Are color requirements qualified by declared action color or numerical threshold ({Blue} >= 3)?
- [ ] If Tier 2 or 3 bodily trauma, is an in-combat removal `action:` appropriately omitted (or limited strictly to temporary tactile suppression)?
- [ ] Does the out-of-combat `task:` specify realistic time, `Requires:` (tools/facilities), and `Cost:` (consumables)?
- [ ] Is the `task:` check difficulty aligned with the GM Guide benchmarks for that tier (or omitted for simple Tier 1 time/resource tasks)?
- [ ] Does the card specify 2 to 4 realistic Leaf Tags under `vulnerable:` (`positioning`, `exertion`, `head`, `torso`, `limbs`, `bleeding`, `sensory`, `fear`, `mental`) with zero root tags (`injury`, `physical`, `combat`)?
- [ ] Does the card use `vulnerable:` tags for pool escalation?
- [ ] If the card represents a binary posture/mental state that cannot stack with itself (`Knocked Prone`, `Off Balance`, `Afraid`), does it include a same-tier redraw rule for duplicates (and superseded lower states)?
- [ ] Does the `notes:` field articulate the physiological/biomechanical basis for both the passives and the `vulnerable:` tags?
