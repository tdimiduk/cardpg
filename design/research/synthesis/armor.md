# Factual Basis for Design: The Armor Tradeoff

This document provides an evidence-based framework for modeling armor. It translates our research findings into a practical reference for designing mechanics that capture the fundamental tradeoff of wearing armor: the balance between its protective qualities and its significant physiological cost.

## The Core Tradeoff: Protection vs. Exertion

Armor's primary function is to protect the wearer from harm. However, this protection is not free. Every layer of armor imposes a direct and quantifiable physiological cost, impacting a combatant's mobility, endurance, and overall effectiveness. Our design approach models this tradeoff through two key lenses: **Protection Profile** (how armor mitigates harm) and **Physiological Cost** (the energetic price of wearing it).

---

## Part 1: Protection Profile

An armor's ability to prevent injury is determined by how it manages the energy of an incoming blow. This is achieved through two physical principles:

* **Spatial Distribution:** The armor's ability to spread the force of an impact over a wide area. This is the primary function of **rigid** components like steel plates or hardened leather.
* **Temporal Distribution:** The armor's ability to cushion a blow by increasing the duration of the impact. This is the primary function of **soft**, compressible components like a padded gambeson.

### Protection Rating Key

The following numerical ratings (1-10) are used to provide a scannable, absolute measure of an armor's effectiveness against different types of harm. Each number corresponds to a specific functional outcome.

| Rating | Functional Description | Tactical Outcome |
| :--- | :--- | :--- |
| **1-2** | **Vulnerable** | The armor offers little to no effective protection. The attack's effect is largely unabated. |
| **3-4** | **Resistant** | The armor mitigates the attack, significantly reducing its severity. A cut may be turned into a bruise; a thrust may be deflected or slowed. |
| **5-6** | **Robustly Resistant** | The armor reliably mitigates the attack, usually preventing any significant harm from all but the most powerful or well-aimed strikes. |
| **7-8** | **Highly Resistant** | The armor is exceptionally effective, negating the vast majority of attacks of this type. Only specialized tactics or overwhelming force have a reasonable chance of causing harm. |
| **9** | **Nearly Immune** | The armor's physical properties make it almost impossible to defeat with this type of attack. Harm is only possible by targeting small, specific gaps or through overwhelming, atypical force. |
| **10** | **Functionally Immune** | By the laws of physics, the armor cannot be defeated by this type of attack under normal combat conditions (e.g., a sword edge cannot cut through a solid steel plate). |

### Armor Tiers & Protective Function

| Armor Type | Key Principle(s) | vs. Shearing/Slashing | vs. Piercing | vs. Crushing |
| :--- | :--- | :--- | :--- | :--- |
| **Padded Doublet (Gambeson)** | Temporal | 3 | 1 | 2 |
| **Maille Hauberk (over Gambeson)** | Temporal + Shear Resistance | 8 | 4 | 3 |
| **Brigandine / Lamellar (over Gambeson)** | Spatial + Temporal | 9 | 7 | 6 |
| **Full Plate Harness (over Arming Doublet)**| Spatial + Temporal | 10 | 9 | 8 |

---

## Part 2: Physiological Cost

The most significant and defining cost of wearing armor is not clumsiness, but a severe and quantifiable increase in the metabolic energy required for any physical action. This "energetic tax" fundamentally alters a combatant's stamina, forcing a more deliberate and efficient fighting style.

The primary drivers of this cost are the distribution of mass onto the limbs, the efficiency of the armor's load-bearing structure, secondary stressors like thermoregulation and respiratory restriction, and finally, total mass.

### The Energetic Tax of Armor

The following table synthesizes the findings from our research reports, using a **Metabolic Cost Multiplier** to quantify the increased energy expenditure of wearing different armor tiers compared to being unarmored. A higher multiplier means a greater drain on stamina for any given action.

| Armor Tier | Approx. Weight (kg) | Metabolic Cost Multiplier (vs. Unarmored) | Key Fatigue Mechanisms | Source Confidence |
| :--- | :--- | :--- | :--- | :--- |
| **Unarmored** | N/A | **1.0x** | Baseline human performance. | High |
| **Maille + Gambeson** | 14 - 18 | **~1.6x** | Poor load distribution (hanging from shoulders), significant heat retention from the gambeson. | Medium-Low |
| **Full Plate Harness (Standard Fit)** | 30 - 40 | **~2.2x** | High total mass, with a disproportionate cost from the weight on the limbs. The cuirass and helmet can also restrict breathing. | High |
| **Full Plate Harness (Masterwork Fit)** | 30 - 40 | **~1.7x** | Superior articulation and load distribution mitigate some of the limb-loading penalties, functioning more like an efficient exoskeleton. | Medium |
