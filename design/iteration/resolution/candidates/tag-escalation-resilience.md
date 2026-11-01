---
title: "Candidate Proposal: Tag Escalation Replacing Resilience"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Candidate Proposal: Tag Escalation Replacing Resilience

## Document Purpose

This proposal isolates and explores a single core architectural change: **replacing the global `Resilience` march with localized `Tag Escalation`**, without adopting the full Consequence Pool or "I Cut, You Choose" drafting market.

It tests whether caRdPG's primary harm progression goals (eliminating Unified Doom, modeling localized anatomical trauma, and maintaining decisive pacing) can be achieved within a lightweight resolution loop that retains the speed and simplicity of canon `Defense`.

---

## 1. The Core Problem with Canon `Resilience`

In canon `core-rules.md`, resolution works as follows:

1. Flipped cards equal `Impact` ($I$).
2. Impact is divided by `Defense` ($D$); each full group inflicts **1 Consequence**.
3. Consequences are arranged on the table in rows of width `Resilience` ($R$). When the first row fills, subsequent consequences escalate to Severity 2; when the second row fills, they escalate to Severity 3 (incapacitation).

### The Fatal Flaw: Unified Doom / Harm Bleed

Because `Resilience` is an abstract global counter across all domains:

- If a hero suffers 2 minor social complications (`Slighted Honor`, `Social Faux Pas`) and 1 exploration setback (`Chilled`), their Severity 1 row of width $R=3$ is completely full.
- The next physical attack in an alleyway—even a minor dagger scrape—**instantly inflicts a Severity 2 moderate bodily trauma** (`Cracked Ribs` or `Knocked Prone`).
- Even within combat, an attack to the left foot pushes a subsequent blow to the head into severe concussion territory.

This violates **Ludonarrative Harmony** and creates degenerate cross-pillar bleed.

---

## 2. The Tag Escalation Proposal

### 2.1. The Rules Patch

Replace Step 3 of `## 2. Facing a Challenge` in `design/rules/core-rules.md` with:

```markdown
### 3. Suffer Consequences (Tag Escalation)

1. **Calculate Consequences:** Divide your Impact by your domain-applicable **Defense** rating ($\lfloor \text{Impact} / \text{Defense} \rfloor$). You suffer 1 Consequence for each completed group. Leftover cards that do not complete a group cause no harm and are discarded.
2. **Determine Severity via Matching Tags:**
   - When a consequence is inflicted, check the incoming attack or obstacle's tags against the **active conditions** currently in front of you.
   - **If No Match (Parallel Condition):** Draw from the **Severity 1** deck of the appropriate domain. The condition enters play in front of you at Tier 1.
   - **If a Matching Tag is Found (Escalation):** The attack exploits an existing opening. You do not place a new Tier 1 condition; instead, the active condition sharing that tag **escalates to the next Severity tier**:
     - _Card Upgrade:_ Discard the lower-tier condition and draw from the matching **Severity $K+1$** deck (or advance its pip marker if using consolidated tiered cards).
3. **Terminal Climax:** When any active condition reaches terminal severity (Severity 4, or Severity 3 depending on ladder depth), or when you accumulate two active Tier 3 conditions, you are Taken Out (following the defeat or crisis clock rules on the terminal card).
```

---

## 3. How Tag Escalation Operates in Play

### 3.1. Anatomical & Domain Decoupling (Zero Harm Bleed)

Every consequence card and attack carries specific **Leaf Tags**:

- Physical: `[head]`, `[torso]`, `[limbs]`, `[positioning]`, `[bleeding]`, `[exertion]`.
- Non-Combat: `[social, composure]`, `[social, reputation]`, `[environmental, cold]`, `[arcane, resonance]`.

When harm lands:

- If a diplomat has `Slighted Honor` (`[social, reputation]`) and is later ambushed by thugs, a sword strike (`[physical, limbs]`) shares **no tags** with their social condition.
- The physical hit lands at **Severity 1** (`Bleeding Cut` or `Poor Footing`), completely unaffected by the social setback.
- Harm bleeds across domains only when biologically or narratively honest (e.g., a condition with `[exertion]` affecting a physical chase).

### 3.2. Localized Downward Spiral

Instead of an abstract health bar, combat creates focused anatomical crises:

- **Round 1:** An enemy strikes your guard, landing 1 consequence. It has tag `positioning`. You gain `Poor Footing` (Tier 1).
- **Round 2:** Another attack with `positioning` lands. Because `positioning` matches your active condition, it **escalates**: `Poor Footing` is replaced by `Knocked Prone` (Tier 2).
- **Round 3:** An enemy strikes while you are prone. If the attack targets your compromised position, it escalates to Tier 3 (`Sundered Armor`). If an enemy instead targets your arm (`limbs`), it opens a _parallel_ Tier 1 condition (`Bruised Forearm`), preserving anatomical realism.

---

## 4. Architectural Comparison: Tag Escalation vs. Consequence Pool

| Dimension                        | Consequence Pool & Tag Escalation                                    | Tag Escalation Replacing Resilience                                     |
| :------------------------------- | :------------------------------------------------------------------- | :---------------------------------------------------------------------- |
| **Armor / Soak Model**           | Consequence Pool Size ($N$). Soak is $I < N \implies$ 0 cards drawn. | Canon `Defense` divisor ($\lfloor I / D \rfloor$). Remainder discarded. |
| **Card Draw Volume**             | **High** ($1\text{ card per Impact}$, 4–8 cards per exchange).       | **Minimal** (Exactly 1 card drawn per consequence inflicted).           |
| **Tablefootprint & Reshuffling** | Heavy multi-deck churn; frequent reshuffling.                        | Very low deck churn; 1 card stays on table.                             |
| **Defender Agency**              | **High post-flip selection** ("You Choose" from $N$ cards).          | **Pre-flip only** (Reactive Defend Action Stacks from hand).            |
| **Attacker Curation**            | **High** ("I Cut" curates sharpest cards into bottlenecks).          | **Low** (Attacker relies on weapon/attack tags to trigger escalations). |
| **Harm Bleed (Unified Doom)**    | **Solved** (decoupled via tags).                                     | **Solved** (decoupled via tags).                                        |
| **Core Rules Complexity**        | ~1 page (threshold, pool fill, tag matching, curate, suffer).        | **~1 paragraph** (replace Resilience row with tag matching).            |
| **Pacing & Speed**               | Moderate (2 decision points per exchange).                           | **Fast** (Quickly scan for matching consequences and escalate).         |

---

## 5. Critical Analysis & Open Questions

### 5.1. Where Tag Escalation Succeeds

1. **Extreme Procedural Elegance:** It requires almost zero new rules. Players already know how to check tags on cards. It eliminates the 2D "Resilience grid" from character sheets entirely.
2. **Respects the 10x Rule:** The core rule is two sentences. The nuance of what escalates lives naturally on attack cards and condition cards.
3. **Scale Invariance Preserved:** Because it uses canon `Defense` and card flip ratios, it functions identically across single digits and army-level hundreds.

### 5.2. Potential Failure Modes & Design Questions

1. **Tag Dilution / Match Probability:**
   - _Risk:_ If there are too many fine-grained leaf tags (e.g. 15 different tags), consecutive attacks might rarely match, causing combatants to accumulate 4–5 parallel Tier 1 conditions without ever escalating to Tier 2.
   - _Solution:_ Keep the leaf tag taxonomy compact (5–7 combat leaf tags: `head`, `torso`, `limbs`, `positioning`, `bleeding`, `exertion`), and ensure broad platform conditions like `Knocked Prone` list multiple vulnerable tags (e.g., `Vulnerable: [positioning, limbs, torso]`).
2. **Loss of Incremental Impact Leverage:**
   - Without the Consequence Pool, an attack that generates `Impact 7` against `Defense 4` yields $\lfloor 7/4 \rfloor = 1\text{ Consequence}$. The extra 3 points of Impact are discarded.
   - _Next Step:_ Can we combine this lightweight Tag Escalation engine with one of the lightweight incremental impact models (see [incremental-impact-mechanics.md](../incremental-impact-mechanics.md))?
