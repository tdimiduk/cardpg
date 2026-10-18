---
title: "Design Proposal: Carrying Capacity, Load, and Pack Architecture"
doc_type: iteration
track: ludology
origin: Collaborative
epistemic_status:
  confidence: high
  vetted_by_human: false
  vetting_notes: "Settled carrying capacity module architecture: Unified Worn Load for armor, single unified Zero-Indexed Burden formula, and bounded Frame & Physique (12/15/18) anchored at character creation."
related_files:
  - "design/rules/core-rules.md"
  - "design/iteration/carrying-capacity-benchmarks.md"
  - "design/authoring/advancement-and-progression.md"
  - "design/research/synthesis/load-carriage-and-pack-biomechanics.md"
  - "design/research/synthesis/armor.md"
  - "design/research/synthesis/hardship-and-exertion.md"
  - "design/research/synthesis/consequences-logistics.md"
  - "design/research/theory/readings/exploration-is-logistics.md"
  - "design/research/theory/readings/calibrating-your-expectations.md"
---

# Design Proposal: Carrying Capacity, Load, and Pack Architecture

This document outlines the core architecture for the **Carrying Capacity & Logistics Module** in _caRdPG_. It introduces a physics-grounded model for item encumbrance (`Weight` and `Awkwardness` compiling into `Load`), a character scaling model (**Bounded `Frame & Physique`** determining `Load Increment`), a unified **`Worn Load`** model for armor, and a Fatigue Cycle rule (**`Averaged Burden`**) that rewards realistic tactical choices—like dropping packs in combat—without enabling timing exploits.

> [!NOTE]
> **Module Scope ("Digital Tools Encouraged"):** Near-term playtesting targets the _caRdPG_ VTT, which computes container transformations, deck-derived `Load Increment`, and weighted-average `Burden` automatically. To preserve physical table playability, every item card also carries a pre-computed **`Default Load`** ($W + A$), and `Burden` maps directly to physical **Load Rows** of cards on the table.

---

## 1. Item Primitives: `Weight`, `Awkwardness`, and `Load`

Single-number encumbrance systems (such as PF2e's `Bulk`) struggle when players interact with physical reality because they conflate **gravitational mass** with **geometric unwieldiness** before containers are applied. A 10-foot pole and a sack of coins may feel equally taxing in bare hands, but they behave completely differently when stuffed into a backpack, lashed to a frame, or loaded onto a cart.

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

Containers, pack frames, and vehicles act as transformation functions over $(W, A)$ for the items stored within them (subject to the container's capacity and accepted Form Tags):

$$L_{\text{container}} = W_{\text{container}} + A_{\text{container}} + \sum_{i \in \text{contents}} \left( m_W \cdot W_i + m_A \cdot A_i \right)$$

| Storage / Transport Method        | Accepted Forms                                |            Awkwardness Multiplier ($m_A$)            |  Weight Multiplier ($m_W$)   | Tactical & Physical Constraints                                                                                                                                  |
| :-------------------------------- | :-------------------------------------------- | :--------------------------------------------------: | :--------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Bare Hands / Unrigged**         | Any                                           |                        $1.0$                         |            $1.0$             | Occupies 1–2 hands; must be dropped to fight two-handed. Extreme lumbar counter-moment ($>3.9\times$ mass in disc compression, Liu 2023).                        |
| **Belt Pouch / Scabbard**         | `[Compact]` / 1 Weapon                        |                        $0.0$                         |            $1.0$             | Keeps items immediately accessible in Crisis Time; strict slot limit.                                                                                            |
| **Sack / Wooden Chest**           | `[Compact]`, `[Packable]`                     |                   $0.0$ (contents)                   |            $1.0$             | Eliminates internal $A$, but the sack/chest itself has high $A_{\text{container}}$ unless lashed to a frame or cart.                                             |
| **Shoulder Backpack**             | `[Compact]`, `[Packable]`                     |                        $0.0$                         |            $1.0$             | Frees hands; 100% of vertical force passes through spine/clavicles ($+10\%\text{–}15\%$ metabolic penalty vs. framed pack). Retrieving items requires an action. |
| **Roman _Furca_ / Shield Rig**    | `[Compact]`, `[Packable]`                     |                        $0.0$                         |          **$0.85$**          | Crossbar pack propped on back-slung shield. Occupies 1 hand on the march, but enables **instant free jettison** (2 seconds) at the start of Crisis Time.         |
| **External Pack Frame (_Kraxe_)** | `[Compact]`, `[Packable]` + 2 lashed `[Long]` |       $0.0$ (packable)<br>$0.3$ (lashed long)        |      **$0.75 – 0.80$**       | Transfers 40–50% of vertical force from shoulders to iliac crest/pelvis. Imposes $+1$ combat `Burden` if kept on during melee.                                   |
| **Wheelbarrow / Handcart**        | Any                                           |                        $0.0$                         |      **$0.25 – 0.35$**       | Occupies both hands; unusable on stairs, narrow ledges, deep mud, or boulder scree.                                                                              |
| **Magic: _Weightless Chest_**     | `[Compact]`, `[Packable]`                     | $0.0$ (contents), retains $A_{\text{container}}=5.0$ |          **$0.05$**          | Almost weightless internally, but remains a rigid 4-foot trunk that must be physically steered through tight passages.                                           |
| **Magic: _Dimensional Satchel_**  | Items fitting aperture                        |                        $0.0$                         | **$0.0$** (fixed bag weight) | `[Long / Rigid]` items exceeding the bag mouth cannot enter; un-sheathed sharp items risk rupturing the interior.                                                |

---

### Armor: Unified `Worn Load` ($L_{\text{worn}}$)

Wearing armor functions as a specialized body-worn suspension mode with a calibrated **`Worn Load` ($L_{\text{worn}}$)** on the exact same numerical `Load` scale as carried cargo (see [`carrying-capacity-benchmarks.md`](file:///home/tdimiduk/cardpg/cardpg/design/iteration/carrying-capacity-benchmarks.md) for full stress-test comparisons):

- **No Double Taxing:** Because empirical metabolic multipliers for armor ([`armor.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/armor.md)) already include the armor's gravitational mass, armor does not impose a separate `Intrinsic Burden` on top of its `Load`.
- **No Stowing Paradox:** Because worn armor contributes its calibrated $L_{\text{worn}}$ to `Total Load`, taking off a gambeson, maille shirt, or standard harness and stowing it in a framed pack ($m_W = 0.75$) never increases your `Burden`.

| Armor Tier                                | Mass $W$ (kg) | Unrigged $A$ | Worn Load ($L_{\text{worn}}$) | Stowed Load (Framed Pack, $m_W=0.75$) | Biomechanical Basis & Tactical Function ([`armor.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/armor.md))                                                                                                                                                                                                                               |
| :---------------------------------------- | :-----------: | :----------: | :---------------------------: | :-----------------------------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Padded Doublet (Gambeson)**             |      4.0      |     2.0      |            **4.0**            |                **3.0**                | Quilted linen/wool layers. Worn mass rests comfortably on torso ($L=4$). Stowing it in a framed pack yields $3\text{ Load}$, cooling the body on long road marches.                                                                                                                                                                                          |
| **Maille Hauberk (over Gambeson)**        |     16.0      |     6.0      |           **16.0**            |               **12.0**                | 12 kg maille + 4 kg gambeson. Draped deadweight hanging from clavicles without pelvic transfer; imposes a $1.6\times$ metabolic cost multiplier (Askew et al. 2011). $16\text{ Load}$ consumes $\approx 1$ standard increment. Stowing in a framed pack transfers weight to the hips ($12\text{ Load}$), relieving shoulder fatigue.                         |
| **Brigandine / Lamellar (over Gambeson)** |     18.0      |     5.0      |           **16.0**            |               **13.5**                | 14 kg riveted plates + 4 kg padded doublet. Although heavier in raw mass ($18\text{ kg}$) than maille, its semi-rigid plates distribute torso forces far more efficiently, earning a calibrated $L_{\text{worn}} = 16$.                                                                                                                                      |
| **Full Plate Harness (Standard Fit)**     |     32.0      |     12.0     |           **32.0**            |               **24.0**                | Articulated munition plate. While the cuirass rests on the pelvis, encumbering the distal limbs (greaves, sabatons) incurs an extreme $4\times\text{–}6\times$ metabolic penalty per kg (US Army 2008), driving walking metabolic cost to $2.2\times$ (Askew 2011). Stowing plate in a framed pack eliminates limb-swing inertia ($24\text{ Load}$ on hips). |
| **Full Plate Harness (Masterwork Fit)**   |     32.0      |     12.0     |           **22.0**            |               **24.0**                | Bespoke tailored harness. Jaquet et al. (2016) demonstrated that superior articulation and custom pelvic load paths act as an exoskeleton, reducing the metabolic multiplier to $1.7\times$. Remarkable result: **it is easier to wear a masterwork harness on the body ($22\text{ Load}$) than to haul it in a backpack ($24\text{ Load}$)!**               |

---

## 2. Character Carrying Capacity: Bounded `Frame & Physique`

A character's carried equipment and worn armor compile into a single unified value: **`Total Load`**.

Their active **`Burden`** is determined by a clean, zero-indexed division against their **`Load Increment`**:

$$\text{Burden} = \left\lfloor \frac{\text{Total Load (Worn + Carried)}}{\text{Load Increment}} \right\rfloor$$

### Physical Table Representation: "Load Rows"

To eliminate division during physical play, players organize their active item cards on the table into **Load Rows** (bundles where the sum of `Load` in each row is $\le \text{Load Increment}$):

- **Row 1 is the Unencumbered Row ($0\text{ Burden}$):** Any gear fitting within the first row incurs zero fatigue penalties.
- **Each Additional Row Adds $+1\text{ Burden}$:** Starting or completing Row 2 adds $+1\text{ Burden}$; Row 3 adds $+2\text{ Burden}$; Row 4 adds $+3\text{ Burden}$.
- Players never need to sum their entire inventory; they simply stack cards into piles equal to their `Load Increment` and count the rows beyond the first.

---

### The Capacity Formula: Bounded `Frame & Physique`

$$\text{Load Increment} = \text{Frame}_{\text{physique}} \times M_{\text{size}} \times M_{\text{posture}}$$

For a standard Medium Humanoid ($M_{\text{size}} = 1.0, M_{\text{posture}} = 1.0$), $\text{Frame}_{\text{physique}}$ is an **anatomical baseline established at character creation**, anchored to the character's starting physical build:

| Physique Archetype            |                           Starting Deck Criteria                            | $\text{Frame}_{\text{physique}}$ (Load Increment) | Human Anatomical & Biomechanical Basis ([`load-carriage-and-pack-biomechanics.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/load-carriage-and-pack-biomechanics.md))                                                        |
| :---------------------------- | :-------------------------------------------------------------------------: | :-----------------------------------------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Slight / Unconditioned**    |    Starting $\sum \text{Red} \le 48$<br>($\approx 16\%\text{–}22\%$ Red)    |                    **12 Load**                    | Slight adult frame ($50\text{–}60\text{ kg}$ body mass, $36\text{–}42\text{ kg}$ lean body mass). 12 kg represents $20\%\text{ BM}$ aerobic capacity.                                                                                            |
| **Standard / Fit Adventurer** | Starting $\sum \text{Red} \in [49, 84]$<br>($\approx 25\%\text{–}38\%$ Red) |                    **15 Load**                    | Standard conditioned adult ($70\text{–}80\text{ kg}$ body mass, $55\text{–}62\text{ kg}$ lean body mass). 15 kg represents the classic $20\%\text{ BM}$ military fighting load.                                                                  |
| **Brawny / Heavy Vanguard**   |         Starting $\sum \text{Red} \ge 85$<br>($\approx 40\%+$ Red)          |                    **18 Load**                    | Heavy strength-endurance athlete ($85\text{–}95\text{ kg}$ body mass, $70\text{–}75\text{ kg}$ lean body mass). High aerobic capacity ($\dot{V}\text{O}_{2\max} > 4.5\text{ L/min}$). Can reach **20 Load** with a dedicated _Strongback_ trait. |

#### Anatomical Multipliers ($M_{\text{size}}$, $M_{\text{posture}}$)

- **$M_{\text{size}}$ (Size & Skeletal Mass):**
  - _Small (Halfling, Goblin, ~38 kg):_ $\times 0.60 \implies \mathbf{9\text{ Load}}$ (Slight 7.2 / Fit 9.0).
  - _Medium (Human, Elf, Dwarf):_ $\times 1.00$ (Dwarves have a racial trait granting $\text{Frame} = 18\text{–}20$ due to heavy bone density).
  - _Large (Ogre, Troll, ~280 kg):_ $\times 3.00 \implies \mathbf{45\text{ to }54\text{ Load}}$.
- **$M_{\text{posture}}$ (Skeletal Suspension):**
  - _Biped:_ $\times 1.00$.
  - _Equine Quadruped (Pony, Riding Horse):_ $\times 1.33\text{ to }\times 1.50$ (horizontal spine; aerobic limit capped at $15\%\text{–}20\%\text{ BWR}$; $\mathbf{36\text{ Load}}$ for pony, $\mathbf{72\text{ Load}}$ for warhorse).
  - _Pack Beast (Donkey, Mule):_ $\times 2.00$ (straight back, low withers, upright hooves; $\mathbf{36\text{ Load}}$ for 130 kg donkey, $\mathbf{75\text{ Load}}$ for 380 kg mule).

---

### Why `Load Increment` Does Not Auto-Scale with Card Tier

`Load Increment` is intentionally bounded to the character's physical frame rather than continuously inflating as card values scale across tiers (see [`carrying-capacity-benchmarks.md`](file:///home/tdimiduk/cardpg/cardpg/design/iteration/carrying-capacity-benchmarks.md#L197-L337) for the comparative stress-tests of dynamic scaling models):

1. **Empirical Invariance of Walking Mechanics:**
   Peer-reviewed exercise physiology ([`load-carriage-and-pack-biomechanics.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/load-carriage-and-pack-biomechanics.md#L91-L106); [Looney et al. 2022](file:///home/tdimiduk/cardpg/cardpg/design/research/sources/verisimilitude/looney-2022-modeling-metabolic-costs-backpacking/extracted.md)) demonstrates that human walking mechanical efficiency is invariant with training (~0–3% difference between an untrained recruit and an elite veteran). Carrying a 30 kg load requires the exact same gravitational work and oxygen volume per step. Training increases an individual's aerobic ceiling by only $+10\%\text{–}20\%$ and lean muscle mass by $+2\%\text{–}5\%$ (Harman et al. 2008; Knapik et al. 2012), taking a novice into "trail shape" (+15%–25% capacity gain), after which human skeletal capacity permanently plateaus.
2. **Preserving Armor Tradeoff Integrity Across Tiers:**
   Armor is designed to provide massive protective value (absorbing impact and deflecting consequences), balanced by the physical cost of `Burden` and [[Fatigue]]. Keeping human `Load Increment` bounded in the $12\text{–}18$ ($20$ max) envelope ensures high-tier warriors never out-scale Full Plate Harness ($32\text{ Load}$) or Maille ($16\text{ Load}$) into **Burden 0**. High-tier characters overcome physical challenges more easily because their cards have higher `Red` values when flipped—not because steel armor stops weighing 32 kg.
3. **Preventing Perverse Deck Advancement Incentives:**
   Deriving `Load Increment` from dynamic card color ratios would cause upgrading a Yellow finesse card or Blue tactical card on a fighter to inadvertently _decrease_ their carrying capacity by lowering their Red ratio. Conversely, continuous sub-linear scaling would allow a frail scholar to close the carrying gap with a knight simply by leveling up arcane cards. Fixing `Frame & Physique` at creation keeps logistics tactile, stable, and immune to mathematical exploitation.

> [!TIP]
> **Advancement in Logistics:** Progression does not make heavy sacks of flour weigh less. Instead, seasoned adventurers advance logistically by:
>
> - Upgrading from an unconditioned frame to trail shape via a one-time milestone (**Trail Conditioning:** `12 -> 15` or `15 -> 18`).
> - Commissioning **Masterwork Armor** (reducing worn plate from $32\text{ Load}$ to $22\text{ Load}$).
> - Adopting **Pack Frames** ($m_W = 0.75$), **Pack Animals** (Mule increment = $75$), and **Wagons** ($m_W = 0.25$).
> - Unlocking explicit supernatural gifts in mythic campaigns (e.g., _Titan's Shoulders: Double Frame_).

---

### The Armor + Weapon Loadout Matrix

The table below illustrates how different armor suites combined with standard weapons ($3\text{–}5\text{ kg}$) compile into `Load` and `Burden` across the three human frames:

| Equipment Suite                                                                      | Total Load (Worn + Weapons) |        Slight Frame (`Inc 12`)         |       Standard Frame (`Inc 15`)        |         Brawny Frame (`Inc 18`)         | Tactical Reality & Headroom Analysis                                                                                                                                                                                                                                      |
| :----------------------------------------------------------------------------------- | :-------------------------: | :------------------------------------: | :------------------------------------: | :-------------------------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Light Scout / Unarmored**<br>(Robes/Clothing + Dagger + Staff/Bow)                 |        **5.0 Load**         |   **Burden 0**<br>_(7 kg headroom)_    |   **Burden 0**<br>_(10 kg headroom)_   |   **Burden 0**<br>_(13 kg headroom)_    | Completely unencumbered fighting stance. All three frames have ample room for daypacks or loot.                                                                                                                                                                           |
| **Padded Gambeson + Weapons**<br>(Gambeson 4 + Arming Sword 1.2 + Shield 3)          |        **8.2 Load**         |  **Burden 0**<br>_(3.8 kg headroom)_   |  **Burden 0**<br>_(6.8 kg headroom)_   |   **Burden 0**<br>_(9.8 kg headroom)_   | Standard light infantry skirmish loadout. Clean zero-burden mobility.                                                                                                                                                                                                     |
| **Maille Hauberk + Weapons**<br>(Maille 16 + Sword 1.2 + Shield 3.0)                 |        **20.2 Load**        | **Burden 1**<br>_(3.8 kg to Burden 2)_ | **Burden 1**<br>_(9.8 kg to Burden 2)_ | **Burden 1**<br>_(15.8 kg to Burden 2)_ | **Universal Burden 1:** Maille's draped mass imposes 1 Burden across all three frames. However, the Brawny warrior has nearly $16\text{ kg}$ of spare capacity for gear before taking another Burden, while the Slight frame takes Burden 2 after picking up a waterskin! |
| **Full Plate (Standard) + Weapons**<br>(Plate 32 + Longsword 1.5 + Poleaxe 5.0)      |        **38.5 Load**        |   **Burden 3**<br>_(Severe strain)_    | **Burden 2**<br>_(6.5 kg to Burden 3)_ | **Burden 2**<br>_(15.5 kg to Burden 3)_ | Severe physical tax. Standard warriors fight at Burden 2; an unconditioned human collapses under Burden 3.                                                                                                                                                                |
| **Full Plate (Masterwork) + Weapons**<br>(Masterwork Plate 22 + Longsword + Poleaxe) |        **28.5 Load**        | **Burden 2**<br>_(7.5 kg to Burden 3)_ | **Burden 1**<br>_(1.5 kg to Burden 2)_ | **Burden 1**<br>_(7.5 kg to Burden 2)_  | **The Masterwork Payoff:** Superior articulation drops the fighting state for Standard and Brawny warriors to **Burden 1**, matching a maille hauberk!                                                                                                                    |

---

## 3. "Spend Averaged Burden" & Dropping Packs in Combat

In _caRdPG_, a character's active `Burden` at any moment is calculated directly from their live `Total Load`:

$$\text{Active Burden} = \left\lfloor \frac{\text{Total Load}}{\text{Load Increment}} \right\rfloor$$

### The Timing Problem

If `Burden` only checked the character's state at the exact instant a [[Fatigue Cycle]] triggered (when the draw pile emptied), players would haul 50 kg backpacks through 22 cards of their deck, drop their packs on Round 1 of an ambush, reshuffle at Burden 0, and pick the packs back up afterward—laundering hours of heavy marching exertion.

Conversely, in real life (and authentic tactical doctrine), **dropping your rucksack at the start of an ambush is smart and necessary**, and the rules must reward it honestly.

### The Rule: Card-Weighted Averaged Burden

Whenever a [[Fatigue Cycle]] triggers, the extra [[Fatigue]] cards added to the deck equal the character's **weighted average `Burden` across the cards expended during that cycle** (rounded to the nearest whole number):

$$\text{Fatigue Added} = 2 + \text{round}\left( \frac{\sum_{c \in \text{Expended}} \text{Burden}(c)}{N_{\text{Expended}}} \right)$$

- **VTT Implementation:** Each time a card moves into the Expended Pile (from hourly [[Vigilance]] flushes, [[General Actions]], or Crisis rounds), the VTT tags the card with the character's active `Burden` and displays the live running average on the deck HUD.
- **Physical Table Heuristic:** The table uses a simple proportional eyeball:
  - _"You marched through roughly three-quarters of your deck with your heavy approach pack (Burden 2) before dropping it for this skirmish (Burden 1)—take Burden 2 on this reshuffle. If the fight lasts long enough to force a second reshuffle, you'll be at Burden 1."_

### Tactical Dynamics of Dropping a Pack in Crisis Time

1. **Immediate Value of Shedding Load:** Dropping your pack lowers the active `Burden` tagged onto every card played or flipped for the rest of the fight, eliminates framed pack awkwardness penalties, and prevents the $+1$ combat Burden penalty of external pack frames.
2. **Unstrapping Cost vs. Quick-Release Rigging:**
   - Shedding a standard shoulder backpack or heavy framed pack during Crisis Time requires **discarding 1 card from hand** (or using a minor action) to unbuckle and shrug off the straps.
   - Equipping a **Quick-Release Buckle** (or carrying a Roman-style _furca_ pole) allows **instant free jettison (0 cards / 2 seconds)** at the start of Round 1.
3. **Battlefield Vulnerability:** A dropped pack remains on the ground where it was shed. If the party is forced into a fighting retreat, knocked back, or driven out of the chamber, their sustainment supplies and loot are left behind enemy lines.

---

## 4. Open Questions & Next Steps

With item primitives (`Weight`, `Awkwardness`, `Form Tag`), container transformations, unified `Worn Load` for armor, bounded `Frame & Physique` (`12 / 15 / 18`), and `Averaged Burden` settled and benchmarked in [`carrying-capacity-benchmarks.md`](file:///home/tdimiduk/cardpg/cardpg/design/iteration/carrying-capacity-benchmarks.md), three concrete items remain for the next design and implementation passes:

### 1. Low-Vigilance Travel (`Vigilance 0`) & Overland March Attrition

- **The Current Gap:** In [`core-rules.md`](file:///home/tdimiduk/cardpg/cardpg/design/rules/core-rules.md#L92-L95), paying for `Vigilance 0` (marching at ease) expends $0$ cards per hour. Consequently, an encumbered or heavily armored character (`Burden >= 1`) traveling at `Vigilance 0` never depletes their deck and never triggers a `Fatigue Cycle`.
- **Empirical Anchors ([`hardship-and-exertion.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/hardship-and-exertion.md#L43-L48)):** Heavy load carriage burns $500\text{–}800\text{ kcal/hr}$, depleting intramuscular glycogen within $2\text{–}3\text{ hours}$ ("bonking") without carbohydrate intake, and multi-day human endurance is bounded by the $2.5\times\text{ BMR}$ alimentary ceiling ($\approx 4,500\text{ kcal/day}$). Additionally, prolonged loaded marching degrades prefrontal executive vigilance (`drain-2023`).
- **Design Question:** Should overland marching require a base hourly card expenditure (or periodic March `General Action` check), or should carrying `Burden >= 1` impose a minimum hourly card drain (e.g., discarding cards equal to `Burden` or a minimum of $1\text{–}2$ cards/hr) even when traveling at `Vigilance 0`?

### 2. High Overload Thresholds (`Burden >= 3`), Pace Degradation & Strain Consequences

- **Empirical Anchors ([`load-carriage-and-pack-biomechanics.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/load-carriage-and-pack-biomechanics.md#L43-L50)):**
  - At $44\%\text{ BM}$ (`Burden 2–3`, $32\text{–}40\text{ kg}$), maximum aerobic walking speed drops $\approx 15\%$.
  - At $66\%\text{ BM}$ (`Burden 3–4`, $45\text{–}53\text{ kg}$), maximum walking speed drops $\approx 25\%$, and shear forces rapidly accelerate friction blisters and lumbar/tibial overuse microtrauma ([`hardship-and-exertion.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/hardship-and-exertion.md#L85-L95)).
  - Above $75\%\text{ BM}$ (`Burden 4+`, $>58\text{ kg}$), human pendular gait breaks down completely.
- **Design Question:** Beyond adding extra [[Fatigue]] cards on reshuffle, how should `Burden 3+` affect overland travel pace, in-combat movement/defense, exposure to overuse consequences (blisters, sprains, stress fractures), and what is the hard ceiling (e.g., `Burden 4` / $< 5\times\text{Load Increment}$) beyond which sustained movement is impossible?

### 3. VTT Data Model & HUD Integration

- **Item & Container Schema:** Represent item `(weightKg, awkwardness, formTag, maybeWornLoad)` and container transformation rules `(emptyWeight, emptyAwkwardness, acceptedForms, capacityLimit, weightMult, awkwardnessMult, jettisonCost)` in the Haskell domain model.
- **Deck HUD & Expended Pile Tracking:** Tag each card moving to the Expended Pile with `expendedAtBurden :: Int` so the VTT can display live `Active Burden`, live `Averaged Burden` for the current cycle, and one-click **Drop Pack** state transitions at the start of Crisis Time.
