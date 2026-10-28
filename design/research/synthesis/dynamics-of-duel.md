---
title: "Dynamics of the Duel"
doc_type: "synthesis"
track: "verisimilitude"
origin: "AI synthesized (upgraded from legacy report)"
epistemic_status:
  confidence: "high"
  audited_by: "Gemini 3.8 Flash (Antigravity)"
  vetted_by_human: false
  vetting_notes: "Grounded in peer-reviewed combat sports chronometry and bioenergetics (Wylde et al. 2023 / PLOS One PMC10234521) and exercise metabolism (Murray 2018)."
related_files:
  - "design/research/synthesis/combat-timelines-and-tempos.md"
  - "design/research/synthesis/combat-spacing-and-reach.md"
  - "design/research/synthesis/action-duration-and-perceptual-present.md"
  - "design/research/synthesis/hardship-and-exertion.md"
  - "design/research/synthesis/stress-induced-analgesia.md"
---

# Dynamics of the Duel

## Executive Summary

The pacing, physical mechanics, and tactical progression of one-on-one armed combat are strictly bounded by human exercise physiology, bioenergetics, and neuromuscular motor control. A duel is not a continuous, high-exertion brawl; it is an intermittent, staccato series of brief explosive actions fueled by anaerobic energy pathways, interspersed with mandatory aerobic recovery lulls.

---

## 1. The Bioenergetic Engine of Single Combat

Human muscular force production during high-intensity combat shifts across three distinct metabolic pathways:[^murray-2018-glycogen-metabolism]

1. **The ATP-PCr (Phosphagen) System ($\le 15\text{ s}$):** Intracellular stores of adenosine triphosphate (ATP) and phosphocreatine (PCr) provide immediate, maximal-rate muscular contraction without requiring oxygen or producing lactic acid. Intramuscular ATP is depleted within 2–4 seconds, while PCr cleavage sustains maximal burst output for another 5–10 seconds. Replenishment is an oxidative process requiring 2–5 minutes of low-intensity recovery (a 1:10 to 1:12 work-to-rest ratio).
2. **The Anaerobic Glycolytic System ($15\text{–}90\text{ s}$):** Once phosphagen stores are exhausted, intramuscular glycogen degradation provides rapid ATP without oxygen.[^murray-2018-glycogen-metabolism] Byproducts ($H^+$ ions and lactate) cause cellular acidosis, impairing actin-myosin cross-bridge cycling and inducing muscular fatigue.
3. **The Oxidative (Aerobic) System ($2+\text{ min}$):** The high-capacity, oxygen-dependent pathway. In combat, the aerobic system sustains baseline movement (circling, maintaining guard) and serves as the primary engine of recovery—oxidizing lactate and resynthesizing phosphocreatine during lulls between exchanges.[^wylde-2023-energy-systems]

### Time-Motion Chronometry of Weapon Exchanges

Empirical time-motion analysis of elite weapon combat demonstrates how the biological recovery profile of these energy systems dictates the structural cadence of armed exchanges across distinct tactical modalities:[^wylde-2023-temporal-parameters]

| Weapon Modality | Work Phase Duration (AAT, Mean ± SD)                     | Rest Phase Duration (AHT, Mean ± SD)                     | Work-to-Rest Ratio (W/R)             | Effective Combat Time (% WT·[WT+PRT]⁻¹) | Primary Physiological Substrate & Bioenergetics                                                                                                                                                                                                                                                                                                                                                              |
| :-------------- | :------------------------------------------------------- | :------------------------------------------------------- | :----------------------------------- | :-------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sabre**       | **1.7 ± 0.4 s**<br>_(M: 1.6 ± 0.5 s, W: 1.9 ± 0.3 s)_    | **16.0 ± 3.0 s**<br>_(M: 16.6 ± 3.4 s, W: 15.5 ± 2.5 s)_ | **1:9.2**<br>_(M: 1:10.4, W: 1:8.2)_ | **9.4% – 11.5%**                        | **Alactic Phosphagen (ATP-PCr Dominance)**.<br>Immediate, highly explosive actions (<2 s) driven by rapid apparatus lockout timings (130 ms) and tactical initiative demands,[^wylde-2023-sabre-explosiveness] followed by prolonged passive inter-exchange recovery (~16 s) permitting near-total intramuscular phosphagen resynthesis without substantial lactate accumulation.[^wylde-2023-blood-lactate] |
| **Foil**        | **5.8 ± 2.5 s**<br>_(M: 5.1 ± 2.3 s, W: 6.5 ± 2.6 s)_    | **15.1 ± 3.7 s**<br>_(M: 15.6 ± 3.8 s, W: 14.5 ± 3.6 s)_ | **1:2.6**<br>_(M: 1:3.0, W: 1:2.2)_  | **25.5% – 31.8%**                       | **Mixed Alactic-Aerobic with Intermittent Glycolysis**.<br>Multi-action attack/parry phrases averaging ~5–6 s with moderate pauses (~15 s). Post-bout blood lactate remains modest (~2.4 mmol·L⁻¹), below the 4.0 mmol·L⁻¹ onset of blood lactate accumulation (OBLA) threshold.[^wylde-2023-blood-lactate]                                                                                                  |
| **Épée**        | **17.9 ± 3.1 s**<br>_(M: 18.1 ± 3.5 s, W: 17.8 ± 2.8 s)_ | **15.5 ± 5.5 s**<br>_(M: 18.6 ± 6.2 s, W: 12.4 ± 2.0 s)_ | **1:0.9**<br>_(M: 1:1.0, W: 1:0.7)_  | **53.6% – 62.5%**                       | **Aerobic Dominance with Alactic Bursts**.<br>80–90% of total match metabolic energy is aerobic,[^wylde-2023-energy-systems] supporting prolonged continuous maneuvering (~18 s work phrases) with brief rest intervals (~12–18 s). Explosive lunges draw on alactic phosphagen stores, while blood lactate remains low (~2.7 mmol·L⁻¹).[^wylde-2023-blood-lactate]                                          |

_Definitions: AAT = Average Allez Time (active combat interval between Allez and Halte); AHT = Average Halte Time (passive pause between Halte and subsequent Allez); W/R = Work-to-Rest Ratio (AAT : AHT); WT = Work Time; PRT = Period Rest Time._

### The Inescapable Staccato Rhythm

The striking alignment between the biochemical recovery ratio of the phosphagen system (1:10 to 1:12) and the empirically observed work-to-rest ratio in elite sabre fencing (1:9.2 to 1:10.4) confirms that single decisive actions are constrained by cellular bioenergetics:[^wylde-2023-temporal-parameters]

- **The Decisive Burst:** In weapons combat characterized by high lethality and lack of right-of-way incentive to delay attack initiation, combatants commit to short, violent bursts of 1–2 seconds.[^wylde-2023-sabre-explosiveness]
- **The Mandatory Pause:** Following a committed flurry, combatants are physiologically forced to separate and maneuver in measure. The ~16-second pause observed across all weapons provides the metabolic window needed for rapid phosphagen resynthesis ($t_{1/2} \approx 20\text{–}30\text{ s}$).
- **The Aerobic Reserve:** In prolonged probing engagements (analogous to épée), 80–90% of the energy expended during active footwork and distance management is supplied aerobically,[^wylde-2023-energy-systems] preserving intramuscular phosphocreatine for the decisive explosive lunge.

---

## 2. Tactical Pedagogy and the First Exchange

The opening seconds of an armed encounter represent a singular physiological state. The acute sympathetic stress response floods the bloodstream with epinephrine and norepinephrine, inducing tachycardia, pupillary dilation, peripheral vasoconstriction, and stress-induced analgesia.

Simultaneously, intracellular phosphagen stores are fully charged. The first 10–15 seconds represent the only window in which a combatant can operate at absolute peak power output before the onset of fatigue.

Historical combat doctrines intuitively exploited this non-repeatable window:

- **The Doctrine of _Vor_ ("Before"):** Johannes Liechtenauer's German longsword school prioritizes taking the initiative to force the opponent into the purely reactive _Nach_ ("After").
- **Fight-Ending Master Cuts (_Meisterhäue_):** The five master cuts (Zornhau, Krumphau, Zwerchhau, Schielhau, Scheitelhau) are single-tempo counter-attacks designed to simultaneously deflect an incoming blow and strike an opening, terminating the encounter within the initial phosphagen window.
- **Cognitive Adaptation under Stress:** High cognitive stress causes perceptual narrowing (tunnel vision) and impairs novel problem-solving. Liechtenauer codified these principles into a mnemonic poem, the _Zettel_—using simple, rhyming couplets to ensure rapid recall when complex cognitive processing is compromised.

---

## 3. Devolution to Grappling and Sensorimotor Breakdown

When a duel is not resolved in the opening exchange, cumulative anaerobic exertion induces progressive physical and cognitive degradation:

- **Physical Degradation:** As high-intensity work exceeds 15–90 seconds, intracellular acidosis and glycogen depletion cause reduced muscle force output, increased kinematic movement variability, and a 1.5% to 14.3% slowing of choice reaction times.
- **Cognitive Breakdown:** Metabolic distress and sympathetic overload impair executive function, inducing "brain fog" and forcing combatants to abandon adaptive decision-making in favor of pre-programmed motor habits.
- **Devolution from Fencing to Grappling:** Fine motor skills, subtle blade control, and rapid precision footwork (_Zogho Largo_) degrade first under acute fatigue. As distance fencing becomes dangerously error-prone, combat naturally collapses into close play (_Zogho Stretto_), where gross motor skills—pushing, pulling, clinching, and leverage—are resilient to fatigue.
- **Codification of Grappling:** Historical manuals reflect this physiological inevitability. Liechtenauer's _Ringen am Schwert_ (wrestling at the sword) and Fiore dei Liberi's _Abrazare_ (unarmed grappling as the foundation of _Il Fior di Battaglia_) systematically teach infighting techniques, joint locks, and throws executed while retaining or trapping the weapon.

---

## 4. The Post-Combat State and Non-Lethal Trauma

Surviving a violent confrontation does not leave a combatant primed for immediate subsequent action. The immediate aftermath is characterized by acute vulnerability:

- **Postural Disruption:** Kinetic impact shifting the center of gravity outside the base of support leaves a combatant functionally helpless for 1–2 seconds while core muscles re-establish equilibrium.
- **Concussive Ataxia:** Acceleration-deceleration forces on the brain induce mild traumatic brain injury, manifesting as ataxia, staggering gait, and motor incoordination that can persist well past the immediate clash.
- **The Autonomic Rebound ("Crash"):** Following the withdrawal of intense sympathetic stimulation, the body undergoes a parasympathetic rebound. Within 15–60 minutes, the combatant experiences profound exhaustion, muscle tremors, nausea, dizziness, and cognitive lethargy. _(Note: This physiological rebound is a normal neuroendocrine recovery response, distinct from clinical adrenal crisis)._
- **Stress-Induced Analgesia & "Walking Wounded":** Acute threat triggers dual opioid and non-opioid (endocannabinoid $\text{CB}_1$ and descending serotonergic $5\text{-HT}_{1\text{A}}$ / noradrenergic) pain suppression (see detailed synthesis in [stress-induced-analgesia.md](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/stress-induced-analgesia.md)). While initial pain contact is substantially blunted, central sensitization (wind-up slope across repeated strikes) remains completely uninhibited. Crucially, subjective antinociception provides zero structural protection: combatants frequently sustain fractures, deep lacerations, or ligament tears without conscious awareness, risking catastrophic secondary tissue destruction when continuing high-intensity exertion during the 10–40 minute analgesic window.

---

## Citations and Primary References

[^murray-2018-glycogen-metabolism]:
    source: murray-2018-fundamentals-glycogen-metabolism
    locator: "Introduction, p. 244 ([extracted.md#L9](../sources/verisimilitude/murray-2018-fundamentals-glycogen-metabolism/extracted.md#L9))"
    quote: "During intense, intermittent exercise and throughout prolonged physical activity, muscle glycogen particles are broken down, freeing glucose molecules that muscle cells then oxidize through anaerobic and aerobic processes to produce the adenosine triphosphate (ATP) molecules required for muscle contraction.1 The rate at which muscle glycogen is degraded depends primarily upon the intensity of physical activity; the greater the exercise intensity, the greater the rate at which muscle glycogen is degraded."
    status: unverified

[^wylde-2023-temporal-parameters]:
    source: wylde-2023-temporal-demands-fencing
    locator: "lines 98 ([extracted.md#L98](../sources/verisimilitude/wylde-2023-temporal-demands-fencing/extracted.md#L98))"
    quote: "In a global analysis, by weapon, we observe that the AAT values are 17.9 ± 3.1s for épée and 5.8 ± 2.5s for foil and 1.7 ± 0.4s for the sabre. On the other hand, the AHT records are 15.5 ±5.5s; 15.1 ±3.7s; 16.0 ±3.0s respectively. Finally, the W/R in épée is 1:0.9, in foil 1:2.6 and in sabre 1:9.2."
    status: unverified

[^wylde-2023-sabre-explosiveness]:
    source: wylde-2023-temporal-demands-fencing
    locator: "line 366 ([extracted.md#L366](../sources/verisimilitude/wylde-2023-temporal-demands-fencing/extracted.md#L366))"
    quote: "In sabre, both opponents want to have the initiative, which is why sabre has become a weapon with a lot of physical power, with immediate and very explosive actions motivated by the regulations and the new blocking times of the apparatus."
    status: unverified

[^wylde-2023-blood-lactate]:
    source: wylde-2023-temporal-demands-fencing
    locator: "line 372 ([extracted.md#L372](../sources/verisimilitude/wylde-2023-temporal-demands-fencing/extracted.md#L372))"
    quote: "blood lactate concentrations across all weapons are below the onset of blood lactate accumulation (4mmol.L-1) ... suggesting a relatively low reliance on the lactic acid system."
    status: unverified

[^wylde-2023-energy-systems]:
    source: wylde-2023-temporal-demands-fencing
    locator: "line 372 ([extracted.md#L372](../sources/verisimilitude/wylde-2023-temporal-demands-fencing/extracted.md#L372))"
    quote: "several authors have a general agreement that all weapons rely on the alactic energy system to provide explosive movements such as the lunge ... found that 80–90% of a fight utilises the aerobic energy system and increases as a fight progresses."
    status: unverified
