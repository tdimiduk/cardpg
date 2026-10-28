---
title: "Action Duration, the Perceptual Present, and Motor Control"
doc_type: "synthesis"
track: "verisimilitude"
origin: "AI synthesized"
epistemic_status:
  confidence: "high"
  audited_by: "Gemini 3.8 Flash (Antigravity)"
  vetted_by_human: false
  vetting_notes: "Grounded in peer-reviewed psychophysics, cognitive neuroscience, and motor control: discrete perceptual time slices (Herzog 2016), sensorimotor synchronization limits (Repp 2005), motor point-of-no-return EEG studies (Schultze-Kraft 2016), micro-temporal order thresholds (Pöppel 2009; Wittmann 2011), empirical critique of multi-second clock constructs (White 2017), and psychophysical time dilation testing (Stetson & Eagleman 2007)."
related_files:
  - "design/research/synthesis/combat-timelines-and-tempos.md"
  - "design/research/synthesis/dynamics-of-duel.md"
  - "design/iteration/crisis-round-duration-and-phrase-cadence-brief.md"
---

# Action Duration, the Perceptual Present, and Motor Control

## Executive Summary: Chronometric Architecture of Human Action

This synthesis brings together empirical findings from cognitive psychology, neurobiology, psychophysics, and motor control to establish the biological foundation of human action duration and temporal perception in high-stress, dynamic physical environments.

Human action and perception are neither continuous analog streams nor arbitrary slices of time. Rather, the human central nervous system (CNS) operates across multiple nested, task-dependent temporal scales:

1. **The Micro-Temporal / Sampling Tier (20–50 ms):** Governed by local cortical synchronization in the gamma band (~30–40 Hz), defining the discrete threshold for temporal order and sensory fusion (Pöppel, 2009; Wittmann, 2011).
2. **The Sensorimotor Correction Tier (90–150 ms):** Bounded by automatic, subcortical visual and somatosensory feedback loops that steer limb trajectories ("auto-pilot") without voluntary goal modification (Day & Lyon, 2000).
3. **The Ballistic Execution & Point of No Return Tier (150–250 ms):** Pure feed-forward motor programs (triphasic EMG; Schmidt & Lee, 2019) and the ~200 ms readiness potential threshold beyond which motor cancellation is biologically impossible (Schultze-Kraft et al., 2016).
4. **The Perceptual "Time Slice" (~300–400 ms):** Unconscious accumulation of sensory features rendered into conscious awareness in discrete epochs (Herzog et al., 2016).
5. **The Voluntary Reprogramming & Choice Tier (300–500 ms):** Visual feedback integration, Hick's law choice selection, and motor re-planning (Carlton, 1992).
6. **The Predictive Motor Synchronization Ceiling (~1.8 s):** The upper temporal boundary for automatic, anticipatory sensorimotor entrainment (Repp, 2005). Beyond ~1.8 seconds, the internal predictive model breaks down, and motor responses degrade into reactive feedback control.
7. **Multi-Scale Integration (Information Capacity vs. Clock Time):** Systematic review demonstrates that the brain possesses no single privileged 2–3 second biological clock or unitary "subjective present" (White, 2017). Instead, temporal integration is local, multi-scale, and constrained by task complexity and information density.

```
+----------------------------------------------------------------------------------------------------+
|                                    MASTER CHRONOMETRIC TAXONOMY                                    |
+----------------------+--------------------+--------------------------------------------------------+
| Temporal Scale       | Neurobiological    | Functional / Behavioral Phenomenon                     |
|                      | Mechanism          |                                                        |
+----------------------+--------------------+--------------------------------------------------------+
| 2–5 ms               | Auditory Receptor  | Interaural time difference (auditory spatial fusion)   |
| 10–20 ms             | Visual Transduction| Visual flicker fusion limit (photoreceptor kinetics)  |
| 20–40 ms             | Monosynaptic (M1)  | Spinal stretch reflex (muscle stiffness regulation)    |
| 30–50 ms             | Gamma Oscillations | Temporal order threshold (distinguishing A before B)   |
| 50–80 ms             | Transcortical (M2) | Long-latency stretch reflex (task-dependent stiffness) |
| 90–140 ms            | Subcortical Loops  | Fast automatic visuomotor correction ("auto-pilot")    |
| 100–150 ms           | Cortical Relay     | Visual transmission to V1 / Dorsal-Ventral streams     |
| 150–250 ms           | Ballistic Program  | Duration of pure feed-forward strike (jab, cut)        |
| 200 ms               | Readiness Potential| Motor Point of No Return (cancellation impossible)     |
| 200–250 ms           | Frontal-Basal Gang | Stop-Signal Reaction Time (covert motor inhibition)    |
| 250–400 ms           | Hick-Hyman Law     | Choice Reaction Time in high-entropy combat contexts   |
| 300–400 ms           | Perceptual Slice   | Discrete conscious rendering of visual features (Herzog)|
| 300–500 ms           | Cortical Feedback  | Voluntary closed-loop reprogramming / target switch    |
| 450–700 ms           | OODA / Bottleneck  | Full prediction error reset / PRP refractory delay     |
| 500–600 ms           | Spontaneous Motor  | Spontaneous Motor Tempo (SMT) / sub-movement cadence   |
| 1.8–2.0 s            | Sensorimotor Limit | Predictive motor synchronization ceiling (Repp 2005)   |
+----------------------+--------------------+--------------------------------------------------------+
```

---

## 1. Perceptual Integration Scales: Discrete Time Slices and Multi-Scale Processing

### 1.1 Elementary Temporal Events & Temporal Order Thresholds (20–50 ms)

At the finest temporal boundary of human perception, sensory and motor systems operate in discrete operational quanta governed by high-frequency neuronal oscillations (30–40 Hz gamma band):

- **Perceptual Fusion & Atemporal Time Points:** Stimuli lasting $\le 40\text{ ms}$ possess no internal duration and are experienced as dimensionless "time points" (or fused into co-temporality).[^poppel-2009-mach-atemporal-point] Two acoustic events separated by less than 2–5 ms or two visual flashes within 20–40 ms fuse into a single sensory event.
- **Temporal Order Thresholds:** The minimum latency required to reliably discern which of two stimuli occurred first is strictly constrained across modalities:
  - Auditory: ~2–5 ms for fusion; 20–30 ms for temporal order.
  - Tactile: ~10 ms for fusion; 30 ms for temporal order.
  - Visual: ~20–40 ms for fusion; 40–50 ms for temporal order.
- **Oculomotor and RT Quanta:** Motor control chronometrics (saccades, pursuit eye movements, and choice reaction time) reveal multimodal response histograms with periodic peaks spaced 30–40 ms apart, demonstrating that central motor initiation is discretized into ~30–40 ms operational steps.[^poppel-2009-elementary-events]
- **The Functional Moment:** Wittmann (2011) classifies this boundary as the _functional moment_—the elementary building block that defines simultaneity versus succession in sensory processing.[^wittmann-2011-moments-in-time]

### 1.2 Conscious Percept Duration: Discrete "Time Slices" (300–400 ms)

While millisecond-level sensory features are detected rapidly, rendering those features into conscious awareness is not continuous. Michael Herzog and colleagues (2016, 2020) demonstrated a two-stage model of visual awareness:[^herzog-2016-time-slices]

- **Unconscious High-Resolution Processing:** Sensory features (color, orientation, spatial trajectory) are processed unconsciously and quasi-continuously with millisecond resolution during a temporal window lasting **~300 to 400 ms**.
- **Discrete Perceptual Rendering:** At the conclusion of this ~300–400 ms integration epoch, the features are bound together and rendered simultaneously into conscious awareness as a discrete "time slice."
- **Epistemic Invariant:** Conscious awareness cannot occur beforehand; feature fusion requires the full ~300–400 ms window to complete. The phenomenal impression of continuous perception is a postdictive construction stitched across sequential ~400 ms processing epochs.[^herzog-2016-time-slices]

### 1.3 Multi-Scale Temporal Integration vs. Fixed Clock Constructs

Historically, early time-perception literature hypothesized that the central nervous system possessed a dedicated biological primitive—a ~2–3 second "subjective present" or internal clock that automatically packaged conscious experience into uniform multi-second chunks (Fraisse, 1963; Pöppel, 1997).

In a systematic review in _Psychological Bulletin_, Peter A. White (2017) evaluated every empirical line of evidence traditionally cited in favor of the multi-second clock hypothesis and demonstrated that the construct does not hold up under empirical scrutiny:[^white-2017-critique-subjective-present]

1. **Duration Reproduction Lacks a 3-Second Break-Point:** In empirical reproduction tasks, underestimation errors grow continuously and curvilinearly with duration rather than exhibiting a sharp discontinuity at 2–3 seconds. Furthermore, cognitive load disrupts interval reproduction at durations as short as **>500 ms** (Rammsayer & Ulrich, 2011; Brown, 1997), disproving the claim that multi-second intervals are processed automatically without attentional resources.
2. **Subjective Rhythmization Collapses at ~1.5 Seconds:** When listeners mentally group isochronous click trains into rhythmic pairs or triplets, automatic grouping collapses when the inter-stimulus interval exceeds **~1.5 seconds (1500 ms)** (Bolton, 1894; Baath, 2015)—substantially shorter than a 3-second window. Crucially, the total span of grouped beats shrinks from ~2.4 s at 1 Hz down to ~1.0 s at 5 Hz, demonstrating that grouping is constrained by **information rate**, not fixed clock duration.
3. **Action Segmentation Was Methodologically Confounded:** Field studies claiming cross-cultural 2–3 second "action units" (e.g., Schleidt et al., 1987) relied on subjective, unstated pause-duration criteria and selectively excluded common repetitive activities (eating, working, games). When pause criteria are varied systematically, observed behavioral units range from under 1 second to over 13 seconds (Kien & Kemp, 1997; Po et al., 2011).
4. **The "Envelope of Integration":** White demonstrated that temporal integration is not governed by a unitary clock. Instead, the central nervous system performs local, task-dependent temporal integration across multiple distributed mechanisms (from millisecond sensory binding to multi-second working memory maintenance). These windows are defined by **information density and processing capacity**, and their asynchronous outputs are dynamically integrated into a coherent global representation—an _envelope of integration_.[^white-2017-critique-subjective-present]

### 1.4 Predictive Sensorimotor Synchronization Ceiling (~1.8 Seconds)

While the brain does not have a uniform 3-second temporal clock, the motor system exhibits a clear empirical ceiling for continuous, predictive timing.

In a comprehensive review of sensorimotor synchronization, Bruno Repp (2005) established the upper limit for automatic anticipatory motor entrainment:[^repp-2005-synchronization-ceiling]

- **Predictive Entrainment (IOI < 1.8 s):** When synchronizing repetitive physical movements (such as finger tapping) to an external isochronous beat, humans maintain a small _negative mean asynchrony_ (anticipating the beat by 10–30 ms) for inter-onset intervals (IOIs) up to approximately **1.8 seconds (1800 ms)**.
- **Predictive Breakdown (IOI > 1.8 s):** When beat intervals exceed ~1.8 seconds, the internal predictive forward model fails. Motor responses begin lagging behind target events, degenerating into simple reactive adjustments (~200 ms latency) or requiring conscious mental subdivision and counting.[^repp-2005-synchronization-ceiling]
- **Significance for Motor Control:** 1.8 seconds marks the outer boundary of uninterrupted predictive motor execution. Beyond ~1.8 seconds, intentional movement sequences require sensory recalibration, closed-loop feedback, or deliberate cognitive renewal.

---

## 2. Motor Control: Feed-Forward (Open-Loop) vs. Feedback (Closed-Loop) Action

### 2.1 The Ballistic Motor Program (Feed-Forward / Open-Loop)

A motor program is a pre-structured set of central muscle commands formulated prior to movement onset in the premotor cortex (PMC), supplementary motor area (SMA), basal ganglia, and cerebellum, transmitted down the corticospinal tract to peripheral alpha motor neurons (Schmidt & Lee, 2019).

```
+-----------------------------------------------------------------------------+
|                TRIPHASIC ELECTROMYOGRAPHIC (EMG) PATTERN                    |
|                      IN FAST BALLISTIC STRIKES                              |
|                                                                             |
| Agonist Force  /\ (AG1: 50–100 ms)           /\ (AG2: 30–50 ms)             |
|               /  \                          /  \                            |
|              /    \                        /    \                           |
| ------------+------+----------------------+------+-------------- Target     |
|                    \                      /                     Impact      |
| Antagonist          \ (ANT: 50–100 ms)   /                                  |
| Braking              \/                 \/                                  |
|                                                                             |
| 0 ms               100 ms                200 ms               250 ms        |
| [--- OPEN-LOOP REGIME: IMMUNE TO VOLUNTARY SENSORY CORRECTION ---]          |
+-----------------------------------------------------------------------------+
```

- **Kinematics & EMG Structure:** Fast ballistic movements (e.g., a boxing jab, martial strike, or rapid parry) exhibit a classic **triphasic electromyographic (EMG) pattern**:
  1. **Agonist Burst 1 (AG1; 50–100 ms):** Explosive activation of prime movers driving acceleration toward the target.
  2. **Antagonist Burst (ANT; 50–100 ms):** Rapid counter-contraction acting as an active dynamic brake to prevent joint subluxation and stabilize trajectory.
  3. **Agonist Burst 2 (AG2; 30–50 ms):** Terminal clamping burst locking the limb onto the target coordinates at impact.
- **Maximum Duration of Pure Open-Loop Execution:** In movements lasting less than **150 to 200 ms**, the entire command sequence is discharged before incoming visual or proprioceptive sensory signals can be received, processed, and translated into an altered motor output. The movement is entirely ballistic and deterministic.

### 2.2 Empirical Latencies of Ballistic Physical Actions

Quantitative biomechanical analysis demonstrates the compressed duration of high-speed intentional strikes:

- **Boxing Jab:** 150–250 ms total delivery time; explosive phase 80–120 ms.
- **Karate Reverse Punch (_Gyaku-zuki_):** 150–220 ms from foot drive to target impact.
- **Fencing Lunge / Flèche (Initiation phase):** 300–450 ms total duration; however, the initial explosive extension of the weapon arm takes only **120–180 ms** before the lower body commits to the leap.
- **Baseball Swing / Weapon Swing:** 150–200 ms from initial rotational commitment to point of impact.

### 2.3 The Sensory Feedback Hierarchy and Latencies

```
+-----------------------------------------------------------------------------+
|                         SENSORY CORRECTION LATENCY                          |
|                                                                             |
| 20–40 ms   : Spinal Stretch Reflex (M1 Monosynaptic)                        |
|              [No directional correction; stiffness regulation only]          |
|                                                                             |
| 50–80 ms   : Transcortical Stretch Reflex (M2/M3 Polysynaptic)              |
|              [Modulates limb impedance based on pre-set task goals]         |
|                                                                             |
| 90–140 ms  : Fast Visuomotor Online Correction ("Auto-Pilot")               |
|              [Subconscious directional steering; Day & Lyon, Pruszynski]     |
|                                                                             |
| 200–250 ms : Stop-Signal Reaction Time (SSRT)                               |
|              [Covert motor inhibition threshold; Logan & Cowan]              |
|                                                                             |
| 300–500 ms : Voluntary Closed-Loop Reprogramming / Choice Target Switch     |
|              [Visual detection + Hick's Law decision + Motor replanning]     |
+-----------------------------------------------------------------------------+
```

1. **Short-Latency Spinal Reflex (M1; 20–40 ms):** Monosynaptic arc through Ia spindle afferents to spinal alpha motor neurons. Compensates for brief mechanical loads; incapable of altering goal-directed trajectory.
2. **Long-Latency Transcortical Reflex (M2/M3; 50–80 ms):** Proprioceptive signals traverse dorsal column-medial lemniscal pathways through primary somatosensory cortex (S1) and primary motor cortex (M1). Pruszynski and Scott (2008) demonstrated that M2 responses are "task-dependent," modulating limb stiffness according to intended targets, but cannot switch goals.
3. **Fast Visuomotor Online Corrections (90–140 ms):** Day & Lyon (2000), Franklin & Wolpert (2008), and Pruszynski et al. (2010) identified an automatic, sub-conscious visual feedback loop:
   - When a target or obstacle shifts mid-trajectory, involuntary EMG adjustments in the reaching arm appear within **90 to 140 ms**.
   - This "automatic pilot" is mediated via subcortical tectospinal (superior colliculus) and rapid parieto-frontal pathways. It can steer an existing trajectory toward a moving point, but **cannot cancel the movement or switch to a new tactical plan**.
4. **Voluntary Motor Reprogramming (300–500 ms):**
   - True voluntary modification—detecting an opponent's parry, aborting an ongoing attack, selecting a secondary opening, and initiating a distinct motor command—requires visual transmission (100–150 ms) + choice decision time (150–200 ms) + motor replanning and electromechanical delay (100–150 ms).
   - Carlton (1992) and Zelaznik et al. (1983) established that the minimum time required for visual feedback to consciously alter a goal-directed movement is **300 to 450 ms**.

### 2.4 The Motor "Point of No Return" and Stop-Signal Reaction Time (SSRT)

Can an actor abort a movement once it has been prepared?

- **Stop-Signal Reaction Time (SSRT):** Logan & Cowan (1984) established the independent horse-race model between a "go" process and a "stop" process. In human adults, the covert time required to cancel an initiated motor response is **200 to 250 ms**.
- **The Physical Point of No Return (Schultze-Kraft et al., PNAS 2016):**
  - Using real-time EEG brain-computer interfaces (BCIs), researchers monitored the readiness potential (Bereitschaftspotential) generated in the supplementary motor area as subjects prepared self-initiated movements.
  - Subjects were challenged with a sudden visual stop signal while their readiness potential was already peaking.
  - **The Empirical Threshold:** The point of no return occurs approximately **200 ms before movement (EMG) onset**.[^schultze-kraft-2016-point-of-no-return]
  - If the stop signal appeared more than 200 ms before movement, the brain successfully vetoed the action. If the signal arrived within the final 200 ms, the motor command had already crossed into subcortical/spinal execution; the movement occurred involuntarily, even while the subject consciously attempted to stop.

---

## 3. Temporal Limits of Simultaneous Action, Cognitive Bottlenecks & Acute Combat Stress

### 3.1 Defining Simultaneity in Physical Combat: The Co-Action Envelope

In dynamic kinetic interactions (martial arts, fencing, close-quarters combat), when can two actors be considered to act "simultaneously"?

```
TIMELINE OF INITIATION AND PERCEPTION BETWEEN TWO ACTORS

Actor A:  Initiates Strike (t = 0 ms)
          |
          v (Photons travel; retinal processing & V1 conduction: 100–120 ms)
Actor B:  First possible sensory registration of Actor A's movement (t = 100–120 ms)
          |
          +--- If Actor B initiates between t = 0 and t = 150 ms:
          |    Actor B's motor program was selected and launched INDEPENDENTLY.
          |    ==> TRUE SIMULTANEOUS ACTION / MUTUAL HIT ("DOUBLE TOUCH").
          |
          v (Choice reaction latency + Hick's Law: 250–350 ms)
          |
          +--- If Actor B initiates at t >= 250–300 ms:
               Actor B is REACTING in closed-loop defense.
               Actor A possesses absolute temporal initiative (Vor).
```

- **The Visual Latency Horizon (100–120 ms):** Visual signal transduction across the retina, optic nerve, lateral geniculate nucleus (LGN), and primary visual cortex (V1) consumes roughly 100 ms before the actor's cortex registers movement.
- **The Co-Action Envelope (0 to 150 ms):**
  - If Actor B launches an attack within 0 to 150 ms of Actor A's initiation, Actor B's CNS had already finalized and committed the motor command prior to receiving visual feedback of Actor A's action.
  - Neither actor can adjust, parry, or abort based on the other's movement. Both are executing independent, ballistic, open-loop motor programs that collide in physical space.
  - In competitive épée fencing (where double-touches are registered electronically without right-of-way rules), the scoring apparatus employs an electronic lockout interval of **40 to 50 ms**. If two strikes arrive within 40 ms of each other, a double-hit is awarded. Because human simple visual reaction time is ~200 ms and choice reaction time is ~300–370 ms, a 40 ms contact window proves that both athletes initiated their ballistic actions simultaneously; neither reacted to the other's terminal delivery.
- **The Reactive Regime (>250 ms):** If Actor B initiates at $t \ge 250\text{ ms}$, Actor B's action is biologically reactive. Actor A controls the temporal initiative (_Vor_), forcing Actor B into a closed-loop reactive state (_Nach_).

### 3.2 The Psychological Refractory Period (PRP) & The Central Bottleneck

When an actor must process two rapid, conflicting stimuli in succession, the human cognitive architecture suffers an unavoidable structural delay:

```
+-----------------------------------------------------------------------------+
|                 THE CENTRAL BOTTLENECK MODEL (WELFORD, PASHLER)             |
|                                                                             |
| Stimulus 1 (Feint)                                                          |
|   |--- Perceptual Stage (P1) ---|--- Decision Stage (C1) ---|--- Motor (M1)|
|                                                                             |
| Stimulus 2 (Real Strike; arrives 100 ms after Feint)                        |
|   |--- Perceptual Stage (P2) ---|====== SLACK / BOTTLENECK =====|--- C2 --- |
|                                 [C2 is frozen waiting for C1]               |
+-----------------------------------------------------------------------------+
```

- **The Bottleneck Mechanism (Welford, 1952; Pashler, 1994):** Information processing consists of three phases: Perceptual analysis ($P$), Central decision/response selection ($C$), and Motor execution ($M$).
  - Perceptual analysis ($P$) can operate in parallel.
  - Central response selection ($C$) is strictly serial—a single-channel bottleneck.
- **The Cost of Deception (The Biomechanics of a Feint):**
  - When Actor A executes a feint ($S_1$), Actor B's central processor engages to select an appropriate defensive response ($C_1$).
  - When Actor A alters the attack trajectory ($S_2$) within 50 to 200 ms (a short Stimulus Onset Asynchrony, SOA), Actor B's perceptual cortex processes $S_2$, but central response selection ($C_2$) is blocked.
  - **Cognitive Slack:** $C_2$ cannot begin until $C_1$ completes. This injects an artificial delay ("slack") of **200 to 400 ms** into Actor B's reaction time to the real threat.
  - In dynamic combat, this cognitive stall leaves the defender frozen or executing an obsolete defensive motor command while the true attack lands.

### 3.3 The OODA Loop / Active Inference Prediction Error Reset

The military concept of the OODA loop (Observe, Orient, Decide, Act; Boyd, 1987) directly maps to the neurobiology of predictive active inference:

```
+-----------------------------------------------------------------------------+
|            NEUROBIOLOGY OF AN UNPREDICTED DISRUPTION (OODA RESET)           |
+-------------+----------------------+--------------------+-------------------+
| Stage       | Neural Structure     | Processing Latency | Cumulative Time   |
+-------------+----------------------+--------------------+-------------------+
| Observe     | Retina -> LGN -> V1  | 100–150 ms         | 100–150 ms        |
| Orient      | Posterior Parietal / | 100–200 ms         | 200–350 ms        |
|             | Anterior Cingulate   |                    |                   |
| Decide      | Dorsolateral PFC /   | 100–150 ms         | 300–500 ms        |
|             | Premotor / Striatum  |                    |                   |
| Act         | M1 -> Corticospinal  | 100–150 ms         | 400–650 ms        |
|             | -> Muscle EMD        |                    |                   |
+-------------+----------------------+--------------------+-------------------+
```

- When an opponent creates a severe, unpredicted tactical violation (e.g., an unexpected flank maneuver, sudden weapon drop, or unexpected physical obstacle), the actor's top-down generative model fails.
- The resulting prediction error spike requires a full re-orientation cycle:
  - Detection: ~100–150 ms.
  - Prediction error resolution / orientation: ~100–200 ms.
  - Decision / action selection: ~100–150 ms.
  - Motor reprogramming and electromechanical delay (EMD): ~100–150 ms.
- **Total Cognitive Reset Latency:** **450 to 700 ms**. During this half-second window, the actor is cognitively incapacitated, incapable of launching a proactive counter-measure.

### 3.4 Acute Combat Stress & Sympathetic Nervous Arousal

```
+-----------------------------------------------------------------------------+
|               NEUROCHEMISTRY OF ACUTE SURVIVAL AROUSAL                      |
|                                                                             |
| Threat Perception (Amygdala) ---> Hypothalamus                              |
|                                   |                                         |
|       +---------------------------+---------------------------+             |
|       v                                                       v             |
| Sympathetic Adrenal Medulla                             Locus Coeruleus     |
| [Epinephrine / Norepinephrine]                          [High Norepinephr]  |
|       |                                                       |             |
|       v                                                       v             |
| Peripheral Vasoconstriction / HR Acceleration       Prefrontal Cortex (PFC) |
| Loss of Fine Motor Coordination                     DOWNSHIFT & DECOUPLING  |
| [Striatum & Amygdala take control]                  [Loss of working memory]|
+-----------------------------------------------------------------------------+
```

#### Prefrontal Cortex (PFC) Downregulation (Arnsten, 2009; 2015)

Under acute life-threatening stress, the sympathetic adrenal medullary system floods the body with epinephrine and norepinephrine, while the locus coeruleus drenches the forebrain in high concentrations of norepinephrine and dopamine:

- High levels of catecholamines engage lower-affinity **$\alpha_1$-adrenergic** and **$D_1$-dopaminergic receptors**, which shut down the persistent firing of prefrontal cortical pyramidal networks through intracellular cAMP-PKA signaling (opening potassium channels).
- **Executive Function Suppression:** Working memory, flexible rule evaluation, creative problem-solving, and deliberate risk appraisal are rapidly uncoupled.
- **Subcortical Shift:** Control of behavior shifts from the rational, goal-directed prefrontal cortex to reflexive, evolutionarily primitive circuits: the amygdala, dorsal striatum (habitual routines), and brainstem.

#### Tachypsychia & Perceptual Distortions: Eagleman's Perceptual Chronometer

A widespread anecdotal claim in combat, motor vehicle crashes, and falling accidents is **tachypsychia**—the sensation that time has slowed down to "bullet time," allowing the actor to observe details with superhuman clarity.

- **The Empirical Reality (Stetson, Fiesta, & Eagleman, PLoS ONE 2007):**
  - David Eagleman and colleagues evaluated whether human visual temporal resolution actually speeds up during terror.
  - Subjects were dropped backward from a 31-meter (100+ foot) tower into a Suspended Catch Air Device (SCAD) net in free fall (reaching speeds of 70 km/h under profound existential terror).
  - Subjects wore a wrist-mounted "perceptual chronometer" displaying alternating digital numerals flickering just beyond the critical flicker fusion frequency (CFF)—numbers that were impossible to read at normal frame rates.
  - **Result:** Subjects plummeting in terror were **no better at reading the flickering digits than they were sitting safely in a laboratory chair**.[^stetson-2007-time-dilation] Their real-time visual sampling rate did not increase by even a fraction of a millisecond.
  - **The Mechanism of Temporal Dilation:** When participants landed, they retrospectively estimated their fall duration to be **36% longer** than identical falls observed from the ground.
  - **Conclusion:** Tachypsychia is a **retrospective memory illusion**, not a real-time perceptual alteration. Under severe survival threat, the basolateral amygdala hyper-activates, forcing memory storage into overdrive. The brain encodes sensory data with extraordinary density and vividness. When the cognitive system later interrogates that memory, the sheer density of stored data causes the retrospective heuristic: _"Because this memory contains vast detail, it must have lasted a long time."_

#### Empirical Sensory Distortions in Armed Encounters (Artwohl & Christensen, 1997; 2002)

Surveys of law enforcement personnel involved in lethal force encounters document consistent acute perceptual alterations:

- **Auditory Exclusion (Diminished Sound): 84% to 88%** of actors. The brainstem and midbrain selectively gate acoustic processing to preserve visual bandwidth.
- **Tunnel Vision (Selective Attentional Narrowing): 79% to 82%** of actors. Peripheral vision drops by up to 70%, locking visual fixation entirely onto the immediate threat or weapon.
- **Perceived Slow-Motion Time (Tachypsychia): 62% to 67%** of actors.
- **Perceived Fast-Motion Time (Time Compression): 17%** of actors (events appear to occur with impossible, unmanageable velocity).
- **Dissociation / Memory Gaps: 50% to 60%** of actors.

#### Motor Skill Degradation Across Sympathetic Arousal Tiers (Siddle, 1995; Grossman, 1996)

As heart rate escalates under acute sympathetic activation, motor capabilities degrade in distinct physiological tiers:

```
+-----------------------------------------------------------------------------+
|              MOTOR PERFORMANCE UNDER SYMPATHETIC AROUSAL                    |
+-------------------+--------------------+------------------------------------+
| Heart Rate (BPM)  | Physiological Tier | Functional Motor Capacity          |
+-------------------+--------------------+------------------------------------+
| 60–100 bpm        | Normal Homeostasis | Baseline fine and complex motor    |
|                   |                    | control; optimal dexterity         |
| 115–145 bpm       | Optimal Combat     | Maximum reaction speed; enhanced   |
|                   | Readiness          | visual vigilance; gross power peak |
| > 115 bpm         | Fine Motor         | Peripheral vasoconstriction; loss  |
|                   | Degradation        | of finger dexterity and threading  |
| > 145 bpm         | Complex Motor      | Loss of multi-joint coordination;  |
|                   | Breakdown          | tracking errors; timing jitter     |
| > 175 bpm         | Hyper-Arousal /    | Tunnel vision; auditory exclusion; |
|                   | Gross Motor Only   | freezing; default to bilateral     |
|                   |                    | gross motor flexion/extension      |
+-------------------+--------------------+------------------------------------+
```

1. **Optimal Performance Zone (115–145 bpm):** Vasoconstriction increases central blood pressure; reaction times are at their peak; visual tracking of macro-movements is acute; gross motor power output reaches maximum.
2. **Fine Motor Degradation (>115 bpm):** Sympathetic peripheral vasoconstriction diverts blood from extremities to major core muscles. Micro-musculature of the fingers and wrists loses fine proprioceptive calibration. Fine tasks (e.g., picking a lock, fine blade angle adjustments, knot manipulation) degrade severely.
3. **Complex Motor Breakdown (>145 bpm):** Skills requiring multi-segment biomechanical coordination (combining footwork, torso rotation, and targeted weapon tracking) rapidly disintegrate. Hick's Law degrades—reaction times slow exponentially when faced with multiple tactical choices.
4. **Gross Motor Dominance & Freezing (>175 bpm):** Full autonomic overdrive. Prefrontal cortex function is severely suppressed. The actor defaults strictly to primitive, large-muscle bilateral gross motor patterns (charging forward, flailing, running, cowering). The parasympathetic brake fails, leading to catastrophic cognitive freezing or uncoordinated motor spasticity.

---

## 4. Synthesis: Operational Chronometrics of an Intentional Motor Action

Synthesizing motor control neurobiology and cognitive chronometrics establishes the concrete latencies governing how intentional physical actions unfold:

```
+-----------------------------------------------------------------------------+
|            CHRONOMETRIC ARCHITECTURE OF AN INTENTIONAL ACTION               |
|                                                                             |
| 0.0 s                 0.2 s          0.5 s                    1.8 s         |
| +---------------------+--------------+------------------------+             |
| | SUB-MOVEMENT 1      | VOLUNTARY    | SUB-MOVEMENT 2         |             |
| | Pure Ballistic      | CORRECTION   | Chained kinematic      |             |
| | Feed-Forward Strike | WINDOW       | follow-through / reset |             |
| +---------------------+--------------+------------------------+             |
| [--- 150–200 ms ---]                                                        |
| Triphasic EMG AG1/ANT                                                       |
|                                                                             |
| [- 200 ms to 0 ms -]                                                        |
| Point of No Return                                                          |
| (Veto impossible)                                                           |
|                       [-- 300–500 ms --]                                    |
|                       Visual feedback                                       |
|                       reprogramming / abort                                 |
|                                                                             |
| [=================== UP TO ~1.8 SECONDS ====================]               |
| Predictive motor entrainment ceiling (Repp, 2005)                           |
| Beyond ~1.8 s, continuous forward modeling degrades into reactive tracking  |
+-----------------------------------------------------------------------------+
```

1. **Ballistic Commitment and the Point of No Return:**
   - Fast explosive sub-movements (150–250 ms, such as a jab, cut, or initial lunge) are discharged via open-loop, triphasic EMG motor programs.
   - The neurological **Point of No Return occurs ~200 ms before EMG onset** (Schultze-Kraft et al., 2016). Once the readiness potential crosses this threshold, the command cannot be vetoed; it executes ballistically regardless of sensory changes.
2. **Closed-Loop Feedback Latencies:**
   - Involuntary, subcortical visuomotor adjustments ("auto-pilot") can steer limb trajectory within **90 to 140 ms** (Day & Lyon, 2000), but cannot cancel the action or switch tactical goals.
   - Conscious voluntary reprogramming (aborting an attack, reacting to an unexpected parry, or re-aiming) requires **300 to 500 ms** (Carlton, 1992).
3. **Simultaneity and Co-Action (The 0–150 ms Collision Envelope):**
   - Due to visual transduction and cortical processing latencies (~100–120 ms), actions initiated by two combatants within **0 to 150 ms** of each other are physically and cognitively independent.
   - Neither combatant can perceive or react to the other's launch; both commit to their ballistic actions simultaneously, producing concurrent collisions or double-touches.
   - Reactive defenses require at least **250 to 300 ms** to initiate.
4. **Deception and Bottlenecks (The PRP Feint):**
   - Central response selection is strictly serial (Pashler, 1994).
   - An effective feint forces the defender to commit to resolving Stimulus 1. A secondary real strike launched 50–200 ms later creates an artificial cognitive stall ("slack") of **200 to 400 ms**, during which the defender cannot initiate a second response.
5. **Predictive Action Horizon (~1.8 s):**
   - An intentional combat sequence consists of 1 to 3 chained sub-movements (each ~200–500 ms; SMT ~500–600 ms).
   - Feed-forward predictive timing remains accurate only up to approximately **1.8 seconds** (Repp, 2005). Beyond this horizon, continuous predictive execution breaks down, requiring the actor to transition to reactive tracking, pause, or re-orient.
   - Severe unpredicted disruptions force an active inference OODA reset requiring **450 to 700 ms** before voluntary action can resume.
6. **Stress Modulation:**
   - Acute survival terror does **not** grant heightened temporal resolution (Stetson et al., 2007). Real-time perceptual sampling rates remain unchanged; perceived time dilation is a retrospective memory artifact caused by amygdalar encoding density.
   - Elevated sympathetic arousal progressively strips away fine motor dexterity (>115 bpm) and complex multi-joint coordination (>145 bpm), default-locking the actor into rapid gross motor patterns.

---

## 5. Peer-Reviewed References & Empirical Literature

1. **Arnsten, A. F. T.** (2009). "Stress signalling pathways that impair prefrontal cortex structure and function." _Nature Reviews Neuroscience_, 10(6), 410–422. DOI: 10.1038/nrn2648.
2. **Arnsten, A. F. T.** (2015). "Stress weakens prefrontal networks: molecular insults to higher cognition." _Nature Neuroscience_, 18(10), 1376–1385. DOI: 10.1038/nn.4087.
3. **Artwohl, A., & Christensen, L. W.** (1997). _Deadly Force Encounters: What Cops Need to Know to Mentally and Physically Prepare for and Survive a Gunfight_. Police Marksman Association.
4. **Baddeley, A.** (2000). "The episodic buffer: a new component of working memory?" _Trends in Cognitive Sciences_, 4(11), 417–423. DOI: 10.1016/S1364-6613(00)01538-2.
5. **Boyd, J. R.** (1987). "A Discourse on Winning and Losing." _Air University Library Document No. M-U 43947-1_.
6. **Carlton, L. G.** (1992). "Visual processing time and the control of movement." In L. Proteau & D. Elliott (Eds.), _Vision and Motor Control_ (pp. 3–31). Amsterdam: North-Holland.
7. **Day, B. L., & Lyon, I. N.** (2000). "Voluntary modification to express visuomotor responses in humans." _The Journal of Physiology_, 526(2), 471–482. DOI: 10.1111/j.1469-7793.2000.00471.x.
8. **Desmurget, M., & Grafton, S.** (2000). "Forward modeling allows feedback control for fast reaching movements." _Trends in Cognitive Sciences_, 4(11), 423–431. DOI: 10.1016/S1364-6613(00)01537-0.
9. **Franklin, D. W., & Wolpert, D. M.** (2008). "Specificity of reflex adaptation for task-relevant variables." _Journal of Neuroscience_, 28(52), 14167–14175. DOI: 10.1523/JNEUROSCI.4406-08.2008.
10. **Grossman, D.** (1996). _On Killing: The Psychological Cost of Learning to Kill in War and Society_. Little, Brown and Company.
11. **Herzog, M. H., Kammer, T., & Scharnowski, F.** (2016). "Time Slices: What Is the Duration of a Percept?" _PLOS Biology_, 14(4), e1002433. DOI: 10.1371/journal.pbio.1002433.
12. **Hick, W. E.** (1952). "On the rate of gain of information." _Quarterly Journal of Experimental Psychology_, 4(1), 11–26. DOI: 10.1080/17470215208416600.
13. **Keele, S. W., & Posner, M. I.** (1968). "Processing of visual feedback in rapid movements." _Journal of Experimental Psychology_, 77(1), 155–158. DOI: 10.1037/h0025754.
14. **Logan, G. D., & Cowan, W. B.** (1984). "On the ability to inhibit thought and action: A theory of an act of control." _Psychological Review_, 91(3), 295–327. DOI: 10.1037/0033-2909.91.3.295.
15. **Pashler, H.** (1994). "Dual-task interference in simple tasks: data and theory." _Psychological Bulletin_, 116(2), 220–244. DOI: 10.1037/0033-2909.116.2.220.
16. **Pöppel, E.** (2009). "Pre-semantically defined temporal windows for cognitive processing." _Philosophical Transactions of the Royal Society B: Biological Sciences_, 364(1525), 1887–1896. DOI: 10.1098/rstb.2009.0015.
17. **Pruszynski, J. A., Kurtzer, I., & Scott, S. H.** (2008). "Rapid motor responses are exquisitely tuned to the task." _Nature Neuroscience_, 11(10), 1104–1106. DOI: 10.1038/nn.2184.
18. **Pruszynski, J. A., King, G. L., Boisse, L., Zhou, H., Flanagan, J. R., & Scott, S. H.** (2010). "Fast visuomotor responses in human elbow muscles define a dynamic control system." _Journal of Neurophysiology_, 103(1), 168–179. DOI: 10.1152/jn.00697.2009.
19. **Repp, B. H.** (2005). "Sensorimotor synchronization: A review of the tapping literature." _Psychological Bulletin_, 131(6), 969–1016. DOI: 10.1037/0033-2909.131.6.969.
20. **Schmidt, R. A., & Lee, T. D.** (2019). _Motor Control and Learning: A Behavioral Emphasis_ (6th ed.). Champaign, IL: Human Kinetics.
21. **Schultze-Kraft, M., Birman, D., Rusconi, M., Allefeld, C., Görgen, K., Dähne, S., Blankertz, B., & Haynes, J. D.** (2016). "The point of no return in vetoing self-initiated movements." _Proceedings of the National Academy of Sciences (PNAS)_, 113(4), 1080–1085. DOI: 10.1073/pnas.1513569112.
22. **Siddle, B. K.** (1995). _Sharpening the Warrior's Edge: The Psychology & Science of Training_. Belleville, IL: PPCT Research Publications.
23. **Stetson, C., Fiesta, M. P., & Eagleman, D. M.** (2007). "Does time really slow down during a frightening event?" _PLoS ONE_, 2(12), e1295. DOI: 10.1371/journal.pone.0001295.
24. **Welford, A. T.** (1952). "The 'psychological refractory period' and the timing of high-speed performance: A review and a theory." _British Journal of Psychology_, 43(1), 2–19. DOI: 10.1111/j.2044-8295.1952.tb00322.x.
25. **White, P. A.** (2017). "The three-second 'subjective present': A critical review and a new proposal." _Psychological Bulletin_, 143(7), 735–756. DOI: 10.1037/bul0000104.
26. **Wittmann, M.** (2011). "Moments in time." _Frontiers in Integrative Neuroscience_, 5, 66. DOI: 10.3389/fnint.2011.00066.
27. **Zacks, J. M., Speer, N. K., Swallow, K. M., Braver, T. S., & Reynolds, J. R.** (2007). "Event perception: a mind-brain perspective." _Psychological Bulletin_, 133(2), 273–293. DOI: 10.1037/0033-2909.133.2.273.
28. **Zelaznik, H. N., Hawkins, B., & Kisselburgh, L.** (1983). "Rapid visual feedback processing in single-aiming movements." _Journal of Motor Behavior_, 15(3), 217–236. DOI: 10.1080/00222895.1983.10735298.

---

## 6. Primary Evidence Anchors (Claim-Level Citations)

[^poppel-2009-mach-atemporal-point]:
    source: poppel-2009-presemantically-defined-temporal-windows
    locator: "p. 1888 ([extracted.md#L11](../sources/verisimilitude/poppel-2009-presemantically-defined-temporal-windows/extracted.md#L11))"
    quote: "in studying differential sensitivities in the auditory modality he observed that there is no experience of ‘duration’ for intervals that are shorter than 40 ms. Stimuli with 40 ms duration or shorter are experienced as ‘time points’. ... This time point can be conceived of as the ‘temporal window’ on a physical scale to construct primordial events"
    status: [vetted: tdimiduk]

[^poppel-2009-elementary-events]:
    source: poppel-2009-presemantically-defined-temporal-windows
    locator: "p. 1889 ([extracted.md#L45](../sources/verisimilitude/poppel-2009-presemantically-defined-temporal-windows/extracted.md#L45))"
    quote: "latency distributions of two types of eye movements and response histograms for choice reaction time show identical characteristics; in spite of the differences of average response time the modal distance in all cases is the same. This observation points to a common underlying temporal machinery, i.e. that processed information is temporally segmented into successive units of approximately 30–40 ms; these elementary processing units should not be understood as ‘physical constants’, but as operating ranges with some variability."
    status: [vetted: tdimiduk]

[^white-2017-critique-subjective-present]:
    source: white-2017-three-second-subjective-present-critique
    locator: "Abstract, pp. 735, 750–752 ([extracted.txt#L53-L2863](../sources/verisimilitude/white-2017-three-second-subjective-present-critique/extracted.txt#L53-L2863))"
    quote: "Most of the research findings were not consistent with the three-second window hypothesis. The small amount of supportive evidence is better interpreted as effects of specific processing mechanisms, not as showing general temporal integration. The evidence shows that temporal integration occurs on multiple time scales and no particular duration is special, and that windows of temporal integration are defined in terms of information density, not in terms of duration. The subjective present is constructed through local temporal integration on multiple time scales, further integrated into a coherent global representation of what is going on. ... At the supra-second scale as well as the sub-second scale, temporal integration is a local phenomenon, operating in different ways in different processes. ... The three main features of this proposal are that temporal integration operates in different ways in different processes, that temporal parameters of the \"subjective present\" are set by information density rather than time per se, and that there is some form of global integration of the products of local integration processes that is responsible for the subjective coherence of experience and the general sense of ongoing happening. ... Two conclusions can be drawn from this research. One is that there is no single time window defining the envelope of integration. Instead, there are multiple time windows of integration in perceptual processing and beyond, starting on the millisecond time scale and stretching out to the level of narrative on a time scale perhaps as much as hundreds of seconds ... The other is that each window of temporal integration should be conceptualised in terms of information capacity, not time scale. ... Thus, the envelope of integration is a spatially, temporally, and semantically organised and integrated representation of what is going on, combining local integration of all three kinds into a coherent overall representation. It is not defined in terms of time scales. ... The envelope of integration, then, is an integrated representation of the current percept (the experienced present) with information about the recent past, which is constructed on several time scales or levels of information processing, each of which involves its own internal temporal integration, and each of which is temporally integrated into a coherent representation of what is going on. ... There is no three-second subjective present or experienced moment. There is, instead, an envelope of integration in which there are multiple qualitatively different representations of what is going on, each occupying different and variable time scales of integration, and each integrated into an overall representation that has no fixed time limit, but in any case extends well beyond the three second mark. ... Instead, piecemeal updating is accompanied by integration processes that ensure that our perception of what is going on remains coherent."
    status: unverified
    vetting_note: "Systematic review dismantling the 3-second biological clock. Conclusions across Abstract (lines 53–67), p. 735 (lines 209–235), and pp. 750–752 (lines 2013–2863) demonstrate multi-scale temporal integration governed by task constraints and information density."

[^herzog-2016-time-slices]:
    source: herzog-2016-time-slices-percept-duration
    locator: "pp. 2–4 ([extracted.md#L50-L92](../sources/verisimilitude/herzog-2016-time-slices-percept-duration/extracted.md#L50-L92))"
    quote: "We propose a two-stage model, in which first visual information is unconsciously processed with relatively high temporal resolution ... conscious percepts occur at a much slower rate, at discrete moments, “representing” the output of unconscious processing. ... This experiment revealed that feature fusion is not completed before 400 ms, and consequently consciousness cannot occur beforehand. It thus provides a lower bound for the minimal duration of percepts in this paradigm."
    status: unverified

[^repp-2005-synchronization-ceiling]:
    source: repp-2005-sensorimotor-synchronization-review
    locator: "Section 2 (Rate Limits), pp. 971–972 ([extracted.txt#L152-L244](../sources/verisimilitude/repp-2005-sensorimotor-synchronization-review/extracted.txt#L152-L244))"
    quote: "There is also an upper IOI limit (or lower rate limit) for SMS with a metronome sequence, although it is less sharply defined. A crucial aspect of SMS is the prediction of future events: Although each tap may be regarded as the response to a preceding tone, it is a timed response that is delayed so as to coincide approximately with the next tone. ... When metronome IOIs exceed about 1.8 sec, prediction becomes increasingly difficult, and responses begin to lag behind their respective target events (Engström et al., 1996; Mates, Radil, Müller, & Pöppel, 1994; Y. Miyake, Onishi, & Pöppel, 2004). In other words, when responses can no longer be timed accurately enough to coincide with the next tone, some responses turn into simple reactions to that tone, and this results in a bimodal distribution of asynchronies. ... The upper IOI limit of about 1.8 sec has been related to the duration of the subjective present and the temporal capacity of working memory (Pöppel, 1997; Szelag, von Steinbüchel, Reiser, de Langen, & Pöppel, 1996; Wittmann & Pöppel, 1999/2000). More generally, the IOI limits for SMS coincide with those within which a sequence of events can be perceived to have rhythmic and metrical structure"
    status: unverified

[^wittmann-2011-moments-in-time]:
    source: wittmann-2011-moments-in-time
    locator: "Sections: The Functional Moment, The Experienced Moment, Mental Presence ([extracted.md#L11-L39](../sources/verisimilitude/wittmann-2011-moments-in-time/extracted.md#L11-L39))"
    quote: "Departing from the taxonomy by Pöppel () three different temporal processing levels will be discerned which are assumed to temporally integrate events on different time scales. ... temporal integration provides _functional moments_ of experienced co-temporality. ... Whereas the duration of the _functional moment_ is not perceived, an _experienced moment_ relates to the experience of an extended now. ... Whereas the _experienced moment_ forms an elementary unit, a temporally unified percept, _mental presence_ involves the experience of a perceiving and feeling agent ... within a window of extended presence, a phenomenon that is based on working memory function."
    status: unverified

[^schultze-kraft-2016-point-of-no-return]:
    source: schultze-kraft-2016-point-of-no-return-vetoing
    locator: "Discussion, p. 1083 ([extracted.md#L55](../sources/verisimilitude/schultze-kraft-2016-point-of-no-return-vetoing/extracted.md#L55))"
    quote: "several aspects of our data suggest that subjects were able to cancel an upcoming movement until a point of no return was reached around 200 ms before movement onset. If the stop signal occurs later than 200 ms before EMG onset, the subject cannot avoid moving."
    status: unverified

[^stetson-2007-time-dilation]:
    source: stetson-2007-time-dilation-frightening-event
    locator: "Abstract / PLoS ONE 2(12): e1295 ([extracted.md#L3](../sources/verisimilitude/stetson-2007-time-dilation-frightening-event/extracted.md#L3))"
    quote: "We found no evidence of increased temporal resolution, in apparent conflict with the fact that participants retrospectively estimated their own fall to last 36% longer than others' falls. ... Our findings suggest that time-slowing is a function of recollection, not perception: a richer encoding of memory may cause a salient event to appear, retrospectively, as though it lasted longer."
    status: unverified
