# Proposed New Action Resolution Mechanic

Update to `design/rules/core-rules.md`. Replaces `## Defend Actions`.

## Action Resolution (Crisis Time)

1. **Determine Impact**: The defender meets incoming attack Strength and tallies cards flipped.
2. **Attacker Draws Candidates & Resolves Escalations**: Attackers spend accumulated Impact to draw candidate consequences from the severity decks, resolving escalations as cards are drawn.
3. **Attacker Curates the Consequence Pool**: The attackers select $N$ cards from their candidates (where $N$ is the defender's Pool Size) to present to the defender.
4. **Defender Suffers a Consequence**: The defender selects and suffers exactly 1 consequence from the curated pool.

---

### 1. Determine Impact

You must meet the `Strength` of each incoming attack declared against you:

1. **Hand Defense**: You may play **Defend** cards from your hand. Defend cards contribute their printed value in the attack's `Color` without generating Impact.
2. **Deck Flips**: If the attack's Strength is not fully met from hand, flip cards one by one from the top of your deck until the cumulative value in the attack's Color meets or exceeds the attack's Strength.
3. **Accumulate Impact**: The `Impact` of a defense is the number of cards you flipped from your deck. If multiple attacks target you in the same round, sum the cards flipped across **all** attacks to find your **`Total Round Impact`**.

---

### 2. Draw Candidate Consequences & Resolve Escalations

Attackers spend the defender's Total Round Impact as currency to draw a hand of candidate consequences from the severity decks:

- **Severity 1** costs **1 Impact**
- **Severity 2** costs **2 Impact**
- **Severity 3** costs **3 Impact**
- **Severity $S$** costs **$S$ Impact**

Attackers may spend their Impact across any combination of severities they can afford. If multiple attackers targeted the defender in the round, they pool their generated Impact and draw candidates together.

#### Resolving Escalations

As each candidate card is drawn, check its tags against:

1. **Active Table Conditions** already in play in front of the defender.
2. **Candidate Cards** already drawn into the attacker's hand during this resolution.

If the newly drawn card matches an escalation condition on an active table condition or an earlier candidate card:

- Follow the card's printed escalation instructions (e.g., return the drawn card and draw a card of Severity $+2$, or replace it with a specific higher-tier card).
- **Once Per Source Limit**: Each condition card (on the table or in the candidate hand) can only trigger its escalation **once per round**. Turn table conditions sideways (90 degrees) when used.

---

### 3. Curate the Consequence Pool

The defender's traits and equipped gear set the **Consequence Pool Size ($N$)**:

- **Minions / Mooks**: Pool Size **1** (instant hit; no drafting choice).
- **Unarmored Heroes**: Base Pool Size **2** (standard heroic drafting choice).
- **Light Armor (Gambeson & Maile)**: Pool Size **3** (Pierce 4 reduces to 2).
- **Heavy Armor (Full Harness)**: Pool Size **4** (Pierce 6 reduces to 3; Pierce 12 reduces to 2).

#### The "I Cut" Curation Step

From their hand of drawn and escalated candidate cards, the attackers **choose exactly $N$ cards** to form the final Consequence Pool. All unchosen candidate cards are returned to their respective decks.

#### Implicit "No Consequence" Blanks

If the attackers drew fewer than $N$ candidate cards (e.g., they could not afford $N$ cards or chose to buy fewer, more expensive cards), any unfilled slots in the pool of $N$ are **implicitly filled with "No Consequence"**.

- _Armor Soak Threshold_: To guarantee inflicting a consequence of Severity $S$, attackers must produce at least $N$ candidate cards of at least Severity $S$, requiring at least $N \times S$ Impact (or lucky escalations). If fewer than $N$ cards are offered, "No Consequence" will be available for the defender to pick.

---

### 4. Defender Suffers Exactly 1 Consequence (The "You Choose" Step)

1. The curated pool of $N$ cards (along with any "No Consequence" blanks) is presented to the defender.
2. The defender **chooses exactly 1 option** from the pool to suffer.
3. If "No Consequence" is in the pool, the defender may select it to suffer no additional harm beyond the stamina/fatigue cards already flipped from their deck.
4. The chosen card is placed into play in front of the defender and takes effect immediately. All other cards in the pool are returned to their respective decks.

---

### Severity Reference

| Severity | Category                               | Description & Gameplay Effect                                                                   | Examples                                                                 |
| :------: | :------------------------------------- | :---------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------- |
|  **1**   | **Minor Friction / Wear**              | Fleeting setbacks, positioning slips, or minor stamina costs. Easily pushed through or cleared. | `Near Miss`, `Poor Footing`, `Out of Breath`, `Slightly Battered`        |
|  **2**   | **Tactical Constraint / Minor Injury** | Specific tactical hindrances that limit actions or make you vulnerable to follow-up strikes.    | `Rattled Guard`, `Strained Offense`, `Afraid`, `Off Balance`             |
|  **3**   | **Significant Impediment**             | Severe tactical disruptions or meaningful physical wounds requiring mid-combat attention.       | `Mild Concussion`, `Terrified`, `Hamstrung`, `Knocked Prone`             |
|  **4**   | **Major Trauma**                       | Structural failure of defense or severe bodily injury. Forces a major tactical shift.           | `Broken Arm`, `Sundered Armor`, `Dislocated Knee`, `Deep Puncture Wound` |
|  **5**   | **Critical Injury**                    | Life-threatening trauma or near-total collapse. One step from defeat.                           | `Severe Concussion`, `Sucking Chest Wound`, `Compound Leg Fracture`      |
|  **6**   | **Taken Out**                          | Incapacitated, unconscious, dying, or completely removed from the conflict.                     | `Unconscious`, `Mortal Bleedout`, `Mind Void`, `Taken Out (Surrendered)` |
