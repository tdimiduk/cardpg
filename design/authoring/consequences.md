---
title: "Authoring Guide: Consequences and Status Conditions"
doc_type: guide
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# Authoring Guide: Consequences and Status Conditions

This guide provides high-level design principles and practical instructions for authoring complications, injuries, physical strains, and status cards in **caRdPG**.

---

## 1. The Two Layers of Harm

Harm in _caRdPG_ operates on two distinct layers with different tactile roles at the table:

| Layer               | Type                            | Location                   | Mechanical Role                                                                                                                                                       | Schema & SSOT                                                                                                                    |
| :------------------ | :------------------------------ | :------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------- |
| **Status Cards**    | Systemic Attrition              | **In the Player's Deck**   | Enters the expended pile, cycles into the active deck during [[Fatigue Cycles]], and dilutes draw quality with low stats (`1/1/1` or `0/0/0`) and dead cards in hand. | [`CoreCard`](../../core/src/Core/Card.hs), defined in [`data/cards/status/core.yaml`](../../data/cards/status/core.yaml).        |
| **Condition Cards** | Specific Trauma & Complications | **On the Table** (in play) | Stays face-up in front of the character, imposing ongoing passive friction on actions, movement, or table capacities until treated or healed.                         | [`ConsequenceCard`](../../core/src/Core/Card.hs), defined in [`data/cards/consequences/*.yaml`](../../data/cards/consequences/). |

> [!TIP]
> For exact YAML field specifications and Mini-DSL parser grammar (`Task:`, `When`, `Passive:`), consult [Authoring Guide: Card Schemas and Mini-DSL Syntax](card-schemas-and-syntax.md).

---

## 2. Empirical Grounding & Medieval Fantasy Naming

Consequences should draw their **underlying biomechanics, onset triggers, and recovery timelines** from the **[Consequence Database Hub](../research/synthesis/consequence-database.md)** and its domain registries ([Combat](../research/synthesis/consequences-combat.md), [Exploration](../research/synthesis/consequences-exploration.md), [Social](../research/synthesis/consequences-social.md), [Crafting](../research/synthesis/consequences-crafting.md), [Arcane](../research/synthesis/consequences-arcane.md), and [Logistics](../research/synthesis/consequences-logistics.md)).

### Diegetic Naming (No Modern Clinical Jargon on Cards)

While our research synthesis uses clinical terminology to anchor real-world physiology, **printed card names (`name:`) must use evocative, in-world language suited to a medieval fantasy setting**:

- **Do NOT write:** `"Aching Quads (DOMS)"`, `"Grade II Ankle Sprain"`, `"Mild Dehydration"`, or `"Trench Foot"`.
- **DO write:** `"Lead-Heavy Legs"`, `"Wrenched Ankle"`, `"Parched Throat"`, or `"Boot-Rot"`.
- **Where clinical terms belong:** Place the clinical or empirical reference in the card's non-printed `notes:` field (e.g., `notes: "Grade II ATFL sprain; partial ligament tear requiring immobilization and multi-week healing."`) so designers and auditors can trace the real-world basis without breaking table immersion.

---

## 3. Writing Valid Mechanical Friction

Characters in _caRdPG_ do not have static RPG ability scores—do **not** write generic stat penalties like `"-2 Strength"` or `"-1 Agility"`. Instead, condition passives must interact with the actual physical components of the card engine:

### A. Strength Accumulation vs. Direct Impact (Do Not Conflate)

When a consequence makes actions harder or riskier, distinguish clearly between two distinct mechanisms:

1. **Impairing Strength Accumulation (Indirectly Increases Flips):**
   A condition can reduce how much [[Strength]] specific cards contribute during resolution (e.g., _"Flipped cards contribute at most 1 {Red} during marching or climbing checks"_ or _"Cards played from hand contribute -1 {Yellow}"_). Because each card contributes less toward the challenge's target Strength, the player is naturally forced to flip more cards from their deck—which in turn increases [[Impact]] through those extra flips.
2. **Adding Direct Impact (Does Not Change Card Flips):**
   A condition can add flat [[Impact]] to an action resolution (e.g., _"When you flip one or more cards during a physical check, add +1 Impact to the resolution"_). This increases the consequence toll of exerting an injured body without changing how many cards are flipped to meet Strength.

> [!IMPORTANT]
> Never conflate these two mechanisms in a single phrase (such as _"requires more flips (+1 Impact)"_). State either how the condition alters Strength accumulation **or** how much direct Impact it adds.

### B. Other Valid Condition Friction

- **Table Capacities & Thresholds:** Reducing effective [[Defense]] against specific tags, increasing [[Burden]] during Fatigue Cycles, or lowering maximum [[Vigilance]] (or prohibiting [[Readied Cards]]).
- **Action & Pace Restrictions:** Prohibiting specific action tags (e.g., cannot Sprint or make `Cost 2+` melee attacks) or increasing the time cost of overland travel segments.

---

## 4. Recovery Tasks: Field First Aid vs. True Convalescence

The `rules:` block on a consequence card defines how characters treat or clear the condition via `Task:` entries. **Non-magical removal tasks must respect what mundane field care can actually accomplish:**

1. **Field First Aid Stabilizes; It Does Not Instantly Heal Structural Trauma:**
   - Do **not** allow a 30-minute field task to erase a structural injury (like a wrenched ankle, deep laceration, or cracked rib) or merely swap it for a couple of `Fatigue` cards.
   - Mundane field care (`Bandaging`, `Splinting`, `Poultice`) can **stop acute deterioration** (such as halting active bleeding) or **transition/mitigate** an untreated injury into a stabilized state, but torn ligaments, broken bones, and deep wounds require days or weeks of rest in a `Haven` (`Time 7 days; Requires Haven` or `Time 14 days; Requires Haven`) to actually clear from the table.
2. **Transient Strains Can Clear in the Field:**
   - Short-term environmental or metabolic friction—such as surface chills, muscle cramps, parched throat, or grit in the eyes—can be removed directly through plausible short tasks (`Time 1 hour; Requires Campfire, dry clothes`, or consuming water/supplies during a rest stop).
3. **Role of Magic:**
   - Depending on campaign setting parameters, magical healing or rare alchemical draughts may accelerate tissue repair or mend severe trauma faster than natural physiology, but mundane `Task:` lines printed on standard consequence cards should always reflect realistic physical recovery.

---

## 5. Tags & Resolution Portability

The action-resolution and consequence mechanics in _caRdPG_ are actively evolving. Do not couple consequence card designs too tightly to the specifics of the current 3-level Defense/Resilience row structure.

Instead, focus on expressive **tags** (`Physical`, `Exertion`, `Cold`, `Cut`, `Bludgeon`, `Legs`, `Hands`, `Sensory`, `Social`, `Equipment`, `Supply`, etc.) that serve two enduring purposes:

1. **Connecting Actions to Fallout:** Tags link the nature of an obstacle, travel hazard, general action, or combat strike to the specific pool of consequences it can inflict.
2. **Contextual Vulnerability:** Tags identify what kinds of actions or defenses a condition interacts with across combat, overland travel, and campaign play.

> [!NOTE]
> The tag taxonomy in [Consequence Database Hub](../research/synthesis/consequence-database.md) is an initial baseline compiled during early domain research and will be revisited to align more closely with whole-campaign play, overland travel, and general actions.

---

## 6. Schema & Mini-DSL Example

```yaml
- name: "Lead-Heavy Legs"
  severity: 1
  notes: "Delayed onset muscle soreness (DOMS) from steep descents or forced marches."
  passive: "When you flip one or more cards during a physical travel or climbing check, add +1 Impact to the resolution."
  rules:
    - "Task: Rest Day (Time 24 hours; Requires Haven) → Remove this"
  tags:
    - "Exploration"
    - "Condition"
    - "Physical"
    - "Exertion"
```

### Essential Mini-DSL Syntax Rules:

- **`Task:` Clause Formatting:** Enclose task clauses in parentheses separated by semicolons: `(Check {Color} X; Time <Duration>; Cost <Text>; Requires <Tags>)`.
- **Duration Keywords:** Use canonical durations parsed by [`Core.Time`](../../core/src/Core/Time.hs): `5 min`, `15 min`, `30 min`, `1 hour`, `4 hours`, `8 hours`, `24 hours`, `1 day`, `7 days`, `14 days`.
- **Preconditions (`Requires`):** Use engine keywords (`Haven`, `Shelter`, `Campfire`, `Unburdened`) or custom narrative conditions (`dry clothes`, `clean water`).
