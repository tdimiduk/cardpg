# Differentiate Game Elements Primarily Through Core Math

## Core Principle

The most elegant design is one where the distinctiveness and power of a game element "fall out" as a natural consequence of its core numerical stats. New keywords and special rules should be reserved for representing truly unique tactical functions that the core math cannot adequately represent.

## Rationale

This precept is a direct implementation of our "Mechanical Elegance" and "Casual Realism" guiding principles. By relying on the established numerical systems (Strength Modifier, Cost Reduction, Severity Thresholds, etc.), we create a game that is internally consistent and intuitive. When effects emerge naturally from the math, the world feels more logical and less "gamey." It also prevents rules bloat, ensuring that any special rule we do add feels genuinely significant.

## Implementation Guide

When designing a new card or mechanic, follow these steps:

1. Identify the Desired Outcome: Clearly define the narrative and mechanical effect you want to achieve (e.g., "This armor should feel invincible," or "This attack should feel overwhelmingly powerful").
2. Modify Core Numbers First: Before inventing a new keyword or rule, attempt to achieve the desired outcome by tuning the element's existing numerical values.
3. Look for Emergent Properties: Analyze how your proposed numbers will interact with the rest of the system. Does the desired outcome happen naturally as a result of these interactions?
4. Add a Special Rule for Tactical Uniqueness: Only if you want to represent a specific *technique* or *quality* that cannot be captured by raw numbers should you add a special rule. Ask: "Does this just hit harder, or does it do something clever?"

## Case Studies

* Case Study 1 (Defense): The Full Harness
  * We initially considered giving the Full Harness a complex special rule like "Impervious." Instead, we simply gave very high base stats. The armor feels nearly invincible against conventional attacks because its core math makes it so, while remaining vulnerable to specialized, armor-defeating tactics. The desired effect emerges from the numbers.
* Case Study 2 (Offense): The "Mighty Blow" Attack
  * We needed an attack that felt overwhelmingly powerful. Instead of adding a special rule, we gave the *Mighty Blow* card a very high **Strength Modifier**. This *causes* it to be harder to defend against by forcing the defender to expend more cards, which naturally increases the potential for severe consequences. The effect of being "harder to defend" falls out naturally from a simple, high number.

# Default to Success at a Cost; Make Failure an Explicit Consequence

## Core Principle

 Actions are presumed to succeed at their immediate goal. The core tension of the game does not come from asking "if" an action works, but "at what cost?" Outright failure is an exceptional outcome that must be explicitly stated on a `Consequence Card`.

## Rationale 

This is the central mechanical implementation of our "Fail Forward & Narrative Momentum" guiding principle. It ensures the story never stalls on a single bad roll. By focusing on the cost and consequences, we create a dynamic where players are always moving forward, but accumulating complications and facing difficult choices about how much they are willing to risk.

## Implementation Guide 

When designing actions, challenges, and especially `Consequence Decks`:

1. **Assume Success:** The default state is that the player's stated goal is achieved. They leap the chasm, they persuade the guard, they decipher the ancient text. `Attack Actions` against active opponents are an exception and are resolved via their own procedure.
2. **Focus on the Cost:** The mechanical resolution should determine the cost of that success, primarily through the number of cards expended and the potential for drawing from a `Consequence Deck`.
3. **Isolate Failure:** Do not design challenges with a binary pass/fail state. True failure should only occur when a `Consequence Card` is drawn that specifically says "The action fails" or describes an outcome that negates the success. This should be a rare and impactful event.

# Model Harm and Complications with Two Distinct Card Types

## Core Principle 

Harm, exhaustion, and other complications are modeled using two distinct mechanical and narrative tools: `Status Cards` represent general, accumulating wear-and-tear, while `Condition Cards` represent specific, persistent afflictions.

## Rationale 

This distinction allows the system to model the "downward spiral" of the `Illusion of Lethality` in two different ways. `Status Cards` create a slow, unpredictable drain on a character's effectiveness. `Condition Cards` create immediate, tactical problems that must be actively managed. This separation prevents all negative effects from feeling homogenous and provides a richer, more textured model of harm.

### Implementation Guide 

When designing new consequences, injuries, or negative effects, assign them to one of the following two categories:

* Status Cards: These represent general exhaustion, pain, and minor injuries (e.g., `Fatigue`, `Wound`).

  * Mechanical Location: They are added directly to a character's deck.

  * Effect: They degrade a character's overall effectiveness by clogging their hand with less useful cards, slowing access to their better abilities, and coming up during defense resolutions increasing the Impact of the attack (because they have low values).

  * Use Case: Use `Status Cards` to model the accumulating cost of exertion and taking minor/nonspecific hits.

* Condition Cards: These represent specific, significant injuries or afflictions (e.g., `Concussed`, `Arm Injury`, `Grappled`).

  * Mechanical Location: They are placed on the table in front of the player.

  * Effect: They impose a persistent mechanical penalty and must have a clear, actionable method for their removal.

  * Use Case: Use `Condition Cards` to model severe, narrative-rich injuries or external effects that create an immediate tactical challenge.

# Mandate Simultaneous Action Resolution

### Core Principle 

During `Crisis Time`, all player and enemy actions are declared simultaneously and resolved simultaneously. This is a non-negotiable core of the action system.

**Rationale** 
This precept is the primary mechanical support for the Combat pillar's goal of being "fast-paced and decisive." It eliminates player downtime, keeping everyone engaged in the action of every round. It also creates a more realistic and chaotic feel for combat, where characters must commit to a course of action based on their prediction of what others will do.

**Implementation Guide**
When designing abilities, especially reactive ones, ensure they are compatible with simultaneous resolution. Avoid creating "interrupt" style actions that would disrupt the flow of the round. Triggered effects (such as those with the Resolve: keyword) are the preferred method for handling reactions, as they are queued at the start of the step and resolve alongside all other actions.

# Design for Narrative Possibility, Not Game States

## Core Principle 

An action's viability should be determined by its narrative context and its cost, not by an abstract game state. If a player can describe how their character performs an action and is willing to pay the associated costs and risk the consequences, the rules should facilitate that action.

## Rationale 

This is a direct implementation of our **Ludonarrative Harmony** principle. It prevents dissonant, "gamey" player behavior (such as the "bag of rats" problem) where players are incentivized to create artificial scenarios to gain a mechanical benefit. By focusing on narrative logic, we ensure that the mechanically optimal choice aligns with what makes sense in the story.

## Implementation Guide 

When designing a new ability, especially a powerful one, follow these rules:

* **Design Universally:** An action should have the same fundamental mechanics regardless of the target or situation. Swinging a sword costs the same whether aimed at a dragon or a training dummy; the difference is in the potential consequences. Avoid keywords like "enemy" that create artificial constraints.
* **Balance Through Cost and Consequence:** The primary tool for balancing powerful abilities is their cost (in cards) and the severity of their potential consequences, not arbitrary limitations on when they can be used. A mighty blow is always costly to perform; using it in a high-stakes fight is a tactical choice, while using it on a peasant is a narrative statement. 
* **Trust the Narrative:** The rules should define the mechanics of an action, but the narrative context should define its meaning and appropriateness.

# Apply the Three Core Colors Across All Pillars

The three Core Colors are the primary framework for categorizing actions and ensuring all character archetypes have meaningful ways to contribute to any challenge. The following precepts provide guidance on applying this framework to non-combat encounters. For a comprehensive list of example actions, refer to the `Colors of Action` document.

## Map Social Actions to the Three Core Colors

### Core Principle 

Social challenges should be designed to allow for multiple avenues of approach, mapped directly to the three Core Colors.

### Rationale 

This precept directly supports the `Social` pillar's goal of eliminating the "party face" problem. By providing distinct mechanical paths for different social tactics, we make social encounters a puzzle for the entire party to solve.

### Implementation Guide 

When designing a social encounter, consider how a character could apply each of the three Colors:

* Red (Force/Presence): Represents intimidation, commanding presence, and appeals to authority or raw power.

* Yellow (Cunning/Finesse): Represents fast-talking, charming wit, reading a room quickly, and exploiting social openings.

* Blue (Intellect/Discipline): Represents formal debate, logical persuasion, leveraging knowledge, and recalling etiquette or precedent.

## Design Exploration Challenges Around the Three Core Colors

### Core Principle 

Exploration and environmental challenges should be designed with multiple potential solutions in mind, each corresponding to one of the Core Colors.

### Rationale 

This ensures that all characters can meaningfully contribute to exploration, preventing situations where only the "nimble" or "perceptive" character gets to solve problems. It transforms the environment into a multi-faceted puzzle.

### Implementation Guide

When designing an exploration challenge, consider how it could be overcome with different approaches:

* Red (Force/Endurance): Smashing a crumbling wall, enduring a harsh blizzard, or taming a wild beast.

* Yellow (Speed/Precision): Picking a complex lock, navigating a trapped corridor, or moving silently past a sentry.

* Blue (Intellect/Lore): Deciphering ancient runes, planning a safe route through a dangerous area, or recalling lore about a creature's habitat.

## Frame Downtime Activities by Color

### Core Principle 

Downtime activities, particularly long-term projects, should be framed by the Core Colors to provide thematic and mechanical structure.

### Rationale 

Categorizing downtime actions by Color helps players and GMs define the nature and goals of a project. It provides a clear mechanical hook for resolving these actions and ensures that a character's core strengths are relevant even outside of active adventuring.

### Implementation Guide 

When a player initiates a long-term project during downtime, work with them to determine its primary Color:

* Red (Endurance/Dominion): Represents projects of physical labor or establishing authority, such as smithing a weapon, recruiting a militia, or constructing a fortification.

* Yellow (Cunning/Finesse): Represents projects of subtlety and skill, such as building an information network, crafting intricate items, or practicing a delicate art.

* Blue (Intellect/Planning): Represents projects of research and strategy, such as conducting magical research, composing a masterwork, or orchestrating a complex scheme.

# Death is a Consequence of a Process, Not a Random Outcome

## Core Principle

Player character death should not be an unavoidable consequence from a card draw. Instead, death is the ultimate outcome of failing to address a specific, persistent "dying" state.

## Rationale

This directly supports "Fail Forward" by ensuring a character is not abruptly removed from the narrative by a single unlucky draw. It creates a "telegraphed downward spiral," giving players agency to react to the escalating danger.

## Implementation Guide

When designing consequences, threats, and healing mechanics, adhere to the following:

1. **No "Instant Death" Consequences:** Do not create any standard consequence card that simply says "The character dies."
2. **Create "Dying" States:** The most severe outcomes should be persistent, negative conditions that will lead to death *if left untreated*. These cards create a new, desperate objective for the entire party.
3. **Provide a Clear Path to Averting Death:** The "dying" state must have a clear method of removal, even if it is difficult to achieve.

## Case Study Example: Designing Severity 3 Consequences

We initially considered having "Death" as a possible `Severity 4` outcome. However, we realized this violated our "telegraphed death" principle. A character could go from healthy to dead based on a single, high-cost defense.

By following this precept, we removed "Death" and instead designed the `Severity 4` consequence **`Bleeding Out`**.

* **The Effect:** The card itself doesn't kill the player. It puts them on a timer.
* **The Cause:** Death is now the result of the *process*—the party failing to help their ally before the timer runs out.
* **The Result:** This creates a far more dramatic and engaging scenario. The tension comes from the desperate, player-driven struggle for survival, not from the random chance of a card draw.

# Define the Core by the Pillars of Play 

A mechanic is **core** if its removal would fundamentally break or diminish one of the established Pillars of Play (Combat, Exploration, Social, Downtime). The `General Action` system is core to all pillars, while the `Crisis Time` system is core to the Combat pillar. A mechanic is a candidate for a **module** if it adds an optional, self-contained layer of depth or flavor to a pillar that already functions without it (e.g., `Snap Checks` for Exploration).

# Design Advancement for Tangibility

Character advancement should provide tangible, exciting new tools, not just abstract numerical improvements. While increasing a core stat is a valid upgrade, the most compelling rewards are often new, named `Action Cards` that grant a character a specific, dramatic capability they can choose to deploy. This makes advancement feel more meaningful and reinforces the `Grounded Heroism` principle.

# Support Archetypes with Specific Mechanics

Core character fantasies (like the armored defender) should be supported by specific, active mechanics, not just passive stats. While high defensive numbers are essential for a "tank," the ability to use a specific "Guard" action to mechanically protect an ally is what truly fulfills the archetype. Reserve new rules and keywords for these kinds of unique tactical functions.

# Appendix: Potential TTRPG Misinterpretations

**DO NOT assume actions have a binary pass/fail outcome.** Actions almost always succeed at their immediate goal. The core mechanical tension does not come from a "roll to hit" or a check against a target number. Instead, the system is built on "Success at a Cost". The central resolution mechanic is determining the *Cost* of an action (how many cards you flip), which in turn determines the potential *Severity* of the consequences you risk. True failure is an exceptional outcome dictated by a specific, high-severity Consequence Card, not the default result of a "miss".
**DO NOT treat damage as simple Hit Point loss.** Characters do not have an abstract health pool that just gets depleted. Instead, harm is modeled through two distinct and tangible mechanics:

* **`Status Cards` (e.g., `Fatigue`, `Wound`):** These represent general exhaustion, pain, and minor injuries. They are added directly to a character's deck, degrading their overall effectiveness by clogging their hand with less useful cards and slowing access to their better abilities. This models the "downward spiral" of accumulating wear-and-tear.
* **`Condition Cards` (e.g., `Concussed`, `Arm Injury`):** These represent specific, significant injuries or afflictions. Unlike `Status Cards`, they are placed on the table in front of you. Each `Condition Card` imposes a persistent mechanical penalty (like "Draw only 1 card each turn") and has a clear, actionable method for its removal (like "1 week of rest"). This transforms taking damage from simple math into a tactical challenge of managing specific, narrative-rich debuffs.

**DO NOT treat death as an instantaneous event from damage.** Player character death is never the direct result of a single attack or card draw. It is the final step in a clearly telegraphed
 *process*. A character must first be put into a specific, persistent "dying" state (e.g., `Bleeding Out`) by a very high-severity consequence. This state then acts as a timer or a new, desperate objective that the party must work to resolve. This is a core design precept ensuring that death is a dramatic, preventable outcome, not a sudden, random event.
**DO NOT separate resources from general action-taking.** There are no distinct resource pools like "spell slots," "per-day powers," or "action points." A character's 24-card deck is their sole and universal resource for everything they do. Every significant action—whether attacking, defending, casting a spell, or performing a feat of exploration—is paid for by expending these cards. This mechanic unifies the concepts of physical stamina, mental focus, and "health" into a single, constantly cycling resource pool

**DO NOT assume the attacker makes the decisive roll.** The attacker's role is to set the difficulty by calculating their action's `Strength`. The defender is the active agent in resolving the action. The defender flips cards from their own deck until they meet or exceed the attacker's `Strength`. The number of cards the defender flips becomes the `Cost`, which is the crucial number used to determine the severity of the consequence. The mechanical and narrative focus is on the defender's struggle to endure the attack.

# Document Purpose

This is a designer-facing document intended for internal use by the design team.

It serves as a technical companion to the [Guiding Principles](guiding_principles.md) document, translating high-level philosophy into concrete, actionable design patterns. Where the `Guiding Principles` explains the **"Why"** of our design and the `Core Rules` explains the **"How,"** this document details the **"How-To"**—the specific techniques, preferred mechanics, and established patterns we use when creating new content.

Its purpose is to ensure mechanical consistency and elegance across all aspects of the game.
