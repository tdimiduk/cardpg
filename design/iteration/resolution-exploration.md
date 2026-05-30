# Resolution Mechanic Exploration

## Background

The current "core resolution mechanic" (Defense + Resiliance, how consequences accumulate) is actually the "first thing that we came up with that can work" to fix a flaw in an older resolution mechanic that (looked like it) would make mostly always optimal to save up for the biggest attack you could with the intent of knocking an opponent out in one blow. That analysis was mostly theoretical, but Jeff felt it was important to fix that up before wrote cards for a playtesting campaign. Under time pressure, the current mechanic was the thing we came up with.

The current mechanic does "check the boxes" in terms giving people warning shots before hitting them with serious consequences, making "small attacks" relevant (mostly, it's got a little bit of a situation where attacks that do not have appreciable probabibility of hitting even 1 defense increment are kind of bad). It prevents one big attack from knocking someone out too easily (it still has to count up all the levels).

It does offer the nice property that setting Resiliance to 0 or 1 is an elegant way to handle what 4e D&D did with "Minion" enemies who can be threatening but dispatched quickly.

### Resolution Mechanism: Analysis and Critiques

The current Canon resolution machanics has some properties that (at least Tom thinks) are not ideal.

It forces us to have specific persistent "consequences" and deeply couples them to a character's remaining survivability. In other iterations of things we could have more flexible "status" cards that imposed penalties without having to specifically track "is this a consequence that marches me up the severity track".

It does not (really) leave any room for some kind of consequences only affecting some kinds of things, every consequence you take always marches you towards being taken out.

It ends up being a little bit "hit points in disguise" (though is there actually any way to avoid something feeling a little bit "hit pointy" while meeting our other design goals?).

It ends up with defense feeling a bit less "interactive" than we'd prefer (you just flip cards to meet the defense, making it essentially pure RNG). We've trying patching that with introducing more cards that affect defense that you can play from hand.

## Exploration

### Declared Defenses

Proposal form Anh.

Defender sees the Strength + Color of the attack then declares how much effort they want to put into the defense (in a number of cards they want to flip). They then flip exactly that many cards and total them to compare to the attack. If that meets the strength, they have "nominally succeeded" avoiding/blocking the attack (or accomplishing the task without serious complications).

If the declared number does not hit the strength then "something goes wrong".

#### Cost of Declaration

Just the fatigue cost of declaring a large number is probably not a high enough cost (in many circumastances), so we probably also want something like "accepted costs" that come with (large?) declarations. The most obvious one is tiem the action takes (for things where that make sense).

In combat this could include things like getting pushed out of position, dropping prone to avoid an attack, or even accepting a minor wound to avoid a more serious one.

We'd want to think through a good way to have this play that feels right for "accepting" consequences, and probably not guaranteed to happen.

Maybe something with a "menu" of choices you could take to "pay off" your declared effort? Maybe with some amount of effort "free"? (Number of cards in the attacker's action is an obvious threshold). Could have consequence only have a chance of applying if it is bigger (a value 8 consequence when your accepted cost was only 4 only happening 50% of the time or something)

#### Something Goes wrong

It should matter how much you missed by, and we probably want it scaled based on the numbers in your deck (to avoid having things go weird/deadly for "high level characters").

An obvious answer here would be to keep flipping until you hit the target, then count that number of cards. Some formula that then converts that to consequences you take (obvious simple one would just be count number of cards, that is a severity level)

#### Needs further thought

##### How do fights end?

I don't love hard caps on how many cards you can declare for a defense, but then that would mean that people can theoretically just always declare a number where they can (almost?) never fail even as they get really battered.

Caps could come in based on accepted consequences (from earlier declarations)? Combine with the [fatigue proposal](./fatigue-change-proposal.md) and have the number of cards you have remaining in your deck/discard be the soft cap? That has weird danger spikes though if you have lots of cards in hand or on the table. Would probaly need some rules for using cards from hand

##### Analysis Paralysis

This does make it so there is real benifit to keeping track of exactly what cards remain in your deck and doing probability calculations every time you defend. Some tables might have fun with that, but it's going to drag if it's just one or two players doing that.

In the digital version we could just do those calculations for players automatically and present the numbers so that players don't have to do the math and tracking, just weigh their risk tolerance. Not sure what the answer is in the physical version

##### What does armor/defensive items/... do in this system

### Defending From hand

In early versions of caRdPG we had everyone defend from hand (and consequences kick in based on meeting fractions of the attack strength). This gave lots of defender agency, but ended up with some not great table play:

- players who were saving up for some action feeling bad when they then had to spend them to defend themselves
- monsters getting "stun locked" where they were just always spending their cards to defend, accumulating consequences but taking a long time to finish off but it was pretty clear they were never getting an another attack in
- Noob trap of needing to save cards in hand to be able to defend yourself or risk getting on-shotted.

However defending from hand is a space we probably still want to explore (likely in concert with other things, probably flips). The route we have gone so far is having specific cards that say you can add them to defenses from hand. We could also have say shields always let you defend from hand, or even everyone can always defend from hand (but still use some other mechanic as well)
