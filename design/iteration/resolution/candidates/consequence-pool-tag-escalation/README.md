# Consequence Pool & Tag Escalation Resolution Engine

## Executive Summary & Design Overview

This directory contains the settled design proposal, play traces, equipment architecture, prototype consequence database, and authoring guidelines for replacing the legacy `Defense` and `Resilience` resolution mechanics with the **Consequence Pool & Tag Escalation Engine**.

In this new engine, resolution is reframed as an **"I Cut, You Choose" consequence drafting market**:

1. **Layered Pool Fill**: $1\text{ Impact} = 1\text{ Card Drawn}$. Cards fill tiers of width $N$ (the defender's Pool Size) from Severity 1 upward, procedurally building the pool without integer partition math.
2. **Pool Size is the Soak Multiplier**: The defender's gear and nature determine the row width $N$ that attackers must saturate before breaking into higher severity tiers.
3. **Implicit Blanks ("No Consequence")**: Unfilled Tier 1 slots ($I < N$) become "No Consequence", creating an emergent armor soak threshold without requiring abstract divisor stats.
4. **Tag Vulnerability Exploitation ("Place to Draw, Scoop to Curate") Replaces Global Resilience**: Active conditions expose specific **`Vulnerable: [Tags]`** (`positioning`, `limbs`, `torso`, `head`, `armor`, `exertion`, `fear`). Matching an unplaced candidate (Tier $K \le S$) to an active condition (Tier $S$) lets the attacker place that candidate onto the condition to **draw +1 additional card from Tier $K+1$**, then scoop all candidates back into the pool in Step 4 to curate $N$ cards—simultaneously adding $+1$ net candidate to crack heavy armor shells ($I < N$) and building an escalating **Consequence Pyramid** when $I \ge N$.

---

## 1. Directory Manifest & Key Documents

| File                                                                           | Purpose & Contents                                                                                                                                                                                 |
| :----------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **[proposal.md](proposal.md)**                                                 | **The Core Rules Patch**: The normative replacement text for `design/rules/core-rules.md` (`## 2. Facing a Challenge`, `### Defend Actions`, and `### General Actions`).                           |
| **[players-guide-patch.md](players-guide-patch.md)**                           | **Player's Guide Patch**: Tactical strategy for consequence curation ("I Cut") and intra-tier evaluation.                                                                                          |
| **[gamemaster-guide-patch.md](gamemaster-guide-patch.md)**                     | **Gamemaster's Guide Patch**: Antagonist curation tactics (brutes, swarms, combined assaults), minion batching, and General Actions calibration.                                                   |
| **[guide-to-writing-consequences.md](guide-to-writing-consequences.md)**       | **Authoring & Style Guide**: Standards for writing consequence cards (Continual Passives, Action vs. Task Duality, `Requires:` vs. `Cost:`, color qualifiers, ban on "damage" terminology).        |
| **[consequences.yaml](consequences.yaml)**                                     | **Prototype Card Database**: Prototype cards across Severities 1–3 (plus Tier 4 exit states) with rules, in-combat actions, downtime tasks, tag vulnerabilities, and clinical/biomechanical notes. |
| **[equipment.yaml](equipment.yaml)**                                           | **Item & Armor Baseline**: Demonstrates how protective gear and domain traits establish Consequence Pool Size ($N$).                                                                               |
| **[critique-and-brainstorming-seeds.md](critique-and-brainstorming-seeds.md)** | **Historical Critiques & Brainstorming Seeds**: Early explorations of tabletop ergonomics and multi-tier card consolidation.                                                                       |

---

## 2. Core Resolution Loop Overview

> [!IMPORTANT]
> **Normative Rules Specification:** Read **[proposal.md](proposal.md)** for the exact rules text to be promoted into `design/rules/core-rules.md`. The sections below provide the visual summary, mathematical rationale, and design discussion for evaluating the proposal.

```mermaid
flowchart TD
    A["1. Incoming Attacks Declared (Simultaneous Resolve Step)"] --> B["2. Defender Meets Strength for Each Attack (Hand Defend + Deck Flips)"]
    B --> C["3. Count Impact (I) per Attack = Cards flipped for that attack"]
    C --> D["4. Per-Attack Layered Draw & Optional Pool Merge: Draw tiers of width N; keep pools separate or merge"]
    D --> E["5. Exploit Vulnerabilities (Once per Condition per Pool): Place matching Tier K <= S card on condition -> Draw +1 Tier K+1 card"]
    E --> F["6. Scoop & Curate Pools: Scoop cards off conditions and curate N cards per pool"]
    F --> G["7. Defender Selects 1 Consequence per Pool (or Blank if Candidates < N)"]
```

### Tactile Tracking: Why "Place to Draw, Scoop to Curate" Works

During Step 3, placing the matching Tier $K$ candidate directly onto the defender's active condition card solves two tracking problems with a single physical gesture:

1. **In-Step Tracking (Zero Tokens):** While checking tags and chaining draws in Step 3, any active condition with a card on it is visibly spent for that pool, and the triggering candidate card is out of your hand so it cannot accidentally be used twice to trigger a second condition. Meanwhile, the newly drawn Tier $K+1$ card enters your hand unplaced, so it can immediately be placed onto a second empty active condition (Severity $\ge K+1$) to chain into Tier $K+2$.
2. **Clean Table Handoff in Step 4:** As soon as Step 3 finishes for a pool, the attacker **scoops the placed candidate cards back off the defender's conditions** into their pool to select the final $N$ cards. This gives the pool $+1$ net card per exploited condition (filling blank soak slots when $I < N$ and preserving sharp Tier $K$ cards for curation when $I \ge N$) while leaving the defender's tableau completely clear for Step 5 and for any parallel pools.

---

## 3. Character Tiers & Pool Size Architecture

An entity's **Consequence Pool Size ($N$)** defines the number of consequence slots the attacker must fill to guarantee harm. Pool size is contextual and domain-specific:

- **Armor defines Pool Size against Physical Harm:** Physical armor (gambeson, maille, full plate) increases Pool Size specifically against physical trauma and melee/ranged strikes.
- **Domain Cards & Relevant Standing:** Table cards and traits define pool sizes for non-physical spheres (e.g., a `Silver Tongue` card gives Pool Size 3 for social debate and composure defense).
- **Universal Baseline Fallback ($N = 2$):** For any challenge or situation where an entity does not have a specific armor, skill, or table card in play, their Consequence Pool Size defaults to **2**. Minions have an inherent Pool Size of **1** across all domains.

| Archetype / Armor                           | Pool Size ($N$) |          Soak Threshold (Sev 1)          | Tactical Profile                                                                |
| :------------------------------------------ | :-------------: | :--------------------------------------: | :------------------------------------------------------------------------------ |
| **Minions / Mooks**                         |      **1**      |         Instant Hit ($I \ge 1$)          | No drafting choice; single slot means every point of Impact buys harm directly. |
| **Universal Baseline / Unarmored**          |      **2**      | $I \le 1$ ($2\text{ Impact for Sev } 1$) | Base heroic drafting choice ($2 \times S$); requires active hand defense.       |
| **Light Armor (Gambeson / Boiled Leather)** |  **3 (Phys)**   | $I \le 2$ ($3\text{ Impact for Sev } 1$) | Reliable frontline baseline; soaks stray blows ($3 \times S$).                  |
| **War Armor (Maille Hauberk / Brigandine)** |  **4 (Phys)**   | $I \le 3$ ($4\text{ Impact for Sev } 1$) | Heavy battlefield protection; cushions swarms and power strikes ($4 \times S$). |
| **Full Plate Harness / Giant Monsters**     |  **5 (Phys)**   | $I \le 4$ ($5\text{ Impact for Sev } 1$) | Walking fortress; immune to diffuse hits; requires tag setup or heavy strikes.  |

### Symmetrical Minion Design

Minions have `Consequence Pool Size: 1` printed on their Nature card. When PCs attack a minion and generate 2 Impact, the attacker simply spends 2 Impact to draw 1 Severity 2 card. There is no second slot. The minion takes the card. Because minions have no blank slots to dilute incoming harm, even moderate attacks inflict immediate, unavoidable consequences. When an attack reaches terminal severity or compounded trauma overwhelms them, they drop cleanly. This eliminates GM drafting overhead while making mook-cleaving fast and satisfying.

---

## 4. The Severity Scale & Downward Spiral Mathematics

| Tier  | Category                                | Description & Gameplay Effect                                                                                                                                                                    | Examples / Manifestation                                                                        |
| :---: | :-------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------- |
| **1** | **Tactical Impairments & Setbacks**     | Sparring band: clearable friction (Priority 1–3) to stiff action/movement locks (Priority 4–5). Real table presence; kindling for tag escalation.                                                | `Poor Footing`, `Dust in Eyes`, `Winded`, `Off Balance`, `Afraid`, `Bleeding Cut`               |
| **2** | **Platform Ceilings & Moderate Trauma** | Major tactical disruption, stance loss, concussive fog, cracked ribs, or deep lacerations. Operational divergence (Platform vs Biological vs Suppressive).                                       | `Knocked Prone`, `Mild Concussion`, `Cracked Ribs`, `Deep Laceration`, `Terrified`, `Hamstrung` |
| **3** | **Severe Structural Trauma**            | Structural failure of bodily integrity, bone fractures, arterial bleeding, chest trauma, severe concussion. Orthogonal pillar collapse; zero soft options.                                       | `Broken Arm`, `Severe Concussion`, `Sucking Chest Wound`, `Arterial Hemorrhage`                 |
| **4** | **Taken Out / Incapacitated**           | Incapacitated, unconscious, dying, or completely removed from the conflict. Resolved as **actionable crisis clock / incapacitation** (never instant death; physical cards evaluated separately). | Narrative / Clock: `Unconscious`, `Pinned & Captured`, or `3-Round Mortal Bleedout Clock`       |

### Anti-Alpha Strike & Downward Spiral Mathematics

Under the $\text{Impact} = \text{Pool Size } (N) \times \text{Tier } (S)$ formula:

- **To One-Shot an Unarmored Hero ($N=2$, Tier 4)**: Attackers need $2 \times 4 = \mathbf{8\text{ Impact}}$ (~16–20 unmet Strength undefended). Fresh PCs with defensive cards in hand easily absorb or parry incoming Strength, preventing opening-turn defeats unless caught completely unprepared and undefended.
- **To One-Shot a Combatant in Light Armor ($N=3$, Tier 4)**: Attackers need $3 \times 4 = \mathbf{12\text{ Impact}}$ (~24–30 unmet Strength).
- **To One-Shot a Warrior in War Armor ($N=4$, Tier 4)**: Attackers need $4 \times 4 = \mathbf{16\text{ Impact}}$ (~35–40 unmet Strength).
- **To One-Shot a Knight in Full Plate ($N=5$, Tier 4)**: Attackers need $5 \times 4 = \mathbf{20\text{ Impact}}$ (~45–50 unmet Strength).

Combatants rarely reach Tier 4 via a single massive direct purchase. Instead, combat follows an accelerating, non-linear downward spiral driven by the **Consequence Pyramid** and **Tag Vulnerability Exploitation**:

- **Initial Foothold (Opening Exchanges)**: Attackers test defenses and search for openings. Early hits inflict Tier 1 friction (`Poor Footing`, `Winded`, `Dust in Eyes`, `Off Balance`) or use merged pools to establish active `Vulnerable` tags on the table.
- **Cracking the Armor Shell ($I < N$)**: Against heavily armored combatants ($N=4\text{–}5$), moderate strikes generating $I < N$ would normally leave "No Consequence" blanks. However, matching drawn Tier 1 candidates against the defender's active `Vulnerable` tags adds **+1 net card at Tier 2** per exploited condition while retaining the matching Tier 1 card when scooped in Step 4—consuming blank soak slots and ensuring that even a 3- or 4-Impact strike penetrates a knight's heavy harness once their posture or guard is compromised.
- **Building the Consequence Pyramid (Vertical Escalation)**: When the pool already has enough cards to fill all $N$ slots ($I \ge N$), each bonus Tier $K+1$ card drawn from exploiting an active vulnerability occupies a slot in the curated $N$-card pool, allowing the attacker to curate out soft lower-tier options and eventually saturate all $N$ slots with **Tier 2 platform/biological trauma** (`Knocked Prone`, `Cracked Ribs`, `Mild Concussion`) without requiring impossible single-hit Impact spikes.
- **Defensive Breakdown & Structural Trauma**: Once Tier 2 conditions are active on the table (often carrying broad `Vulnerable` lists like `Knocked Prone` compromising `positioning, limbs, torso, head`), matching Tier 2 draws are promoted directly into **Tier 3 structural trauma** (severe bodily injury like `Broken Arm`, `Sucking Chest Wound`, or `Severe Concussion`).
- **Terminal Resolution**: Matching a Tier 3 draw against an active Tier 3 condition's `Vulnerable` tags draws a **Tier 4 (Taken Out)** candidate.

### The Tapering Funnel & Meaningful Escalation

Dynamic range within consequence decks does not repeat uniformly across tiers; it **progressively narrows** as severity ascends:

1. **Tier 1 (The Sparring Band - Wide Dynamic Range):**
   - _Dynamic Range:_ Spans from clearable friction (Priority 1–3, e.g. `Poor Footing`, `Winded`) to stiff tactical locks (Priority 4–5, e.g. `Off Balance`, `Afraid`, `Strained Offense`).
   - _Opening Maneuvers:_ Tier 1 models early tactical sparring where combatants can react, steady themselves, or clear footing before severe structural harm occurs.
2. **Tier 2 (Operational Divergence - Platform vs. Biological):**
   - _Operational Divergence:_ Cards split between **Platform conditions** (`Knocked Prone`, severe immediate tactical vulnerability with in-combat recovery actions), **Biological trauma** (`Cracked Ribs`, `Mild Concussion`, persistent ongoing taxes that cannot be cured mid-combat), and **Suppressive trauma** (`Deep Laceration`, requiring direct card commitment). There are zero "soft outs."
3. **Tier 3 (Orthogonal Pillar Collapse - Zero Soft Options):**
   - Every Tier 3 card is an existential collapse of one foundational capability:
     - **Offense:** `Broken Arm` (drops weapons, blocks 2-handed weapons/shields, $+2$ Fatigue on Red).
     - **Respiration & Stamina:** `Sucking Chest Wound` (severe thoracic trauma, collapses tidal volume and caps hand size).
     - **Planning & Hand:** `Severe Concussion` (hand size hard-capped at 3, blocks Blue actions).
     - **Life Clock:** `Arterial Hemorrhage` (life-threatening vascular trauma and acute bleedout clock).
   - Drafting is a tragic triage: _"Which pillar of my character can I afford to lose to survive this round?"_
4. **Meaningful Escalation:** Every consequence tangibly alters the tactical situation, restricts options, or ratchets immediate danger rather than absorbing hits as passive padding.

---

## 5. General Actions Adaptation (Non-Crisis Resolution)

General Actions resolve using the exact same core engine and Vigilance mechanics from [core-rules.md](../../rules/core-rules.md):

1. The GM declares the challenge's **Color** and **Strength** (e.g. Blue 10 to pick a complex lock; Yellow 25 to leap a chasm).
2. **Commit Vigilance (Optional):** Per [core-rules.md](../../rules/core-rules.md), the player may resolve the task using deck flips alone, or pick up their **[[Vigilance]]** pool to either play an applicable reactive/mitigation Action Stack (e.g., a skill or tool modifier) or substitute high-value cards from hand directly into the flipped stack (counting as flips toward Impact, then flushing remaining hand cards afterward).
3. **Meet Strength & Count Impact:** The player flips cards (and/or inserts committed Vigilance cards) into their **flipped stack** to meet the Strength. The number of cards in the flipped stack equals the **Impact**.
4. The GM spends the Impact to build a Consequence Pool of the player's domain Pool Size (fallback 2, or modified by relevant skills/tools).
5. The player drafts 1 consequence (or "No Consequence" if an empty slot remains).

### Single-Card Flips and Clean Success ("Saying Yes")

When a player meets the required Strength with a **single card flip** ($\text{Impact} = 1$):

- The GM draws 1 candidate card from the appropriate domain Severity 1 deck.
- Against the baseline Pool Size ($N = 2$), the second slot is an **implicit "No Consequence" blank**.
- The player selects "No Consequence," succeeding cleanly with zero complications beyond the single card expended from their deck.

A single-card flip ($\text{Impact} = 1$) represents routine effort, allowing the player to select the blank slot and succeed without complications. Complications emerge when tasks demand genuine strain or opposition ($\text{Impact} \ge N$).

---

## 6. Multi-Attacker Combat & Swarm Scaling

When multiple attackers target the same defender during Crisis Time, resolution remains completely simultaneous and order-independent through **Per-Attack Draw & Optional Pool Merging**:

1. **Per-Attack Impact & Candidate Draws**:
   - The defender meets each incoming attack's `Strength` individually; the cards flipped for an attack equal that attack's **Impact ($I$)**.
   - Each attacker independently converts their own attack's Impact into candidate cards by filling tiers of width $N$ (the defender's Pool Size) from the bottom up. Because individual minion hits usually generate $I \le N$, each minion natively draws **Tier 1** cards from its own consequence deck without cross-deck ordering issues.
2. **Simultaneous Vulnerability Exploitation ("Place to Draw, Scoop to Curate")**:
   - After attackers decide whether to keep their drawn candidate pools separate or merge them, each Consequence Pool may exploit active conditions that were on the defender **at the start of the round** (at most 1 placed candidate per active condition **per pool**) to draw $+1$ candidate from Tier $K+1$.
   - Because placed candidates are scooped back into their pool at the start of Step 4, separate pools resolving in parallel never collide physically on the defender's tableau or compete over the defender's active conditions.
   - Consequences inflicted during the round enter play simultaneously at the end of the round, preventing same-round chain-promotion kills.
3. **Separate vs. Merged Pools (Tactical Choice)**:
   - **Separate Pools vs. Low-$N$ Targets:** Against an unarmored skirmisher ($N=2$), four goblins generating 2 Impact each draw 2 Tier 1 cards apiece. Because each goblin already fills an $N=2$ pool (`[Sev 1, Sev 1]`), they keep their 4 pools separate—forcing the skirmisher to suffer **4 Tier 1 consequences simultaneously** (burying them in tactical friction and exposing `Vulnerable` tags for Round 2 without one-shotting them on Round 1).
   - **Merged Pools vs. Heavy Armor ($N=4\text{–}5$):** Against a knight in Full Plate ($N=5$), three goblins generating `1, 2, 2` Impact would each leave "No Consequence" blanks on their own. By **merging their drawn candidate cards into a single shared pool**, their 5 Tier 1 cards fill all 5 slots (`[Sev 1 x 5]`, zero blanks), forcing the knight to suffer **1 Tier 1 consequence**.
4. **Deck Attrition as Mob Danger**: Beyond condition drafting, defending against a swarm forces multiple flips in rapid succession, draining the defender's 24-card deck and accelerating Fatigue Cycles toward Defensive Collapse.

---

## 7. Evaluation Against Design Precepts

| Design Precept                   | Alignment in Proposed System                                                                                                                                                                     |
| :------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Default to Success at a Cost** | **Perfect alignment**. Tasks and attacks land; resolution determines the exact tactical cost chosen by the defender.                                                                             |
| **Mechanical Elegance**          | **High**. Removes two abstract character sheet stats (`Defense` and `Resilience`). Replaces division math with physical card drafting.                                                           |
| **Ludonarrative Harmony**        | **Contextual & Thematic**. Wounds compound contextually via tags rather than through an arbitrary global counter. Armored fighters absorb diffuse blows; targeted tags cause realistic collapse. |
| **Player Agency**                | **Very High**. Both attacker (allocating impact and hunting tag synergies) and defender (choosing the manageable penalty) make active, high-stakes decisions every turn.                         |

---

## 8. Suggested Next Steps for Promotion

1. **Core Rules Integration**:
   - Promote [proposal.md](proposal.md) into `design/rules/core-rules.md` (updating `## 2. Facing a Challenge`, `### Defend Actions`, and `### General Actions`).
   - Apply [players-guide-patch.md](players-guide-patch.md) and [gamemaster-guide-patch.md](gamemaster-guide-patch.md) to `design/rules/players-guide.md` and `design/rules/gamemaster-guide.md`.
2. **Consequence & Equipment YAML Schema Upgrade**:
   - Update [consequences.yaml](consequences.yaml) and `data/cards/consequences/*.yaml` to use `vulnerable: [Tags]` and `priority:` ratings per [guide-to-writing-consequences.md](guide-to-writing-consequences.md).
   - Audit [equipment.yaml](equipment.yaml), `data/cards/pc/*.yaml`, and `data/cards/monsters/*.yaml` to align armor Pool Size ($N$) with the new engine.
3. **Expanding Domain Consequence Decks**:
   - Author specialized domain consequence decks for _Exploration & Environmental Trauma_, _Social & Relational Fallout_, and _Arcane & Alchemical Backdrafts_.
