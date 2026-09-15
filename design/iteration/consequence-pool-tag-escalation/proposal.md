# Proposed New Action Resolution Mechanic

Update to `design/rules/core-rules.md`. Replaces `## Defend Actions`.

## Action Resolution (Crisis Time)

1. **Determine Impact**: The defender meets incoming attack Strength and tallies cards flipped.
2. **Attacker Draws Candidate Consequences**: Attackers spend accumulated Impact directly as currency to draw candidate consequences from the severity decks (1 Impact = 1 Severity).
3. **Attacker Curates the Consequence Pool**: The attackers select $N$ cards from their candidates (where $N$ is the defender's Pool Size) to present to the defender.
4. **Defender Suffers a Consequence**: The defender selects and suffers exactly 1 consequence from the curated pool, triggering explicit condition escalations if matching active vulnerabilities.

---

### 1. Determine Impact

You must meet the `Strength` of each incoming attack declared against you:

1. **Hand Defense**: You may play **Defend** cards from your hand. Defend cards contribute their printed value in the attack's `Color` without generating Impact.
2. **Deck Flips**: If the attack's Strength is not fully met from hand, flip cards one by one from the top of your deck until the cumulative value in the attack's Color meets or exceeds the attack's Strength.
3. **Accumulate Impact**: The `Impact` of a defense is the number of cards you flipped from your deck. If multiple attacks target you in the same round, sum the cards flipped across **all** attacks to find your **`Total Round Impact`**.

---

### 2. Draw Candidate Consequences

Attackers spend the defender's Total Round Impact as currency to draw a hand of candidate consequences from the severity decks:

- **Severity 1** costs **1 Impact**
- **Severity 2** costs **2 Impact**
- **Severity 3** costs **3 Impact**
- **Severity $S$** costs **$S$ Impact**

Attackers may spend their Impact across any combination of severities they can afford. If multiple attackers targeted the defender in the round, they pool their generated Impact and draw candidates together.

---

### 3. Curate the Consequence Pool (The "I Cut" Step)

The defender's traits and equipped gear define their **Consequence Pool Size ($N$)** (typically 2 for unarmored heroes, 3–4 for armored combatants, and 1 for minions).

#### Tactical Pool Curation

From their hand of drawn candidate cards, the attackers **choose exactly $N$ cards** to form the final Consequence Pool. All unchosen candidate cards are returned to their respective decks.

- **Targeting Existing Vulnerabilities:** Attackers examine the **Active Conditions** already in play in front of the defender. If the attackers offer a card that matches an active condition's category/tag (e.g., offering a `[Position]` card to a defender who is already `Off-Balance`), they create a stacking escalation threat.

#### Implicit "No Consequence" Blanks

If the attackers drew fewer than $N$ candidate cards (e.g., they could not afford $N$ cards or chose to buy fewer, more expensive cards), any unfilled slots in the pool of $N$ are **implicitly filled with "No Consequence"**.

- _Armor Soak Threshold_: To guarantee inflicting a consequence of Severity $S$, attackers must produce at least $N$ candidate cards of at least Severity $S$, requiring at least $N \times S$ Impact. If fewer than $N$ cards are offered, "No Consequence" will be available for the defender to pick.

---

### 4. Defender Suffers Exactly 1 Consequence (The "You Choose" Step)

1. The curated pool of $N$ cards (along with any "No Consequence" blanks) is presented to the defender.
2. The defender **chooses exactly 1 option** from the pool to suffer.
3. If "No Consequence" is in the pool, the defender may select it to suffer no additional harm beyond the stamina/fatigue cards already flipped from their deck.
4. **Applying the Consequence & Table Escalation:**
   - **Transient Consequence:** If the chosen card is a transient effect (e.g., `Out of Breath`, `Shallow Laceration`, `Near Miss`), apply its immediate deck/status effect and discard/return it immediately.
   - **Novel Condition:** If the chosen card is a persistent condition and the defender has no active condition with an `escalate:` trigger matching this card's tags, place the card into play in front of the defender as a new active condition.
   - **Condition Escalation:** If an active condition in play in front of the defender has an `escalate:` trigger matching the chosen card's tag, discard the active condition and place the upgraded condition into play. (If the chosen consequence is already equal to or higher severity than the upgrade target, discard the lower active condition and put the chosen card into play).
5. All unchosen cards in the pool are returned to their respective decks.

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
