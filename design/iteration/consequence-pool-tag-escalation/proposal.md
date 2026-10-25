# Proposed New Action Resolution Mechanic

Update to `design/rules/core-rules.md`. Replaces `## Defend Actions`.

## Action Resolution (Crisis Time)

1. **Determine Impact**: The defender meets incoming attack Strength and tallies total cards flipped against all incoming attacks this round.
2. **Draw Candidate Consequences (Layered Fill)**: Each point of Impact draws 1 candidate card, filling tiers of width $N$ (the defender's Pool Size) from Severity 1 upward.
3. **Attacker Curates the Consequence Pool**: Attackers choose any $N$ cards from all candidates drawn to present to the defender.
4. **Defender Suffers a Consequence**: The defender selects and suffers exactly 1 consequence from the curated pool (or a "No Consequence" blank if total Impact $< N$).

---

### 1. Determine Impact

You must meet the `Strength` of each incoming attack declared against you:

1. **Reactive "Defend" Actions (Optional)**: You may play a **Defend** card from your hand as an [[Action Stack]] (along with additional cards from hand equal to its printed [[Cost]]). The card's printed rules text defines how it modifies the resolution (commonly adding the stack's Strength without generating Impact, allowing cross-color defense, or granting conditional avoidance).
2. **Deck Flips**: If the attack's Strength is not yet met, flip cards one by one from the top of your deck into a **flipped stack** until the cumulative value in the attack's Color meets or exceeds the attack's Strength.
3. **Accumulate Impact**: The `Impact` of a defense is the number of cards in your **flipped stack** for that attack. If multiple attacks targeted you this round, sum their Impact into a single **Total Impact ($I$)**.

---

### 2. Draw Candidate Consequences (Layered Pool Fill)

Total Impact ($I$) generated against the defender is converted into candidate cards: **1 Impact = 1 card drawn**.

Candidates are drawn from the severity decks by filling tiers of width $N$ (the defender's Pool Size) from the bottom up:

1. **Tier 1 (Severity 1)**: The first $N$ Impact draws up to $N$ cards from the **Severity 1** deck.
   - If total Impact is less than $N$, remaining unfilled slots are implicit **"No Consequence" blanks** (clean armor soak).
2. **Tier 2 (Severity 2)**: Once Tier 1 has $N$ cards, each additional point of Impact (from $N+1$ to $2N$) draws 1 card from the **Severity 2** deck.
3. **Tier 3 (Severity 3)**: Once Tier 2 has $N$ cards, each additional point of Impact (from $2N+1$ to $3N$) draws 1 card from the **Severity 3** deck.
4. **Tier 4 (Taken Out)**: Once Tier 3 has $N$ cards, each additional point of Impact (from $3N+1$ to $4N$) allocates one **Severity 4 (Taken Out)** candidate.

> **Table Shortcut (Buried Tiers):** When total Impact is $\ge 2N$, attackers may skip drawing from fully saturated lower tiers unless actively fishing for lower-tier tag escalations.

---

### 3. Curate the Consequence Pool (The "I Cut" Step)

The defender's traits, table cards, and equipped gear define their **Consequence Pool Size ($N$)**:

- **Armor defines Pool Size for Physical Harm:** Equipped armor cards specify pool size against physical trauma (e.g., 3 for light armor/padded gambeson, 4 for war armor/maille, 5 for full plate harness).
- **Domain Cards & Traits:** Non-physical domains derive pool sizes from applicable training or table cards (e.g., _Silver Tongue_ provides Pool Size 3 for social debate; _Iron Will_ provides Pool Size 3 for mental composure).
- **Universal Baseline Fallback ($N = 2$):** For any challenge or domain without specialized gear or traits, Pool Size defaults to **2**. (Minions have an inherent Pool Size of **1** across all domains).

#### Curating the $N$ Slots

From all candidates drawn across all active tiers, the attackers **choose any $N$ cards** to form the final Consequence Pool. All unchosen candidate cards return to their respective decks.

- **Targeting Active Vulnerabilities:** Attackers inspect the active conditions in front of the defender. Any candidate card whose tag matches an active condition's `escalate:` trigger takes top priority.
- **The Bottleneck Slot:** When a higher tier is partially filled (e.g. $N=3$ with 5 Impact: two Sev 2s and three Sev 1s), attackers use their surplus lower-tier draws to place the sharpest or tag-escalating card into the remaining slot that the defender will seek to pick.
- **Implicit Blanks:** If total Impact was less than $N$, unfilled slots are presented as "No Consequence" blanks.
- **Guaranteed Severity Thresholds:** Inflicting a guaranteed consequence of Tier $S$ requires $\mathbf{S \times N}$ Total Impact (filling all $N$ slots with cards of that tier or higher).

---

### 4. Defender Suffers Exactly 1 Consequence (The "You Choose" Step)

1. The curated pool of $N$ cards (along with any "No Consequence" blanks) is presented to the defender.
2. The defender **chooses exactly 1 option** from the pool to suffer.
3. If "No Consequence" is in the pool, the defender may select it to suffer no additional harm beyond the stamina/fatigue cards already flipped from their deck.
4. **Applying the Consequence & Table Escalation:**
   - **Novel Condition:** If the defender has no active condition with an `escalate:` trigger matching the chosen card's leaf tags, place the card into play in front of the defender as a new active condition.
   - **Condition Escalation & Card Fallbacks:** If an active condition in play in front of the defender has an `escalate:` trigger matching the chosen card's leaf tag, follow the explicit instructions printed on the active card (upgrading to the indicated condition, entering play as an independent parallel condition, applying a setback to current mitigation progress, or resolving a kinetic overmatch wildcard if the track is already at its ceiling). When an upgrade occurs, discard the lower active condition and put the upgraded condition into play.
   - **Tier 4 (Taken Out / Crisis Clock):** If the defender selects a Severity 4 consequence or an active Tier 3 condition escalates to Tier 4, the character is functionally out of the fight (never instant death). The attacker or narrative context defines an actionable exit state or rescue clock (e.g., knocked `Unconscious`, `Pinned & Captured`, or placed on an emergency `3-Round Mortal Bleedout Clock` if escalating from an arterial bleed). No card is drawn from a physical deck.
5. All unchosen cards in the pool are returned to their respective decks.

---

### 5. General Actions & Clean Success ("Saying Yes")

General Actions (non-combat tasks and exploration challenges) resolve using the exact same consequence engine and Vigilance rules from `core-rules.md`:

1. **Commit Vigilance & Meet Strength:** The player flips cards from their deck into a **flipped stack** to meet the challenge's declared Strength (optionally picking up their **[[Vigilance]]** pool first to play an applicable Action Stack modifier or insert high-value cards from hand directly into the flipped stack, then flushing remaining hand cards). The number of cards in the flipped stack equals the **Impact**.
2. **Curate the Pool:** The GM applies Layered Fill using that Impact to draw candidate consequences from the appropriate domain deck, curating a pool of $N$ cards (defaulting to 2 unless a domain-specific skill, tool, or table card applies).
3. **Draft the Outcome:** The player selects exactly 1 consequence (or "No Consequence" if an empty slot remains).

#### Single-Card Flips and Clean Success ("Saying Yes")

When a task is sufficiently easy or the player's flip meets the required Strength on the **first card flipped** ($\text{Impact} = 1$):

- The GM spends 1 Impact to draw one Tier 1 candidate card.
- Against the character's baseline Pool Size ($N = 2$), the second slot is an **implicit "No Consequence" blank**.
- The player selects "No Consequence," suffering zero complications beyond the single card expended from their deck.

**Design Philosophy & GM Guidance:**
This clean success is completely intentional. The design intent of "Success at a Cost" is that the system introduces complications rather than having the rules say "No"—but the rules are fully allowed to say "Yes." Resolving a check with a single card flip represents a character expending a tiny, routine amount of energy to succeed fully without collateral friction. In fact, if an attempt resolves cleanly in a single flip, it was borderline whether the GM even needed to call for a mechanical check at all rather than simply saying "yup" and moving the narrative forward. Complications are reserved for tasks that demand genuine strain or opposition ($\text{Impact} \ge N$).

---

### Severity Reference

| Tier  | Category                                | Description & Gameplay Effect                                                                                                                                        | Examples / Manifestation                                                                           |
| :---: | :-------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------- |
| **1** | **Tactical Impairments & Setbacks**     | Sparring band: clearable footing/sensory slips (Priority 1–3) to stiff action/movement/armor locks (Priority 4–5). Real table presence; kindling for tag escalation. | `Poor Footing`, `Dust in Eyes`, `Winded`, `Off Balance`, `Afraid`, `Rattled Guard`, `Bleeding Cut` |
| **2** | **Platform Ceilings & Moderate Trauma** | Major tactical disruption, complete stance loss, concussive fog, cracked ribs, or deep lacerations. Operational divergence (Platform vs Biological vs Suppressive).  | `Knocked Prone`, `Mild Concussion`, `Cracked Ribs`, `Deep Laceration`, `Terrified`, `Hamstrung`    |
| **3** | **Severe Structural Trauma**            | Structural failure of defense, bone fractures, arterial bleeding, sundered plate, severe clinical emergencies. Orthogonal pillar collapse; zero soft options.        | `Broken Arm`, `Severe Concussion`, `Sundered Armor`, `Arterial Hemorrhage`                         |
| **4** | **Taken Out / Incapacitated**           | Incapacitated, unconscious, dying, or completely removed from the conflict. Resolved as **actionable crisis clock / incapacitation** (never instant death).          | Narrative / Clock: `Unconscious`, `Pinned & Captured`, or `3-Round Mortal Bleedout Clock`          |
