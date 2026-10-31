# Proposed New Action Resolution Mechanic

Update to `design/rules/core-rules.md`. Replaces `## Defend Actions`.

## Action Resolution

1. **Determine Impact**: The defender meets incoming attack Strength; total cards flipped from the deck equal Total Impact ($I$).
2. **Draw Candidates (Layered Fill)**: Each point of Impact draws 1 candidate card, filling tiers of width $N$ (the defender's Pool Size) from Severity 1 upward.
3. **Promote Vulnerabilities**: Attackers may exploit active conditions on the defender matching drawn candidate tags to promote candidates to the next higher severity tier ($K+1$).
4. **Curate the Pool**: Attackers choose any $N$ cards from the candidate pool to present to the defender.
5. **Defender Suffers a Consequence**: The defender selects and suffers 1 consequence from the pool (or a blank if Impact $< N$).

---

### 1. Determine Impact

You must meet the `Strength` of each incoming attack declared against you:

1. **Reactive "Defend" Actions (Optional)**: You may play an applicable **Defend** card from your hand as an [[Action Stack]] (along with additional cards from hand equal to its printed [[Cost]]). The card's printed rules text defines how it modifies the resolution.
2. **Deck Flips**: If the attack's Strength is not yet met, flip cards one by one from the top of your deck into a **flipped stack** until the cumulative value in the attack's Color meets or exceeds the attack's Strength.
3. **Accumulate Impact**: The `Impact` of a defense is the number of cards in your **flipped stack** for that attack. If multiple attacks targeted you this round, sum their Impact into a single **Total Impact ($I$)**.

---

### 2. Draw Candidate Consequences

The defender's equipped gear, traits, or table cards define their **Consequence Pool Size ($N$)**:

- **Armor defines Pool Size for Physical Harm:** Equipped armor cards specify pool size against physical trauma (e.g., 3 for light armor/padded gambeson, 4 for war armor/maille, 5 for full plate harness).
- **Domain Cards & Traits:** Non-physical domains derive pool sizes from applicable training or table cards (e.g., _Silver Tongue_ provides Pool Size 3 for social debate; _Iron Will_ provides Pool Size 3 for mental composure).
- **Universal Baseline Fallback ($N = 2$):** For any challenge or domain without specialized gear or traits, Pool Size defaults to **2**. (Minions have an inherent Pool Size of **1** across all domains).

Total Impact ($I$) generated against the defender is converted into candidate cards: **1 Impact = 1 card drawn**. Candidates are drawn from the severity decks by filling tiers of width $N$ from the bottom up:

1. **Tier 1 (Severity 1)**: The first $N$ Impact draws up to $N$ cards from the **Severity 1** deck.
   - If total Impact is less than $N$, remaining unfilled slots are implicit **"No Consequence" blanks** (clean armor soak).
2. **Tier 2 (Severity 2)**: Once Tier 1 has $N$ cards, each additional point of Impact (from $N+1$ to $2N$) draws 1 card from the **Severity 2** deck.
3. **Tier 3 (Severity 3)**: Once Tier 2 has $N$ cards, each additional point of Impact (from $2N+1$ to $3N$) draws 1 card from the **Severity 3** deck.
4. **Tier 4 (Taken Out)**: Once Tier 3 has $N$ cards, each additional point of Impact (from $3N+1$ to $4N$) allocates one **Severity 4 (Taken Out)** candidate.

---

### 3. Promote via Active Vulnerabilities

Active conditions in play in front of the defender list **`Vulnerable: [Tags]`**—specific openings created by that condition.

After drawing all base candidates, attackers may exploit active conditions on the defender to promote drawn candidates into higher severity tiers:

1. **Matching:** An active condition of **Severity $S$** can promote any drawn candidate of **Severity $K \le S$** whose tags match one of its `Vulnerable` tags.
2. **Promotion:** Place the matching candidate sideways across the exploited condition and immediately draw 1 replacement candidate from the **Severity $K+1$** deck (or allocate a **Tier 4 Taken Out** candidate if promoting a Tier 3 card via an active Tier 3 condition).
3. **Limit:** Each active condition on the defender may hold at most 1 sideways card (promoting at most 1 candidate) per resolution.
4. **Chained Promotion:** A newly drawn replacement card may be promoted again only if the defender has another unspent active condition of Tier $\ge K+1$ with a matching `Vulnerable` tag.

---

### 4. Curate the Consequence Pool (The "I Cut" Step)

From all active candidates remaining after promotions, the attackers **choose any $N$ cards** to form the final Consequence Pool:

- If total Impact was less than $N$, unfilled slots are presented as **"No Consequence" blanks**.
- All unselected candidates are returned to their respective decks.

---

### 5. Defender Suffers a Consequence (The "You Choose" Step)

1. The curated pool of $N$ cards (along with any "No Consequence" blanks) is presented to the defender.
2. The defender **chooses exactly 1 option** from the pool to suffer.
3. If "No Consequence" is in the pool, the defender may select it to suffer no additional harm beyond the stamina/fatigue cards already flipped from their deck.
4. **Applying the Consequence:**
   - **Active Condition:** Place the chosen card into play in front of the defender. If the card specifies that it supersedes an existing condition, discard the superseded condition.
   - **Tier 4 (Taken Out / Crisis Clock):** If the defender selects a Severity 4 candidate, the character is out of the fight (never instant death). The attacker or narrative context defines an actionable exit state or rescue clock (e.g., knocked `Unconscious`, `Pinned & Captured`, or an emergency bleedout clock). No card is drawn from a physical deck.
5. **Clean Up:** All unchosen cards in the pool and all cards laid sideways across active conditions are returned to their respective decks.
