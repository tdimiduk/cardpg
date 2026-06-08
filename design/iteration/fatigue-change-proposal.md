# Fatigue Change Proposal

## Background

The current rules have fatigue, injury, ... cards added to a player's deck. This pollutes the deck with poor cards (bad numbers, no useful actions), but does not directly affect their existing actions.

Prior art (Gloomhaven) actually took player's actions out of the deck (into a lost pile) through fatigue, injury or expending them.

In previous iterations of the game, we had more rigidly defined "timescales" scaling up by factors of 12 which gave the cool property of one go through of a deck (drawing 2 cards per turn) would take 1 of the next "bigger" timescale (assuming nothing spent cards faster). We have moved away from that rigidly defined of timescales (because it mostly felt like unjustified complexity and we can get most of the richness and tracking we want without needing that structure)

We still think there is some value to keeping decks at exactly (or at least closer to) 24 cards.

## Insight

There is a good way to track "replacing" a card with a fatigue (or other status card) even in the physical version of the game.

If we accept that people will be playing with sleeved cards, we can have a status "insert" that transforms the card into another one (fatiguing out the action). When the character rests and recovers from the fatigue, removing the insert restores the original card.

## Proposal

Any status card replaces a specific card in the deck, making that card unavailable until the character recovers from the fatigue. Adding cards to a player's "cycling deck" is rare (and generally only for cards that track something specific and then usually remove themselves after having their effect).

When you do a fatigue cycle you pick cards from your expended pile to "fatigue" (or it could be random, but picking seems like it might reduce feel bad moments). We could also have cards/mechanics to let you move the fatigue overlay from one card to another (making a specific card available again).

We might want to have some heirarchy of severity that let you further degrade a "fatigue" into a "wound", or maybe you always have to hit a new card with a status card.

## Analysis

- Deck size stays (closer to) constant. Simplifies analysis and design of some things
- Fatigue/status is higher impact (since count of good cards goes down in addition to count of bad cards going upC)
- Slight increase in complexity (need a little bit of rules about the overlays and managament of them)
- closer to how gloomhaven manages things

How is the feel of this?

### Defensive collapse

The current system (adding fatigue cards) handles a "defensive collapse" without any special casing, if you don't have enough cards in your deck to meet the strength of an attack, you just do fatigue cycles and flip the new fatigue cards to the defense until you count up (one by one) to the necessary value. This is Very Bad for the character it happens to, but nicely handled in the rules with no special casing.

If we are replacing cards with fatigue in the fatigue cycles it is possible to end up in a situation where you cannot count up to the required value with all of the "cycling" cards (deck + discard). So we'd need some special case rule or other re-designs to handle this situation.

---

# Document Purpose

This is a designer-facing proposal, **not a decided change.**

It outlines a potential shift in how fatigue works mechanically. The analysis section identifies open problems (particularly around defensive collapse) that would need to be solved before adoption. See [core-rules.md](../rules/core-rules.md) for the current canon fatigue rules.
