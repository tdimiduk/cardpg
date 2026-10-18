---
title: "Carrying Capacity & Logistics: Empirical Benchmarks & Formula Stress-Testing"
doc_type: iteration
track: ludology
origin: Collaborative
epistemic_status:
  confidence: medium
  vetted_by_human: false
  vetting_notes: "Empirically calibrated benchmark dataset for weapons, armor, containers, delving gear, trade goods, and pack creatures, updated to reflect settled Unified Worn Load and Bounded Frame & Physique (12/15/18) model."
related_files:
  - "design/iteration/carrying-capacity-proposal.md"
  - "design/research/synthesis/load-carriage-and-pack-biomechanics.md"
  - "design/research/synthesis/armor.md"
  - "design/research/synthesis/hardship-and-exertion.md"
  - "design/research/synthesis/consequences-logistics.md"
  - "design/research/synthesis/combat-spacing-and-reach.md"
  - "design/research/synthesis/combat-timelines-and-tempos.md"
  - "design/authoring/advancement-and-progression.md"
  - "design/research/theory/readings/calibrating-your-expectations.md"
---

# Carrying Capacity & Logistics: Empirical Benchmarks & Formula Stress-Testing

This document provides a comprehensive, empirically grounded benchmark dataset for the **Carrying Capacity & Logistics Module** outlined in [`carrying-capacity-proposal.md`](file:///home/tdimiduk/cardpg/cardpg/design/iteration/carrying-capacity-proposal.md). It compiles physical masses, geometric awkwardness values, container transformations, animal suspension limits, and archetype loadout simulations.

Its primary purpose is to calibrate and document the settled rules architecture—specifically the **Unified `Worn Load` ($L_{\text{worn}}$)** for armor, the **Bounded `Frame & Physique` (`12 / 15 / 18`)** model for carrying capacity, and the zero-indexed **`Load Rows`** mechanic—ensuring that _caRdPG_ achieves "Casual Realism" anchored to peer-reviewed biomechanical literature ([`calibrating-your-expectations.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/theory/readings/calibrating-your-expectations.md); [`load-carriage-and-pack-biomechanics.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/load-carriage-and-pack-biomechanics.md)).

---

## 1. Armor & Shields Benchmark Table

In _caRdPG_, armor encumbrance is modeled as a specialized **body-worn suspension mode** with a calibrated **`Worn Load` ($L_{\text{worn}}$)** on the exact same numerical scale as carried cargo.

This architecture unifies two earlier failed models:

1. **The "Double Tax" Model:** Imposing a separate `Intrinsic Burden` (+1 or +2) _and_ adding the armor's full mass $W$ to carried `Load`. Under this model, wearing 32 kg plate cost 2 Load Burden + 2 Intrinsic Burden = **Burden 4** before a knight even drew a weapon, making armor unrealistically crippling.
2. **The "Zero Worn Load" Model:** Treating armor _only_ as Intrinsic Burden with zero mass added to `Load`. This produced an absurd reverse paradox: taking off a 4 kg gambeson or 16 kg maille shirt and stuffing it into a backpack _increased_ active Burden!

Instead, wearing armor places a calibrated **`Worn Load`** onto the character's skeletal axis. Stowing armor in a framed backpack transfers weight directly to the iliac crest/hips ($m_W = 0.75$), which cools the body and eliminates distal limb-swing penalties during non-combat road marches.

| Item                                      |     Form Tag     | Real Mass $W$ (kg) | Unrigged Awkwardness $A_{\text{raw}}$ | Default Load ($W + A_{\text{raw}}$) | Worn Load ($L_{\text{worn}}$) | Stowed Load (Framed Pack, $m_W=0.75$) | Notes & Biomechanical References ([`armor.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/armor.md))                                                                                                                                                                                                                                      |
| :---------------------------------------- | :--------------: | :----------------: | :-----------------------------------: | :---------------------------------: | :---------------------------: | :-----------------------------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Padded Doublet (Gambeson)**             |     `[Worn]`     |        4.0         |                  2.0                  |                 6.0                 |            **4.0**            |                **3.0**                | Quilted linen/wool layers (2–4 kg). Primary thermal insulator. Worn mass rests comfortably on torso ($L=4$). Stowing in a framed pack yields $3\text{ Load}$, cooling the body on long road marches.                                                                                                                                                         |
| **Maille Hauberk (over Gambeson)**        |     `[Worn]`     |        16.0        |                  6.0                  |                22.0                 |           **16.0**            |               **12.0**                | 12 kg maille + 4 kg gambeson. Draped deadweight hanging from clavicles without pelvic transfer; imposes a $1.6\times$ metabolic cost multiplier (Askew et al. 2011). $16\text{ Load}$ consumes $\approx 1$ standard increment. Stowing in a framed pack transfers weight to the hips ($12\text{ Load}$), relieving shoulder fatigue.                         |
| **Brigandine / Lamellar (over Gambeson)** |     `[Worn]`     |        18.0        |                  5.0                  |                23.0                 |           **16.0**            |               **13.5**                | 14 kg riveted plates in fabric/leather shell + 4 kg padded undergarment. Although heavier in raw mass ($18\text{ kg}$) than maille, its semi-rigid plates distribute torso forces far more efficiently, earning a calibrated $L_{\text{worn}} = 16$.                                                                                                         |
| **Full Plate Harness (Standard Fit)**     |     `[Worn]`     |        32.0        |                 12.0                  |                44.0                 |           **32.0**            |               **24.0**                | Articulated munition plate (cuirass, pauldrons, arm/leg harness, sabatons, helm, doublet). Askew et al. (2011): $2.2\times$ walking metabolic multiplier due to distal leg swing inertia ($4\times\text{–}6\times$ per kg on feet/calves) and thoracic restriction. Stowing plate in a framed pack eliminates limb-swing inertia ($24\text{ Load}$ on hips). |
| **Full Plate Harness (Masterwork Fit)**   |     `[Worn]`     |        32.0        |                 12.0                  |                44.0                 |           **22.0**            |               **24.0**                | Bespoke tailored harness. Jaquet et al. (2016): superior articulation and custom pelvic load paths act as an exoskeleton, reducing the metabolic multiplier to $1.7\times$. Remarkable result: **it is easier to wear a masterwork harness on the body ($22\text{ Load}$) than to haul it in a backpack ($24\text{ Load}$)!**                                |
| **Buckler**                               |   `[Compact]`    |        1.0         |                  1.0                  |                 2.0                 |            **1.0**            |               **0.75**                | 30 cm steel/wood boss with center fist-grip. Belt-hooked via frog ($m_A=0$). Ultra-rapid recovery in Crisis Time; does not obstruct hand transitions.                                                                                                                                                                                                        |
| **Target / Round Shield**                 |   `[Packable]`   |        3.5         |                  3.0                  |                 6.5                 |            **3.5**            |               **2.63**                | 70 cm planked linden/pine with center iron boss. Slung across back via guige strap ($m_A=0$). Held in hand, occupies 1 arm.                                                                                                                                                                                                                                  |
| **Heater Shield (Strapped)**              |   `[Packable]`   |        3.0         |                  2.0                  |                 5.0                 |            **3.0**            |               **2.25**                | 55–60 cm layered wood with leather face and forearm enarmes. Slung on shoulder guige ($m_A=0$). Highly stable passive defense.                                                                                                                                                                                                                               |
| **Roman _Scutum_ / Tower Shield**         | `[Long / Rigid]` |        7.5         |                  5.0                  |                12.5                 |            **7.5**            |             _Cannot pack_             | 105 cm curved 3-ply plywood with brass boss (Roth 1999; Junkelmann 1986). Slung over back, its top rim forms the rigid load shelf for the Marian _furca_ pack rig.                                                                                                                                                                                           |

---

## 2. Weapons & Ammunition Benchmark Table

Weapons carried loose in hand impose severe rotational inertia and occupy hand capacity. When housed in custom scabbards, frogs, baldrics, or quivers, their unrigged awkwardness drops to zero ($m_A = 0$), leaving only their gravitational mass $W$ resting along the body's skeletal axis.

| Item                                     |     Form Tag     | Mass $W$ (kg) | Unrigged $A$ (in hand) | Default Load ($W + A$) | Sheathed / Slung Load ($m_A=0$) | Notes & Rotational Inertia                                                                                                                                                                                                        |
| :--------------------------------------- | :--------------: | :-----------: | :--------------------: | :--------------------: | :-----------------------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Dagger / Rondel**                      |   `[Compact]`    |      0.5      |          0.5           |          1.0           |             **0.5**             | 30 cm blade. Carried in belt sheath; instantaneous draw (0 tempo).                                                                                                                                                                |
| **Shortsword / Gladius**                 |   `[Packable]`   |      1.0      |          1.0           |          2.0           |             **1.0**             | 60–75 cm blade. Worn in hip baldric; excellent close-quarters clearance.                                                                                                                                                          |
| **Arming Sword**                         |   `[Packable]`   |      1.2      |          1.5           |          2.7           |             **1.2**             | 80–90 cm blade. Balanced at 8–10 cm from guard; worn in scabbard on sword belt.                                                                                                                                                   |
| **Flanged Mace**                         |   `[Packable]`   |      1.3      |          2.0           |          3.3           |             **1.3**             | 60 cm steel shaft with bronze/steel head. Forward-weighted center of percussion; carried in belt frog.                                                                                                                            |
| **Warhammer / Battleaxe**                |   `[Packable]`   |      1.5      |          2.0           |          3.5           |             **1.5**             | 65–75 cm ash haft. Concentrated strike mass; top-heavy rotational moment when held bare in hand.                                                                                                                                  |
| **Longsword / Bastard Sword**            | `[Long / Rigid]` |      1.5      |          3.0           |          4.5           |             **1.5**             | 115–125 cm length. Snags doorways and brush if loose in hand; scabbard holds weapon close to hip/leg axis.                                                                                                                        |
| **Greatsword / Zweihänder**              | `[Long / Rigid]` |      3.0      |          5.0           |          8.0           |             **3.0**             | 160–180 cm two-handed war sword. Cannot be drawn from a hip scabbard; carried resting bare across shoulder or lashed across external pack frame.                                                                                  |
| **Spear (Two-Handed, 2.4m)**             | `[Long / Rigid]` |      1.8      |          4.0           |          5.8           |             **1.8**             | 2.4 m ash stave. Supreme zone-control reach ([`combat-spacing-and-reach.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/combat-spacing-and-reach.md)); trail-carried in hand on march or lashed to pack frame. |
| **Javelin (Bundle of 2)**                |   `[Packable]`   |      2.0      |          2.5           |          4.5           |             **2.0**             | 1.2–1.5 m light throwing spears (1.0 kg each). Bound with leather strap across back or strapped to pack frame.                                                                                                                    |
| **Pike / Long Halberd**                  | `[Long / Rigid]` |      4.0      |          7.0           |          11.0          |             **4.0**             | 3.5–4.5 m formation weapon. Immense snag hazard in subterranean passages or forest trails; cannot fit inside standard packs.                                                                                                      |
| **Shortbow (Strung)**                    |   `[Packable]`   |      0.6      |          1.5           |          2.1           |             **0.6**             | 1.0–1.2 m stave. Slung diagonally across chest or unstrung in bow-case.                                                                                                                                                           |
| **Military Longbow**                     | `[Long / Rigid]` |      1.0      |          3.5           |          4.5           |             **1.0**             | 1.8–2.0 m yew/elm self-bow. Tall rigid stave; slung unstrung in water-resistant oiled canvas sleeve.                                                                                                                              |
| **Crossbow (Light / Hand-Spanned)**      |   `[Packable]`   |      2.5      |          2.0           |          4.5           |             **2.5**             | Composite/steel prod with wooden stock and goat's-foot lever. Slung across shoulder.                                                                                                                                              |
| **Crossbow (Heavy / Windlass Arbalest)** | `[Long / Rigid]` |      6.0      |          4.0           |          10.0          |             **6.0**             | Heavy steel prod (4.5 kg) + separate iron windlass/cranequin mechanism (1.5 kg). High deadweight; slung across back.                                                                                                              |
| **Quiver of 20 Arrows / Bolts**          |   `[Packable]`   |      1.0      |          2.0           |          3.0           |             **1.0**             | Rigid molded leather cylinder (0.2 kg) + 20 arrows/bolts (0.8 kg). Loose shafts spill and snap ($A=2.0$); quiver keeps fletchings aligned.                                                                                        |

---

## 3. Adventuring Gear, Survival Supplies & Treasure Benchmark Table

This table details the mundane tools, expedition rations, and dungeon extraction cargo that make up an adventurer's operational pack.

- **Stowed Load (Standard Pack, $m_W=1.0$):** Eliminates internal awkwardness ($m_A=0$), but all gravitational mass transfers through the shoulder straps to the spine.
- **Stowed Load (Framed Pack / Hip Belt, $m_W=0.75$):** Transfers 30–50% of vertical force off the spine directly onto the iliac crest ([`load-carriage-and-pack-biomechanics.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/load-carriage-and-pack-biomechanics.md)), providing a $25\%$ mechanical discount to carried weight ($m_W = 0.75$).

| Item                                             |     Form Tag     | Mass $W$ (kg) | Unrigged $A$ | Default Load ($W+A$) | Stowed (Standard Pack) | Stowed (Framed Pack) | Notes & Physical Constraints                                                                                                                                                                                                              |
| :----------------------------------------------- | :--------------: | :-----------: | :----------: | :------------------: | :--------------------: | :------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Daily Rations (Dry Grain / Hardtack / Jerky)** |   `[Compact]`    |     0.85      |     0.5      |         1.35         |        **0.85**        |       **0.64**       | Historical Roman _frumentum_ ration: 850 g/day unground wheat (Roth 1999). Dense, shelf-stable, water-sensitive ([`consequences-logistics.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-logistics.md)). |
| **Full Waterskin (2 Liters)**                    |   `[Compact]`    |      2.2      |     1.0      |         3.2          |        **2.2**         |       **1.65**       | 2.0 kg water + 0.2 kg cured leather skin. Sloshing center of mass when loose; stowed tightly near spine.                                                                                                                                  |
| **7-Day Ration Bundle**                          |   `[Packable]`   |      6.0      |     2.5      |         8.5          |        **6.0**         |       **4.50**       | Seven daily grain/pork packets in sealed canvas wrapper. Standard weekly march reserve.                                                                                                                                                   |
| **14-Day Legionary Grain Sack**                  |   `[Packable]`   |     12.0      |     4.0      |         16.0         |        **12.0**        |       **9.00**       | Approx. 1 Roman _modius_ (11.9 kg) unground wheat. Vegetius _Epit._ 1.19 standard field sustainment load.                                                                                                                                 |
| **Bedroll / Wool Blanket & Groundcloth**         |   `[Packable]`   |      2.0      |     2.5      |         4.5          |        **2.0**         |       **1.50**       | Coarse wool blanket + oiled canvas ground tarp. Bulky volume; strapped beneath backpack or pack frame.                                                                                                                                    |
| **Canvas Tent (2-Person Expedition)**            |   `[Packable]`   |      5.0      |     3.5      |         8.5          |        **5.0**         |       **3.75**       | Heavy waxed canvas + ash ridge stakes + iron ground pegs. Shared shelter; split between companions.                                                                                                                                       |
| **Iron Cookpot & Bronze Mess Kit**               |   `[Packable]`   |      2.5      |     2.5      |         5.0          |        **2.5**         |       **1.88**       | Cast-iron kettle + ladle + shallow bronze mess bowl (_patera_). Rattles loudly if unpadded in pack.                                                                                                                                       |
| **Torch (x1)**                                   |   `[Packable]`   |      0.5      |     1.0      |         1.5          |        **0.5**         |       **0.38**       | 50 cm pitch-soaked wooden torch. Burns 1 hour; smoky blackdamp risk in enclosed spaces.                                                                                                                                                   |
| **Bundle of 6 Torches**                          |   `[Packable]`   |      3.0      |     2.5      |         5.5          |        **3.0**         |       **2.25**       | Six torches wrapped in burlap sacking. Bulky combustible fuel supply.                                                                                                                                                                     |
| **Hooded Brass Lantern**                         |   `[Packable]`   |      1.2      |     1.5      |         2.7          |        **1.2**         |       **0.90**       | Sheet-brass casing with horn/glass panes and adjustable shutter. Delicate glass; carried upright.                                                                                                                                         |
| **Flask of Lamp Oil (0.5 Liter)**                |   `[Compact]`    |      0.6      |     0.5      |         1.1          |        **0.6**         |       **0.45**       | Ceramic or tin flask with wax-sealed stopper. Provides 6 hours of lantern illumination.                                                                                                                                                   |
| **Tallow Candles (Bundle of 6)**                 |   `[Compact]`    |      0.3      |     0.3      |         0.6          |        **0.3**         |       **0.23**       | Rendered beef/mutton tallow candles. Burns 2 hours each; melts under extreme heat.                                                                                                                                                        |
| **Hemp Rope (15m / 50ft Coil)**                  |   `[Packable]`   |      4.0      |     2.5      |         6.5          |        **4.0**         |       **3.00**       | Heavy 3-strand twisted hemp cordage (Chapman 1868). Tensile breaking strength $\approx 5.5\text{ kN}$; water-absorbent.                                                                                                                   |
| **Silk / Fine Braided Cord (15m)**               |   `[Compact]`    |      1.5      |     1.0      |         2.5          |        **1.5**         |       **1.13**       | Tightly braided silken cordage. Equal tensile strength at $37\%$ the mass; packs into small pocket.                                                                                                                                       |
| **Forged Grappling Hook**                        |   `[Packable]`   |      1.5      |     2.0      |         3.5          |        **1.5**         |       **1.13**       | 4-tined forged iron anchor. Outward prongs catch on foliage and straps; requires leather tine-sheaths.                                                                                                                                    |
| **Iron Crowbar (1m)**                            | `[Long / Rigid]` |      3.5      |     3.0      |         6.5          |     _Cannot stow_      |       **3.53**       | Solid forged iron wedge. Exceeds standard backpack length; lashed externally to pack frame ($m_A=0.3$).                                                                                                                                   |
| **Entrenching Dolabra / Shovel**                 | `[Long / Rigid]` |      2.5      |     2.5      |         5.0          |     _Cannot stow_      |       **2.63**       | Roman dual-ended pickaxe/axe or spade. Essential delving tool; lashed externally to pack frame ($m_A=0.3$).                                                                                                                               |
| **Iron Spikes / Pitons (10) + Hammer**           |   `[Packable]`   |      2.5      |     1.5      |         4.0          |        **2.5**         |       **1.88**       | 10 wrought-iron spikes (1.5 kg) + cross-peen forging hammer (1.0 kg). Wedge doors, anchor climbing lines.                                                                                                                                 |
| **10-Foot Delving Pole (Ash, 3m)**               | `[Long / Rigid]` |      2.5      |     7.0      |         9.5          |     _Cannot stow_      |       **6.08**       | 3.0 m straight ash pole. Extreme rotational moment; snags subterranean arches ($m_A=0.6$ even when lashed).                                                                                                                               |
| **Wooden Scaling Ladder (3m Section)**           | `[Long / Rigid]` |      8.0      |     8.0      |         16.0         |     _Cannot stow_      |   _Lashed to cart_   | Heavy ash rungs with pine side-rails. Hand-carried by 2 delvers ($W=4, A=3 \implies 7\text{ Load}$ each).                                                                                                                                 |
| **Thieves' Tools / Lockpick Roll**               |   `[Compact]`    |      0.2      |     0.5      |         0.7          |        **0.2**         |       **0.15**       | Fine steel tension wrenches and picks in velvet roll. Stowed in belt pouch ($m_A=0$).                                                                                                                                                     |
| **Healer's Poultice Satchel**                    |   `[Packable]`   |      1.5      |     1.0      |         2.5          |        **1.5**         |       **1.13**       | Linen bandage rolls, bone needle, honey tins, herbal tinctures. Clean, protected storage.                                                                                                                                                 |
| **Heavy Padlock & Chain (2m)**                   |   `[Packable]`   |      3.5      |     2.5      |         6.0          |        **3.5**         |       **2.63**       | Wrought-iron welded link chain and key-box lock. Secure containment; heavy dense deadweight.                                                                                                                                              |
| **100 Silver / Gold Coins**                      |   `[Compact]`    |      1.0      |     1.5      |         2.5          |        **1.0**         |       **0.75**       | Pre-modern bullion standard: 100 coins $\approx 1.0\text{ kg}$ (10 g/coin). Loose coins clink and burst bags.                                                                                                                             |
| **500 Silver / Gold Coins**                      |   `[Compact]`    |      5.0      |     3.0      |         8.0          |        **5.0**         |       **3.75**       | Heavy concentrated weight. Stowed in reinforced leather money-bag.                                                                                                                                                                        |
| **Gold / Silver Trade Ingot**                    |   `[Compact]`    |      5.0      |     2.0      |         7.0          |        **5.0**         |       **3.75**       | Cast metal ingot bar. Extremely slippery and unergonomic to carry bare in hand.                                                                                                                                                           |
| **Pouch of Cut Gemstones (50 pcs)**              |   `[Compact]`    |      0.1      |     0.5      |         0.6          |        **0.1**         |       **0.08**       | High-value, ultra-low-mass loot. Carried in inner velvet pocket.                                                                                                                                                                          |
| **Carved Stone Idol / Altar Relic**              | `[Long / Rigid]` |     25.0      |     8.0      |         33.0         |     _Cannot stow_      |      **18.75**       | Solid granite/basalt religious sculpture. Severe lifting challenge; lashed securely to heavy cargo frame.                                                                                                                                 |
| **Ornate Framed Painting / Tapestry**            | `[Long / Rigid]` |      3.0      |     8.0      |         11.0         |     _Cannot stow_      |       **6.25**       | Wide 1.2m $\times$ 1.5m gilded wooden frame. Fragile, catches wind, snag hazard ($m_A=0.5$ lashed to pack frame).                                                                                                                         |
| **Iron-Banded Chest of Silver Coins**            |   `[Packable]`   |     30.0      |     8.0      |         38.0         |     _Cannot stow_      | _Cart / Pack Beast_  | 5 kg oak/iron box + 25 kg coin. Requires two hands to carry; two-man carry = $18\text{ Load}$ each ($W=15, A=3$).                                                                                                                         |

---

## 4. Containers, Rigging & Transport Benchmark Table

Containers and pack frames act as mathematical transformation functions over stored $(W, A)$. They eliminate internal awkwardness ($m_A = 0$), distribute weight efficiently to skeletal leverage points ($m_W \le 1.0$), and dictate the operational tempo required to jettison gear when combat erupts.

$$L_{\text{container}} = W_c + A_c + \sum_{i \in \text{contents}} \left( m_W \cdot W_i + m_A \cdot A_i \right)$$

| Container / Rigging System                   |    Empty Mass $W_c$ (kg)     |  Empty Awkwardness $A_c$   |                Accepted Forms                 | Capacity Limit (Max $W$ or Items) | Mass Multiplier $m_W$ |        Awkwardness Multiplier $m_A$         |                Crisis Jettison Cost                | Notes & Biomechanical Mechanism                                                                                                                                                           |
| :------------------------------------------- | :--------------------------: | :------------------------: | :-------------------------------------------: | :-------------------------------: | :-------------------: | :-----------------------------------------: | :------------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Belt Pouch**                               |             0.2              |            0.0             |                  `[Compact]`                  |         2.0 kg / 3 items          |       **1.00**        |                   **0.0**                   |                **0 actions** (worn)                | Fast access in Crisis Time; worn directly on waistbelt. Zero limb restriction.                                                                                                            |
| **Weapon Scabbard / Baldric**                |             0.4              |            0.0             |                   1 Weapon                    |        1 weapon up to 1.3m        |       **1.00**        |                   **0.0**                   |            **0 actions** (draw weapon)             | Rigid wood/leather sheath. Eliminates weapon length penalty ($A=0$) while keeping weapon ready for instant draw.                                                                          |
| **Ammunition Quiver**                        |             0.5              |            0.0             |                  `[Compact]`                  |       20 arrows or 30 bolts       |       **1.00**        |                   **0.0**                   |                **0 actions** (worn)                | Rigid molded back or hip quiver. Protects delicate fletchings and points.                                                                                                                 |
| **Burlap Sack / Grain Bag**                  |             0.2              |            2.0             |           `[Compact]`, `[Packable]`           |               20 kg               |       **1.00**        |             **0.0** (contents)              |             **Free** (drop from hand)              | Eliminates internal awkwardness of items, but sack itself has $A_c=2.0$ (floppy, hand-carried) unless lashed to a frame.                                                                  |
| **Reinforced Wooden Chest**                  |             6.0              |            6.0             |           `[Compact]`, `[Packable]`           |               40 kg               |       **1.00**        |             **0.0** (contents)              |             **Free** (drop from hands)             | Iron-banded oak trunk with bail handles. High empty mass and awkwardness; designed for wagons or pack saddles.                                                                            |
| **Simple Shoulder Backpack**                 |             1.5              |            0.0             |           `[Compact]`, `[Packable]`           |               20 kg               |       **1.00**        |                   **0.0**                   |            **1 Discard / Minor Action**            | Frees hands. 100% of vertical force passes through clavicles and cervicothoracic spine ($+10\%\text{–}15\%$ metabolic penalty vs. framed pack). Risk of rucksack palsy under heavy loads. |
| **Roman _Furca_ + _Scutum_ Rig**             |             1.0              |            0.0             |           `[Compact]`, `[Packable]`           |               25 kg               |       **0.85**        |                   **0.0**                   |            **Free (0 actions / 2 sec)**            | Crossbar pole (_furca_) balanced against top rim of back-slung _scutum_. Transfers load down shield curvature into hips. Occupies 1 hand on march, but drops instantly at combat onset.   |
| **External Pack Frame (_Kraxe_ / Hip Belt)** |             2.5              |            0.0             | `[Compact]`, `[Packable]` + 2 lashed `[Long]` |               35 kg               |       **0.75**        | **0.0** (packable)<br>**0.3** (lashed long) | **1 Discard** (unbuckle)<br>_(0 if quick-release)_ | Rigid ash/aluminum ladder frame with padded hip belt. Transfers $40\%\text{–}50\%$ of vertical force to iliac crest. Imposes $+1$ combat `Burden` if kept on during melee.                |
| **Wheelbarrow / Handcart**                   | 15.0 (barrow)<br>35.0 (cart) | 0.0 (trail)<br>4.0 (scree) |                      Any                      | 100 kg (barrow)<br>250 kg (cart)  |    **0.25 – 0.35**    |                   **0.0**                   |             **Free** (release handles)             | Single or dual wheel bears $65\%\text{–}75\%$ of cargo mass. Requires both hands; unusable on steep stairs, boulder scree, deep mud, or ledges.                                           |
| **Magic: _Weightless Chest_**                |             1.0              |            5.0             |           `[Compact]`, `[Packable]`           |              100 kg               |       **0.05**        |             **0.0** (contents)              |             **Free** (drop from hands)             | Enchanted trunk almost negates internal mass ($m_W=0.05$), but retains its rigid 1.2 m dimensions ($A_c=5.0$), requiring two hands to steer through dungeon passages.                     |
| **Magic: _Dimensional Satchel_**             |             0.5              |            0.0             |            Items fitting aperture             |               50 kg               |       **0.00**        |                   **0.0**                   |                   **0 actions**                    | Extradimensional aperture (30 cm mouth). Contents have zero effective weight ($m_W=0.0$); items exceeding opening cannot enter. Punctures trigger catastrophic planar collapse.           |

---

## 5. Creatures, Mounts & Pack Beasts Benchmark Table

Pack animal carrying limits differ fundamentally from human bipeds due to horizontal spine mechanics, cooling efficiency, and hoof surface geometry ([`load-carriage-and-pack-biomechanics.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/load-carriage-and-pack-biomechanics.md); Bukhari et al., 2021).

$$\text{Base Load Increment} = \text{Frame}_{\text{base}} \times M_{\text{size}} \times M_{\text{posture}}$$

Where human baseline $\text{Frame}_{\text{base}} = 15\text{ Load units}$ ($\approx 20\%\text{ of }75\text{ kg lean body mass}$).

| Creature                            | Body Mass (kg) |   Empirical Aerobic Load (% BM & kg)    |  Empirical Heavy Strain Load (% BM & kg)   | Proposed $M_{\text{size}}$ | Proposed $M_{\text{posture}}$ | Base `Load Increment` | Comparison vs. Empirical Veterinary Data                                                                                                                                                                                                          |
| :---------------------------------- | :------------: | :-------------------------------------: | :----------------------------------------: | :------------------------: | :---------------------------: | :-------------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Small Biped (Halfling / Goblin)** |     38 kg      |   **20% – 25% BM**<br>(7.5 – 9.5 kg)    |      **40% – 50% BM**<br>(15 – 19 kg)      |            0.60            |         1.00 (Biped)          |     **9.0 Load**      | 1 Increment = 9.0 kg ($23.7\%\text{ BM}$), matching human aerobic thresholds. 2 Increments ($18\text{ kg} = 47.4\%\text{ BM}$) triggers heavy strain.                                                                                             |
| **Medium Biped (Human / Elf)**      |     75 kg      |    **20% – 25% BM**<br>(15 – 19 kg)     |      **40% – 50% BM**<br>(30 – 38 kg)      |            1.00            |         1.00 (Biped)          |     **15.0 Load**     | 1 Increment = 15.0 kg ($20\%\text{ BM}$, fighting load). 2 Increments = 30.0 kg ($40\%\text{ BM}$, approach march). 3 Increments = 45.0 kg ($60\%\text{ BM}$, full Roman _sarcina_).                                                              |
| **Stocky Medium Biped (Dwarf)**     |     80 kg      |    **25% – 30% BM**<br>(20 – 24 kg)     |      **45% – 55% BM**<br>(36 – 44 kg)      |    1.25 _(Dense Frame)_    |         1.00 (Biped)          |    **18.75 Load**     | Denser bone density and broad pelvic shelf give $+25\%$ skeletal load-bearing capacity. Can carry heavy plate ($32\text{ Load}$) within $\approx 1.7$ increments.                                                                                 |
| **Large Biped (Ogre / Troll)**      |     280 kg     |    **20% – 25% BM**<br>(56 – 70 kg)     |     **40% – 50% BM**<br>(112 – 140 kg)     |            3.00            |         1.00 (Biped)          |     **45.0 Load**     | Massive muscle cross-section. 1 Increment = 45 kg; comfortably carries an armored warrior ($80\text{ kg}$) at 2 Increments ($+1\text{ Load Burden}$).                                                                                             |
| **Riding Pony**                     |     230 kg     |    **15% – 20% BWR**<br>(35 – 46 kg)    |     **25% – 30% BWR**<br>(58 – 69 kg)      |            1.80            |    1.33 (Equine Quadruped)    |     **36.0 Load**     | 1 Increment = 36 kg ($15.7\%\text{ BWR}$), matching the strict $15\%\text{–}20\%$ aerobic ceiling for equids. Strain onset at 2 Increments ($72\text{ kg} = 31.3\%\text{ BWR}$).                                                                  |
| **Riding / War Horse**              |     480 kg     |    **15% – 20% BWR**<br>(72 – 96 kg)    |    **25% – 30% BWR**<br>(120 – 144 kg)     |            3.20            |    1.50 (Equine Quadruped)    |     **72.0 Load**     | 1 Increment = 72 kg ($15.0\%\text{ BWR}$). Accommodates an armored rider ($75\text{ kg human} + 16\text{ kg armor}$) at $1.2$ Increments. Exceeding 144 kg ($30\%\text{ BWR}$) induces acute muscle microtrauma and lameness (Dyson et al. 2020). |
| **Working Donkey**                  |     130 kg     |    **25% – 30% BM**<br>(33 – 40 kg)     |      **40% – 50% BM**<br>(52 – 65 kg)      |            1.20            |      2.00 _(Pack Beast)_      |     **36.0 Load**     | Straight back, low withers, and upright hooves yield $2.0\times$ posture suspension (Legha 2018). Achieves the same 36 kg capacity as a 230 kg pony at nearly half the body mass!                                                                 |
| **Pack Mule**                       |     380 kg     |    **25% – 30% BM**<br>(95 – 114 kg)    |     **40% – 50% BM**<br>(150 – 190 kg)     |            2.50            |      2.00 _(Pack Beast)_      |     **75.0 Load**     | Hybrid vigor and thick distal cannon bone. 1 Increment = 75 kg ($19.7\%\text{ BM}$); 2 Increments = 150 kg ($39.5\%\text{ BM}$). The premier long-distance pack animal of antiquity.                                                              |
| **Draft Ox**                        |     650 kg     | **18% – 22% BM**<br>(120 – 145 kg pack) | **30% BM** (pack)<br>Pull: 400–600 kg cart |            4.00            |    1.50 (Bovine Quadruped)    |     **90.0 Load**     | Massive low-speed draft capacity. As a pack beast: 90 kg per increment. When hitched to a cargo cart ($m_W = 0.25$), 1 Increment supports **$360\text{ kg}$ of freight**!                                                                         |

---

## 6. Archetype Loadout Scenarios & Settled Model Evaluation

### 6.1 The Settled Engine Model: Bounded `Frame & Physique` (`12 / 15 / 18`)

Under the settled rules architecture, a character's **`Load Increment`** is an anatomical baseline established at character creation, reflecting their physical build:

- **Slight Frame (`12 Load Increment`):** Starting $\sum \text{Red} \le 48$ ($\approx 16\%\text{–}22\%$ Red).
- **Standard / Fit Frame (`15 Load Increment`):** Starting $\sum \text{Red} \in [49, 84]$ ($\approx 25\%\text{–}38\%$ Red).
- **Brawny Frame (`18 Load Increment`):** Starting $\sum \text{Red} \ge 85$ ($\approx 40\%+$ Red), up to **20 Load** with a dedicated _Strongback_ trait.

Active `Burden` is calculated using the single unified zero-indexed formula:

$$\text{Burden} = \left\lfloor \frac{\text{Total Load (Worn + Carried)}}{\text{Load Increment}} \right\rfloor$$

On the table, this maps directly to **Load Rows**:

- **Row 1 is free ($0\text{ Burden}$)** for gear fitting within the first increment.
- **Each additional row started or completed adds $+1\text{ Burden}$**.

---

### 6.2 Concrete Archetype Equipment Profiles

We evaluate 5 representative archetypes across three operational states:

- **State 1: Fighting / Expeditus Load** (Weapons, armor, belt pouch; pack dropped).
- **State 2: Approach March Load** (Fighting load + framed pack or _furca_ with 7–14 days rations, water, bedroll, delve tools).
- **State 3: Heavy Haul / Loot Extraction** (Approach march load + 25 kg extracted treasure/loot).

#### Archetype Itemizations:

1. **Frail Scholar / Arcanist (Slight Frame, `Inc 12`):**
   - _State 1 (Fighting):_ Scholar's Robes ($L_{\text{worn}}=1.0$), Sheathed Dagger ($0.5$), Walking Quarterstaff ($W=1.2, A=1.5 \implies 2.7$), Belt Pouch ($0.7$). **Total Load = 4.9**.
   - _State 2 (March):_ Fighting Load (4.9) + Simple Shoulder Backpack ($W_c=1.5, m_W=1.0$) carrying 2L water (2.2), 7d rations (6.0), bedroll (2.0), 2 torches (1.0), herbal kit (1.5), grimoire & ink (1.5). Pack Load = $1.5 + 14.2 = 15.7$. **Total Load = 20.6**.
   - _State 3 (Loot):_ March Load (20.6) + 25 kg extracted relics/ingots in sack. **Total Load = 45.6**.

2. **Nimble Scout / Archer (Standard Frame, `Inc 15` / Slight `Inc 13.5`):**
   - _State 1 (Fighting):_ Gambeson ($L_{\text{worn}}=4.0$), Shortsword in scabbard ($1.0$), Longbow slung ($1.0$), Quiver of 20 ($1.0$), Dagger ($0.5$), Belt Pouch ($0.8$). **Total Load = 8.3**.
   - _State 2 (March):_ Fighting Load (8.3) + Lightweight Pack Frame ($W_c=2.0, m_W=0.75$) carrying 2L water (2.2), 7d rations (6.0), bedroll (2.0), silk rope 15m (1.5), grappling hook (1.5), mess kit (1.2). Pack Load = $2.0 + 0.75 \times 14.4 = 12.8$. **Total Load = 21.1**.
   - _State 3 (Loot):_ March Load (21.1) + 25 kg trade ingots on pack frame ($+25 \times 0.75 = +18.75$). **Total Load = 39.85** ($\approx 39.9$).

3. **Standard Footman / Adventurer (Standard Frame, `Inc 15`):**
   - _State 1 (Fighting):_ Maille Hauberk over Gambeson ($L_{\text{worn}}=16.0$), Arming Sword in scabbard ($1.2$), Heater Shield slung ($3.0$), Dagger ($0.5$), Belt Pouch ($0.7$). **Total Load = 21.4**.
   - _State 2 (March):_ Fighting Load (21.4) + External Pack Frame ($W_c=2.5, m_W=0.75$) carrying 2L water (2.2), 7d rations (6.0), bedroll (2.0), hemp rope 15m (4.0), 6 torches (3.0), cookpot (2.5), entrenching shovel lashed ($2.63$). Pack Load = $2.5 + 0.75 \times 19.7 + 2.63 = 19.91$. **Total Load = 41.31** ($\approx 41.3$).
   - _State 3 (Loot):_ March Load (41.31) + 25 kg stone idol on pack frame ($+18.75$). **Total Load = 60.06** ($\approx 60.1$).

4. **Roman Legionary / Heavy Vanguard (Brawny Frame, `Inc 18`):**
   - _State 1 (Fighting):_ Lorica Hamata + Gambeson ($L_{\text{worn}}=16.0$), Gladius in scabbard ($1.0$), Pugio ($0.4$), Pilum ($2.0$), Roman _Scutum_ ($7.5$), Balteus & pouch ($0.8$). **Total Load = 27.7**.
   - _State 2 (March):_ Fighting Load (27.7) + Roman _Furca_ Rig ($W_c=1.0, m_W=0.85$ over back-slung _scutum_, instant 2s drop) carrying 14d grain sack (12.0), 2L water (2.2), bronze mess kit (2.0), dolabra (2.5), stakes & cloak (3.5). Furca Load = $1.0 + 0.85 \times 22.2 = 19.87$. **Total Load = 47.57** ($\approx 47.6$).
   - _State 3 (Loot):_ March Load (47.57) + 25 kg spoils in furca bundle ($+25 \times 0.85 = +21.25$). **Total Load = 68.82** ($\approx 68.8$).

5. **Full-Plate Knight / Juggernaut (Brawny Frame, `Inc 18` / `Inc 20` with _Strongback_):**
   - Weapons suite: Longsword in scabbard ($1.5$), Heavy Poleaxe on shoulder ($5.0$), Dagger ($0.5$), Heater Shield ($3.0$), War Belt ($1.0$). Weapons sum = $11.0\text{ Load}$.
   - Heavy Framed Pack: $W_c=2.5, m_W=0.75$, contents = 20.5 kg (water, 7d rations, tent-half, lantern, rope, spares). Pack Load = $2.5 + 0.75 \times 20.5 = 17.88\text{ Load}$.
   - _Configuration A (Standard Munition Plate, $L_{\text{worn}}=32.0$):\_
     - State 1 Fighting Load: $32.0 + 11.0 = \mathbf{43.0\text{ Load}}$.
     - State 2 March Load: $43.0 + 17.88 = \mathbf{60.88\text{ Load}}$ ($\approx 60.9$).
     - State 3 Loot Load: $60.88 + 18.75 = \mathbf{79.63\text{ Load}}$ ($\approx 79.6$).
   - _Configuration B (Masterwork Tailored Plate, $L_{\text{worn}}=22.0$):\_
     - State 1 Fighting Load: $22.0 + 11.0 = \mathbf{33.0\text{ Load}}$.
     - State 2 March Load: $33.0 + 17.88 = \mathbf{50.88\text{ Load}}$ ($\approx 50.9$).
     - State 3 Loot Load: $50.88 + 18.75 = \mathbf{69.63\text{ Load}}$ ($\approx 69.6$).

---

### 6.3 Settled Model Evaluation Matrix

Applying $\text{Burden} = \lfloor \text{Total Load} / \text{Load Increment} \rfloor$ yields clean, stable, and highly intuitive results:

| Archetype & Frame             | Frame (`Increment`) | State 1: Fighting Load | State 2: March Load | State 3: Loot Load | Active Burden (S1 / S2 / S3) | Pack Drop Advantage ($\Delta \text{Burden}$) |
| :---------------------------- | :-----------------: | :--------------------: | :-----------------: | :----------------: | :--------------------------: | :------------------------------------------: |
| **Frail Scholar**             |     **12 Load**     |         4.9 kg         |       20.6 kg       |      45.6 kg       |     **Burden 0 / 1 / 3**     |          **$\Delta = -1$** (1 to 0)          |
| **Nimble Scout**              |     **15 Load**     |         8.3 kg         |       21.1 kg       |      39.9 kg       |     **Burden 0 / 1 / 2**     |          **$\Delta = -1$** (1 to 0)          |
| _(Scout, Unconditioned)_      |     _13.5 Load_     |         8.3 kg         |       21.1 kg       |      39.9 kg       |     **Burden 0 / 1 / 2**     |          **$\Delta = -1$** (1 to 0)          |
| **Standard Footman**          |     **15 Load**     |        21.4 kg         |       41.3 kg       |      60.1 kg       |     **Burden 1 / 2 / 4**     |          **$\Delta = -1$** (2 to 1)          |
| **Heavy Vanguard**            |     **18 Load**     |        27.7 kg         |       47.6 kg       |      68.8 kg       |     **Burden 1 / 2 / 3**     |          **$\Delta = -1$** (2 to 1)          |
| **Knight (Standard Plate)**   |     **18 Load**     |        43.0 kg         |       60.9 kg       |      79.6 kg       |     **Burden 2 / 3 / 4**     |          **$\Delta = -1$** (3 to 2)          |
| _(Knight, Strongback)_        |      _20 Load_      |        43.0 kg         |       60.9 kg       |      79.6 kg       |     **Burden 2 / 3 / 3**     |          **$\Delta = -1$** (3 to 2)          |
| **Knight (Masterwork Plate)** |     **18 Load**     |        33.0 kg         |       50.9 kg       |      69.6 kg       |     **Burden 1 / 2 / 3**     |          **$\Delta = -1$** (2 to 1)          |
| _(Masterwork, Strongback)_    |      _20 Load_      |        33.0 kg         |       50.9 kg       |      69.6 kg       |     **Burden 1 / 2 / 3**     |          **$\Delta = -1$** (2 to 1)          |

---

### 6.4 Why Dynamic Tier-Scaling Candidates (A, B, C) Were Superseded

During development, we explored three dynamic formulas that recalculated `Load Increment` as cards upgraded:

- **Candidate A ($\sqrt{\sum \text{Red} / 72}$):** As card numbers quadrupled into Tier 3, capacity doubled ($2.0\times$).
- **Candidate B ($0.5 + 1.5 \times (\text{Red} / \text{Total})$):** Tied capacity to the proportion of Red in the deck.
- **Candidate C (Hybrid with exponent $k$):** Scaled capacity by deck scale raised to power $k \in [0, 0.5]$.

#### The Failure Modes of Dynamic Tier Scaling:

1. **Candidate A Deleted Logistics at High Tiers:** In Tier 3, a Scholar's increment inflated from $10.6$ to $21.2\text{ Load}$, and a Footman reached $30.0\text{ Load}$. Consequently, a Tier 3 Scholar could march with a 20 kg expedition pack with **$0$ Burden**, and a Footman could haul 60 kg of loot with only Burden 2. Physical survival friction dissolved simply because card stats escalated, violating the core principle that caRdPG's scale-invariance should preserve tactile tension across all tiers ([`calibrating-your-expectations.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/theory/readings/calibrating-your-expectations.md)).
2. **Candidate B Created Counter-Intuitive Deck Building Penalties:** If a martial character upgraded their deck by adding a high-tier Yellow finesse card or Blue tactical card, their total deck pool grew faster than their Red sum, inadvertently _decreasing_ their carrying capacity!
3. **Contradiction with Exercise Physiology:** As proven in [`load-carriage-and-pack-biomechanics.md#1.8`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/load-carriage-and-pack-biomechanics.md#18-inter-individual-variance-vs-training-adaptations-in-load-carriage), human walking mechanical efficiency is invariant with training (~0–3% variance), and human lean body mass and aerobic capacity plateau after an initial $+15\%\text{–}25\%$ conditioning gain. Human skeletons do not double in load capacity simply because a warrior becomes an expert swordsman.

**Conclusion:** The **Bounded `Frame & Physique` (`12 / 15 / 18`)** model grounds character capacity permanently in human anatomy, preserves the protective-vs-fatigue tradeoff of armor across all tiers, and makes logistical advancement a deliberate, tactile pursuit (acquiring pack animals, masterwork armor, carts, or explicit supernatural traits).

---

## 7. Key Analytical Insights & Design Conclusions

The calibrated benchmark dataset establishes four foundational takeaways for system design:

### 7.1 Insight 1: Zero-Indexed Increments ($\lfloor \text{Total Load} / \text{Increment} \rfloor$) Deliver Flawless Tabletop Ergonomics

- **Row 1 is the Unencumbered Allowance:** Gear whose total Load is $< \text{Increment}$ produces $\lfloor \text{Load} / \text{Increment} \rfloor = 0$. Unarmored and lightly armored characters (Scholar fighting load 4.9 kg; Scout fighting load 8.3 kg) fight at **Burden 0**.
- **No Complex Math at the Table:** Players organize their carried item cards into stacks equal to their `Load Increment`. Row 1 is free; each additional row completed or started adds $+1\text{ Burden}$.

### 7.2 Insight 2: Unified `Worn Load` Perfectly Balances Armor Protection vs. Exertion

- By assigning armor a single **`Worn Load` ($L_{\text{worn}}$)** on the universal Load scale, we eliminate both the "double tax" on plate armor and the "zero worn load" backpack paradox.
- **Maille ($16\text{ Load}$)** naturally consumes 1 increment, placing combatants at **Burden 1** ($1.6\times$ metabolic cost).
- **Standard Plate ($32\text{ Load}$)** places combatants at **Burden 2** ($2.2\times$ metabolic cost), reflecting the heavy limb-swing inertia of sabatons and greaves.
- **Masterwork Plate ($22\text{ Load}$)** drops combat exertion to **Burden 1** ($1.7\times$ metabolic cost), beautifully rewarding characters who invest in bespoke armor.

### 7.3 Insight 3: Universal Incentive to Drop Packs in Combat

- Across all 5 archetypes, shedding an approach march pack before engaging in combat drops active Burden by **exactly $1\text{ point}$** ($\Delta = -1$), saving 1 fatigue card per reshuffle and removing pack inertia.
- When extracting heavy dungeon loot (State 3), dropping cargo immediately sheds **2 to 3 points of Burden**, creating dramatic, life-or-death tactical dilemmas when ambushed deep in a dungeon.

### 7.4 Insight 4: Authenticity of the "Knight's Paradox" & Pack Mount Logistics

- A standard plate knight carries $43\text{ Load}$ in weapons and harness, placing them at Burden 2 in combat. Attempting to march on foot with a heavy expedition pack pushes them to Burden 3 (or Burden 5 under earlier unrefined models).
- This is an authentic feature of medieval warfare: knights did not march on foot with expedition packs. They rode mounts on the march and relied on pack horses ($72\text{ Load Increment}$) and pack mules ($75\text{ Load Increment}$) to haul their gear, validating the necessity of pack trains in wilderness expeditions.
