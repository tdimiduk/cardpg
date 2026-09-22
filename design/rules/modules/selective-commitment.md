---
title: "Rules Module: Selective Commitment"
doc_type: rules
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Rules Module: Selective Commitment

In the core rules, committing your [[Ready Hand]] to a [[General Action]] is an all-or-nothing choice: you either resolve the task using only deck flips (Casual Attempt), or pick up your entire [[Ready Hand]] and flush all unplayed cards upon resolution (Committed Effort).

**Selective Commitment** allows players to pick up any subset of their [[Ready Hand]] (such as 1 or 2 cards instead of all 4). This gives players granular control over stamina attrition without forcing a full hand flush.

---

## Player Rules

### The Concept: Buying Filtered Flips

When you resolve a challenge through blind deck flips, every flipped card adds to your [[Impact]], regardless of its value. Low cards increase your risk of consequences while contributing negligible [[Strength]].

Committing cards into your hand lets you **pay stamina to filter your flips**:

- **High Cards:** Cards that beat your deck's average value replace blind flips, meeting [[Strength]] with minimal [[Impact]].
- **Low Cards:** Cards with poor values or the wrong [[Color]] can be held and flushed harmlessly to your expended pile, rather than entering the flipped stack and inflicting [[Consequences]].

Selective Commitment allows you to buy a measured amount of filtering—spending a smaller, targeted amount of deck stamina rather than flushing your entire hand.

### Tabletop Procedure

1. **Declare and Lift (Before Inspection):** You must declare how many cards you are committing and physically lift them into your hand _before_ looking at their faces. Uncommitted cards remain face down on the table. You may never inspect your [[Ready Hand]] and retroactively choose what to leave behind.
2. **Resolve the Action:** Resolve the [[General Action]] as normal using your committed cards and deck flips:
   - Committed cards placed into the flipped stack count as 1 [[Impact]] each.
   - Action Cards played as [[Action Stacks]] do not count toward [[Impact]].
3. **Flush and Refill:**
   - Discard any unplayed cards from your committed hand into your expended pile.
   - **Deal cards face down from your deck until your [[Ready Hand]] reaches your chosen vigilance size.** Undisturbed cards remain on the table.

### Interacting with Face-Up Guards

- **Exact Fuel:** If you have an Action Card face up as your guard (e.g., Cost 1), you can pick up the guard plus 1 face-down card to pay its cost (committing 2 cards). Remaining cards stay undisturbed on the table.
- **Preserving a Guard:** You may commit only face-down cards to an obstacle, leaving a prepared combat stance (`Parry`) undisturbed on the table for future hazards. (An undisturbed guard card cannot modify the current action).
- **Face-Down Refills:** All newly dealt cards are dealt face down from the top of the deck. Expending a face-up guard does not grant a free deck search; setting a new guard still requires roughly one minute of quiet focus.

---

## Gamemaster's Guide

### When to Use This Module

The core rules' all-or-nothing commitment rule is an onboarding tool: keeping the choice strictly binary minimizes cognitive load and prevents analysis paralysis when teaching new players. Once players understand the card economy, however, flushing 4 cards for a minor task can feel artificially blunt.

Selective Commitment is often the first module a group adopts. It is ideal for:

- **Graduating Past Onboarding Friction ("Feel Bad"):** Once players understand Effort Cycles, being forced to flush an entire hand just to spend 1 card on an obstacle feels needlessly punishing. Selective Commitment resolves that table friction without adding tokens or altering combat math.
- **Tactical Groups & Card Economy:** Groups that enjoy deck management and want fine-tuned control over their deck cycling and stamina attrition.
- **Gritty Campaigns & Dungeon Crawls:** Environments where characters are balancing frequent minor obstacles against an impending Fatigue Cycle, making every card cycled toward deck exhaustion count.

> [!TIP]
> Remind players that a Casual Attempt (0 cards committed) remains the most stamina-efficient choice whenever a character has sufficient [[Defense]] to absorb minor [[Impact]] without taking consequences.

---

## Examples of Play

### Example 1: Fueling a Prepared Action (Athletics on a Leap)

A Swashbuckler with a [[Ready Hand]] of 4 (1 face-up prepared maneuver—hypothetically `Athletics`: Cost 1, `Yellow 4`, text: _+2 Strength, Defense 2 on physical maneuvers_—and 3 face-down cards) faces a Challenging chasm leap (**[[Yellow]] 18 [[Strength]]**).

1. **Selective Commitment:** The Swashbuckler commits **2 cards**: the face-up `Athletics` card and 1 face-down card. The other 2 cards remain undisturbed on the table.
2. **Action Stack:** They play `Athletics`, paying the face-down card for its Cost of 1. `Athletics` contributes $4 + 2 = 6$ [[Yellow]] [[Strength]] and establishes active [[Defense]] 2.
3. **Flips:** To meet the remaining 12 [[Strength]], the player flips 3 cards from the deck (`Yellow 5`, `Yellow 4`, `Yellow 4`). Total [[Strength]] is $6 + 5 + 4 + 4 = 19$ (meeting 18).
4. **Resolution:** The flipped stack contains 3 cards ([[Impact]] 3). With [[Defense]] 2, the player takes 1 completed stack ($3 / 2 = 1$) as a minor [[Severity 1]] scrape; the 1 leftover card is discarded without harm.
5. **Flush and Refill:** Both committed cards were used in the stack (no cards to flush). The Swashbuckler deals 2 cards face down from the deck, restoring their [[Ready Hand]] to 4 while having cycled 2 fewer cards through their deck.

### Example 2: A Measured Blind Gamble (Picking a Lock)

A Rogue with a [[Ready Hand]] of 4 (all cards face down) attempts an iron lock (**[[Yellow]] 8 [[Strength]]**). The Rogue has only 6 cards left in their draw deck and wants to reach a safe room to take [[The Breather]]. Flipping blind risks high [[Impact]], but committing all 4 cards would flush 4 cards, redraw 4, and trigger an untimely [[Fatigue Cycle]].

1. **Selective Commitment:** The Rogue commits **2 cards**, lifting 2 face-down cards before looking at them.
2. **Inspection:** The cards are `Yellow 6` and `Red 1`.
3. **Playing to the Stack:** The Rogue places `Yellow 6` into the flipped stack (6 [[Strength]], 1 [[Impact]]). The `Red 1` contributes no [[Yellow]] [[Strength]], so the Rogue holds it in hand rather than suffering useless [[Impact]].
4. **Deck Flip:** The Rogue flips 1 card from the deck: `Yellow 3`. The lock opens ($6 + 3 = 9$ [[Strength]]).
5. **Resolution:** Flipped stack has 2 cards ([[Impact]] 2). The Rogue resolves consequences against their armor.
6. **Flush and Refill:** The unplayed `Red 1` flushes to the expended pile. The Rogue deals 2 cards face down from the deck to restore their [[Ready Hand]] to 4, spending only 2 cards of deck stamina instead of 4 and avoiding an untimely [[Fatigue Cycle]].
