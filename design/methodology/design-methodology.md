# Design Methodology

## Document Purpose

This is a designer-facing document intended for internal use.

Its purpose is to define the high-level principles for how we structure the game's design and organize the project's content. It provides a shared architectural framework to ensure consistency and maintain focus on our core design goals.

---

## Core vs. Modular Design

To maintain the project's focus on "Mechanical Elegance" and "Modular Design", we use the Pillars of Play as a key metric for organizing the ruleset. This distinction guides what belongs in the core rulebook versus an optional module.

* A mechanic is considered **core** if its removal would fundamentally break or diminish one of the established Pillars of Play (Combat, Exploration, Social, Downtime). The `General Action` system, for example, is core to all pillars, while the `Crisis Time` system is core to the Combat pillar.
* A mechanic is a candidate for a **module** if it adds an optional, self-contained layer of depth or flavor to a pillar that already functions without it (e.g., `Snap Checks` for Exploration).
