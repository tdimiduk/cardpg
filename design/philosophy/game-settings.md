# Game Settings: Curating the Experience

This document outlines the philosophy and practical application of "Game Settings" in caRdPG. "Settings," in this context, refers not just to the campaign world, but to the specific "dials" on the game engine that are tuned to achieve a certain feel. The primary dials are the nature of Consequences, the availability of healing and recovery, and the style of character advancement. The three settings in this document give 3 points in design space that nicely map out the span of what we are interested in acheving with this game at the current point.

## A Unified Theory of Harm

Our design approach is to first model a harsh, baseline reality grounded in our verisimilitude research. From there, we strategically introduce heroic elements—primarily supernatural and magical tools—to mitigate the harshest aspects of that reality.

This means the **"Grim Simulationist"** setting described below is not just one option; it is the physical "source code" of the game system. The **"Grounded Heroism"** setting uses the same physics but gives players unique tools to overcome them. This makes heroism feel more meaningful because the dangers are verifiably real, not toned down for the players' benefit.

## Independent Variable: Power Level

A campaign's **Power Level** is a separate dial from its tonal setting. It defines the overall scope and scale of the characters, the magnitude of challenges they face, and the **advancement ceiling** of card numbers:

- **Numerical Advancement as a Setting Dial:** In _caRdPG_, character advancement is driven by the **numerical scaling of cards** (upgrading card color values, defenses, and modifiers in the 24-card deck) alongside acquiring new tactical stances and actions. The setting dial determines how far those numbers advance:
  - **Bounded / Low Power (Single Digits):** Card values stay tightly bounded in the single digits (values 1–5, peaking around 8–10). Even a +1 card upgrade represents a career milestone. Mortal biological limits remain central throughout the campaign.
  - **Heroic / High Power (Double Digits):** Characters scale steadily into double-digit card numbers (values 10–50+), allowing them to directly confront mythical beasts, colossal environmental hazards, and small garrisons.
  - **Exalted / Anime Tier (Triple Digits):** In rare, extremely high-power settings, individual hero cards can scale into triple digits (100–500+), enabling characters to act as living forces of nature capable of sundering terrain and shattering legions.
- **The Scope of Action & Scale of Threats:** A low-power character influences a village and treats a single armored knight as a lethal boss; a high-power character topples dynasties and trades blows with dragons.
- **Fractal Scope: Macro-Entity Decks (Armies, Provinces, Kingdoms):** The core engine's scale invariance means high numbers are not reserved only for mythic heroes. A deck can represent an entire **army**, a **province**, or an **empire**. Giant numbers on macro cards represent the coordinated manpower, pooled wealth, and collective logistics of thousands of people. Mass warfare and geopolitical campaigns resolve using the exact same Crisis Time and General Action mechanics as a tavern skirmish, providing smooth abstracted resolution at any narrative scale.

---

## Setting 1: Grim Simulationist

- **Core Concept & Inspirations:** Models the harsh realities of a pre-modern world where survival is the primary victory. Adheres strictly to the findings of our research documents (`physical-harm-and-trauma.md`, etc.).
- **Inspirations:** _Darkest Dungeon_, _Torchbearer_, The Black Company Series, Berserk, Alien (1979). _Thematic Intent: To capture a tone of costly attrition and psychological toll, where protagonists are often worn down by their struggles rather than purely empowered._
- **Narrative Focus:** Survival, attrition, the high cost of violence. A "successful" character is one who lives to retire, often permanently scarred.
- **Tuning the Dials:**
  - **Consequences:** Severe and often permanent. The default Consequence Deck is used, featuring `Condition Cards` like `Compound Fracture` or `Sepsis`. The full, terrifying text on the "Prognosis Side" of Layered Condition cards is the norm.
  - **Healing & Recovery:** Mundane healing is slow, risky, and often incomplete. Magic, if it exists, is more often a source of dangerous complications than a "problem solver". A poorly-set bone could result in a permanent `Limp` Condition.
  - **Advancement (Non-Monotonic Progression):** Characters grow, but this growth is not a simple upward climb. They gain new skills and experience from their trials, but they also accumulate the permanent costs of a harsh life. Advancement involves trade-offs, where characters might gain a new `Action Card` and incrementally higher card numbers (within a tight, bounded single-digit band), but also acquire a permanent, negative `Condition Card` like `Old War Wound` or `Lingering Trauma`. A character's story is one of change, not just improvement.

---

## Setting 2: Grounded Heroism (Default)

- **Core Concept & Inspirations:** The game's intended default experience. Balances gritty reality with heroic fantasy, where characters are defined by their ability to overcome otherwise insurmountable odds.
- **Inspirations:** The Lord of the Rings, _The Witcher_, _A Song of Ice and Fire_, Samurai Cinema, Blades in the Dark. _Thematic Intent: To model a heroism defined by perseverance. The protagonists are exceptional, but their victories are earned through enduring tangible costs and consequences._
- **Narrative Focus:** Earned victories, perseverance, facing meaningful consequences. A grievous wound isn't just a penalty; it can become the central plot of an entire side quest, making the eventual hard-won recovery feel all the sweeter.
- **Tuning the Dials:**
  - **Consequences:** The same harsh Consequence Deck as the Grim Simulationist setting is used. However, players have access to heroic tools to manage these outcomes.
  - **Healing & Recovery:** Magical healing and supernatural abilities exist. These are the primary tools that differentiate this setting. A spell might interact with an `Injury` keyword on a `Condition Card` to remove it, bypassing the complex and dangerous mundane treatment detailed on its "Prognosis Side." Healing is still costly but it makes recovery from dire wounds possible. The cost of healing is a shared burden. While a healer expends cards (and potentially other costs) to power a magical effect, the recipient's body must still endure the taxing process of accelerated mending. This is typically modeled by converting the removed `Wound` or `Injury` into a number of `Fatigue` cards added to their expended pile. This ensures that even with magical aid, recovery has a tangible cost and prevents a single hero from being propped up by an army of healers to bypass intended downtime.
  - **Advancement (Largely Monotonic Progression):** Characters are heroes on an upward trajectory. They consistently grow more powerful and capable as the campaign progresses, upgrading their cards numerically into higher double-digit tiers, learning specialized master stances, and refining deck synergy. While they may suffer significant setbacks from consequences, these are generally confined to the scope of a single story arc and are not expected to be permanent. The default path is one of increasing heroic stature, allowing characters to face ever-greater challenges.

---

## Setting 3: Kid-Friendly Adventure

- **Core Concept & Inspirations:** A lighter, whimsical tone suitable for all ages. The focus is on creative problem-solving and personal growth without the grim realities of violence.
- **Inspirations:** _Avatar: The Last Airbender_, Studio Ghibli films, Might and Magic Series, The Hobbit, The Chronicles of Narnia _Thematic Intent: To provide models for non-lethal conflict and character advancement centered on friendship and learning new skills, rather than overcoming violent threats._
- **Narrative Focus:** Friendship, learning, helping others. "Defeat" is a temporary, low-stakes setback that provides a lesson for the future.
- **Tuning the Dials:**
  - **Consequences:** Consequences are framed as temporary tactical disadvantages, not lasting harm. The focus is on creating a clear, immediate, and solvable problem. The Consequence Deck is custom-built with cards that have direct, mechanical names reflecting their in-game effect. Examples include `Degrade Attack`, `Degrade Defense`, `Staggered`, or `Pinned Down`. These are treated as `Condition Cards` that impose a simple penalty for the duration of the current crisis and are removed automatically when the scene ends.
  - **Healing & Recovery:** `Fatigue` is the primary representation of attrition. Characters recover fully between scenes; a short rest is all that's needed to remove all `Fatigue` cards and reset for the next challenge. Long-term attrition is not a factor.
  - **Advancement:** Progression is positive and straightforward. Characters gain new, exciting abilities and their card numbers scale upward reliably. There are no permanent negative trade-offs.
  - **Magic & The Supernatural:** Magic is wondrous and a primary tool for creative problem-solving. Its costs are minimal, encouraging frequent and inventive use.
