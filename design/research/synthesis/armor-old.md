# Factual Basis for Design: The Armor Tradeoff

This document provides an evidence-based framework for modeling armor. It translates our research findings into a practical reference for designing mechanics that capture the fundamental tradeoff of wearing armor: the balance between its protective qualities and its significant physiological cost.

## The Core Tradeoff: Protection vs. Exertion

Armor's primary function is to protect the wearer from harm. However, this protection is not free. Every layer of armor imposes a direct and quantifiable physiological cost, impacting a combatant's mobility, endurance, and overall effectiveness. Our design approach models this tradeoff through two key lenses: **Protection Profile** (how armor mitigates harm) and **Physiological Cost** (the energetic price of wearing it).

---

## Part 1: Protection Profile

An armor's ability to prevent injury is determined by how it manages the energy of an incoming blow. This is achieved through two physical principles:

- **Spatial Distribution:** The armor's ability to spread the force of an impact over a wide area. This is the primary function of **rigid** components like steel plates or hardened leather.
- **Temporal Distribution:** The armor's ability to cushion a blow by increasing the duration of the impact. This is the primary function of **soft**, compressible components like a padded gambeson.

### Armor Tiers & Protective Function

The following table summarizes the protective qualities of core armor types. The ratings are on a 1-10 scale, where 10 represents the pinnacle of protection against that type of harm.

| Armor Type                                   | Key Principle(s)            | vs. Shearing/Slashing | vs. Piercing | vs. Crushing | Tactical Summary                                                                                                                                                                                                                               |
| :------------------------------------------- | :-------------------------- | :-------------------- | :----------- | :----------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Padded Doublet (Gambeson)**                | Temporal                    | 3/10                  | 1/10         | 2/10         | Excellent at turning moderate cuts into bruises, but offers little protection against focused thrusts or heavy blunt force.                                                                                                                    |
| **Maille Hauberk (over Gambeson)**           | Temporal + Shear Resistance | 8/10                  | 4/10         | 3/10         | A composite system. The maille is nearly immune to cuts, while the gambeson absorbs some blunt force. It remains vulnerable to powerful thrusts and concussive blows.                                                                          |
| **Brigandine / Lamellar (over Gambeson)**    | Spatial + Temporal          | 9/10                  | 7/10         | 6/10         | A highly effective composite defense. The overlapping internal plates provide excellent spatial distribution against all forms of attack.                                                                                                      |
| **Full Plate Harness (over Arming Doublet)** | Spatial + Temporal          | 10/10                 | 9/10         | 8/10         | The pinnacle of personal protection. The large, perfectly shaped steel plates offer unmatched spatial distribution, making the wearer nearly immune to cuts and highly resistant to all but the most powerful, specialized anti-armor attacks. |

---

## Part 2: Physiological Cost

The most significant and defining cost of wearing armor is not clumsiness, but a severe and quantifiable increase in the metabolic energy required for any physical action. This "energetic tax" fundamentally alters a combatant's stamina, forcing a more deliberate and efficient fighting style.

### The Energetic Tax of Armor

The following table synthesizes the findings from our research reports, using a **Metabolic Cost Multiplier** to quantify the increased energy expenditure of wearing different armor tiers compared to being unarmored.

| Armor Tier             | Approx. Weight (kg) | Metabolic Cost Multiplier | Dynamic Reach Penalty (Est.) | Key Fatigue Mechanisms                                                                                                                                                       |
| :--------------------- | :------------------ | :------------------------ | :--------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Unarmored**          | N/A                 | **1.0x**                  | 0%                           | Baseline human performance.                                                                                                                                                  |
| **Gambeson**           | 2-4                 | **~1.1x - 1.2x**          | ~5%                          | Primarily severe heat retention and insulation.                                                                                                                              |
| **Maille + Gambeson**  | 12-18               | **~1.3x - 1.5x**          | ~10%                         | Significant weight with poor, shoulder-based load distribution, causing high muscular fatigue over time.                                                                     |
| **Full Plate Harness** | 30-50               | **~1.9x - 2.3x**          | ~15-20%                      | High total mass and limb-distributed weight more than doubles the energy cost of locomotion. The cuirass and helmet also restrict breathing mechanics, accelerating fatigue. |
