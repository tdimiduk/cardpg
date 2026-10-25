---
title: "Design Brief: Consequence Scaling, Progression, and Recovery Economics"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# Design Brief: Consequence Scaling, Progression, and Recovery Economics

## Purpose of this Working Session Track

To explore and formalize how **Consequence Cards** (their passive penalties, in-combat `action:` mitigations, and out-of-combat `task:` recovery checks) interact with **Character Progression** and **Scale Invariance**.

In _caRdPG_, the core resolution engine is designed to be **scale-invariant**: because `Impact` is measured by the _count of cards flipped_ to meet incoming `Strength` (rather than flat numerical subtraction), an attack of Strength 15 against a starter character (card values 2–3) and an attack of Strength 150 against a legendary hero or macro-scale army (card values 20–30) both flip ~5–6 cards (`Impact 5–6`).

However, once a consequence card enters play on the table, a critical design tension emerges: **Should consequence recovery costs and passive penalties be scale-invariant (card counts), or should they use fixed numerical Strength thresholds so that higher-level characters shrug off or recover from certain consequences more easily?**

---

## 1. The Core Design Tensions

### Tension 1: Fixed Numerical Costs vs. Card-Count Costs on Consequence Recovery

Consequence cards currently use two different vocabularies for mitigation and recovery (see [guide-to-writing-consequences.md](consequence-pool-tag-escalation/guide-to-writing-consequences.md)):

1. **Fixed Numerical Thresholds (`Spend {Red} 20`, `Check {Blue} 35`):**
   - **How it behaves across progression:** As a character upgrades the numbers on their cards (e.g., from an average of 2–3 per card to 6–8+ per card) or acquires better medical/tool gear, a fixed threshold like `Spend {Red} 20` or `Check {Blue} 35` requires fewer and fewer cards (and thus less `Impact` / stamina) to clear.
   - **Where this feels great (Grounded Heroism & Progression):** A seasoned veteran _should_ have an easier time shaking off `Rattled Nerves`, powering through a muscle spasm, or treating a routine field laceration than a novice recruit. If every recovery cost scales proportionally forever (e.g., "always costs 2 cards"), characters never feel more resilient against minor/environmental friction as they advance.
   - **Where this gets tricky:**
     - If a Tier 1 tactical reset is calibrated to a mid/high-tier number (like `Spend {Red} 20`), a starting character (with card values 1–3) might find it mathematically impossible to clear in a single Crisis Time action!
     - Conversely, if an opponent of equal high tier inflicts `Off-Balance` on a high-level duelists, should the duelist recover from an equal-tier opponent's trip effortlessly just because the `Off-Balance` card has a low static number printed on it?

2. **Scale-Invariant Card-Count Costs (`Tuck 2 cards from hand`, `Expend 1 card from hand`):**
   - **How it behaves across progression:** Costs expressed in cards (`Tuck 2 cards`, `When cards on top exceed your Burden...`, `+1 Impact on defenses`) scale automatically with the character's deck, because 1 card is always $1/24\text{th}$ of their action/endurance economy regardless of whether their card stats are `2/2/2` or `50/50/50`.
   - **Where this feels great:** Peer-to-peer tactical positioning in combat (`Knocked Prone`, `Pinned`, `Off-Balance`) and fractal macro-scale play (armies/realms).
   - **Where this feels flat:** If _everything_ uses card counts, progression feels like a treadmill where higher numbers on your cards never make fixed world hazards or minor bodily setbacks easier to overcome.

---

### Tension 2: Relative vs. Absolute Consequences (Peer-Relative vs. World-Absolute)

Not all consequences represent the same kind of reality:

| Consequence Category                               | Examples                                                                           | Should Higher-Level Characters Clear It Easier?                                                                                                                                                                                                                                            |
| :------------------------------------------------- | :--------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. World-Absolute / Biological & Environmental** | `Bleeding Cut`, `Cracked Ribs`, `Mild Concussion`, `Frostbite`, `Dust in Eyes`     | **Yes (or via better gear/skills).** A human body's biology and a mundane campfire's warmth are absolute benchmarks. A master physician or a toughened veteran with `Red 8` cards should breeze through a `Strength 15` stamina or medical check that taxes a novice.                      |
| **2. Peer-Relative / Contested Tactical States**   | `Off-Balance`, `Grappled / Pinned`, `Rattled Guard`, `Suppressed`                  | **Questionable / Contextual.** Being pinned by a goblin vs. being pinned by a Giant or a Master Duelist is not the same physical obstacle. If `Pinned` has a static `Spend {Red} 10` escape cost, it is impossible at Level 1 and trivial at Level 5—even when pinned by a Level 5 Dragon! |
| **3. Systemic / Resource Taxes**                   | `Winded`, `Dazed`, `Severe Concussion` (hand-size caps, card-tucking suppressions) | **Depends.** Card-count taxes (`Expend 1 card when attacking`) remain proportionally punishing at all levels, whereas flat stat penalties (`-2 to Blue actions`) vanish into rounding errors at high levels.                                                                               |

---

### Tension 3: Macro-Scale / Fractal Play Compatibility

Per [resolution-design-constraints.md](resolution-design-constraints.md) (§1.8), we want the core engine to support fractal entity modeling (e.g., an army or keep using a 24-card deck with values in the 100s) or at least wide numerical progression without rewriting the rules.

- If consequence cards have printed numbers (like `Spend {Red} 20` or `Check {Blue} 35`), what numerical band are standard consequence decks authored for?
- How do starter characters (stats 1–3 vs. 4–6) interact with those numbers on Day 1 vs. Campaign End?

---

## 2. Key Questions for the Brainstorming Session

1. **What is the canonical starting vs. advanced number scale for character decks?**
   - In `data/cards/`, some files use single-digit card stats (`1–4`) while some consequence drafts use double-digit action spends (`15–25`) and task checks (`20–100`). Locking down the expected sum of a standard 1-, 2-, or 3-card Action Stack at novice vs. veteran tiers will immediately clarify what `Spend {Red} X` actually costs in Crisis Time vs. Adventuring Time.
2. **Which parts of a Consequence Card should be fixed numbers vs. card counts?**
   - Should **Out-of-Combat `task:` checks** use fixed numerical `Strength` (so better skills, higher stats, and medical kits make treatment much easier/safer as you progress)?
   - Should **In-Combat `action:` recoveries** use fixed numbers (making veterans shrug off Tier 1 setbacks effortlessly), card-tucking/card-count mechanics (keeping tactical posture resets consistent across tiers), or a mix of both?
   - Can/should **Contested Tactical Conditions** (`Pinned`, `Grappled`, `Afraid`) reference the source or scale, or is having veterans shrug off Tier 1 conditions a feature rather than a bug (because high-tier enemies will be inflicting Tier 2/3 conditions or stacking tags faster)?
3. **How do Passive Penalties scale?**
   - Should passives stick strictly to **scale-invariant mechanics** (card taxes, `+1 Impact`, action type restrictions, ignoring Pierce thresholds), or is there a place for numerical modifiers?

---

## 3. Relevant Files to Load for This Session

- [resolution-design-constraints.md](resolution-design-constraints.md) (§1.8 Scale Invariance & §3.3 Consequence Removal Lifecycle)
- [consequence-pool-tag-escalation/guide-to-writing-consequences.md](consequence-pool-tag-escalation/guide-to-writing-consequences.md) (§3 `action:` vs. `task:` Removal Duality)
- [consequence-pool-tag-escalation/consequences.yaml](consequence-pool-tag-escalation/consequences.yaml) (Prototype consequence cards)
- [authoring/advancement-and-progression.md](../authoring/advancement-and-progression.md) (Character progression & number scaling)
- [rules/gamemaster-guide.md](../rules/gamemaster-guide.md) (General Action difficulty benchmarks)
