---
title: "Design Proposal: Carrying Capacity, Load, and Pack Architecture"
doc_type: iteration
track: ludology
origin: Collaborative
epistemic_status:
  confidence: medium
  vetted_by_human: false
  vetting_notes: "Initial high-level design proposal for carrying capacity module (Load = Weight + Awkwardness, Frame + Conditioning Load Increment, and Averaged Burden)."
related_files:
  - "design/rules/core-rules.md"
  - "design/authoring/advancement-and-progression.md"
  - "design/research/synthesis/load-carriage-and-pack-biomechanics.md"
  - "design/research/synthesis/armor.md"
  - "design/research/synthesis/hardship-and-exertion.md"
  - "design/research/synthesis/consequences-logistics.md"
  - "design/research/theory/readings/exploration-is-logistics.md"
  - "design/research/theory/readings/calibrating-your-expectations.md"
---

# Design Proposal: Carrying Capacity, Load, and Pack Architecture

This document outlines a high-level design for an optional **Carrying Capacity & Logistics Module** in _caRdPG_. It introduces a physics-grounded model for item encumbrance (`Weight` and `Awkwardness` compiling into `Load`), a character scaling model (`Frame + Conditioning` determining `Load Increment`), and a Fatigue Cycle rule (`Averaged Burden`) that rewards realistic tactical choices—like dropping packs in combat—without enabling timing exploits.

> [!NOTE]
> **Module Scope ("Digital Tools Encouraged"):** Near-term playtesting targets the _caRdPG_ VTT, which can compute container transformations, deck-derived `Load Increment`, and weighted-average `Burden` automatically. To preserve physical table playability, every item card also carries a pre-computed **`Default Load`** ($W + A$), and `Averaged Burden` can be quickly eyeballed by the table.

---

## 1. Item Primitives: `Weight`, `Awkwardness`, and `Load`

Single-number encumbrance systems (like PF2e's `Bulk`) struggle when players interact with physical reality because they conflate **gravitational mass** with **geometric unwieldiness** before containers are applied. A 10-foot pole and a sack of coins may feel equally taxing in bare hands, but they behave completely differently when stuffed into a backpack or loaded onto a cart.

Every physical item is defined by two underlying primitives and a Form Tag:

1. **`Weight` ($W$):** Raw physical mass (calibrated in kilograms, where $1\text{ unit} \approx 1\text{ kg}$). Governs skeletal axial load and structural weight limits (rope tensile strength, weak floorboards, wagon axles).
2. **`Awkwardness` ($A$):** The ergonomic and rotational-inertia penalty of carrying the object _unrigged_ (in bare hands, tucked under an arm, or draped loosely), driven by length, volume, sloshing, or poor grip.
3. **`Form Tag`:** Categorizes how the object interacts with storage and rigging:
   - **`[Compact]`:** Coins, rations, vials, caltrops, small tools. High $A$ if held loose in hands; $A$ drops to $0$ inside any pouch, sack, or pack.
   - **`[Packable]`:** Bedrolls, coiled rope, lanterns, cookpots, grapples. Moderate $A$ when slung loosely; $A$ drops to $0$ inside a backpack or chest.
   - **`[Long / Rigid]`:** 10-foot poles, pikes, greatswords, shovels, ladders, tower shields. High $A$ due to rotational inertia and snagging. **Cannot fit inside soft sacks or standard backpacks**; requires scabbards, external frame lashings, or hand carriage.
   - **`[Worn]`:** Clothing, harnesses, boots, armor. Worn directly on the body rather than stowed in containers.

### Baseline Formula (`Default Load`)

When an item is carried raw without specialized containment or rigging, its effective **`Load` ($L$)** is a simple sum printed directly on the card:

$$L_{\text{default}} = W + A$$

### Container, Rigging, and Transport Transformations

Containers, pack frames, and vehicles act as functions over $(W, A)$ for the items stored within them (subject to the container's capacity and accepted Form Tags):

$$L_{\text{container}} = W_{\text{container}} + A_{\text{container}} + \sum_{i \in \text{contents}} \left( m_W \cdot W_i + m_A \cdot A_i \right)$$

| Storage / Transport Method                   | Accepted Forms                                  |             Awkwardness Multiplier ($m_A$)             |  Weight Multiplier ($m_W$)   | Tactical & Physical Constraints                                                                                                                          |
| :------------------------------------------- | :---------------------------------------------- | :----------------------------------------------------: | :--------------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Bare Hands / Unrigged**                    | Any                                             |                         $1.0$                          |            $1.0$             | Occupies 1–2 hands; must be dropped to fight two-handed.                                                                                                 |
| **Belt Pouch / Scabbard**                    | `[Compact]` / 1 Weapon                          |                         $0.0$                          |            $1.0$             | Keeps items immediately accessible in Crisis Time; strict slot limit.                                                                                    |
| **Sack / Wooden Chest**                      | `[Compact]`, `[Packable]`                       |                    $0.0$ (contents)                    |            $1.0$             | Eliminates internal $A$, but the sack/chest itself has high $A_{\text{container}}$ unless lashed to a frame or cart.                                     |
| **Shoulder Backpack**                        | `[Compact]`, `[Packable]`                       |                         $0.0$                          |            $1.0$             | Frees hands; retrieving stowed items in Crisis Time requires an action/tempo cost.                                                                       |
| **Roman _Furca_ / Shield-Balanced Pole**     | `[Compact]`, `[Packable]`                       |                         $0.0$                          |          **$0.85$**          | Crossbar pack propped on back-slung shield. Occupies 1 hand on the march, but enables **instant free jettison** (2 seconds) at the start of Crisis Time. |
| **External Pack Frame (_Kraxe_ / Hip-Belt)** | `[Compact]`, `[Packable]` + 1–2 lashed `[Long]` |        $0.0$ (packable)<br>$0.3$ (lashed long)         |      **$0.75 – 0.80$**       | Transfers 30–50%+ of vertical force from shoulders to the iliac crest/pelvis. Imposes $+1$ combat `Burden` if kept on during melee.                      |
| **Wheelbarrow / Handcart**                   | Any                                             |                         $0.0$                          |      **$0.25 – 0.35$**       | Occupies both hands; unusable on stairs, narrow ledges, deep mud, or boulder scree.                                                                      |
| **Magic: _Weightless Chest_**                | `[Compact]`, `[Packable]`                       | $0.0$ (contents), retains bulky $A_{\text{container}}$ |          **$0.05$**          | Almost weightless, but remains a rigid 4-foot trunk that must be physically maneuvered through tight passages.                                           |
| **Magic: _Dimensional Satchel_**             | Items fitting aperture                          |                         $0.0$                          | **$0.0$** (fixed bag weight) | `[Long / Rigid]` items exceeding the bag mouth cannot enter; un-sheathed sharp items risk rupturing the interior.                                        |

### Armor: Dual Interaction (`Burden` + `Load`)

Armor interacts with **both** the `Burden` and `Load` systems to reflect two distinct physiological realities ([`armor.md`](../research/synthesis/armor.md)):

1. **Intrinsic `Burden` (Irreducible Biomechanical & Thermal Tax):** Represents distal limb-swinging penalties (greaves/gauntlets costing $1.5\times\text{–}6\times$ more energy per kg than torso weight), restricted chest expansion, and gambeson heat retention. Even the strongest warrior pays this cost.
2. **Armor `Load` (Axial Mass on the Skeleton):** Represents the raw $15\text{–}40\text{ kg}$ resting on the wearer's spine, hips, and knees.
   - A high-capacity warrior absorbs the armor's `Load` comfortably within their first `Load Increment` with room to spare for gear.
   - A low-capacity character wearing the same harness consumes their `Load Increment` immediately, meaning any additional pack weight tips them into extra `Burden`.
   - **Masterwork Fit:** Reduces the armor's **intrinsic `Burden` / `Awkwardness`** via superior articulation and pelvic weight distribution, while its physical **`Weight`** remains unchanged.

---

## 2. Character Carrying Capacity: `Frame + Conditioning`

A character's **`Load Increment`** is the amount of carried `Load` they can support per point of **`Load Burden`**:

$$\text{Load Burden} = \left\lfloor \frac{\text{Total Carried Load}}{\text{Load Increment}} \right\rfloor$$

_(Or, depending on playtest calibration, the first `Load Increment` represents unencumbered carrying capacity at $+0\text{ Burden}$, with each full or partial increment beyond the first adding $+1\text{ Burden}$.)_

### Physical Table Representation: "Load Rows"

To avoid arithmetic division when playing with physical item cards at the table, players can organize their carried item cards into **Load Rows** (bundles where the sum of `Load` in each row is $\le \text{Load Increment}$):

- Each started or completed row visually represents **1 Increment of Load** ($+1\text{ Burden}$).
- Players never need to sum their entire inventory and divide; they simply group item cards into stacks of their `Load Increment` and count the stacks.

### Why Pure `Sum of Red` Needs a Frame Anchor

In _caRdPG_, a character's physical power and endurance are represented by the **Red** values printed across their 24-card deck. However, because _caRdPG_ uses scale-invariant numerical progression ([`calibrating-your-expectations.md`](../research/theory/readings/calibrating-your-expectations.md)), a high-tier heroic character may have card values $5\times\text{ to }10\times$ higher than a starting novice.

If `Load Increment` scaled linearly with raw $\sum \text{Red}$, a veteran human duelist would inadvertently carry $500\text{ kg}$ of cargo like an elephant. Conversely, anatomical factors like **Body Size**, **Ancestry**, and **Quadruped Posture** affect skeletal carrying capacity independently of martial skill.

### Proposed `Frame + Conditioning` Formula

We separate **`Load Increment`** into an anatomical baseline (**`Frame`**) modified by a bounded function of the character's deck (**`Conditioning`**):

$$\text{Load Increment} = \text{Frame}_{\text{base}} \times M_{\text{size}} \times M_{\text{posture}} \times f_{\text{conditioning}}(\text{Deck})$$

#### 1. Anatomical Factors ($\text{Frame}_{\text{base}}$, $M_{\text{size}}$, $M_{\text{posture}}$)

- **$\text{Frame}_{\text{base}}$:** Standard human adult baseline ($\approx 12\text{–}15\text{ Load units / kg}$ per increment, corresponding to $15\%\text{–}20\%$ of a $75\text{ kg}$ lean body mass per [`load-carriage-and-pack-biomechanics.md`](../research/synthesis/load-carriage-and-pack-biomechanics.md)).
- **$M_{\text{size}}$ (Size / Mass Multiplier):**
  - _Small (Halfling, Goblin):_ $\times 0.6$
  - _Medium (Human, Elf, Dwarf):_ $\times 1.0$ (Dwarves or stocky ancestries may have a trait granting $\times 1.25$)
  - _Large (Ogre, Warhorse, Draft Beast):_ $\times 2.5\text{ to }\times 4.0$
- **$M_{\text{posture}}$ (Skeletal Suspension — Biped vs. Equid vs. Donkey/Mule):**
  - _Biped:_ $\times 1.0$
  - _Quadruped — Riding/Pack Horse (`[Quadruped]`):_ $\times 1.25\text{ to }\times 1.5$ relative to body mass (horses hit their aerobic ceiling at $20\%\text{ BW}$ and suffer exponential lactate and muscle microtrauma above $25\%\text{–}30\%\text{ BW}$).
  - _Quadruped — Donkey / Mule (`[Pack Beast]`):_ $\times 2.0\text{ to }\times 2.5$ relative to body mass (straight lumbar spine, low withers, and upright hooves allow sustainable carriage at $30\%\text{–}50\%\text{ BW}$). Quadrupeds also ignore stationary postural sway when loads are balanced in a pack saddle.

#### 2. Candidate Functions for $f_{\text{conditioning}}(\text{Deck})$

We have three candidate models for translating a character's 24-card deck into their conditioning multiplier:

- **Candidate A: Sub-Linear / Square-Root Red Scaling (Diminishing Skeletal Returns)**
  $$f_{\text{conditioning}} = \sqrt{\frac{\sum \text{Red}}{R_{\text{baseline}}}}$$
  Where $R_{\text{baseline}} = 72$ (24 cards at average Red $3.0$).
  - _At Tier 1:_ A frail scholar ($\sum \text{Red} = 36$) gets $0.71\times$; an average adventurer ($72$) gets $1.0\times$; a brawny vanguard ($108$) gets $1.22\times$.
  - _At Heroic Tier ($4\times$ card stats, $\sum \text{Red} = 288$):_ Capacity doubles ($2.0\times$—peak strongman/cinematic hero) rather than quadrupling.

- **Candidate B: Color Allocation Ratio (Archetype-Pure, Tier-Invariant)**
  $$f_{\text{conditioning}} = 0.5 + 1.5 \times \left(\frac{\sum \text{Red}}{\sum \text{Red} + \sum \text{Yellow} + \sum \text{Blue}}\right)$$
  - Measures _how much of your character's build is invested in Red_ (typically ranging from $15\%$ Red for a pure scholar up to $55\%$ Red for a pure powerhouse), yielding a clean **$0.72\times\text{ to }1.33\times$** human physiological range regardless of whether card numbers are single digits or triple digits.
  - Superhuman carrying capacity in high-tier games is then unlocked explicitly via **Heroic/Mythic Traits** (e.g., _Titan's Shoulders: $\times 2$ Frame_) rather than accidental number inflation.

- **Candidate C: Hybrid (Build Ratio + Tunable Campaign Power Exponent)**
  Combines Candidate B's build ratio with a campaign-configurable exponent $k \in [0, 1]$ on raw numerical progression ($k=0$ for grounded mortal anatomy, $k=0.5$ for heroic fantasy, $k=1.0$ for mythic/macro-scale entities).

---

## 3. "Spend Averaged Burden" & Dropping Packs in Combat

In _caRdPG_, a character's total active **`Burden`** at any moment is:

$$\text{Total Burden} = \text{Intrinsic Gear Burden} + \text{Load Burden}$$

### The Timing Problem

If `Burden` only checks the character's state at the exact instant a [[Fatigue Cycle]] triggers (when the draw pile empties), players are incentivized to haul massive packs through 22 cards of their deck, drop the pack on Round 1 of an ambush, reshuffle at low `Burden`, and pick the pack back up afterward—laundering hours of heavy marching exertion.

Conversely, in real life (and good tactical play), **dropping your pack at the start of a fight is smart and realistic**, and the rules should reward it honestly.

### The Rule: Card-Weighted Averaged Burden

Whenever a [[Fatigue Cycle]] triggers, the extra [[Fatigue]] cards added to the deck equal the character's **average `Burden` across the cards expended during that cycle** (rounded to the nearest whole number):

$$\text{Fatigue Added} = 2 + \text{round}\left( \frac{\sum_{c \in \text{Expended}} \text{Burden}(c)}{N_{\text{Expended}}} \right)$$

- **VTT Implementation:** Each time a card moves into the Expended Pile (from hourly [[Vigilance]] flushes, [[General Actions]], or Crisis rounds), the VTT records the character's current `Burden` at that moment and displays the live running average on the deck HUD.
- **Physical Table Heuristic:** The GM and player simply eyeball the proportion of the cycle spent under heavy load:
  - _"You marched through three-quarters of your deck with your heavy pack (Burden 3) before dropping it for this skirmish (Burden 1)—take Burden 3 on this reshuffle. If the fight goes long enough to force a second reshuffle, you'll be at Burden 1."_

### Tactical Dynamics of Dropping a Pack in Crisis Time

1. **Immediate Value of Shedding Load:** Dropping your pack at the start of Crisis Time lowers the `Burden` tagged onto every card you play or flip during the fight, and eliminates any in-combat awkwardness or movement penalties imposed by bulky frames.
2. **Unstrapping Cost vs. Quick-Release Rigging:**
   - Shedding a standard buckled backpack or shoulder-slung sack during Crisis Time is not a free 0-second thought—it requires **discarding 1 card from hand** (or using a minor action on Round 1) to unbuckle and shrug off.
   - Upgrading to a **Quick-Release Assault Pack** (or Roman-style _furca_ pole drop) allows jettisoning the pack for free when Crisis Time begins.
3. **Battlefield Vulnerability:** A dropped pack remains at the physical location where it was shed. If the party is forced into a fighting retreat, knocked back, or driven out of the room, their rations, tools, and treasure are left behind enemy lines.

---

## 4. Empirical Calibration Anchors & Open Questions

From [`load-carriage-and-pack-biomechanics.md`](../research/synthesis/load-carriage-and-pack-biomechanics.md), we have concrete biomechanical anchors for the next design pass:

1. **Human Load Brackets (LCDA Power Law, $1 + 1.96 \cdot L_{\text{Bp}}^{1.36}$):**
   - **Fighting Load ($20\%\text{–}25\%\text{ BM}$, $15\text{–}20\text{ kg}$):** $1.25\times\text{–}1.32\times$ metabolic cost.
   - **Moderate Marching Load ($30\%\text{–}35\%\text{ BM}$, $24\text{–}28\text{ kg}$):** $1.42\times\text{–}1.50\times$ metabolic cost.
   - **Heavy Approach March ($40\%\text{–}50\%\text{ BM}$, $32\text{–}40\text{ kg}$):** $1.60\times\text{–}1.75\times$ metabolic cost; max aerobic speed drops $\approx 15\%$.
   - **Emergency / Full _Sarcina_ ($60\%\text{–}66\%\text{ BM}$, $45\text{–}53\text{ kg}$):** $2.00\times\text{–}2.15\times$ metabolic cost; max speed drops $\approx 25\%$.
   - **Critical Biomechanical Overload ($>75\%\text{ BM}$, $>58\text{ kg}$):** Catastrophic gait breakdown ($>2.5\times\text{–}3.2\times$ cost).
2. **Awkwardness Multipliers (`Liu 2023`, `US Army 2008`):**
   - **Symmetric Backpack:** Linear spinal disc stress ($1.0\times$ baseline for shoulder-borne mass; $+10\%\text{–}15\%$ penalty vs. hip-belt frame).
   - **Unilateral Shoulder Sling:** $+20\%\text{–}35\%$ metabolic/spinal penalty; exponential L4–L5 shear stress.
   - **One-Handed / Unrigged Carry:** $+40\%\text{–}90\%$ metabolic penalty ($1.4\times\text{–}1.9\times$ torso cost); lumbar compressive force exceeds $3.9\times$ actual object weight, with exponential disc stress across all lumbar segments ($R^2 = 0.998$).
3. **Remaining Open Questions:**
   - **Exact Formula Selection:** Which of Candidates A, B, or C for $f_{\text{conditioning}}(\text{Deck})$ feels best across both grounded playtests and heroic progression?
   - **Low-Vigilance Travel Floor:** In [`core-rules.md`](../rules/core-rules.md#L92-L95), marching at `Vigilance 0` expends 0 cards per hour. Should carrying `Load Burden >= 1` (or marching in armor) impose a minimum hourly card expenditure during travel even at `Vigilance 0`?
   - **Overload Ceiling & Speed Degradation:** At `Load Burden >= 3` ($>40\%\text{ BM}$), should characters also suffer reduced travel pace or exposure to overuse consequences ([`hardship-and-exertion.md`](../research/synthesis/hardship-and-exertion.md), [`consequences-logistics.md`](../research/synthesis/consequences-logistics.md))?
