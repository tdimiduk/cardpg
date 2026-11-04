# Keyword Glossary Patch: Consequence Pool & Tag Escalation

Patch for `design/rules/keyword-glossary.md`, updating action resolution terminology and adding evergreen keywords for the **Consequence Pool & Tag Escalation Engine**.

---

## Updates to `## Action Resolution`

### Impact

The number of cards in your **flipped stack** when facing a challenge. In Action Resolution, each point of [[Impact]] draws 1 candidate consequence card (`1 Impact = 1 card drawn`), filling tiers of width equal to your [[Consequence Pool Size]] ($N$) from Severity 1 upward.

### Consequence Pool Size

_Aliases: Pool Size, Pool Size (N)_

The soak multiplier and drafting threshold ($N$) for an entity within a given domain. An attack's candidate cards must reach at least $N$ cards to present a Consequence Pool (isolated attacks with $I < N$ fail to penetrate armor or poise and draw 0 cards). When curating consequences, the attacker curates down to exactly $N$ cards from which the defender selects 1. Defaults to **2** for unarmored characters, and **1** for minions. (Replaces legacy [[Defense]] and [[Resilience]]).

### Consequence Pool

The drafting market of candidate consequence cards drawn by attackers during Step 2 of Action Resolution. Attackers curating a pool must present exactly $N$ cards, from which the defender selects and suffers 1. Multiple attackers targeting the same defender may merge their drawn candidates into a single shared pool to reach $N$.

### Severity

_Aliases: Severity 1, Severity 2, Severity 3, Severity 4_

The escalation tier of consequence cards:

- **Severity 1:** Tactical impairments, friction, and clearable setbacks.
- **Severity 2:** Moderate bodily trauma, stance loss (prone), and concussive fog.
- **Severity 3:** Severe structural bodily failure (fractures, arterial bleeding, chest trauma).
- **Severity 4:** Taken out / incapacitation clocks (coma, mortal bleedout).

---

## Additions to `## Action Types & Card Keywords`

### POOL:

_Aliases: Pool Block, Pool Clauses_

A dedicated visual area on consequence cards, weapons, or attack actions detailing rules that modify candidate card draws during Step 2 of Action Resolution. Rendered at the bottom of the card to allow attackers to glance across the defender's tableau during candidate draws.

### Vulnerable

_Aliases: Vulnerable: [Tags]_

An evergreen keyword appearing in a condition card's `POOL:` block, listing 2 to 4 compromised leaf tags (e.g. `positioning`, `limbs`, `torso`, `head`, `bleeding`, `exertion`, `fear`).

During Step 2 of Action Resolution, if a Consequence Pool contains an unplaced candidate card of Severity $K \le S$ (where $S$ is this condition's Severity) matching one of its listed tags, the attacker may place that candidate onto the condition to draw **+1 additional candidate from the Severity $K+1$ deck** into the pool (at most once per active condition per pool). All placed candidates return to the pool before curation in Step 4.
