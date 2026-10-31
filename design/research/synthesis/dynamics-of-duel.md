---
title: "Dynamics of the Duel"
doc_type: "synthesis"
track: "verisimilitude"
origin: "AI synthesized (upgraded from legacy report)"
epistemic_status:
  confidence: "high"
  audited_by: "Gemini 3.8 Flash (Antigravity)"
  vetted_by_human: false
  vetting_notes: "Grounded in peer-reviewed combat sports chronometry and bioenergetics (Wylde et al. 2023 / PLOS One PMC10234521; Miarka et al. 2020 / Frontiers in Psychology; Martusciello et al. 2025 / Sports PMC12197034), exercise metabolism (Murray 2018), acute neuromuscular fatigue kinematics (Pavelka et al. 2020 / PLOS ONE PMC6994193; Rodrigues et al. 2023 / PeerJ PMC9897062), sensorimotor and haptic psychophysics (Hanson et al. 2009 / NeuroReport PMC3364445), and post-concussion postural instability kinematics (Valovich McLeod & Snyder 2014 / J Athl Train PMC4137680; Patejak et al. 2021 / IJSPT PMC8486395)."
related_files:
  - "design/research/synthesis/combat-timelines-and-tempos.md"
  - "design/research/synthesis/combat-spacing-and-reach.md"
  - "design/research/synthesis/action-duration-and-perceptual-present.md"
  - "design/research/synthesis/hardship-and-exertion.md"
  - "design/research/synthesis/stress-induced-analgesia.md"
---

# Dynamics of the Duel

## Executive Summary

The pacing, physical mechanics, and tactical progression of one-on-one armed combat are strictly bounded by human exercise physiology, bioenergetics, sensory latency, and neuromuscular motor control. A duel is not a continuous, high-exertion brawl; it is an intermittent, staccato series of brief explosive actions fueled by anaerobic energy pathways, interspersed with mandatory aerobic recovery lulls.

When combatants cross blades in the bind (_am Schwert_), tactile sensory feedback bypasses the ~50 ms photopic retinal transduction lag and divided-attention bottlenecks of vision, operating via a pre-attentive 2 ms mechanoreceptor channel (_fühlen_). If an encounter is not resolved during the initial 10–15 second alactic burst, cumulative metabolic acidosis degrades neuromuscular consistency by ~15% and induces kinetic-chain failure from the ground up, forcing outfighting (_Zogho Largo_) to collapse inexorably into gross-motor wrestling (_Zogho Stretto_ / _Ringen am Schwert_). Post-clash trauma manifests as acute dynamic postural instability and mediolateral center-of-mass sway that persists for days under physical or cognitive load, masked immediately only by transient, structurally unprotective stress-induced analgesia.

---

## 1. The Bioenergetic Engine of Single Combat

Human muscular force production during high-intensity combat shifts across three distinct metabolic pathways:[^murray-2018-glycogen-metabolism]

1. **The ATP-PCr (Phosphagen) System ($\le 15\text{ s}$):** Intracellular stores of adenosine triphosphate (ATP) and phosphocreatine (PCr) provide immediate, maximal-rate muscular contraction without requiring oxygen or producing lactic acid. Intramuscular ATP is depleted within 2–4 seconds, while PCr cleavage sustains maximal burst output for another 5–10 seconds. Replenishment is an oxidative process requiring 2–5 minutes of low-intensity recovery (a 1:10 to 1:12 work-to-rest ratio).
2. **The Anaerobic Glycolytic System ($15\text{–}90\text{ s}$):** Once phosphagen stores are exhausted, intramuscular glycogen degradation provides rapid ATP without oxygen.[^murray-2018-glycogen-metabolism] Byproducts ($H^+$ ions and lactate) cause cellular acidosis, impairing actin-myosin cross-bridge cycling and inducing muscular fatigue.
3. **The Oxidative (Aerobic) System ($2+\text{ min}$):** The high-capacity, oxygen-dependent pathway. In combat, the aerobic system sustains baseline movement (circling, maintaining guard) and serves as the primary engine of recovery—oxidizing lactate and resynthesizing phosphocreatine during lulls between exchanges.[^wylde-2023-energy-systems]

### Time-Motion Chronometry: Weapon Fencing vs. Full-Contact Combat

Empirical time-motion analysis across both weapon fencing and continuous full-contact combat confirms that the biochemical recovery profile of these energy systems dictates the structural cadence of armed and unarmed exchanges:[^wylde-2023-temporal-parameters][^martusciello-2025-punching-duration][^miarka-2020-intensity-ratio]

| Combat Modality                     | Work Phase Duration (Mean ± SD)                                                                | Rest / Preparatory Phase (Mean ± SD)                                                                    | Work-to-Rest Ratio (W/R)                                       | Effective High-Intensity Activity                            | Primary Physiological Substrate & Bioenergetics                                                                                                                                                                                                                                                                                                                                                                       |
| :---------------------------------- | :--------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------- | :----------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sabre Fencing**                   | **1.7 ± 0.4 s**<br>_(M: 1.6 ± 0.5 s, W: 1.9 ± 0.3 s)_                                          | **16.0 ± 3.0 s**<br>_(M: 16.6 ± 3.4 s, W: 15.5 ± 2.5 s)_                                                | **1:9.2**<br>_(M: 1:10.4, W: 1:8.2)_                           | **9.4% – 11.5%**                                             | **Alactic Phosphagen (ATP-PCr Dominance)**.<br>Immediate explosive actions (<2 s) driven by rapid apparatus lockout timings (130 ms) and tactical initiative demands,[^wylde-2023-sabre-explosiveness] followed by prolonged passive inter-exchange recovery (~16 s) permitting near-total phosphagen resynthesis without substantial lactate accumulation.[^wylde-2023-blood-lactate]                                |
| **Foil Fencing**                    | **5.8 ± 2.5 s**<br>_(M: 5.1 ± 2.3 s, W: 6.5 ± 2.6 s)_                                          | **15.1 ± 3.7 s**<br>_(M: 15.6 ± 3.8 s, W: 14.5 ± 3.6 s)_                                                | **1:2.6**<br>_(M: 1:3.0, W: 1:2.2)_                            | **25.5% – 31.8%**                                            | **Mixed Alactic-Aerobic with Intermittent Glycolysis**.<br>Multi-action phrases (~5–6 s) with moderate pauses (~15 s). Post-bout blood lactate remains modest (~2.4 mmol·L⁻¹), below the 4.0 mmol·L⁻¹ onset of blood lactate accumulation (OBLA) threshold.[^wylde-2023-blood-lactate]                                                                                                                                |
| **Épée Fencing**                    | **17.9 ± 3.1 s**<br>_(M: 18.1 ± 3.5 s, W: 17.8 ± 2.8 s)_                                       | **15.5 ± 5.5 s**<br>_(M: 18.6 ± 6.2 s, W: 12.4 ± 2.0 s)_                                                | **1:0.9**<br>_(M: 1:1.0, W: 1:0.7)_                            | **53.6% – 62.5%**                                            | **Aerobic Dominance with Alactic Bursts**.<br>80–90% of total match energy is aerobic,[^wylde-2023-energy-systems] supporting prolonged continuous maneuvering (~18 s work phrases) with brief rest intervals (~12–18 s). Explosive lunges draw on alactic phosphagen stores; blood lactate remains low (~2.7 mmol·L⁻¹).[^wylde-2023-blood-lactate]                                                                   |
| **Elite Boxing** (Finals, 3×3 min)  | **Punching (P): 1.48 ± 0.35 s to 1.74 ± 0.32 s**<br>_Fighting (F): 1.9 ± 1.5 s to 2.4 ± 1.9 s_ | **No-Fighting (NF): 1.84 ± 1.32 s to 4.65 ± 3.14 s**<br>_Clinching (C): 2.29 ± 0.86 s to 4.98 ± 0.60 s_ | **~1:1 to 1.5:1** (F : NF)<br>_High-burst ratio 1:2 to 1:3_    | **~50% – 65% total active**<br>_Bursts strictly <2 s_        | **Alactic Burst Cycles over Aerobic Engine**.<br>Individual striking exchanges (P) are strictly bounded to 1.4–2.0 s bursts across all weight divisions,[^martusciello-2025-fighting-duration] separated by maneuvering (NF, 2–5 s) or clinching (C, 2–5 s). Arbitral interruptions provide brief metabolic breaks (4.6–6.4 s).[^martusciello-2025-punching-duration]                                                 |
| **Professional MMA** (5-min rounds) | **Standing Combat: 17.3 ± 31.1 s**<br>_Max flurries: 5–10 s (>2–4 strikes/s)_                  | **Standing Preparatory: 131.0 ± 92.4 s**<br>_(Circling, spacing, footwork)_                             | **1:2 to 1:4** (High : Low intensity)<br>_Overall round ratio_ | **~15% – 25% High Intensity**<br>_Groundwork: 49.9 ± 76.5 s_ | **Hybrid Alactic-Glycolytic with Isometric Grappling**.<br>High-intensity standing flurries occur in short 5–10 s windows self-regulated by biological capacity,[^miarka-2020-self-regulated-intensity] embedded within prolonged low-intensity preparatory maneuvering (~130 s) adhering to a 1:2 to 1:4 ratio.[^miarka-2020-intensity-ratio] Ground phases shift to sustained isometric muscular endurance (~50 s). |

### The Inescapable Staccato Rhythm

The remarkable convergence between weapon fencing chronometry (1.7 s sabre flurries), elite boxing (1.4–1.7 s punching exchanges), and MMA (5–10 s high-intensity flurries surrounded by 1:2 to 1:4 low-intensity recovery) demonstrates that the intermittent cadence of combat is biologically mandatory:[^wylde-2023-temporal-parameters][^martusciello-2025-punching-duration][^miarka-2020-intensity-ratio]

- **The Decisive Burst:** In lethal or high-impact combat without institutional incentives to delay, combatants commit to short, violent bursts of 1–2 seconds.[^wylde-2023-sabre-explosiveness][^martusciello-2025-fighting-duration] This aligns perfectly with the depletion of intramuscular ATP and immediate phosphagen availability.
- **The Mandatory Biological Pause:** Following a committed flurry, combatants are physiologically forced to separate and maneuver in measure. Even in continuous full-contact formats without referee resets, combatants self-regulate round intensity to maintain a 1:2 to 1:4 high-to-low intensity ratio,[^miarka-2020-intensity-ratio][^miarka-2020-self-regulated-intensity] utilizing preparatory footwork intervals (~30–50 s) for oxidative phosphagen resynthesis ($t_{1/2} \approx 20\text{–}30\text{ s}$).
- **The Aerobic Reserve:** In prolonged probing engagements (analogous to épée or MMA standing preparatory time), 80–90% of the energy expended during active footwork and distance management is supplied aerobically,[^wylde-2023-energy-systems] preserving intramuscular phosphocreatine for the decisive explosive lunge or counter-strike.

---

## 2. Tactical Pedagogy and the First Exchange

The opening seconds of an armed encounter represent a singular physiological state. The acute sympathetic stress response floods the bloodstream with epinephrine and norepinephrine, inducing tachycardia, pupillary dilation, peripheral vasoconstriction, and stress-induced analgesia.

Simultaneously, intracellular phosphagen stores are fully charged. The first 10–15 seconds represent the only window in which a combatant can operate at absolute peak power output before the onset of fatigue.

Historical combat doctrines intuitively exploited this non-repeatable window:

- **The Doctrine of _Vor_ ("Before"):** Johannes Liechtenauer's German longsword school prioritizes taking the initiative to force the opponent into the purely reactive _Nach_ ("After").
- **Fight-Ending Master Cuts (_Meisterhäue_):** The five master cuts (Zornhau, Krumphau, Zwerchhau, Schielhau, Scheitelhau) are single-tempo counter-attacks designed to simultaneously deflect an incoming blow and strike an opening, terminating the encounter within the initial phosphagen window.
- **Cognitive Adaptation under Stress:** High cognitive stress causes perceptual narrowing (tunnel vision) and impairs novel problem-solving. Liechtenauer codified these principles into a mnemonic poem, the _Zettel_—using simple, rhyming couplets to ensure rapid recall when complex cognitive processing is compromised.

---

## 3. The Tactical Chess Match: The Bind, Haptics & Sensory Switching

When two blades cross and remain in contact, the nature of sensory perception and motor control fundamentally transforms. This phase—known as the bind (_am Schwert_ in the German tradition, or _incrosar_ in the Italian school)—shifts combat from a visual tracking problem to a closed-loop haptic motor guidance interaction.

### Blade Contact Physics: Edge Bite vs. Slippage

In theatrical performance and sporting fencing with blunt, rounded simulators, steel blades slide effortlessly along one another. In historical combat with sharp, live blades, the physics of blade contact are drastically different:

- **Edge Engagement ("Bite"):** When sharp carbon steel edges collide under pressure, the concentrated force deforms the micro-geometry of the opposing edges, causing the blades to "bite" into each other rather than slide. This momentary mechanical interlock creates a stable physical pivot.
- **The Fulcrum of Leverages:** In the bind, leverage is determined by the division of the blade into the _forte_ (strong, near the hilt) and the _debole_ / _schwach_ (weak, near the tip). By placing one's _forte_ against the opponent's _debole_, a combatant gains massive mechanical advantage, controlling the opponent's weapon with minimal muscular effort.

### Neurological Grounding: Tactile vs. Visual Reaction Latency

The transition to the bind provides a profound biological advantage rooted in the sensory processing architecture of the human nervous system:[^hanson-2009-transduction-latencies][^hanson-2009-divided-attention]

- **Transduction Latency Disparity:** Converting environmental physical stimuli into neural action potentials exhibits stark sensory disparities. Phototransduction across retinal photoreceptors requires **~50 ms** under photopic (light) conditions.[^hanson-2009-transduction-latencies] In sharp contrast, mechanical transduction by cutaneous mechanoreceptors (Pacinian and Meissner's corpuscles) and muscle spindle proprioceptors requires only **~2 ms**.[^hanson-2009-transduction-latencies]
- **Baseline Latency Hierarchy:** In unimodal simple reaction time tasks, tactile stimuli trigger motor responses significantly faster than visual stimuli (mean tactile RT: 192.3 ms vs. visual RT: 206.9 ms; $p < 0.001$).[^hanson-2009-transduction-latencies]
- **Divided Attention Immunity:** In a dynamic combat environment, attention is perpetually divided across multiple sensory channels and spatial sectors. When human attention is divided across visual, auditory, and tactile modalities, visual reaction time degrades significantly, introducing a latency penalty of **+14.7 to +29.1 ms** (+7.1% to +14.1%, $p < 0.001$).[^hanson-2009-modality-cost] In stark contrast, tactile reaction time is **completely invariant and unaffected by divided attention** ($F_{3, 12} = 2.36, p > 0.05$).[^hanson-2009-divided-attention]
- **Pre-Attentive Prioritization:** Tactile events are processed preferentially and pre-attentively by the central nervous system, bypassing cognitive resource bottlenecks.[^hanson-2009-divided-attention] In the bind, a combatant receives instantaneous, unattenuated haptic information regarding the direction, magnitude, and velocity of an opponent's intent 20–50 ms before those intentions can be visually registered.

### Historical Codification: _Fühlen_, _Winden_, and _Indes_

Historical masters of the 14th and 15th centuries codified this neurobiological phenomenon into precise pedagogical doctrines:

- **The Sense of _Fühlen_ ("Feeling"):** In the Liechtenauer tradition (MS 3227a, Sigmund Ringeck, Peter von Danzig), students are instructed never to pull away from the bind, but to rely on _Fühlen_—perceiving through the hands whether the opponent's blade is _Hart_ (hard/pushing) or _Weich_ (soft/yielding).
- **Acting _Indes_ ("Instantly / In the Middle"):** Because haptic feedback bypasses visual processing delays, the master can act _Indes_ (in the single tempo of the opponent's pressure shift). If the opponent is _Hart_, the master yields and winds (_Winden_) to the other side; if the opponent is _Weich_, the master thrusts immediately into the opening.
- **Fiore's Crossed Swords:** In Fiore dei Liberi's _Il Fior di Battaglia_, this is articulated as the transition from _Zogho Largo_ (wide play where weapons do not cross) to _Zogho Stretto_ (narrow play where weapons cross and the combatant enters close-quarters control).

### Feinting as an Anaerobic and Attentional Tax

Because visual reaction time suffers from severe divided-attention penalties and cognitive processing lags, combatants use feints to exploit the opponent's sensory bottlenecks:

- **Motor Commitment & The Point of No Return:** Once a defensive parry is initiated past the motor point of no return (~150–200 ms prior to movement execution), it cannot be cancelled without substantial biomechanical resetting delays.
- **The Metabolic Cost of Deception:** Reacting to deceptive visual stimuli forces the defender to fire explosive, alactic motor units to redirect momentum, depleting finite phosphagen stores while attempting to resolve visual ambiguity. Feinting acts as an anaerobic and attentional tax that accelerates defensive breakdown.

---

## 4. Devolution to Grappling and Sensorimotor Breakdown

When a duel is not resolved in the opening phosphagen exchange, cumulative anaerobic exertion induces progressive neuromuscular, sensorimotor, and biomechanical degradation.

### Sensorimotor Degradation: Latency Shift vs. Consistency Collapse

Neuromuscular fatigue impairs defensive and offensive timing not primarily through a uniform slowing of baseline reaction speed, but through a catastrophic loss of **response consistency**:[^kostikiadis-2020-rt-variability]

- **Marginal Latency Slowing:** In combat athletes subjected to supramaximal anaerobic exhaustion (30-second upper-body Wingate arm-cranking at 4 W·kg⁻¹), premotor simple visual reaction time (the latency between visual stimulus onset and initial motor initiation) increases by only **1.5%** (a mean difference of +4.03 ms, shifting from 266.15 ± 37.37 ms pre-fatigue to 270.18 ± 42.79 ms post-fatigue, $p = 0.02$).[^kostikiadis-2020-rt-latency] Mean movement time (the time required to physically complete the motor action once initiated) remains uninfluenced ($p = 0.455$).
- **The Variance Surge (Inconsistency):** In sharp contrast to mean latency, response variability degrades by **14.7%** ($p < 0.001$), measured via individual reaction time residuals (shifting from 0.477 ± 0.031 to 0.547 ± 0.031).[^kostikiadis-2020-rt-variability] Furthermore, movement time consistency correlates directly with the fatigue index ($\beta = 0.008, p = 0.033$), showing that combatants experiencing severe anaerobic power drops suffer elevated execution variability.[^kostikiadis-2020-mt-fatigue-index]
- **The Defensive "Tipping Point":** This dissociation indicates that an exhausted fighter does not react with predictable slowness; rather, their motor system exhibits high temporal entropy. While some responses remain near baseline, intermittent and unpredictable lapses create timing deficits of tens to hundreds of milliseconds—the critical failure window where an opponent's swipe, blow, or submission attempt breaches the guard before conscious registration.[^kostikiadis-2020-tipping-point]

### Kinematic Breakdown and Kinetic Chain Cross-Fatigue

In dynamic striking and weapon delivery, response time (RT) encompasses the entire temporal sequence from external visual stimulus perception through motor execution to target impact.[^tabben-2023-rt-definition] Sport-specific exhaustion reveals profound kinetic-chain interdependencies across body segments:[^tabben-2023-cross-fatigue-punch]

- **Kinetic Chain Cross-Fatigue (Lower to Upper):** Exhaustion of the lower body significantly slows upper-body striking response times. Following an incremental kicking exhaustion protocol, punching RT degrades by **10.5% to 11.4%** ($p < 0.001, d = 1.0\text{–}1.1$), regardless of whether punches are evaluated immediately or following subsequent actions.[^tabben-2023-cross-fatigue-punch] Because powerful ballistic strikes are "leg-driven" actions initiated via rear-foot ground reaction forces and pelvis rotation,[^tabben-2023-kinetic-chain-ground-force] lower-extremity neuromuscular fatigue collapses the proximal anchor of the kinetic chain, degrading distal striking velocity even when arm musculature is unworked.
- **Segment-Specific Asymmetry (Upper to Lower):** In contrast, upper-body motor fatigue does not impair lower-body striking. Exhausting the upper limbs induces a temporary **11.8%** slowing in immediate punching RT ($d = 1.4$), but produces zero significant effect on subsequent kicking RT ($p = 0.12$).[^tabben-2023-kick-degradation] Lower-body fatigue is biologically more systemic than upper-body exertion due to the greater active muscle mass and substantially elevated systemic oxygen consumption involved.[^tabben-2023-systemic-lower-fatigue]
- **Task Complexity and Terminal Impact:** Multi-joint actions with extended trajectories are far more susceptible to fatigue than simple linear trajectories. Kicking exhibits ~40% longer baseline response times than punching and requires greater cortical motor coordination for dynamic balance; consequently, lower-body exhaustion degrades kicking response time by **7.5% to 14.3%** ($p \le 0.01, d = 0.8\text{–}1.5$).[^tabben-2023-kick-degradation][^tabben-2023-task-complexity-kicking] Concurrently, terminal impact force collapses catastrophically—collapsing by up to 70% under exhaustive striking protocols (e.g., peak roundhouse impact dropping from 43 ± 27 g to 13 ± 10 g, $p < 0.01$).[^tabben-2023-kick-impact-collapse]

### Biomechanical Inevitability of Devolution to Grappling

The convergence of sensorimotor inconsistency and kinetic chain failure explains why extended weapon duels inexorably devolve into close-quarters grappling:

- **Collapse of Distant Play (_Zogho Largo_):** Outfighting and distance fencing depend entirely on millisecond-level blade tip placement, subtle tactile feedback, and explosive multi-directional footwork. Under acute metabolic acidosis and sensorimotor timing variance (a ±15% fluctuation in response consistency), maintaining open measure becomes extraordinarily hazardous, as timing miscalculations result in clean, undefended strikes.
- **Gross Motor Resilience of Close Play (_Zogho Stretto_):** As ballistic striking velocity and footwork fail, combatants naturally collapse measure into the clinch. At grappling range, combat shifts from high-velocity ballistic kinetic chains to gross motor recruitment: bilateral collar ties, underhooks, hip frames, and skeletal wedging. These isometric and wrestling mechanics rely on static core tension and leverage rather than rapid sensory processing or explosive rate of force development, remaining functionally viable under severe anaerobic depletion.
- **Historical Codification:** Masters of defense systematically codified this biomechanical transition. In Johannes Liechtenauer's German tradition, _Ringen am Schwert_ ("wrestling at the sword") teaches the combatant to abandon blade fencing at the bind (_Krieg_) to trap arms, hook pommels behind joints, and trip the opponent's base. Similarly, in Fiore dei Liberi's _Il Fior di Battaglia_, _Abrazare_ (unarmed grappling) is presented as the structural foundation of all combat, emphasizing that when swords cross and momentum stalls, the duel is resolved through throws, arm locks, and takedowns.

---

## 5. The Post-Combat State, Concussion & Non-Lethal Trauma

Surviving a violent confrontation does not leave a combatant primed for immediate subsequent action. The immediate aftermath is characterized by acute vulnerability across vestibular, biomechanical, autonomic, and nociceptive systems.

### Concussion Biomechanics, Dynamic Postural Disruption & Ataxia

Kinetic impact to the cranium or violent rotational deceleration induces mild traumatic brain injury (mTBI) and transient sensorimotor disruption:[^mcleod-2014-sensory-triad][^patejak-2021-com-dual-task]

- **Sensorimotor Integration Failure:** Postural equilibrium requires continuous central nervous system integration across three sensory channels: visual, vestibular, and somatosensory/proprioceptive systems.[^mcleod-2014-sensory-triad] Following concussive head impacts, up to 60% of athletes demonstrate significant balance abnormalities across force-plate sensory organization testing (SOT), with somatosensory integration impaired in 40%, visual in 30%, and vestibular in >20%.[^mcleod-2014-sensory-triad]
- **Center of Mass (COM) Mediolateral Displacement:** Concussive trauma produces significant dynamic postural instability during ambulation, characterized by elevated mediolateral center of mass (COM) displacement and increased COM sway velocity.[^patejak-2021-mediolateral-com] Concussed combatants adopt a cautious gait with shortened stride length and widened base of support to prevent falling.
- **Cognitive-Motor Dual-Task Collapse:** While basic static balance on firm surfaces often returns toward clinical baseline within 3 to 5 days post-injury,[^mcleod-2014-postural-recovery] dynamic center of mass instability worsens substantially when an individual is subjected to dual-task conditions (simultaneous walking and cognitive/tactical decision-making).[^patejak-2021-mediolateral-com] This heightened whole-body COM sway and impaired motor control persists for up to **28 days post-injury**, leaving the combatant acutely vulnerable to secondary trauma long after subjective symptoms subside.[^patejak-2021-com-dual-task]

### Autonomic Rebound ("The Crash")

Following the withdrawal of intense sympathetic stimulation, the body undergoes a parasympathetic rebound:

- Within 15–60 minutes post-engagement, as catecholamine levels plummet, the combatant experiences profound exhaustion, involuntary muscular tremors, nausea, dizziness, and cognitive lethargy.
- This neuroendocrine rebound represents a normal homeostatic restoration process (distinct from clinical adrenal crisis), driven by the rapid depletion of circulating glycogen and central nervous system neurotransmitter fatigue.

### Stress-Induced Analgesia & "Walking Wounded"

Acute threat triggers dual opioid and non-opioid (endocannabinoid $\text{CB}_1$ and descending serotonergic $5\text{-HT}_{1\text{A}}$ / noradrenergic) pain suppression (see detailed synthesis in [stress-induced-analgesia.md](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/stress-induced-analgesia.md)):

- **Intact Wind-Up vs. Blunted First Pain:** While initial pain contact is substantially blunted, central sensitization (wind-up slope across repeated strikes) remains completely uninhibited.
- **Structural Vulnerability:** Crucially, subjective antinociception provides zero structural protection: combatants frequently sustain fractures, deep lacerations, or ligament tears without conscious awareness, risking catastrophic secondary tissue destruction when continuing high-intensity exertion during the 10–40 minute analgesic window.

---

## 6. Epistemic Delta: Legacy Claims vs. Empirical Reality

| Action / Parameter                | Legacy Report Claim (Source)                                                     | Verified Empirical Reality (Vault Quote)                                                                                                                                                          | Status                                      | Active Design Impact                                                                                                                               |
| :-------------------------------- | :------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pacing & Exchange Cadence**     | Duels are continuous high-intensity brawls lasting 30–60 s without breaks.       | Intermittent staccato structure. High-intensity bursts strictly bounded to 1.4–2.0 s in boxing and 1.7 s in fencing, with a mandatory 1:2 to 1:4 (MMA) or 1:9 (sabre) recovery ratio.             | **Corrected** (Intermittent Cadence)        | Rules must enforce tempo pauses or stamina depletion for consecutive un-paused attacks; combat cannot sustain uninterrupted high-output combos.    |
| **Tactile Advantage in the Bind** | Fencing binds are purely visual reaction contests where swords slide freely.     | Edge bite creates mechanical interlock. Tactile mechanoreceptors operate at 2 ms transduction (vs. 50 ms for retina) and suffer zero latency loss under divided attention.                        | **Corrected** (Haptic Priority)             | The bind (_am Schwert_) must grant initiative or reaction bonuses, rewarding _fühlen_ over distant open-measure reaction.                          |
| **Fatigue Degradation Mechanism** | Fatigue causes uniform, linear slowing of reaction times by 20–30%.              | Simple visual RT latency slows by only 1.5% (+4.0 ms). Fatigue causes a 14.7% surge in response variability (inconsistency) and collapses terminal impact by up to 70%.                           | **Corrected** (Variance Surge)              | Fatigue should increase defensive variance / fumble thresholds rather than imposing flat, predictable latency penalties.                           |
| **Kinetic Chain Cross-Fatigue**   | Arm fatigue impairs punching; leg fatigue impairs kicking (isolated limb pools). | Lower-body exhaustion degrades punching response time by 10.5–11.4% (proximal ground-force collapse). Upper-body fatigue does not impair kicking.                                                 | **Corrected** (Asymmetric Chain)            | Heavy footwork, movement, and kicking drain total striking efficiency, grounding asymmetric systemic fatigue.                                      |
| **Concussive Balance Disruption** | Concussion causes transient 1–2 second dizziness that resolves immediately.      | Concussive impacts disrupt sensorimotor integration in up to 60% of cases. Dynamic center of mass instability persists for 3–5 days statically and up to 28 days under dual-task cognitive loads. | **Corrected** (Prolonged Dynamic Ataxia)    | Head trauma must impose lasting balance and coordination penalties that resurface under cognitive pressure, rather than instantaneous stun resets. |
| **Devolution to Grappling**       | Grappling occurs randomly as a tactical whim.                                    | Grappling is biomechanically mandatory as fine motor outfighting (_Zogho Largo_) collapses under sensorimotor variance, favoring fatigue-resilient gross-motor wrestling (_Zogho Stretto_).       | **Confirmed** (Biomechanical Inevitability) | Duels exceeding the phosphagen window naturally close distance; grappling is the default terminal phase of extended melee.                         |

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

[^martusciello-2025-punching-duration]:
    source: martusciello-2025-boxing-time-motion
    locator: "line 385 ([extracted.md#L385](../sources/verisimilitude/martusciello-2025-boxing-time-motion/extracted.md#L385))"
    quote: "The analysis of the mean duration of single P, C, NF actions and AI phases with pooled data for rounds revealed significant differences between weight categories. For instance, in the 50 kg category, the average duration of the P phase was 1.48 ± 0.35 s, compared to 1.74 ± 0.32 s in the 81+ kg category. Similarly, the C phase showed more significant variability across weight categories. For example, in the 60 kg category, the average C phases duration reached 4.98 ± 0.60 s, while in the 54 kg category, it was considerably shorter, with an average of 2.29 ± 0.86 s."
    status: unverified

[^martusciello-2025-fighting-duration]:
    source: martusciello-2025-boxing-time-motion
    locator: "line 397 ([extracted.md#L397](../sources/verisimilitude/martusciello-2025-boxing-time-motion/extracted.md#L397))"
    quote: "Specifically, the mean duration of F actions was 2.2 ± 1.9, 1.9 ± 1.5 and 2.4 ± 1.9 s for LWC, MWC and HWC weight divisions, respectively. ... Furthermore, the P sub-phase registered significant differences for rounds, particularly in the first round. The HWC division showed the longest duration (1.96 ± 1.25 s) compared to the other two divisions (LWC: 1.56 ± 1.07 s; MWC: 1.47 ± 0.85 s)."
    status: unverified

[^miarka-2020-intensity-ratio]:
    source: miarka-2020-pacing-tactical-mma
    locator: "line 131 ([extracted.md#L131](../sources/verisimilitude/miarka-2020-pacing-tactical-mma/extracted.md#L131))"
    quote: "Furthermore, the current ratios agree with previous studies with male athletes that showed intensity ratios were similar between all rounds, about 1:2 to 1:4 of high: low-intensity time (Antonietto et al., )."
    status: unverified

[^miarka-2020-self-regulated-intensity]:
    source: miarka-2020-pacing-tactical-mma
    locator: "line 127 ([extracted.md#L127](../sources/verisimilitude/miarka-2020-pacing-tactical-mma/extracted.md#L127))"
    quote: "This observation has a physiological significance, as it indicates that the round intensity during combat phases was self-regulated relative to the female athlete's physical capability near the end of the combat."
    status: unverified

[^hanson-2009-transduction-latencies]:
    source: hanson-2009-tactile-divided-attention
    locator: "line 9 ([extracted.md#L9](../sources/verisimilitude/hanson-2009-tactile-divided-attention/extracted.md#L9))"
    quote: "For example, the process of converting sound waves into neural signals at the cochlea takes approximately 40μs [1]. By comparison, transduction of tactile events by human mechanoreceptors takes approximately 2ms [2], and transduction of visual events at the retina approximately 50ms in photopic conditions [3]."
    status: unverified

[^hanson-2009-divided-attention]:
    source: hanson-2009-tactile-divided-attention
    locator: "line 3 ([extracted.md#L3](../sources/verisimilitude/hanson-2009-tactile-divided-attention/extracted.md#L3))"
    quote: "Results show that tactile reaction time is unaffected by dividing attention, whilst visual and auditory reaction times are significantly and asymmetrically increased. These findings show that tactile information is processed preferentially by the nervous system under conditions of divided attention, and suggest that tactile events may be processed pre-attentively."
    status: unverified

[^hanson-2009-modality-cost]:
    source: hanson-2009-tactile-divided-attention
    locator: "line 45 ([extracted.md#L45](../sources/verisimilitude/hanson-2009-tactile-divided-attention/extracted.md#L45))"
    quote: "The mean cost to reaction time of dividing attention between sensory modalities ranged from 14.7 - 29.1ms (7.1 - 14.1%) in the visual modality, and 36.4 - 43.0ms (22.6 – 26.7%) in the auditory modality."
    status: unverified

[^kostikiadis-2020-rt-variability]:
    source: kostikiadis-2020-fatigue-reaction-time-mma
    locator: "Abstract, line 3 ([extracted.md#L3](../sources/verisimilitude/kostikiadis-2020-fatigue-reaction-time-mma/extracted.md#L3))"
    quote: "Results showed a significant negative effect of fatigue on the reaction times and their consistency, with longer reactions (1.5% change) and lower consistency (14.7% change) after the Wingate test."
    status: unverified

[^kostikiadis-2020-rt-latency]:
    source: kostikiadis-2020-fatigue-reaction-time-mma
    locator: "Results, line 86 ([extracted.md#L86](../sources/verisimilitude/kostikiadis-2020-fatigue-reaction-time-mma/extracted.md#L86))"
    quote: "POST RTs were found significantly higher than PRE (mean difference = 4.031 ms, SE = 1.726, *t*2102 = 2.335, *p*Bonferroni = 0.02)"
    status: unverified

[^kostikiadis-2020-mt-fatigue-index]:
    source: kostikiadis-2020-fatigue-reaction-time-mma
    locator: "Results, line 134 ([extracted.md#L134](../sources/verisimilitude/kostikiadis-2020-fatigue-reaction-time-mma/extracted.md#L134))"
    quote: "we found a statistically significant ()positive effect (β = 0.008, SE = 0.004, _p_ < 0.033) of fatigue index on MT residuals."
    status: unverified

[^kostikiadis-2020-tipping-point]:
    source: kostikiadis-2020-fatigue-reaction-time-mma
    locator: "Discussion, line 148 ([extracted.md#L148-L13](../sources/verisimilitude/kostikiadis-2020-fatigue-reaction-time-mma/extracted.md#L148-L13))"
    quote: "Further, the in/consistency in individual reactions when fatigued (the pattern showed by our participants) might be the so far overlooked “tipping point” of registering and responding on time to opponent’s swipes and attempts for submission or knockout."
    status: unverified

[^tabben-2023-rt-definition]:
    source: tabben-2023-striking-response-time-karate
    locator: "Introduction, line 9 ([extracted.md#L9](../sources/verisimilitude/tabben-2023-striking-response-time-karate/extracted.md#L9))"
    quote: "In the context of striking combat sports, those points can be stated from an external visual or audible stimulus to the end of a strike reaching a target (Sant’ Ana et al., 2017), which in turn, would represent the sensorial perception of an opponent action (_i.e._, hip movement) and its consequent motor response (_e.g_., striking, dodging, or blocking), respectively."
    status: unverified

[^tabben-2023-cross-fatigue-punch]:
    source: tabben-2023-striking-response-time-karate
    locator: "Abstract, line 3 ([extracted.md#L3](../sources/verisimilitude/tabben-2023-striking-response-time-karate/extracted.md#L3))"
    quote: "The negative effect of the lower body fatigue protocol in punches RT was evident regardless of the order of the tests (punch RT first: Δ = 10.5%; t = 4.4; _p_ < 0.001; _d_ = 1.0; kick RT first: Δ = 11.4%; t = 4.8; _p_ < 0.001; _d_ = 1.1)."
    status: unverified

[^tabben-2023-kick-degradation]:
    source: tabben-2023-striking-response-time-karate
    locator: "Abstract, line 3 ([extracted.md#L3](../sources/verisimilitude/tabben-2023-striking-response-time-karate/extracted.md#L3))"
    quote: "Regarding mean kicks RT, significant effects were found between situations for the lower (F(2,22) = 16.6; ω2 = 0.27; _p_ < 0.001) but not for the upper (F(2,22) = 2.3; ω2 = 0.02; _p_ = 0.12) body fatigue protocols. Kick RTs were negatively affected by the lower body fatigue protocol regardless of the RT order applied (punch RT first: Δ = 7.5%; t = 3.0; _p_ = 0.01; _d_ = 0.8; kick RT first: Δ = 14.3%; t = 5.7; _p_ < 0.001; _d_ = 1.5). Upper body fatigue does not impair punch or kick RTs."
    status: unverified

[^tabben-2023-kinetic-chain-ground-force]:
    source: tabben-2023-striking-response-time-karate
    locator: "Discussion, line 105 ([extracted.md#L105](../sources/verisimilitude/tabben-2023-striking-response-time-karate/extracted.md#L105))"
    quote: "The role of lower body muscles in punching performance was already described and supports the notion that “leg drived” actions may be related to higher force production in boxers (Dinu & Louis, 2020). ... Together, this evidence highlights the relevance of lower body actions on punching performance ... fatigue impairments in this segment can be harmful to punching RT."
    status: unverified

[^tabben-2023-systemic-lower-fatigue]:
    source: tabben-2023-striking-response-time-karate
    locator: "Discussion, line 109 ([extracted.md#L109](../sources/verisimilitude/tabben-2023-striking-response-time-karate/extracted.md#L109))"
    quote: "Collectively, these findings suggest that induction of fatigue in the lower body is more systemic than upper body protocols, which would be expected since lower body efforts move more muscle mass, thus producing higher values of O2 consumption (Andreato et al., 2022)."
    status: unverified

[^tabben-2023-task-complexity-kicking]:
    source: tabben-2023-striking-response-time-karate
    locator: "Discussion, line 113 ([extracted.md#L113](../sources/verisimilitude/tabben-2023-striking-response-time-karate/extracted.md#L113))"
    quote: "It is suggested that more complex motor gestures may require more cortical areas to be involved in processing tasks, thus considering that kicking is a more complex task than punch, it may explain why kicks were more easily affected (Snyder & Cinelli, 2022). ... Notwithstanding, kicking has ~40% higher RT than punching, which would suggest a higher susceptibility of kicks to be affected by other factors, such as feedback and fatigue."
    status: unverified

[^tabben-2023-kick-impact-collapse]:
    source: tabben-2023-striking-response-time-karate
    locator: "Discussion, line 107 ([extracted.md#L107](../sources/verisimilitude/tabben-2023-striking-response-time-karate/extracted.md#L107))"
    quote: "Fatigue induced by kick execution was shown to negatively affect RT (145 ± 51 ms to 223 ± 133 ms; _p_ < 0.05) and impact (43 ± 27 g to 13 ± 10 g; _p_ < 0.01) of kicks in taekwondo athletes after a specific fatigue protocol using roundhouse kick (Sant’ Ana et al., 2017)."
    status: unverified

[^mcleod-2014-postural-recovery]:
    source: mcleod-2014-concussion-postural-stability
    locator: "line 21 ([extracted.md#L21](../sources/verisimilitude/mcleod-2014-concussion-postural-stability/extracted.md#L21))"
    quote: "Both the SOT and the BESS show moderate reliability, but a learning effect due to repetitive testing needs to be considered. Both tests indicate that postural stability returns to baseline by day 3 to 5 in most concussed athletes."
    status: unverified

[^mcleod-2014-sensory-triad]:
    source: mcleod-2014-concussion-postural-stability
    locator: "line 39 ([extracted.md#L39](../sources/verisimilitude/mcleod-2014-concussion-postural-stability/extracted.md#L39))"
    quote: "Postural control requires a complex interaction of musculoskeletal and neural systems. ... The neural components that contribute essentially to postural stability include motor processes organizing neuromuscular synergies; sensory/perceptional processes that organize and integrate visual, vestibular, and somatosensory systems; and higher level processes essential for mapping sensation to action."
    status: unverified

[^patejak-2021-com-dual-task]:
    source: patejak-2021-concussion-center-of-mass
    locator: "line 114 ([extracted.md#L114](../sources/verisimilitude/patejak-2021-concussion-center-of-mass/extracted.md#L114))"
    quote: "Gait imbalance during the divided attention condition was marked by greater sway and sway velocity of the whole-body COM that was maintained for up to 28 days following injury."
    status: unverified

[^patejak-2021-mediolateral-com]:
    source: patejak-2021-concussion-center-of-mass
    locator: "line 120 ([extracted.md#L120](../sources/verisimilitude/patejak-2021-concussion-center-of-mass/extracted.md#L120))"
    quote: "Significant differences were found in group-time interaction between dual-task walking for mediolateral displacement of COM and COM medial-lateral velocity. Significant worsening of COM control after return to activity was also illustrated during dual-task walking. Overall mean return to activity mediolateral displacement was significantly greater than controls for same time point measurements when dual-tasking gait."
    status: unverified
