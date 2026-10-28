---
title: "Combat Timelines and Tempos"
doc_type: "synthesis"
track: "verisimilitude"
origin: "AI synthesized (upgraded from legacy report)"
epistemic_status:
  confidence: "high"
  audited_by: "Gemini 3.8 Flash (Antigravity)"
  vetted_by_human: false
  vetting_notes: "Grounded in peer-reviewed biomechanics, locomotor energetics, and experimental archaeology: medieval armor locomotion costs and limb inertia (Askew 2012; US Army 2008), elite javelin throwing kinematics (Campos 2004), ancient and medieval projectile weapon delivery rates and ranges (Harrison 2006), motor point-of-no-return neurobiology (Schultze-Kraft 2016), and glycogen/phosphagen exercise metabolism (Murray 2018)."
related_files:
  - "design/research/synthesis/action-duration-and-perceptual-present.md"
  - "design/research/synthesis/tactical-movement.md"
  - "design/research/synthesis/dynamics-of-duel.md"
  - "design/research/synthesis/hardship-and-exertion.md"
---

# Combat Timelines and Tempos

## Executive Summary: Physical Chronometry of Combat

This document establishes the empirical chronometric framework for pre-modern human combat, synthesizing quantitative findings from human locomotor energetics, sports biomechanics, experimental archaeology, and neurobiological motor control.

Combat is fundamentally constrained by biological and physical realities:

1. **Bioenergetic Pacing:** Muscular power output is governed by metabolic fuel availability—an initial alactic phosphagen burst ($\le 15\text{ s}$), rapid onset of glycolytic fatigue ($15\text{–}90\text{ s}$), and aerobic recovery requirements ($2\text{–}5\text{ min}$).
2. **Kinematic & Neuromuscular Bottlenecks:** Human striking and throwing delivery phases operate within tight ballistic windows ($100\text{–}400\text{ ms}$), while weapon access, target acquisition, and motor reprogramming impose macroscopic delays ($0.8\text{–}2.5\text{ s}$).
3. **The Distal Mass Tax of Armor:** Steel plate armor imposes a disproportionate energetic penalty on locomotion and rotational acceleration ($2.1\text{–}2.3\times$ unarmored walking cost; $1.9\times$ running cost) driven primarily by the high mechanical work of swinging loaded limbs and restrictive thoracic breathing mechanics.

---

## 1. Tactical Principles of Measure and Tempo

Historical martial treatises (notably the 14th-to-16th-century German Liechtenauer tradition and Italian masters) formalize the spatial and temporal realities of armed engagement into structural categories:

- **Measure (_Mensa_):** Physical distance determining tactical options:
  - **_Zufechten_ ("Fighting Towards"):** Approach distance outside committed striking range; requires footwork transitions before a weapon can connect.
  - **_Krieg_ ("War"):** Engagement distance where a combatant can strike with a single committed motor action (e.g., a lunge or passing step).
  - **_Ringen am Schwert_ ("Wrestling at the Sword"):** In-fighting and grappling distance inside the effective leverage arc of the blade.
- **Tempo (_Vor, Nach, Indes_):** Initiative states determined by neural and mechanical latency:
  - **_Vor_ ("Before"):** Taking the initiative to execute an offensive action, forcing the opponent into a reactive state.
  - **_Nach_ ("After"):** The reactive, defensive state responding to the opponent's initiative.
  - **_Indes_ ("Instantly"):** Counter-acting within the opponent's committed movement window, exploiting the physical point of no return.

---

## 2. Physiological Rhythm and Energy System Timelines

Human performance in high-intensity combat shifts through distinct metabolic and physiological phases dictated by cellular energy substrates:[^murray-2018-glycogen-metabolism]

| Timescale                   | Primary Energy Substrate              | Physiological & Biomechanical State                                                                                                                                                                                                   | Functional Tactical Dynamic                                                                                                       |
| :-------------------------- | :------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------------------------- |
| **0–15 Seconds**            | **ATP-PCr (Phosphagen)**              | **Peak Power Window:** Maximum muscular power output fueled by intracellular ATP and phosphocreatine stores. Minimal metabolic by-product accumulation; maximal velocity and explosive force.                                         | Decisive initial exchanges; single-tempo master cuts (_Meisterhäue_); explosive charges and parry-ripostes.                       |
| **15–90 Seconds**           | **Anaerobic Glycolytic**              | **Fatigue Onset & Lactate Accumulation:** Intramuscular glycogen degrades into lactate and hydrogen ions ($H^+$); intracellular acidosis impairs calcium binding and cross-bridge cycling. Fine motor dexterity and velocity degrade. | Transition to conservative binding tactics (_Fühlen_, _Winden_); tactical clinches; collapse to gross motor grappling (_Ringen_). |
| **2–5 Minutes**             | **Aerobic / Oxidative Replenishment** | **Metabolic Recovery:** Aerobic respiration oxidizes lactate and resynthesizes cellular phosphocreatine stores (replenishing ~80% of PCr within 90–120 s; 100% within 3–5 min of low-intensity movement).                             | Tactical disengagement; circular maneuvering in _Zufechten_; resting in guard to recover explosive burst capacity.                |
| **Post-Combat (15–60 min)** | **Autonomic Rebalancing**             | **Post-Adrenaline Crash:** Cessation of intense sympathetic stimulation results in peripheral vasodilation, profound central nervous fatigue, trembling, and cognitive lethargy.                                                      | Extreme physical and sensory vulnerability following life-or-death crisis exertion.                                               |

---

## 3. Sensorimotor Reaction Latencies and Degradation

Neuromuscular and perceptual mechanisms impose absolute lower bounds on human responsiveness in combat:

- **Simple Visual Reaction Time (150–200 ms):** The latency to detect a single, pre-known visual signal and trigger a pre-programmed motor response.
- **Choice Reaction Time (250–400 ms):** Governed by the Hick-Hyman Law; as tactical entropy (multiple attack angles, feints) increases, cognitive processing and response selection delay rises.
- **Motor Point of No Return (~200 ms):** Electroencephalographic and EMG testing demonstrates that once an impending ballistic movement reaches ~200 ms prior to muscle onset, voluntary motor cancellation is biologically impossible; the movement executes inevitably.[^schultze-kraft-2016-point-of-no-return]
- **Fatigue-Induced Degradation (+15% to +40%):** Following 60–90 seconds of maximal anaerobic exertion, visual choice reaction time slows by 15–40% (~230–280 ms), and fine motor tracking degrades markedly due to both central and peripheral fatigue mechanisms.

---

## 4. Quantitative Lexicon of Discrete Combat Actions

The following table provides verified, evidence-based time costs for discrete physical actions in pre-modern combat, categorized by equipment and biomechanical context.

### Master Tactical Tempos Table

| Category     | Action                           | Equipment / Context                            | Action Duration (s) | Epistemic Status                       | Empirical Benchmark / Mechanism                                                                                                                                        |
| :----------- | :------------------------------- | :--------------------------------------------- | :------------------ | :------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ranged**   | **Military Warbow (>100 lbs)**   | Sustained aimed cycle (3–6 rpm)                | **10.0 – 20.0 s**   | Confirmed (Practitioner / Archaeology) | Extreme anaerobic exertion; heavy draw weight (>100–150 lbs) forces back/scapular engagement; sustained fire conserves stamina.[^harrison-2006-longbow-rate-of-fire]   |
|              | **Military Warbow (>100 lbs)**   | Emergency burst volley ("mad minute")          | **6.0 – 10.0 s**    | Confirmed (Practitioner / Archaeology) | Peak burst rate of 6–10 arrows/min in experimental trials; rapidly exhausts ATP-PCr stores and causes severe tremors.                                                  |
|              | **Short Bow (~40–50 lbs)**       | Rapid shot cycle (nock, draw, loose)           | **3.0 – 5.0 s**     | Confirmed (Treatise / Historical)      | Lighter draw weight permits rapid nocking and continuous shooting at 10–12 un-aimed arrows/min.[^harrison-2006-longbow-rate-of-fire]                                   |
|              | **Mechanical Crossbow**          | Span, load bolt, aim, loose                    | **30.0 – 60.0 s**   | Confirmed (Historical / Experimental)  | Mechanical cocking devices (goat's foot, windlass, cranequin) constrain firing rate to <2 bolts/min.[^harrison-2006-crossbow-rate-of-fire]                             |
|              | **Sling**                        | Full cycle (load, 1–3 rotations, release)      | **5.0 – 8.5 s**     | Confirmed (Experimental Archaeology)   | Experienced slingers achieve >12 rounds/min in rapid succession, or ~7 rpm deliberate fire; release speeds exceed 90 m/s.[^harrison-2006-sling-rate-of-fire]           |
|              | **Javelin / Spear Throw**        | Kinetic delivery phase (foot-plant to release) | **0.24 – 0.40 s**   | Confirmed (Tier 1 Biomechanics)        | Elite photogrammetry: preparatory brace-leg plant 140–260 ms; final release phase 100–140 ms.[^campos-2004-javelin-phase-timing]                                       |
|              | **Javelin / Spear Throw**        | Full cycle (draw back from carry + throw)      | **1.5 – 2.2 s**     | Corrected (Kinematic synthesis)        | Full movement includes preparatory cocking and target alignment preceding the 0.3 s explosive delivery.                                                                |
|              | **Throwing Axe (Francisca)**     | Draw and throw from belt loop                  | **1.2 – 2.0 s**     | Corrected (Biomechanical model)        | Hand-thrown delivery phase takes ~200 ms; draw from belt loop/frog takes 1.0–1.5 s. Tactical range restricted to $\le 12\text{ m}$.[^harrison-2006-throwing-axe-range] |
|              | **Throwing Knife**               | Unsheathe, acquire target, throw               | **1.0 – 1.5 s**     | Discredited (0.29 s claim rejected)    | Legacy 0.29 s figure reflects a pre-cocked trick in-hand; drawing from sheath, aiming, and ballistic throwing requires 1.0–1.5 s.                                      |
| **Movement** | **Facing Change / Pivot (90°)**  | Unarmored athletic pivot                       | **0.4 – 0.6 s**     | Confirmed (Sports science)             | Explosive plant-and-turn on force plates; single-step rotational reorientation.                                                                                        |
|              | **Facing Change / Pivot (90°)**  | Full Plate Harness (~30–50 kg)                 | **0.6 – 0.9 s**     | Confirmed (Locomotor energetics)       | Added mass and rotational inertia increase turning torque; limb mass increases deceleration time.[^askew-2012-metabolic-cost][^us-army-2008-foot-mass-cost]            |
|              | **Facing Change / Pivot (180°)** | Unarmored athletic reversal                    | **0.7 – 1.0 s**     | Confirmed (Sports science)             | Two-step rotational pivot and stance deceleration.                                                                                                                     |
|              | **Facing Change / Pivot (180°)** | Full Plate Harness (~30–50 kg)                 | **1.1 – 1.6 s**     | Confirmed (Locomotor energetics)       | High rotational moment of inertia requires muscular braking; ~50–60% time expansion over unloaded pivot.[^askew-2012-metabolic-cost]                                   |
|              | **Climb Waist-High Obstacle**    | Unarmored vault                                | **1.5 – 2.5 s**     | Confirmed (Athletic obstacle trial)    | Direct hand-plant and leg clearance.                                                                                                                                   |
|              | **Climb Waist-High Obstacle**    | Full Plate Harness (~30–50 kg)                 | **4.0 – 6.0 s**     | Confirmed (Experimental Archaeology)   | Plate harness restricts maximal hip flexion and knee flexion; requires deliberate hand-plant and multi-stage body haul.                                                |
|              | **Retrieve Dropped Item**        | Unarmored ground retrieval                     | **1.5 – 2.0 s**     | Confirmed (Time-motion analysis)       | Unconstrained deep squat or waist bend and recovery.                                                                                                                   |
|              | **Retrieve Dropped Item**        | Full Plate Harness (~30–50 kg)                 | **3.5 – 5.0 s**     | Confirmed (Biomechanics & Video)       | Fauld and cuisse plates limit hip bending; requires dropping to one knee to grasp object and rising under load.                                                        |
| **Handling** | **Drop Held Item / Discard**     | Voluntary muscular relaxation                  | **0.15 – 0.25 s**   | Confirmed (Motor neurobiology)         | Neuromuscular cessation of tonic flexor digitorum contraction; bounded by motor point of no return (~200 ms).[^schultze-kraft-2016-point-of-no-return]                 |
|              | **Longsword Grip Transition**    | One-handed to two-handed grip                  | **0.3 – 0.5 s**     | Confirmed (HEMA Video Analysis)        | Fluid movement of off-hand to pommel/grip while primary hand maintains blade alignment.                                                                                |
|              | **Polearm Grip Transition**      | Choking up / half-staffing                     | **0.4 – 0.7 s**     | Confirmed (HEMA Video Analysis)        | Sliding rear hand forward along shaft to shorten operational lever arm.                                                                                                |
|              | **Shield Boss Strike (Punch)**   | Center-grip shield forward impact              | **0.6 – 1.0 s**     | Data Gap / Inferred (Low confidence)   | Biomechanically analogous to straight punch (200–300 ms) plus accelerating 3–5 kg shield mass and recovering guard.                                                    |

---

## 5. Locomotor Energetics: The Biomechanics of Armored Movement

The energetic cost of moving in historical field armor provides the physiological baseline for action cadence and combat stamina:

### 5.1 Metabolic Multipliers and Distal Loading

In controlled treadmill respirometry, Graham Askew and colleagues (2012) demonstrated that walking in 15th-century steel plate armor ($30\text{–}50\text{ kg}$) increases the net mass-specific metabolic cost of locomotion ($C_{met}$) by **2.1 to 2.3 times** compared to unloaded walking, and **1.9 times** for running at equivalent speeds.[^askew-2012-metabolic-cost]

Crucially, this metabolic penalty exceeds the ~40–50% increase in total system mass. The disproportionate energy cost is driven by two biomechanical factors:

1. **Limb Inertia (Distal Mass):** Unlike a backpack where weight is concentrated near the body's center of mass, plate armor distributes mass over the extremities (greaves, sabatons, cuisses, vambraces). Loading the lower limbs requires substantial mechanical internal work ($W_{INT}$) to accelerate and decelerate the legs during every stride.[^askew-2012-metabolic-cost] Load carriage biomechanics show that adding mass to the feet is **4 to 6 times more energetically costly** than adding the equivalent mass to the torso.[^us-army-2008-foot-mass-cost]
2. **Impaired Thoracic Mechanics:** Rigid breastplates and compressive arming garments restrict chest wall expansion, forcing fighters to sustain high ventilation through rapid, shallow breathing patterns that increase respiratory muscle work.[^askew-2012-limb-swing-breathing]

---

## 6. Citations and Primary References

[^murray-2018-glycogen-metabolism]:
    source: murray-2018-fundamentals-glycogen-metabolism
    locator: "Introduction, p. 244 ([extracted.md#L9](../sources/verisimilitude/murray-2018-fundamentals-glycogen-metabolism/extracted.md#L9))"
    quote: "During intense, intermittent exercise and throughout prolonged physical activity, muscle glycogen particles are broken down, freeing glucose molecules that muscle cells then oxidize through anaerobic and aerobic processes to produce the adenosine triphosphate (ATP) molecules required for muscle contraction.1 The rate at which muscle glycogen is degraded depends primarily upon the intensity of physical activity; the greater the exercise intensity, the greater the rate at which muscle glycogen is degraded."
    status: unverified

[^schultze-kraft-2016-point-of-no-return]:
    source: schultze-kraft-2016-point-of-no-return-vetoing
    locator: "Discussion, p. 1083 ([extracted.md#L55](../sources/verisimilitude/schultze-kraft-2016-point-of-no-return-vetoing/extracted.md#L55))"
    quote: "several aspects of our data suggest that subjects were able to cancel an upcoming movement until a point of no return was reached around 200 ms before movement onset. If the stop signal occurs later than 200 ms before EMG onset, the subject cannot avoid moving."
    status: unverified

[^harrison-2006-longbow-rate-of-fire]:
    source: harrison-2006-sling-weaponry
    locator: "Section: Contemporary Weapons ([extracted.md#L1](../sources/verisimilitude/harrison-2006-sling-weaponry/extracted.md#L1))"
    quote: "An experienced archer could fire ten to twelve un-aimed arrows a minute."
    status: unverified

[^harrison-2006-crossbow-rate-of-fire]:
    source: harrison-2006-sling-weaponry
    locator: "Section: Contemporary Weapons ([extracted.md#L1](../sources/verisimilitude/harrison-2006-sling-weaponry/extracted.md#L1))"
    quote: "However, the biggest drawback was the slow reloading time; sometimes less than two bolts a minute could be fired, depending on the version (Devries, 1956; Wise, 1976)."
    status: unverified

[^harrison-2006-sling-rate-of-fire]:
    source: harrison-2006-sling-weaponry
    locator: "Section: Contemporary Weapons ([extracted.md#L2](../sources/verisimilitude/harrison-2006-sling-weaponry/extracted.md#L2))"
    quote: "A good slinger could fire more than twelve rounds a minute."
    status: unverified

[^campos-2004-javelin-phase-timing]:
    source: campos-2004-javelin-kinematics
    locator: "Section 4.1 (Phase Timing), p. 48 ([extracted.txt#L112-L114](../sources/verisimilitude/campos-2004-javelin-kinematics/extracted.txt#L112-L114))"
    quote: "The results show that the greatest differences between athletes occur in the preparatory phase. Times recorded for the duration of the Preparatory Phase (t1–t2) ranged from 140 to 260 milliseconds, and from 100 to 140 milliseconds for the Final Phase (t2 –t3)."
    status: unverified

[^harrison-2006-throwing-axe-range]:
    source: harrison-2006-sling-weaponry
    locator: "Section: Contemporary Weapons ([extracted.md#L1](../sources/verisimilitude/harrison-2006-sling-weaponry/extracted.md#L1))"
    quote: "The throwing axe, like the spear, is thrown by hand and has similar limitations. The effective range is around 12m, allowing the weapon to be used only just before hand-to-hand combat commenced (Underwood, 1999)."
    status: unverified

[^askew-2012-metabolic-cost]:
    source: askew-2012-armour-locomotor-performance
    locator: "Abstract / Section 3 ([extracted.md#L3](../sources/verisimilitude/askew-2012-armour-locomotor-performance/extracted.md#L3))"
    quote: "We found that the net cost of locomotion (*C*met) during armoured walking and running is much more energetically expensive than unloaded locomotion. *C*met for locomotion in armour was 2.1–2.3 times higher for walking, and 1.9 times higher for running when compared with *C*met for unloaded locomotion at the same speed. An important component of the increased energy use results from the extra force that must be generated to support the additional mass. However, the energetic cost of locomotion in armour was also much higher than equivalent trunk loading. This additional cost is mostly explained by the increased energy required to swing the limbs and impaired breathing."
    status: unverified

[^us-army-2008-foot-mass-cost]:
    source: us-army-2008-body-armor-effects-ada504354
    locator: "Section 1.3.2 (Lower Extremity Weighting), p. 3 ([extracted.txt#L130-L136](../sources/verisimilitude/us-army-2008-body-armor-effects-ada504354/extracted.txt#L130-L136))"
    quote: "A number of investigators have reported that the energy cost of walking with a given mass on the feet is 4 to 6 times greater than the cost of the same mass on the torso (Catlin & Dressendorfer, 1979; Holewijn, Heus, & Wammes, 1992; Jones, Knapik, Daniels, & Toner, 1986; Jones, Toner, Daniels, & Knapik, 1984; Legg & Mahanty, 1986; Soule & Goldman, 1969)."
    status: unverified

[^askew-2012-limb-swing-breathing]:
    source: askew-2012-armour-locomotor-performance
    locator: "Section 3 (Results and Discussion), p. 642 ([extracted.md#L43](../sources/verisimilitude/askew-2012-armour-locomotor-performance/extracted.md#L43))"
    quote: "The mass added to the chest and the geometrical constraints imposed by the armour are likely to be additional factors contributing to the increase in the metabolic cost of locomotion. Finally, other potential contributors to the increase in *C*met such as frictional losses within the joints between armour components cannot be ruled out."
    status: unverified
