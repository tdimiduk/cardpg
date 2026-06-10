# Core Resolution Mechanic Exploration

## Background

### Current Mechanic

The current "core resolution mechanic" (Defense + Resilience, how consequences accumulate) is actually the "first thing that we came up with that can work" to fix a flaw in an older resolution mechanic that (looked like it) would make mostly always optimal to save up for the biggest attack you could with the intent of knocking an opponent out in one blow. That analysis was mostly theoretical, but Jeff felt it was important to fix that up before wrote cards for a playtesting campaign. Under time pressure, the current mechanic was the thing we came up with.

The current mechanic does "check the boxes" in terms giving people warning shots before hitting them with serious consequences, making "small attacks" relevant (mostly, it's got a little bit of a situation where attacks that do not have appreciable probability of hitting even 1 defense increment are kind of bad). It prevents one big attack from knocking someone out too easily (it still has to count up all the levels).

It does offer the nice property that setting Resilience to 0 or 1 is an elegant way to handle what 4e D&D did with "Minion" enemies who can be threatening but dispatched quickly.

#### Analysis and Critiques

The current Canon resolution mechanics has some properties that (at least Tom thinks) are not ideal.

1. It forces us to have specific persistent "consequences" and deeply couples them to a character's remaining survivability. In other iterations of things we could have more flexible "status" cards that imposed penalties without having to specifically track "is this a consequence that marches me up the severity track".

2.It does not (really) leave any room for some kind of consequences only affecting some kinds of things, every consequence you take always marches you towards being taken out. Getting your ego bruised in a debate directly marches you up the severity track making you 1-for-1 easier to seriously harm if you get jumped in the ally afterwards. 3. It ends up being a little bit "hit points in disguise" (though is there actually any way to avoid something feeling a little bit "hit pointy" while meeting our other design goals?).

4. It ends up with defense feeling a bit less "interactive" than we'd prefer (you just flip cards to meet the defense, making it essentially pure RNG). We've trying patching that with introducing more cards that affect defense that you can play from hand. It could still be worth keeping an eye out for mechanics that add more interactivity directly without too much complexity

### Prior Mechanic: Defend from hand

We initially started cardpg with the defender defending with cards from their hand and armor providing one or two flips from their deck that were added to the defense before spending cards from hand.

In that system there was no defense or resiliance stat, the severity of consequences was determined by what fraction of the strength of the attack the defender met

| Defense >= Attack | No Effect |
| Defense >= Attack/2 | Minor Consequence |
| Defense >= Attack/4 | Major Consequence |
| Defense < Attack/4 | Critical Consequence |

#### Advantages

1. Defense was very interactive
2. Interesting tempo play interactions
3. Somewhat intuitive in how to play

#### Critique

1. Having to spend cards you had saved up to play an action to defend yourself ended up being a "feel bad" moment, especially for younger players
2. Big attacks felt a bit underwhelming because usually what the defender would do is scrape their way up to half the strength and just accept a minor consequence
3. Fights were hard to close out because with two cards to defend it was pretty easy to stay above the strength/4 which was the knock out condition.
4. Monsters could end up "stun locked". They were able to vaguely defend themselves spending their card draws each turn on defense and gradually accumulating conesquences but hiting a point where it was clear as long as you kept pressuring them they would never attack again in the combat
   5.Noob trap of spending all your cards to play an attack and then being extremely vulnerable to an attack against you.
5. Weird dynamics around multiple attacks against the same character in the same turn, how to resolve them and unintended anti-synergies.

### Prior Mechanic: Allowed Severity

Our first move away from defend from hand introduced defending by flipping from deck and the `Impact` concept. Your armor would provide a table mapping `Impact` to "allowed severity". You would then draw `Impact` number of cards from a deck containing an even mix of consequences of each severity and the attacker would pick one no higher than the "allowed severity". This meant that you had an chance of escaping without consequence from every attack, but that chance got vanishingly small as `Impact` increased. You still would have a chance of receiving a less than maximal severity consequence.

Still no defense or resiliance, instead there was the armor tables of allowed severity.

#### Advantages

1. Dynamic consequences with an always increasing ramp in probability\*severity (because every consequence added an extra draw it incleased the probabilty of something landing)
2. Armor severity tables had lots of room to tune different levels to capture the relative protectiveness of armors

#### Critique

1. Requried significant, complex rules in the core rules explaining the consequence mechanic
2. Delivering low severity consequences could end up underwhelming. This lead to Jeffs theoretical critique that the most efficient way to play in this system was to save up cards until you could play a big enough attack to unlock the highest severity levels.
3. Extra fiddling with an extra deck of cards every action
4. Specific constraints about how the consequence deck had to be structured (same number of cards at each severity)

## Goals

1. Plays well at the table. Doesn't slow down play.
   a. avoid excessive fiddly tracking, reshuffling, ...
   b. avoid analysis paralysis (significant advantages to players from complex probability calculations in real time, detailed tracking of every card remaining in your deck, ...
   c. respect physical realities of playing with cards in the real world
2. Give defender enough agency that they feel like they are **defending themselves** not just being subject to an attack
3. Require as little presence in the core rules as possible (keep complexity on cards if we can)
4. Give us freedom to design consequences for different situations and have them interact well

## Exploration

### Declared Defense Effort

Goal: increase defender interactivity

Proposal form Anh.

Defender sees the Strength + Color of the attack then declares how much effort they want to put into the defense (in a number of cards they want to flip). They then flip exactly that many cards and total them to compare to the attack. If that meets the strength, they have "nominally succeeded" avoiding/blocking the attack (or accomplishing the task without serious complications).

If the declared number does not hit the strength then "something goes wrong".

#### Cost of Declaration

Just the fatigue cost of declaring a large number is probably not a high enough cost (in many circumstances), so we probably also want something like "accepted costs" that come with (large?) declarations. The most obvious one is time the action takes (for things where that make sense).

In combat this could include things like getting pushed out of position, dropping prone to avoid an attack, or even accepting a minor wound to avoid a more serious one.

We'd want to think through a good way to have this play that feels right for "accepting" consequences, and probably not guaranteed to happen.

Maybe something with a "menu" of choices you could take to "pay off" your declared effort? Maybe with some amount of effort "free"? (Number of cards in the attacker's action is an obvious threshold). Could have consequence only have a chance of applying if it is bigger (a value 8 consequence when your accepted cost was only 4 only happening 50% of the time or something)

#### Something Goes wrong

If your declared defense falls short of the strength, you then continue flipping cards until you hit the strength. The number of cards you have to flip to finish the defense then determines the severity of the consequence you take

#### Needs further thought

##### How do fights end?

I don't love hard caps on how many cards you can declare for a defense, but then that would mean that people can theoretically just always declare a number where they can (almost?) never fail even as they get really battered.

Caps could come in based on accepted consequences (from earlier declarations)?

##### Analysis Paralysis

This does make it so there is real benefit to keeping track of exactly what cards remain in your deck and doing probability calculations every time you defend. Some tables might have fun with that, but it's going to drag if it's just one or two players doing that.

In the digital version we could just do those calculations for players automatically and present the numbers so that players don't have to do the math and tracking, just weigh their risk tolerance. Not sure what the answer is in the physical version

##### What does armor/defensive items/... do in this system

### Push your luck

Goal: increase defender agency

#### The Concept

Instead of calculating fractional `Strength` thresholds upfront, resolution happens sequentially. The attacker declares `Strength`. The defender flips cards until they meet or exceed it, with the number of flipped cards generating the `Impact`.

At any point, the defender faces a choice regarding how to handle the incoming `Strength` gap:

- **Press Your Luck:** Keep flipping cards to meet the `Strength`. If you get lucky with high-value cards, your `Impact` remains low and you might escape without serious consequences. If you roll poorly, your `Impact` skyrockets, and you are subjected to the standard, potentially devastating consequence draw (see "I Cut, You Choose" below).
- **The "Buy-Off" (Accepting the Cost):** Stop flipping and bridge the remaining `Strength` gap by accepting a Consequence. The amount of `Strength` "bought off" is determined by a static character statistic (e.g., the highest or median value of the relevant `Color` in their deck).
  - _The Tradeoff:_ Choosing to Buy-Off incurs a **guaranteed severity bump** (e.g., accepting a consequence 1 severity higher than the current calculated impact severity per "buy off increment"). However, the defender gets maximum agency: they draw 3+ consequence cards of that severity and pick their preferred one, entirely bypassing the attacker's input.

#### Critiques

1. Analysis paralysis. Less high stakes large probability calculation than `Declared Defense Effort`, but still incentivizes tracking your deck and doing some mild probability calculations **every** defensive flip.
2. slows down defenses (math + decision point every flip)

### "I Cut, You Choose" Consequence Selection

Goal: increase feeling of agency (for attacker and defender)

#### The Concept

When a character is forced to take a Consequence card, the agency is split between the attacker and the defender to prevent the "punching bag" stall tactic where a defender always chooses optimal penalties.

- The attacker draws a small pool of Consequence cards (maybe impact/2, min 2?) of the appropriate numeric Severity level.
- The attacker selects two options and presents them to the defender.
- The defender makes the final choice of which Condition to suffer.

#### Critiques

1. Extra step and decision (but only at the point of actually taking a consequence)

### Keyword-Driven Redundancy Escalation

Goal: Replace the fixed severity escalation system (possibly replace resiliance stat)

#### The Concept

Maintain the numeric Severity tracks (e.g., Severity 1 through 4), but offload the momentum of the downward spiral onto the cards themselves using physiological and structural tags (e.g., `Legs`, `Arms`, `Core`, `Head`, `Armor`).

Escalation happens mechanically via these tags combined with the numeric severities. If a character takes a consequence bearing a tag they already possess, it triggers an immediate jump in severity.

- _Example Text:_ A Severity 1 `Legs` Condition might read: "If you would take another Severity 1 `Legs` consequence, instead draw two Severity 2 `Legs` consequences and pick one."

#### Advantages

1. If done right could inclease ludonarrative harmony and "Casual Realism" (taking a hit on the arm that has already been wounded naturally puts you in a worse situation)
2. Can live almost entirely on consequence cards. Requires little to no core rules support
3. Naturally supports different domains of consequences

#### Critiques

1. Requires a family of keywords and looking up what you have with what keyword at the table
2. Designer burden (more moving pieces when writing consequence cards and more peices we have to balance correctly)

---

# Document Purpose

This is a designer-facing exploration document, **not settled design.**

It captures critiques of the current resolution mechanic and explores alternative approaches. The ideas here are starting points for discussion, not proposals ready for implementation. See [core-rules.md](../rules/core-rules.md) for the current canon mechanic.
