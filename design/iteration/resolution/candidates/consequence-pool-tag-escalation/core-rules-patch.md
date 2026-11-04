# Core Rules Patch: Action Resolution Engine

Patch for `design/rules/core-rules.md` (replaces Step 3 of `## 2. Facing a Challenge`, updates `### Defend Actions`, `### General Actions`, and `### Keywords and Timing`, and adds `## Appendix: Multiple Attackers and Merged Pools`), integrating the **Consequence Pool & Tag Escalation Engine**.

---

## Action Resolution

When an attack or obstacle targets you, resolve in four steps:

1. **Determine Impact:** Meet incoming Strength with Defend cards from hand and/or deck flips into a flipped stack. The count of cards in your flipped stack is the attack's **Impact**.
2. **Draw Candidates:** Draw 1 candidate consequence card per point of Impact. Cards fill Tier 1 first. Each tier holds cards equal to the defender's **Pool Size** (baseline 2, modified by armor); once a tier is filled, additional cards are drawn from the next severity tier (Tier 2, then Tier 3, then Tier 4).
   - _Pool Clauses:_ If the defender has active cards with `[[POOL]]` clauses on their tableau (such as `[[Vulnerable]]`), the attacker may exploit them to enhance candidate draws (see [Keywords and Timing](#keywords-and-timing)).
3. **Curate Pool:** The attacker forms a **Consequence Pool** equal to the defender's Pool Size from the drawn candidates:
   - **Underfilled:** If total candidates are fewer than the Pool Size, you cannot form a pool—the blow is absorbed with no effect.
   - **Surplus:** If total candidates exceed the Pool Size, the attacker chooses which cards to present in the pool and returns the rest to their decks.
4. **Suffer Consequence:** The defender selects and suffers **exactly 1 consequence** from the curated pool.

_(When multiple attackers target the same defender in a single round, see [Appendix: Multiple Attackers and Merged Pools](#appendix-multiple-attackers-and-merged-pools))._

---

### Defend Actions

When targeted by an attack during Crisis Time, you face the strike by meeting its Strength:

1. **Defend from Hand (Optional):** Play an applicable Defend Action Stack from hand (paying printed Cost). The card's rules text modifies the defense or adds Strength.
2. **Flip from Deck:** If Strength is not yet met, flip cards from your deck one by one into a flipped stack until cumulative Color value meets or exceeds the attack's Strength.
3. **Count Impact:** The number of cards in your flipped stack is the attack's Impact.
4. **Resolve Consequences:** Resolve the attack's Impact against your Consequence Pool Size using the 4-step Action Resolution above.

---

### General Actions

Outside Crisis Time, tasks with meaningful stakes resolve as General Actions:

1. The GM declares the challenge's Color and Strength.
2. **Commit Vigilance (Optional):** You may resolve using deck flips alone or pick up your Vigilance pool to play a relevant Action Stack or substitute high-value cards from hand into the flipped stack.
3. **Meet Strength & Count Impact:** Flip cards from your deck to meet the Strength. The count of cards flipped is your Impact.
4. **Resolve Consequences:** If your Impact fills your domain Pool Size (baseline 2), the GM draws candidates and curates a Consequence Pool from the appropriate domain consequence deck; you select and suffer 1 consequence. If your Impact is below your Pool Size, you succeed cleanly with zero complications.
5. **Flush:** If you picked up your Vigilance pool, discard remaining hand cards and flush back to your chosen Vigilance level.

---

### Keywords and Timing

Add

- **`POOL:` (Card Block):** A dedicated area on consequence cards, weapons, or attack actions that specifies rules modifying candidate card draws during Step 2 of Action Resolution.

---

## Appendix: Multiple Attackers and Merged Pools

When multiple attackers strike the same target in the same round during Crisis Time, each attack is faced individually, but attackers may coordinate how their consequences are formed:

1. **Draw Candidates Per Attack:** Each attacker determines Impact and draws candidates strictly based on their individual attack's Impact. Severity tiers are determined per attack, never by combining Impact: an individual attack must fill Tier 1 on its own to draw Severity 2+ cards.
2. **Form Pools (Separate or Merged):** Attackers targeting the same defender choose whether to keep their candidate pools separate or merge them:
   - **Separate Pools:** Each attack with candidates equal to or exceeding the Pool Size may form its own pool, forcing the defender to curate and suffer multiple separate consequences.
   - **Merged Pools:** Multiple attackers may merge their drawn candidates into a shared pool. This allows multiple sub-threshold attacks to combine their Tier 1 candidates to fill the Pool Size, or combines surplus candidates for sharper curation. Merging pools combines drawn cards—it **never increases the severity tier** of the cards drawn.
3. **Curate and Suffer:** For each presented pool, the attacking side curates cards equal to the defender's Pool Size, and the defender selects and suffers exactly 1 consequence. All suffered consequences enter play simultaneously at the end of the round.
