# Proposed new action resolution mechanic

Update to ../rules/core-rules.md. Replaces `## Defend Actions`

## Action Resolution

1. Defender Determines Impact
2. Attacker Builds a Consequence Pool
3. Defender Suffers a Consequence

### Determine Impact

You need to meet the `Strength` of the attack against you. You may play **Defend** cards from your hand if you have any, and then flip cards from your deck one by one until the total value in the attacks `Color` of all the cards you are defending with is equal to or greater than the attack’s `Strength`. The `Impact` of a defense is the number of cards you flipped. You will take

### Build a Consequence Pool

The defender needs to give the attacker a pool of consequences to choose from. The defender's table cards will set the size of the pool. An unarmored hero has a pool size of 2, a "minion" has a pool size of 1, and typically light armor is 3 and heavy armor 4.

The attacker "Spends" impact from the attack to draw consequence cards and then picks two to hand to the defender. If the attacker cannot pick 2 cards, the pool is implicitly filled with "No Consequence".

"Buying" a consequence draw costs 1 impact per severity level of the consequence. Remember you need at least 2 consequences in the pool to actually impose a consequence.

If multiple attacks happen in the same round, the attackers build a consequence pool together, each spending their own `Impact`.

#### Escalation

As the attacker is drawing consequences for a pool they have a chance to escalate to higher severity consequences based on consequences the defender already has on the table _and_ on consequences already in the consequence pool.

Each consequence only applies an escalation once per consequence pool. Turn the consequence card sideways to note it's escalation has been used.

If multiple escalations can apply simultaneously, the player building the consequence pool chooses which one to resolve.

### Suffer a Consequence

From the two options offered to them, the defender picks 1 to suffer. Accumulate all conequences for attacks against you in one round. After you are done facing consqueces, follow the effects of each card. If the order matters, you may choose.

### **Severity**

Consequences are grouped by severity ranging from 1 (often fleeting minor setbacks or accelerated fatigue and wear) to 6 (incapacitating, risk of death, serious recovery journey)

| Severity | Category                               | Description & Gameplay Effect                                                                   | Examples                                                          |
| :------: | :------------------------------------- | :---------------------------------------------------------------------------------------------- | :---------------------------------------------------------------- |
|  **1**   | **Minor Friction / Wear**              | Fleeting setbacks, positioning slips, or minor stamina costs. Easily pushed through or cleared. | `Near Miss`, `Poor Footing`, `Out of Breath`, `Slightly Battered` |
|  **2**   | **Tactical Constraint / Minor Injury** | Specific tactical hindrances that limit actions or make you vulnerable to follow-up strikes.    | `Breached Guard`, `Staggered`, `Afraid`, `Strained Offense`       |
|  **3**   | **Significant Impediment**             | Severe tactical disruptions or meaningful physical wounds requiring mid-combat attention.       | `Mild Concussion`, `Terrified`, `Hamstrung`, `Knocked Prone`      |
|  **4**   | **Major Trauma**                       | Structural failure of defense or severe bodily injury. Forces a major tactical shift.           | `Broken Arm`, `Armor Shattered`, `Dislocated Knee`                |
|  **5**   | **Critical Injury**                    | Life-threatening trauma or near-total collapse. One step from defeat.                           | `Severe Concussion`, `Arterial Bleed`, `Crushed Ribs`             |
|  **6**   | **Taken Out**                          | Incapacitated, unconscious, dying, or completely removed from the conflict.                     | `Unconscious`, `Mortal Wound`, `Catatonic`                        |

# Document Purpose

This is a designer-facing exploration document, **not settled design.**
