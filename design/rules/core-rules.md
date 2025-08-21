# Cards As your Character

Your character is defined by a 24 card deck that is your resource for everything you do. Every significant action costs cards; running out of cards incurs Fatigue. When you advance you upgrade cards from your deck or gain new ones. Consequences from actions add bad status cards to your deck.

### The Three Colors

The three numbers along the upper left of each card are key. They represent the card’s strength in the game’s three core Colors:

* **Red (Square):** Force, Endurance, Presence, Passion, Dominion
* **Yellow (Circle):** Speed, Precision, Perception, Cunning, Finesse
* **Blue (Diamond):** Intellect, Planning, Discipline, Lore, Intrigue

See [Colors of Action](colors-of-action.md) for reference on how actions map to colors. 

# Taking an Action

When you want to do something significant, you take an action. The first step is always to state your goal, like “I want to hit the goblin with my sword” or “I want to leap across the rooftop.”

All actions require you to play and expend cards, representing the physical and mental effort involved. The rules resolve these actions in one of two ways, depending on the situation.

The first way is with an **Attack Action** and a corresponding **Defend Action**. This pair is the fundamental building block for resolving combat and other adversarial, tense, moment-to-moment conflicts, which are played out in a structured sequence called **Crisis Time**.

The second way is with **General Actions**. This is the standard method for resolving any task that isn't a detailed conflict. The key assumption is that you succeed, and the rules determine the *cost* of that success.

This choice is a collaborative tool for controlling the game's pacing. A minor scuffle might be resolved with a single General Action, while a tense negotiation could be played out moment-by-moment using the Crisis Time rules.

## Attack actions

To perform an Attack Action, you play a stack of cards from your hand to generate its **Strength**. 

The primary and most effective way to do this is by playing a card with an appropriate action printed on it, like "Attack." To do this

1. Play a stack: Play that card on top of a stack with a total number of cards equal to the number in the card’s upper right corner.
2. Compute Strength: Add up the values of the indicated color of all the cards in the stack and add the printed modifier. This gives you the Action’s **Strength**.
3. Declare Color: The colored symbol next to the Attack (or other Action) on the card tells you the action’s **Color**.

*A Note on Narrative Actions**:** If no specific Action Card in your hand applies, you can always perform a Narrative Action by describing what you do. Your Action Cards represent your specific training and the tactical opportunities you are prepared for, but a clever improvisation can also be potent.*

*When you perform a Narrative Action, the GM will provide a Strength modifier. This modifier reflects how effective your action is in the current situation. A generic attempt is likely less effective than a practiced skill, but a creative action that takes advantage of the environment could receive a powerful bonus.*

—

Figure: Example of an attack action

Example Calculation: Using the attack action in the figure above:

* The action's **Color** is Red.
* The calculation is: (Red value of top card \[3\] \+ Red value of second card \[3\]) \+ (Modifier from top card \[+2\]) \= **Strength 8**.

—

## Defend Actions

You need to meet the **Strength** of the attack against you. You may play **Defend** cards from your hand if you have any, and then flip cards from your deck one by one until the total value in the attacks **Color** of all the cards you are defending with is equal to or greater than the attack’s **Strength**. The **Impact** defense is the number of cards you flipped.

Now determine your **Ward** and **Grit** for this attack. They will come from an armor or other card you already have on the table in front of you. Pick the best numbers coming from a card that is applicable to the attack. If you have no relevant cards for **Ward** or **Grit**, use a value of 1\.

Your **Ward** number the amount of **Impact** to impose one consequence on you. If you defend with less than that many cards, you take no consequences, group the cards you flipped to defend into piles of size equal to your **Ward** value. You suffer one consequence for each completed pile.   
Math: Consequences \= round\_down(**Impact** / **Ward**).

The severity of each new consequence you take is determined by how many consequences you are already suffering. Your **Grit** is the number of consequences you can suffer at each severity level before you step to the next severity level. To find the severity of a new consequence you can arrange your consequence cards in rows equal to your **Grit** value. The severity is one more than the number of completed rows.
Math: Severity \= round\_up(“Existing Consequences” / **Grit**)

### **Understanding Severity** 

The Severity level of a consequence is more than just a number; it’s a signal about the escalating danger your character is in.

* **Severity 1 (Acceptable Costs):** These are the expected scrapes and bruises of a conflict. They are penalties you can push through.
* **Severity 2 (Warning Shots):** These are significant problems that make your character vulnerable. They are a clear sign that the tide of battle needs to turn.
* **Severity 3 (The Brink of Defeat):** This is the final warning that death is on the table. A character at this level is severely hampered and should be looking for a way to disengage or end the fight immediately.
* **Severity 4 (Out of the Fight):** These are catastrophic outcomes that take your character completely out of the action, such as being knocked unconscious or mortally wounded.

## General Actions

A **General Action** is the standard way to handle a self-contained task all at once. Success is the default assumption; the resolution determines the *cost* of that success, not *if* it works. Failure is a specific consequence, not the default outcome of an attempt.

**Defining the Scope**
 A `General Action` works best when the goal is a single, resolvable task (e.g., "I want to climb the castle wall," not "I want to storm the castle"). If a stated goal is too broad, the GM has two tools: they can work with the player to identify an appropriate first step, or they can assign a prohibitively high `Strength` to the action, signaling its immense difficulty. Resolving that first step—or attempting the high-risk action—creates a new situation from which the group can decide what to do next.

***Note to Players:** If the `Strength` of a task seems too high, try breaking it down into smaller steps you can more easily succeed at.*

**Note to Gamemasters:** *If a player proposes a General Action that does not feel like it should be resolved in a single step, either suggest the player break it down or assign a prohibitively high `Strength` to the task.*

For a general action, a specific challenge card will give you a **Color** and **Strength** for the action or the gamemaster will tell you. Instead of **Ward** you use a relevant **Skill** number to compute consequences. Your **Skill** is 1 if you have no relevant skill card. 

Resolution proceeds similarly to a defend action: After flipping cards to meet the **Strength**, use your **Skill** to find the number of consequences you suffer, and your **Grit** to find their severity. If you do not have an appropriate consequence deck at hand for the kind of action you are taking your gamemaster may define an appropriate one. Note it down and place it in your consequences area as usual for tracking. 

# Resources and Consequences

## Running Out of Cards: The Fatigue Cycle 

Your deck is a finite resource. When you need to draw a card but your deck is empty, you must perform a **Fatigue Cycle**. This is a common part of the game and represents your character becoming tired as they exert themselves.

**Fatigue Cycle Procedure:**

1. Add 2 **Fatigue** cards to your expended pile.
2. Reshuffle your expended pile to form your new deck.
3. Draw the card you needed.

**Fatigue** is the most common type of **Status Card**.

*Figure: Fatigue Card*

## Types of Harm: Status & Condition Cards 

As you face challenges, you will gain cards that represent harm, exhaustion, and other complications. These fall into two categories:

**Status Cards (In Your Deck)** These represent general wear-and-tear, like **Fatigue** or minor wounds.

* **Where they go:** Added directly to your deck and shuffle pile.
* **What they do:** Clog your hand and deck, making you less effective over time.

**Condition Cards (On the Table)** These represent specific, serious problems, like an `Arm Injury` or being `On Fire`.

* **Where they go:** Placed on the table in front of you.
* **What they do:** Impose a persistent mechanical penalty and present a new tactical problem you must solve.

# Modes of Play

## Crisis Time

Used for combat or other tense, moment-to-moment situations.

Play proceeds in rounds.

* Plan Step**:** Everyone draws two cards and secretly plans their action for the round.
* Resolve Step**:** All actions are revealed and resolved simultaneously.

### Transitioning out of Crisis Time

When the threat is gone or the tension breaks, the crisis ends. Crisis Time represents a state of heightened, second-by-second focus, and the cards in hand are the immediate tactical options relevant to that specific moment. 

Upon leaving the crisis, all characters must discard any cards remaining in their hands. This represents letting go of those fleeting opportunities as your character's focus shifts to the new situation.

### Player & GM Guidance: The Risk of a Large Hand

There is no hard limit to your hand size, but holding many cards is a high-risk strategy. Be aware of two consequences:

* **Faster Fatigue:** A large hand means a smaller deck, causing you to gain Fatigue cards more often.
* **Defensive Collapse:** If you are attacked with too many cards “out of circulation” in your hand, you can be forced into fatigue cycles just to generate cards for defense. This can result in a massive **Impact** and devastating consequences.

Holding more than 8-10 cards is a dangerous gamble. You go "all in" on your own plan at the cost of being vulnerable to surprise.

## Adventuring Time

Used for exploration, travel, and downtime. During Adventuring Time, you resolve tasks using **General Actions** as needed.

You do not hold a hand of cards as you do in a crisis. Instead, you maintain a **Ready** hand of up to 4 cards, kept face down. This represents your character's general alertness and ability to react to sudden events.

This vigilance is not free. Periodically, the GM will call for an **Effort Cycle** to represent the mental cost of staying alert. When this happens, you must discard your entire Ready hand and draw a new one.

### Transitioning to Crisis Time

When exploration or travel is interrupted by a sudden threat, play shifts from Adventuring Time to Crisis Time. The nature of the encounter determines how this transition happens.

* Mutual Awareness: If you encounter enemies and both groups become aware of each other at the same time, all characters immediately pick up their **Ready** hand. You are now in Crisis Time and will begin the first round by planning your actions.
* **Surprise:** If one side becomes aware of the other earlier, they gain a significant advantage. The aware characters may take several rounds of Crisis Time—drawing cards and acting as normal—while the other side remains unaware.
* **Player-Initiated Crisis:** Any player can declare their intent to enter **Crisis Time** at any point. This is the primary tool for modeling a character taking time to prepare, focus, or set up an ambush. This preparation comes at a significant cost: you must discard your hand when the crisis ends even if you don’t end up actually launching the ambush.

# Advanced Details

## Keywords and Timing

Some cards have abilities prefixed by a **keyword** followed by a colon, such as `Resolve:`. This keyword indicates a specific and precise time that the ability triggers.

**Triggered Effects** An effect with a keyword trigger is checked for at the very beginning of the corresponding step.

* If the card with the keyword is in play at the start of that step, its effect is considered "active" for the entire duration of the step.
* The effect itself resolves simultaneously with all other actions and outcomes during that step.
* If a card with a triggered ability enters play *during* a step, its keyword ability does not trigger until the *next* time that step occurs in a subsequent round.

**`Resolve:` Keyword** This keyword triggers during the Resolve Step. Its effect is queued at the start of the step and resolves alongside all other declared actions.

# Document Purpose

This is a player facing document. 

It’s purpose is to be the one document that players need to read and understand to play. It should be crisp, clear, and complete. It should be as long as it needs to be and no longer. Don’t spend words on evocative language or discussions of how the game should feel, that belongs in the [Introduction](https://docs.google.com/document/d/1-asmLiqgniNs4IHzteuSsKp4G1JEk3TL4wNQzDo3Lz8/edit?tab=t.0#heading=h.4abr2m63fpec) (or other documents). 

