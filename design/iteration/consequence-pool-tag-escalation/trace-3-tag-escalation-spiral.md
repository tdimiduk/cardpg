# Play Trace 3: Tag Escalation & The Downward Spiral

## Context & Combatants

- **Setting**: Muddy alleyway skirmish following an earlier brawl.
- **Attacker**: Cutthroat Duelist (Agile Yellow/Red build, exploiting defender's compromised state).
- **Defender**: Veteran Mercenary (Pool Size: **2**, armor already damaged/compromised).

### Existing Table State on Defender

The defender has already sustained two minor setbacks in earlier rounds:

1. `Poor Footing` (Severity 1, Tags: `positioning`, `physical`)
   - _Passive_: Impact of your defenses is increased by 1.
   - _Action_: Regain Footing (Place a card from your hand on top of this. When 2 cards are on top of this, expend them and remove this).
   - _Task_: Catch Balance (Time 1 min) -> Remove this.
   - _Escalation Clause_: **If you draw a `positioning` consequence, return it and draw a consequence of Severity + 2.**
2. `Afraid` (Severity 2, Tags: `fear`, `mental`)
   - _Passive_: You must expend 1 card from hand to make a melee attack or willingly move closer to a foe.
   - _Action_: Martial Fury Surge (Spend {Red} 25) -> Remove this.
   - _Task_: Center Yourself (Check {Blue} 15; Time 5 min) -> Remove this.
   - _Escalation Clause_: **If you draw a `fear` consequence, replace this with `Terrified` (Severity 3).**

---

## Round Sequence

### 1. Plan Step

- Attacker declares `Hamstringing Slice`:
  - Attack: {Yellow} Str = {Yellow} + 1; Cost: 1; Stats: {Yellow: 3, Red: 2}
  - Stack: Top card ({Yellow: 3}) + 1 Resource ({Yellow: 2}) + 1 modifier = **6 Yellow**.

### 2. Defense Step & Impact Calculation

- Defender has no defense cards remaining in hand.
- Defender flips cards from deck to meet 6 Yellow:
  - Flip 1: {Yellow: 2} -> 2
  - Flip 2: {Yellow: 2} -> 4
  - Flip 3: {Yellow: 3} -> 7 (Met: 7 >= 6).
- **Base Flipped Cards**: 3 flips.
- **Passive Trigger from `Poor Footing`**: "Impact of your defenses is increased by 1."
- **Total Round `Impact`**: $3 + 1 = \mathbf{4\text{ Impact}}$.

---

### 3. Draw Candidate Consequences & Resolve Escalations

- **Defender Consequence Pool Size ($N$)**: **2**.
- **Attacker Budget**: **4 Impact**.

#### Candidate Draws & Escalation Triggers

The attacker decides to spend 4 Impact across a mix of candidate draws:

1. **Candidate Draw 1 (Spend 1 Impact | 3 remaining)**:
   - Attacker draws from the **Severity 1** deck: `Near Miss` (Severity 1, Tags: `combat`, `positioning`).
   - Added to candidate hand: `[Near Miss (Sev 1)]`.

2. **Candidate Draw 2 (Spend 1 Impact | 2 remaining)**:
   - Attacker draws from the **Severity 1** deck: `Near Miss` (Severity 1).
   - **In-Hand Escalation**: `Near Miss` already in candidate hand triggers: _"If another Near Miss is drawn, return it and draw a Severity 2 consequence."_
   - Drawn `Near Miss` is returned; attacker draws from **Severity 2** deck $\to$ draws `Afraid` (Severity 2, Tags: `fear`, `mental`).
   - **Table Escalation**: Defender already has `Afraid` (Severity 2) on the table!
   - Table `Afraid` triggers: _"If a fear consequence is drawn, replace this with Terrified (Severity 3)."_
   - Table `Afraid` is turned sideways (90°). Drawn `Afraid` is returned; attacker draws from **Severity 3** deck $\to$ draws **`Terrified`** (Severity 3, Tags: `fear`, `mental`).
   - Added to candidate hand: `[Near Miss (Sev 1), Terrified (Sev 3)]`.

3. **Candidate Draw 3 (Spend 2 Impact | 0 remaining)**:
   - Attacker spends remaining 2 Impact to draw from the **Severity 2** deck: `Off Balance` (Severity 2, Tags: `positioning`, `combat`).
   - **Table Escalation**: Defender's table condition `Poor Footing` (Severity 1, `positioning`) has: _"If a positioning consequence is drawn, return it and draw a consequence of Severity + 2."_
   - `Poor Footing` is turned sideways (90°). Drawn `Off Balance` is returned; attacker draws from **Severity 4** deck $\to$ draws **`Dislocated Knee`** (Severity 4, Tags: `physical`, `legs`, `injury`, `positioning`).
   - Added to candidate hand: `[Near Miss (Sev 1), Terrified (Sev 3), Dislocated Knee (Sev 4)]`.

---

### 4. Attacker Curates the Final Pool (The "I Cut" Step)

The defender's Pool Size is **2**. The attacker holds 3 candidate cards:

- `Near Miss` (Severity 1)
- `Terrified` (Severity 3)
- `Dislocated Knee` (Severity 4)

The attacker curates the final pool by selecting the 2 most devastating options:

- **Selected for Pool**: **`Terrified` (Severity 3)** and **`Dislocated Knee` (Severity 4)**.
- **Returned to Deck**: `Near Miss` (Severity 1).

---

### 5. Defender Suffers Exactly 1 Consequence (The "You Choose" Step)

- **Pool Presented to Defender**:
  1. `Terrified` (Severity 3 — Fear hand card tax)
  2. `Dislocated Knee` (Severity 4 — Prone, non-ambulatory, +2 defense Impact penalty)

- **Defender's Dilemma**:
  - The attacker generated 4 Impact. By leveraging in-hand duplicate escalation and existing table conditions, the attacker generated 3 candidates, discarded the low-tier `Near Miss`, and curated a lethal `{Sev 3, Sev 4}` choice.
- **Defender's Choice**:
  - Defender chooses **`Terrified`** (Severity 3), keeping legs intact while accepting the psychological panic constraint.

---

## Key Insights from Trace 3

1. **Tag Escalation Replaces Global Resilience with Thematic Vulnerability**:
   - In the legacy system, accumulating any 3 consequences pushed the character to the next global tier.
   - In this proposed system, escalation is **contextual and tag-driven**. If an enemy targets a tag where the defender is already compromised (like `positioning`), the severity spikes dynamically without needing a global resilience stat.
2. **Attacker Agency & Tactical Targeting**:
   - The attacker explicitly benefits from understanding the defender's current conditions. By drawing into categories that match the defender's vulnerabilities, low-impact strikes can cascade into high-severity injuries.
3. **Physical Tracking at the Table**:
   - Turning used consequence cards sideways ("tap to mark escalation used") is a clean, physical bookkeeping method that avoids complex token tracking.
