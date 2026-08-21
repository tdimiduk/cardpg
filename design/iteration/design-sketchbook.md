# Exploratory Concept: "Cards-as-Fuel" in Content Design

## Core Concept

Tactical recoveries and maneuvers on cards (such as getting up from prone, shaking off a stagger, or disengaging) can specify costs paid by placing or expending generic cards from hand regardless of their stats or text (e.g., _"Place a card from your hand into your expended pile to regain your footing"_). This ensures that even `Status Cards` like `Fatigue` have tactical utility as fuel for basic recoveries without requiring a separate, rigid "Basic Action" rules subsystem in the core rulebook.

### Rationale & Application

- **Solves the "Hand of Fatigue" paralysis:** A player whose hand is flooded with `Fatigue` cannot execute powerful strikes, but can burn those fatigue cards to stagger to their feet or withdraw.
- **Embedded in Content, Not Bloated Core Rules:** Rather than writing an extensive list of global basic actions into `core-rules.md`, card text and condition cards specify these costs organically where relevant.

# The Flexible Resolution Scale is the Game's Identity

The game's most powerful and unique feature is the ability to seamlessly shift between a narrative resolution (`General Action`) and a tactical one (`Crisis Time`). This duality is the heart of the system's identity. A design that makes half of this equation optional fundamentally weakens the game's core concept.

# Modular Design as Curation, Not Construction

The purpose of our modular design is to allow groups to _curate_ an already complete and satisfying experience, not to require them to _construct_ a playable game from a kit of parts. The core rules should present a strong, opinionated design. Modules are the dials used to tune that core engine to a group's specific tastes (e.g., adding flavor with specific `Consequence Decks` or granularity with `Tactical Movement`).

# Long-Term Vision: Curated Editions:

The modular design philosophy can be elevated to a product-level strategy. In the future, we can release different, standalone editions of the game (e.g., a "Narrative Edition," a "Warlord's Edition"). Each would be a pre-packaged, curated set of modules with a unified rulebook, presenting a complete and polished experience for a specific playstyle. Our current work on the "batteries-included" core is the development of the central, most balanced version of this potential product line.

# Defining "Elegance" as Fitness-for-Purpose

Mechanical elegance is not a pure measure of rules quantity, but of a design's fitness for its purpose. The most elegant system is the one that delivers the desired play experience to its target audience with the least friction. A "batteries-included" approach can be more elegant than a minimalist one if it better meets audience expectations and provides a more satisfying "out-of-the-box" experience.

# Model Environmental Damage Based on Material Properties

- **Core Principle:** When designing environmental or magical damage (Fire, Cold, Lightning, etc.), the effect on a character should be determined by the physical properties of the armor they are wearing, creating realistic and often counter-intuitive trade-offs.
- **Case Study Example: Fire vs. Lightning**
  - A character in a **Full Harness** is highly vulnerable to **Fire**, as the metal conducts heat and cooks the wearer. However, they are highly resistant to **Lightning**, as the metal shell acts as a Faraday cage, directing the current around them.
  - A character in a **Padded Doublet** has the opposite profile. The padding offers good insulation against a brief flash of heat but provides no protection from an electrical charge.
  - **Design Application:** This means a wizard's `Fireball` and `Lightning Bolt` are not just cosmetically different; they are tactically different tools to be used against different types of opponents.

# Model Overwhelming Force Based on Structural Integrity

- **Core Principle:** Attacks from huge creatures (Ogres, Giants) should be modeled not as simple damage, but as events that test the fundamental structural integrity of an armor.
- **Case Study Example: Ogre's Club vs. Armor Tiers**
  - An ogre's attack would be devastating to all but the best armor. It could have a special rule like: "If this attack's defense results in a consequence of `Severity 2` or higher, the defender's armor is automatically moved to its `Damaged` state."
  - **Design Application:** This rule interacts with the armor tiers realistically. A **Brigandine** might barely prevent a lethal wound but be destroyed in the process. A **Full Harness**, with its superior stats, has a much better chance of weathering the blow _and_ remaining intact, justifying its elite status.

# Exploratory Idea: Two-Tiered Armor Exertion (Per-Action Discard + Burden)

> [!NOTE]
> Canonical equipment uses the **`Burden`** keyword (adding extra `Fatigue` cards per cycle). The concept below is an exploratory ideation sketch investigating whether heavy armor should also impose per-action card discards. It is **not** canonical rules.

## Core Principle

The physical cost of wearing armor should be modeled by a single, unified mechanic that accounts for both the immediate, per-action anaerobic cost and the deeper, cumulative aerobic strain of recovery. This provides maximum gameplay depth and realism from the minimum number of rules.

## Rationale

This mechanic is the result of extensive iteration to find an elegant solution for modeling the cost of armor. It synthesizes two distinct physiological effects into one keyword:

1.  **The Immediate Cost:** The per-action discard from the deck models the rapid depletion of the body's explosive energy (ATP-PCr system) when moving in heavy gear. This makes every strenuous action more costly and causes fatigue cycles to occur more frequently.
2.  **The Cumulative Cost:** The addition of extra `Fatigue` cards during a cycle models the deeper, systemic exhaustion an armored character faces. Their "recovery" phase is less effective, reflecting the greater toll on their aerobic system.

By tying both effects to a single stat, `Encumbrance (X)`, we create a simple "knob" for tuning different armor types. This single number defines the entire exertion profile of an armor set, and the flat per-action cost naturally encourages players to adopt the deliberate, energy-efficient tactics appropriate for an armored combatant.

## The Mechanic

Armor cards can have the **`Encumbrance (X)`** keyword, where X is a numerical rating. This keyword has two effects:

1.  When you perform a `Red` or `Yellow` `Attack Action` or a `Move Action`, you must discard **X** cards from the top of your deck.
2.  When you perform a **Fatigue Cycle**, you add **X** additional `Fatigue` cards to your expended pile (for a total of 2+X).

### Case Study

- A **Maille Hauberk** is given **`Encumbrance (1)`**. A character wearing it discards 1 card from their deck per strenuous action and adds a total of 3 `Fatigue` cards (2+1) on a cycle.
- A **Full Plate Harness** is given **`Encumbrance (2)`**. A character wearing it discards 2 cards from their deck per strenuous action and adds a total of 4 `Fatigue` cards (2+2) on a cycle.

# Modular Complexity: The Layered Condition Card

## Core Principle

To model severe injuries with a modular level of complexity. A single `Condition Card` should be able to serve both a "Grounded Heroism" setting (where it's a simple, immediate problem) and a "Grim Simulationist" setting (where it's a complex, long-term struggle) by revealing its mechanical depth only when narratively necessary.

## Rationale

This solves a key design tension between **Mechanical Elegance** and **Casual Realism**. It prevents players in a heroic setting from being burdened with a "wall of text" for an injury that will be quickly healed, while ensuring that the full, gritty reality is available for a simulationist campaign.

## The Mechanic

Severe injuries are represented by two-sided `Condition Cards`.

1.  **The Triage Side (Front):** This is the default state. It shows:
    - **Name & Keyword:** e.g., `Compound Fracture (Injury)`
    - **Immediate Effect:** e.g., "You are non-ambulatory."
    - **Mundane Treatment:** A straightforward General Action to stabilize or remove. e.g., "Can be removed with a successful `Yellow` 25 General Action."
    - **Escalation Trigger:** e.g., "If this condition is not treated before you next enter Downtime, flip this card."

2.  **The Prognosis Side (Back):** This side details the grim, long-term consequences if the injury is not treated promptly.
    - **Chronic Effects:** More detailed penalties.
    - **Mundane Resolution:** A much more difficult, multi-stage process for healing, drawn from our verisimilitude research.

### Interaction with Healing

- **Mundane Healing** targets the explicit General Action printed on the card.
- **Magical Healing** is designed to be a more powerful and versatile tool. It would interact with the card's **Keyword**. For example, a "Lesser Restoration" spell might say "Remove one Condition with the `Injury` keyword." This allows magic to bypass the specific skill check, providing a clean and powerful solution, reinforcing the heroic tone.

# Document Purpose

A collection of specific mechanic ideas, interesting concepts, and design explorations. Also a place we can retire `Design Precepts` to if they don’t feel completely broadly applicable.
