# Proposed New Action Resolution Mechanic

Update to `design/rules/core-rules.md`. Replaces `## Defend Actions`.

## Action Resolution

1. **Determine Impact**: The defender meets each incoming attack's Strength; cards flipped from the deck for an attack equal that attack's Impact ($I$).
2. **Draw Candidates & Form Pools**: Each attacker converts their Impact into candidate cards (`1 Impact = 1 card`), filling tiers of width $N$ (the defender's Pool Size) from Severity 1 upward. Attackers may keep their candidate pools separate or merge them into a shared pool.
3. **Exploit Active Vulnerabilities (Escalate or Widen)**: Within each pool, attackers may exploit start-of-round active conditions on the defender (at most once per condition per pool) matching drawn candidate tags to either escalate candidates to the next higher severity tier ($K+1$) or widen the pool within the same tier (+1 net card to crack armor soak).
4. **Curate the Pool**: For each pool, attackers choose any $N$ cards from its active candidates to present to the defender.
5. **Defender Suffers Consequences**: For each presented pool, the defender selects and suffers 1 consequence (or a blank if remaining candidates in that pool are fewer than $N$). All consequences suffered this round enter play simultaneously.

---

### 1. Determine Impact

You must meet the `Strength` of each incoming attack declared against you:

1. **Reactive "Defend" Actions (Optional)**: You may play an applicable **Defend** card from your hand as an [[Action Stack]] (along with additional cards from hand equal to its printed [[Cost]]). The card's printed rules text defines how it modifies the resolution.
2. **Deck Flips**: If the attack's Strength is not yet met, flip cards one by one from the top of your deck into a **flipped stack** until the cumulative value in the attack's Color meets or exceeds the attack's Strength.
3. **Count Impact**: The `Impact` ($I$) of an attack is the number of cards in your **flipped stack** for that attack.

---

### 2. Draw Candidate Consequences & Form Pools

The defender's equipped gear, traits, or table cards define their **Consequence Pool Size ($N$)**:

- **Armor defines Pool Size for Physical Harm:** Equipped armor cards specify pool size against physical trauma (e.g., 3 for light armor/padded gambeson, 4 for war armor/maille, 5 for full plate harness).
- **Domain Cards & Traits:** Non-physical domains derive pool sizes from applicable training or table cards (e.g., _Silver Tongue_ provides Pool Size 3 for social debate; _Iron Will_ provides Pool Size 3 for mental composure).
- **Universal Baseline Fallback ($N = 2$):** For any challenge or domain without specialized gear or traits, Pool Size defaults to **2**. (Minions have an inherent Pool Size of **1** across all domains).

Each attacker independently converts the Impact ($I$) their attack generated into candidate cards: **1 Impact = 1 card drawn**. Candidates are drawn from the severity decks by filling tiers of width $N$ from the bottom up:

1. **Tier 1 (Severity 1)**: The first $N$ Impact draws up to $N$ cards from the **Severity 1** deck.
   - If an attack's Impact is less than $N$, remaining unfilled slots are implicit **"No Consequence" blanks** (clean armor soak) unless filled by merging pools or widening during Step 3.
2. **Tier 2 (Severity 2)**: Once Tier 1 has $N$ cards, each additional point of Impact (from $N+1$ to $2N$) draws 1 card from the **Severity 2** deck.
3. **Tier 3 (Severity 3)**: Once Tier 2 has $N$ cards, each additional point of Impact (from $2N+1$ to $3N$) draws 1 card from the **Severity 3** deck.
4. **Tier 4 (Taken Out)**: Once Tier 3 has $N$ cards, each additional point of Impact (from $3N+1$ to $4N$) allocates one **Severity 4 (Taken Out)** candidate.

**Separate or Merged Pools (Multi-Attacker):**

- **Keep Separate:** Each attacker may resolve their drawn candidates as their own independent Consequence Pool (allowing multiple attacks that each reach $\ge N$ cards to inflict multiple consequences simultaneously in the same round).
- **Merge Pools (Optional):** Multiple attackers targeting the same defender this round may **combine their drawn candidate cards into a shared pool** before Step 3. Merging allows multiple smaller hits ($I < N$) to fill the defender's $N$ slots together and eliminate **"No Consequence" blanks**.

---

### 3. Exploit Active Vulnerabilities (Escalate or Widen)

Active conditions in play in front of the defender at the start of the round list **`Vulnerable: [Tags]`**—specific openings created by that condition.

Within each Consequence Pool (after any pool merging), attackers may exploit start-of-round active conditions on the defender to amplify or escalate that pool:

1. **Matching:** An active condition of **Severity $S$** can exploit any drawn candidate in the pool of **Severity $K \le S$** whose tags match one of its `Vulnerable` tags.
2. **Tactile Exploitation (Escalate vs. Widen):** Place the matching candidate sideways and choose one:
   - **Escalate (Vertical):** Draw **1 replacement candidate from the Severity $K+1$ deck** (or allocate a **Tier 4 Taken Out** candidate if promoting a Tier 3 card via an active Tier 3 condition). Use this to push harm into higher severity tiers once the pool has enough cards to fill $N$.
   - **Widen (Horizontal):** Draw **2 replacement candidates from the Severity $K$ deck** (adding +1 net candidate to the active pool). Use this to crack heavy armor shells by replacing an implicit "No Consequence" blank slot with an active consequence, or to gain extra curation options.
3. **Limit (Once per Pool):** Each active condition on the defender may be exploited at most **once per Consequence Pool** (holding at most 1 sideways card per pool). When multiple pools resolve in parallel, each separate pool may independently exploit the defender's start-of-round active conditions once.
4. **Chained Exploitation:** Within a pool, a newly drawn replacement card may be exploited again only if the defender has another unspent active condition (not yet exploited by that pool) of Tier $\ge K+1$ (for escalated draws) or Tier $\ge K$ (for widened draws) with a matching `Vulnerable` tag.

---

### 4. Curate Consequence Pools (The "I Cut" Step)

For each Consequence Pool, from the active candidates remaining after promotions and widening, the attackers **choose any $N$ cards** to form the final curated pool:

- **Implicit Blanks:** In any presented pool where total active candidates (base draws plus net cards gained from merging and widening) are less than $N$, unfilled slots are presented as **"No Consequence" blanks**.
- If active candidates in a pool meet or exceed $N$, all $N$ slots are filled with consequence cards (zero blanks).
- All unselected candidates are returned to their respective decks.

---

### 5. Defender Suffers Consequences (The "You Choose" Step)

1. Each curated pool of $N$ cards (along with any "No Consequence" blanks) is presented to the defender.
2. For each presented pool, the defender **chooses exactly 1 option** to suffer.
3. If "No Consequence" is in a pool, the defender may select it to suffer no additional harm from that pool beyond the stamina/fatigue cards already flipped from their deck.
4. **Applying Consequences (Simultaneous):**
   - All consequences suffered during the round enter play simultaneously at the end of the round (they cannot be exploited for Step 3 vulnerability promotions during the same round they are inflicted).
   - **Active Condition:** Place each chosen card into play in front of the defender. If the card specifies that it supersedes an existing condition, discard the superseded condition.
   - **Tier 4 (Taken Out / Crisis Clock):** If the defender selects a Severity 4 candidate, the character is out of the fight (never instant death). The attacker or narrative context defines an actionable exit state or rescue clock (e.g., knocked `Unconscious`, `Pinned & Captured`, or an emergency bleedout clock). No card is drawn from a physical deck.
5. **Clean Up:** All unchosen cards in the pools and all cards laid sideways across active conditions are returned to their respective decks.
