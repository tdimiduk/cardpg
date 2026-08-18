# Proposed new action resolution mechanic

Update to ../rules/core-rules.md. Replaces `## Defend Actions`

## Action Resolution

1. Defender Determines Impact
2. Attacker Builds a Consequence Pool
3. Defender Suffers a Consequence

### Determine Impact

You need to meet the `Strength` of the attack against you. You may play **Defend** cards from your hand if you have any, and then flip cards from your deck one by one until the total value in the attacks `Color` of all the cards you are defending with is equal to or greater than the attack’s `Strength`. The `Impact` of a defense is the number of cards you flipped. You will take

### Build a Consequence Pool

The defender needs to give the attacker a pool of 2 consequences to choose from (unless modified by table cards or existing consequences).

The attacker "Spends" impact from the attack to draw consequence cards and then picks two to hand to the defender. If the attacker cannot pick 2 cards, the pool is implicitly filled with "No Consequence".

"Buying" a consequence draw costs 1 impact per severity level of the consequence. Remember you need at least 2 consequences in the pool to actually impose a consequence.

#### Escalation

As the attacker is drawing consequences for a pool they have a chance to escalate to higher severity consequences based on consequences the defender already has on the table _and_ on consequences already in the consequence pool.

Each consequence only applies an escalation once per consequence pool. Turn the consequence card sideways to note it's escalation has been used.

If multiple escalations can apply simultaneously, the player building the consequence pool chooses which one to resolve.

### Suffer a Consequence

From the two options offered to them, the defender picks 1 to suffer. Accumulate all conequences for attacks against you in one round. After you are done facing consqueces, follow the effects of each card. If the order matters, you may choose.

### **Severity**

Consequences are grouped by severity ranging from 1 (often fleeting minor setbacks or accelerated fatigue and wear) to 6 (incapacitating, risk of death, serious recovery journey)

# Supporting Content

## Table Cards

### Armor

Armor will usually modify the consequence pool construction. The most fundamental way it does so is by increasing it's size, forcing the attacker to give you additional options to choose from.

- When taking a physical harm consequence your consequence pool size is 3
- The first escalation triggered in each consquence pool has no effect (it still counts as used for that consequence)
- The first time a consequence pool would include a card of severity 4 or higher, damage (flip) this armor instead and the attacker must choose a different consequence

## Consequences

### Escalation

Some random examples of what escalaction clauses on cards migth look like

- Instead of drawing a severity 1 consequence, draw a severity 2 consequence
- If you draw a `Legs` keyword consequence return it and intead draw a consequence of 2 severity higher.
- Draw an additional severity 1 consequences

# Open questions/Concerns

## Batch consequences

Should we just build once consequnce pool each round if multiple attacks happen instead of forming a seperate pool per attack?

- Advantages: more streamlined at the table (probably?)
- Disdvantages: groups things together in a way that may reduce verisitimilitude? Could create ambiguity in the "controlling player" for a consquence pool (how much does that matter?)

# Evaluation

of this system, as compared to our existing ones

## Advantages

- Offers more dynamicism in how consequences resolve
- Means we are not forced into a single escalation track for unrelated consequences
- Potentially reduced core rules presence (don't need `Defense` and `Resiliance` stats)
- gives the attacker and defender more agency in how a given attack plays out's

## Disadvantages

- More table time (two extra decision steps for every attack)
- More complexity on the consequence cards
- Does it solve the "alpha strike" problem?

# Document Purpose

This is a designer-facing exploration document, **not settled design.**
