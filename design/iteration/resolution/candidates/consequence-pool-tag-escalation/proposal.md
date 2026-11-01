# Proposed New Action Resolution Mechanic

Update to `design/rules/core-rules.md` (replaces Step 3 of `## 2. Facing a Challenge` and updates `### Defend Actions` and `### General Actions`).

---

## Action Resolution

When an attack or obstacle targets you, resolve in five steps:

1. **Determine Impact:** Meet the incoming `Strength` with Defend cards from hand and/or flipping cards from the top of your deck into a flipped stack. For each incoming attack, the attack's **Impact ($I$)** equals the number of cards in its flipped stack.
2. **Draw Candidates (Per Attack):** Your **Consequence Pool Size ($N$)** is 2, unless modified by table cards. Each attacker draws candidate consequence cards based on their attack's individual Impact (`1 Impact = 1 card drawn`), filling tiers of width $N$ from Severity 1 upward:
   - The first $N$ Impact of an attack draws cards from the **Severity 1** deck.
   - Additional Impact draws from higher severity decks only if that _individual attack's Impact_ exceeds $N$: cards from $N+1$ to $2N$ draw from **Severity 2**; cards from $2N+1$ to $3N$ draw from **Severity 3**; cards beyond $3N$ draw from **Severity 4**.
   - _Severity is determined strictly per attack, never by combining Impact across attacks._
3. **Form Pools (Separate or Merged):** Attackers targeting the same defender in the same round choose whether to keep their candidate pools separate or merge them:
   - **The Pool Threshold ($N$):** A Consequence Pool must contain **at least $N$ candidate cards** to be presented to the defender. If an attack has fewer than $N$ candidates ($I < N$) and is not merged, it fails to penetrate armor or poise—no consequences are suffered (an isolated attacker generating $I < N$ does not need to draw cards).
   - **Merging Candidate Pools:** Multiple attackers targeting the same defender may **merge their drawn candidate cards** into a shared pool. This allows multiple sub-threshold attacks to combine their Tier 1 cards to reach $N$, or combines surplus candidates for curation. Merging pools combines drawn cards—it **never increases the severity tier** of the cards drawn.
4. **Exploit Active Vulnerabilities:** If the defender has active conditions from earlier rounds matching a candidate card's tags:
   - Place a matching candidate of Severity $K \le S$ onto an active Severity $S$ condition to draw **+1 additional candidate from the Severity $K+1$ deck** into the pool (at most once per active condition per pool).
5. **Curate and Suffer:**
   - **Curate $N$ Cards ("I Cut"):** Scoop any candidates placed on active conditions back into the pool. The attacker(s) choose **exactly $N$ cards** from all candidates in that pool to present to the defender. Surplus candidates return to their decks.
   - **Suffer 1 Consequence ("You Choose"):** The defender selects and suffers **exactly 1 consequence** from each presented $N$-card pool. All consequences enter play simultaneously at the end of the round. (Discard any condition superseded by the chosen card as stated on its rules text).

---

### Defend Actions (Updated)

When targeted by an attack during Crisis Time, you face the strike by meeting its Strength:

1. **Defend from Hand (Optional):** Play an applicable Defend Action Stack from hand (paying printed Cost). The card's rules text modifies the defense or adds Strength.
2. **Flip from Deck:** If Strength is not yet met, flip cards from your deck one by one into a flipped stack until cumulative Color value meets or exceeds the attack's Strength.
3. **Count Impact:** The number of cards in your flipped stack is the attack's Impact.
4. **Resolve Consequences:** Resolve the attack's Impact against your Consequence Pool Size ($N$) using the 5-step Action Resolution above.

---

### General Actions (Updated)

Outside Crisis Time, tasks with meaningful stakes resolve as General Actions:

1. The GM declares the challenge's Color and Strength.
2. **Commit Vigilance (Optional):** You may resolve using deck flips alone or pick up your Vigilance pool to play a relevant Action Stack or substitute high-value cards from hand into the flipped stack.
3. **Meet Strength & Count Impact:** Flip cards from your deck to meet the Strength. The count of cards flipped is your Impact.
4. **Resolve Consequences:** If your Impact is less than your domain Pool Size ($N=2$ baseline), you succeed cleanly with zero complications (**0 cards drawn**). If Impact reaches or exceeds $N$, the GM draws and curates an $N$-card pool from the appropriate domain consequence deck; you select and suffer 1 consequence.
5. **Flush:** If you picked up your Vigilance pool, discard remaining hand cards and flush back to your chosen Vigilance level.
