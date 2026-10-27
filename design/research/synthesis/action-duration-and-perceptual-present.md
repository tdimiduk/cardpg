---
title: "Action Duration, the Perceptual Present, and Motor Control"
doc_type: "synthesis"
track: "verisimilitude"
origin: "AI synthesized"
epistemic_status:
  confidence: "high"
  audited_by: "Gemini 3.8 Flash (Antigravity)"
  vetted_by_human: false
  vetting_notes: "Grounded in peer-reviewed cognitive neuroscience (Pöppel 2009, Schleidt 1987, Fraisse 1963), sensorimotor synchronization limits (Repp 2005), visual percept time slices (Herzog 2016), and the systematic critique of the 3-second biological clock by White (2017). Motor control point-of-no-return EEG studies (Schultze-Kraft 2016), and psychophysical time dilation testing (Stetson & Eagleman 2007)."
related_files:
  - "design/research/synthesis/combat-timelines-and-tempos.md"
  - "design/research/synthesis/dynamics-of-duel.md"
  - "design/iteration/crisis-round-duration-and-phrase-cadence-brief.md"
---

# Action Duration, the Perceptual Present, and Motor Control

## Executive Summary: Chronometric Architecture of Human Action

This synthesis brings together empirical findings from cognitive psychology, neurobiology, psychophysics, and motor control to establish the biological foundation of human action duration and temporal perception in high-stress, dynamic physical environments.

Human action and perception are neither continuous analog streams nor arbitrary slices of time. Rather, the human central nervous system (CNS) operates across multiple nested, task-dependent temporal scales:

1. **The Micro-Temporal / Sampling Tier (20–50 ms):** Governed by local cortical synchronization in the gamma band (~30–40 Hz), defining the discrete threshold for temporal order and sensory fusion.
2. **The Sensorimotor Correction Tier (100–300 ms):** Bounded by visual and somatosensory transmission latencies, transcortical reflex loops, and stop-signal reaction times (SSRT), defining the boundary between ballistic feed-forward (open-loop) motor execution and sensory-guided (closed-loop) online steering.
3. **The Perceptual "Time Slice" (~300–400 ms):** Bounded by quasi-unconscious feature integration windows in visual perception, after which integrated perceptual properties are rendered consciously into awareness as a discrete package (Herzog et al., 2016).
4. **The Operative / Behavioral Present (~1.8–3.0 Seconds [Phenomenological Heuristic]):** A robust behavioral transition zone reflecting the convergence of sensorimotor predictive synchronization limits (~1.8 s), working memory buffer decay (2–3 s), and spontaneous motor/linguistic phrasing (2–3 s). While historically hypothesized by Pöppel and Fraisse as a dedicated biological primitive ("subjective present"), modern cognitive neuroscience (notably White, 2017) indicates there is **probably no single biological clock or privileged primitive** here; rather, this multi-second window is an emergent clustering of distinct task constraints, biomechanical cadences, and information-density thresholds.

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
| 1.8–2.0 s            | Sensorimotor Limit | Maximum period for predictive motor sync (Repp 2005)   |
| 2.0–3.0 s            | Behavioral Cluster | Spontaneous action unit / Fraisse-Pöppel heuristic     |
| 3.0–5.0 s            | Gestalt Upper Bound| Classical psychological present upper limit (Fraisse)  |
+----------------------+--------------------+--------------------------------------------------------+
```

---

## 1. The "Psychological Present", Behavioral Chunking, and the Multi-Scale Debate (~300 ms to ~3 Seconds)

### 1.1 Ernst Pöppel’s Hierarchical Taxonomy & The "Subjective Present" Hypothesis

Neuroscientist Ernst Pöppel (1997, 2009) proposed that human temporal experience is organized across nested processing tiers prior to higher-order cognitive or memory reconstruction:

```
+-----------------------------------------------------------------------------+
|               LEVEL 3: MACRO-TEMPORAL COGNITIVE ESTIMATION                  |
|          Durations > 3.0 s; requires working memory rehearsal and           |
|                       episodic memory reconstruction                        |
+-----------------------------------------------------------------------------+
                                      ^
                                      |
+-----------------------------------------------------------------------------+
|               LEVEL 2: AUTOMATIC TEMPORAL INTEGRATION WINDOW                |
|      ~2.0 to 3.0 Seconds (Hypothesized "Subjective Present" / Heuristic)     |
|      Binds discrete sensory events into a single perceptual Gestalt.        |
|           Limits motor programs to "one coherent intentional act."          |
+-----------------------------------------------------------------------------+
                                      ^
                                      |
+-----------------------------------------------------------------------------+
|               LEVEL 1: ELEMENTARY TEMPORAL EVENTS / SAMPLING                |
|             ~30 to 50 Milliseconds (30–40 Hz Gamma Oscillations)            |
|       System states; defines temporal order threshold and event fusion      |
+-----------------------------------------------------------------------------+
```

- **Level 1 (Elementary Temporal Events; ~30–50 ms):** Governed by high-frequency neuronal oscillations (30–40 Hz). At the perceptual boundary, stimuli lasting $\le 40\text{ ms}$ possess no internal duration and are experienced as dimensionless "time points" (or fused into co-temporality).[^poppel-2009-mach-atemporal-point] In parallel, motor control chronometrics (saccades, pursuit eye movements, and choice RT) reveal multimodal response histograms with periodic peaks spaced 30–40 ms apart, demonstrating that central processing is discretized into 30–40 ms operational quanta.[^poppel-2009-elementary-events] The temporal order threshold—the minimum latency needed to reliably discern which of two stimuli occurred first—is modality-dependent:
  - Auditory: ~2–5 ms for fusion; 20–30 ms for temporal order.
  - Tactile: ~10 ms for fusion; 30 ms for temporal order.
  - Visual: ~20–40 ms for fusion; 40–50 ms for temporal order.
- **Level 2 (Automatic Temporal Integration; ~2–3 Seconds [Hypothesis]):** Pöppel hypothesized that the brain automatically bundles sequences of elementary events into dynamic cognitive units lasting approximately 2 to 3 seconds.[^poppel-2009-temporal-integration] Sensory data and motor acts within this window are treated as belonging to a "subjective present" or an "experienced now."[^poppel-2009-subjective-present] Within Pöppel (2009), this hypothesis is supported by several distinct empirical regularities:
  - **Temporal Reproduction Break-Point:** Subjects reproduce auditory or visual durations veridically with low variance up to ~2–3 seconds; beyond 3 seconds, reproduction errors spike with marked under-reproduction as the un-rehearsed trace disintegrates (Pöppel, 1971; Kagerer et al., 2002). Autistic children exhibit a strong default "eigen-operation" snapping duration reproductions to ~3 s or multiples thereof (Szelag et al., 2004c).
  - **Metronome Grouping Ceiling:** When auditory click sequences have an inter-stimulus interval (ISI) under ~2.0–2.5 seconds, listeners effortlessly group them into subjective rhythmic pairs or triplets (Wundt, 1911; Szelag et al., 1997, 1998). When the ISI exceeds ~2.5–3.0 seconds, this automatic "pop-up" grouping vanishes; subjects must rely on conscious numerical counting.
  - **Perceptual Multistability / Reversal Latency:** When observing ambiguous visual stimuli (Necker cube, Rubin's vase) or listening to ambiguous speech streams (verbal transformation), the brain spontaneously flips between interpretations approximately every 2.5 to 3.0 seconds (Gomez et al., 1995; Radilova et al., 1990; Pöppel, 1997a).
  - **Time-Order Error & Psychophysical Scaling:** Comparing the intensity of two sequential stimuli is veridical only if the inter-stimulus interval is within ~2–3 seconds (Köhler, 1923). Similarly, Weber's law for duration discrimination ($\Delta T / T = \text{const}$) holds only up to ~2 seconds, breaking down sharply at longer intervals (Getty, 1975).
- **Level 3 (Macro-Temporal Reconstruction; >3 Seconds):** Intervals exceeding 3 seconds cannot be apprehended as a unified perceptual Gestalt. Tracking duration beyond 3 seconds requires conscious mental rehearsal, secondary working memory loops, or retrospective episodic reconstruction.

> [!NOTE] Epistemic Qualification
> Pöppel explicitly framed this 2–3 second window as a "conceptual notion", an "operating range" with high inter-individual variability, and a theoretical "pragmatic definition of the states of being conscious", rather than a rigid physical constant.[^poppel-2009-temporal-integration]

### 1.2 Paul Fraisse’s Classical Bounds of the Perceived Present (_Le Temps Présent_)

Paul Fraisse (_The Psychology of Time_, 1963; 1984) established the foundational psychophysical framework of the "psychological present":

- **Instantaneity (<100 ms):** Stimuli lasting under 100 ms are processed as instantaneous points lacking internal duration.
- **The Elastic Bounds of the Psychological Present (~0.1 s to ~5.0 s, Centered at 2–3 s):** Fraisse demonstrated that the psychological present is not a fixed duration, but an elastic envelope spanning from a fraction of a second up to approximately 5 seconds:
  - When rhythmic taps or tones are presented at intervals under 2 to 3 seconds, subjects perceive them directly as a coherent rhythmic structure (a "temporal Gestalt").
  - When the inter-stimulus interval exceeds ~2.5–3.0 seconds, automatic grouping dissolves into remembered succession.
  - In low-information-density contexts, the upper bound of immediate sensory memory allows temporal grouping to extend up to ~5.0 seconds.
- **Functional Definition:** The psychological present is the temporal envelope within which an organism perceives a pattern of stimuli or executes a goal-directed sequence without active retrieval from long-term memory.

### 1.3 Behavioral Clustering: Spontaneous Action Units and Motor Cadence

While laboratory tasks isolate specific perceptual thresholds, ethological observations demonstrate that spontaneous human motor output naturally organizes into multi-second bursts:

- **Schleidt, Eibl-Eibesfeldt, and Pöppel (1987):** In a cross-cultural ethological investigation, researchers analyzed thousands of spontaneous, non-verbal intentional human actions across isolated, non-literate societies (the Himba of Namibia, Yanomami of South America, and Eipo of West New Guinea) as well as modern Western and Brazilian populations.
- **The Empirical Action Cluster:** Across all cultures, spontaneous short-term behavioral units (hand gestures, tool strokes, reaching motions, caresses, head-turns, and spontaneous gaze pauses) clustered tightly between **2.0 and 3.0 seconds**.
- **Sensorimotor Synchronization & Spontaneous Motor Tempo (SMT):** The spontaneous cadence of human movement (unprompted finger tapping, pacing) centers at 500–600 ms (Fraisse, 1982). These rhythmic sub-units are hierarchically assembled into motor phrases of 2–3 seconds (typically 4–6 sub-movements per phrase).
- **Linguistic and Poetic Metrics:** Spontaneous conversational speech across typologically unrelated languages (English, German, Chinese, Japanese, Bantu languages) breaks naturally into breath groups and intonation units averaging 2.0 to 3.0 seconds (Pöppel, 1988; Chafe, 1994). Traditional metric poetry across cultures (Homeric dactylic hexameter, French alexandrines, English iambic pentameter, Japanese haiku lines) maps strictly to 2.5–3.0 seconds per line when recited.

### 1.4 The Multi-Scale Debate: Is There an Actual Biological Primitive?

A critical question in contemporary cognitive neuroscience is whether the "2–3 second psychological present" reflects a dedicated **biological primitive** (such as an endogenous neural oscillator) or merely an emergent artifact of task constraints and information density. Modern evidence strongly favors the latter.

#### A. Peter A. White’s Critique: No Fixed 3-Second Clock

In a landmark systematic review published in _Psychological Bulletin_, Peter A. White (2017) scrutinized every major empirical line of evidence traditionally cited in favor of the 3-second subjective present (including duration reproduction, beat synchronization, ambiguous figure reversals, mismatch negativity, and action segmentation).[^white-2017-critique-subjective-present]

White demonstrated that:

1. **Empirical Inconsistency:** The vast majority of empirical studies do not neatly conform to a rigid 3-second boundary. Ambiguous figure reversals vary widely depending on stimulus luminance, spatial frequency, and voluntary attention; duration reproduction accuracy shifts continuously with task difficulty and training.
2. **Information Density vs. Clock Time:** Temporal integration windows are governed by **information density and cognitive load**, not a fixed internal clock. When information flow is dense and complex, the subjective window of integration contracts; when input is sparse, it expands.
3. **Multi-Scale Integration:** The central nervous system does not operate on a single privileged temporal scale. Instead, temporal processing is distributed across a continuous hierarchy of local mechanisms, which are dynamically assembled into a coherent global representation of ongoing events.[^white-2017-critique-subjective-present]

#### B. The True Sensory Percept Slice (~300–400 ms)

If one seeks the neurobiological duration of a single conscious _percept_ (the time required to bind sensory features into awareness), empirical psychophysics demonstrates that it is an order of magnitude shorter than 2–3 seconds.

Michael Herzog and colleagues (2016, 2020) demonstrated a two-stage model of visual awareness:[^herzog-2016-time-slices]

- Sensory features (color, orientation, motion) are processed unconsciously and quasi-continuously with millisecond resolution during a temporal window lasting **~300 to 400 ms**.
- At the conclusion of this ~300–400 ms integration epoch, the features are rendered simultaneously into conscious awareness as a discrete "time slice" or perceptual snapshot.
- The subjective impression of continuous perception is a postdictive illusion constructed from sequential ~400 ms processing epochs.

#### C. The Sensorimotor Synchronization Ceiling (~1.8–2.0 s)

In the motor domain, the upper temporal limit for direct, automatic sensorimotor entrainment is not 3.0 seconds, but approximately **1.8 seconds (1800 ms)** (Repp, 2005; Mates et al., 1994).[^repp-2005-synchronization-ceiling]

- When humans synchronize movements (such as finger tapping) to an isochronous auditory metronome, they maintain negative mean asynchrony (anticipating the tone by 10–30 ms) only for intervals up to ~1.8 s.
- At intervals longer than 1.8 seconds, the internal predictive model breaks down: tapping becomes reactive (occurring ~200 ms after the beat), and participants must resort to conscious subdivision or mental counting.

#### D. Marc Wittmann’s Tripartite Taxonomy

Neuropsychologist Marc Wittmann (2011) resolved these divergent empirical scales by systematizing time consciousness into three distinct, nested functional layers:[^wittmann-2011-moments-in-time]

1. **The Functional Moment (30–50 ms):** The elementary building block defining co-temporality versus succession, governed by cortical gamma synchronization.
2. **The Experienced Moment (~300 ms to ~3 s):** Multi-modal sensory feature binding and automatic Gestalt grouping. Within this range, sensory inputs and kinematic sub-movements are bound into an integrated perceptual-motor episode.
3. **Mental Presence / Working Memory Window (Multiple Seconds):** The continuity of conscious narrative and emotional feeling states, sustained by working memory buffers and grounded in **interoceptive bodily rhythms** (such as cardiac and respiratory cycles tracked by the posterior insular cortex).

#### E. Synthesis & Game Design Implications

The weight of modern empirical evidence indicates that **there is probably no dedicated neurological primitive or universal biological clock running at 2–3 seconds**.

Instead:

- **~300–400 ms** represents the discrete sensory time slice for conscious perceptual rendering (Herzog et al., 2016).
- **~500–600 ms** represents the spontaneous motor tempo for sub-movements (Fraisse, 1982).
- **~1.8 s** represents the ceiling for automatic anticipatory motor entrainment (Repp, 2005).
- **2.0–3.0 s** represents a robust **behavioral and cognitive clustering zone**, reflecting the convergence of working memory buffer decay, respiratory-autonomic pacing, and active inference resets.
- **~5.0 s** represents the absolute upper boundary of immediate sensory grouping under minimal cognitive load (Fraisse, 1963).

For CardPG's combat modeling, treating the 2–3 second interval as an **operational phenomenological heuristic**—rather than a dogmatic neurobiological primitive—provides a firmly grounded foundation. A 2–3 second crisis round or action phase matches the natural empirical cadence of spontaneous human intentional acts (Schleidt et al., 1987) and predictive motor commitments (Repp, 2005) without overclaiming neurobiological rigidity.

### 1.5 Candidate Neurobiological Mechanisms Contributing to Multi-Second Chunking

While the 2–3 second window is not a single hardwired clock, several distinct physiological and computational factors converge to produce multi-second behavioral chunking:

```
+-----------------------------------------------------------------------------+
|               HIERARCHICAL NEURAL OSCILLATION COUPLING                      |
|                                                                             |
|  Infra-Slow Oscillations (~0.3–0.5 Hz / Period = 2.0–3.3 s)                 |
|  [Phase resets operative cognitive hypothesis / active inference window]    |
|          |                                                                  |
|          v Phase-Amplitude Coupling                                         |
|  Theta Band (4–8 Hz / Period = 125–250 ms)                                  |
|  [Working memory sub-slots; kinematic motor sub-movements]                  |
|          |                                                                  |
|          v Phase-Locking                                                    |
|  Gamma Band (30–50 Hz / Period = 20–33 ms)                                  |
|  [Local cortical sensory binding / elementary temporal events]              |
+-----------------------------------------------------------------------------+
```

1. **Infra-Slow Neural Oscillations (ISO):** Electroencephalography (EEG) and local field potential studies reveal resting and task-related infra-slow oscillations (0.1–0.5 Hz, corresponding to periods of 2 to 10 seconds, centered at ~0.33 Hz = 3 seconds). ISO waves modulate the phase and amplitude of higher-frequency theta (4–8 Hz) and gamma (>30 Hz) bands. The ~3-second cycle marks an oscillatory reset that coordinates long-range corticocortical communication.
2. **Working Memory Buffer Decay:** The phonological and episodic working memory buffers (Baddeley, 2000) have an un-rehearsed retention limit of approximately 2 to 3 seconds. Without active attentional refresh, synaptic calcium traces decay, causing representation loss.
3. **Active Inference and Predictive Processing (Friston, Clark; Zacks et al., 2007):** The brain operates as a hierarchical Bayesian predictive engine.
   - Continuous updating at millisecond resolution across large cortical networks is computationally noisy and metabolically unsustainable.
   - Top-down motor predictions ("priors") suppress minor sensory deviations for 1.5–3 seconds, allowing the execution of an intentional movement without destabilizing feedback jitter.
   - Event Segmentation Theory (Zacks et al., 2007) shows that boundaries between action units occur when sensory prediction errors spike, prompting a model reset.
4. **Metabolic Costs of Synchrony:** Sustaining coherent, phase-locked assemblies across frontal, parietal, and motor cortices demands high ATP consumption for ion pumping. Chunking cognition into multi-second bursts interspersed with brief desynchronization prevents local neuroenergetic depletion.

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

## 4. Synthesis: The Operational Timescale of "One Coherent Human Action"

Synthesizing cognitive psychophysics and motor neurobiology establishes the empirical reality of how intentional actions unfold:

```
+-----------------------------------------------------------------------------+
|         THE ANATOMY OF "ONE THING" (AN INTENTIONAL 2–3 SECOND ACTION)       |
|                                                                             |
| 0.0 s                                1.5 s                           3.0 s  |
| +--------------------------------------+-------------------------------+    |
| | SUB-MOVEMENT 1: Ballistic Initiation | SUB-MOVEMENT 2: Terminal      |    |
| | Pre-programmed feed-forward burst   | Adjustment or Follow-Through  |    |
| | (Jab, step, weapon draw)             | (Recovery, bind, riposte)     |    |
| +--------------------------------------+-------------------------------+    |
| [---- 200 ms ----]                                                          |
| Point of No Return                                                          |
| (Uninterruptible)                                                           |
|                  [------ 300–500 ms ------]                                 |
|                  Voluntary Feedback Window                                  |
|                  (Correction / Abort possible)                              |
|                                                                             |
| [=================== 2.0 to 3.0 SECOND TEMPORAL WINDOW ===================] |
|              One Unified Subjective Present (Ernst Pöppel)                  |
|             One Coherent Action Unit (Schleidt et al., 93%)                 |
|             One Cognitive Hypothesis Before Active Inference Reset          |
+-----------------------------------------------------------------------------+
```

1. **The Core Behavioral Envelope is ~1.8 to 3.0 Seconds:** An actor does not maintain an open-ended, continuous stream of uncommitted high-level motor planning. Natural intentional undertakings ("close the distance and strike," "parry and counter," "unholster and align," "vault the obstacle") empirically cluster into discrete behavioral units averaging **1.8 to 3.0 seconds**, bounded by predictive motor synchronization ceilings (Repp, 2005) and working memory buffer decay.
2. **Internal Composition of the Chunk:** Within this ~2–3 second envelope:
   - The action is composed of 2 to 4 chained sub-movements (each lasting ~200–500 ms).
   - The first 150–200 ms of each explosive sub-movement is **purely ballistic and feed-forward**—once initiated past the 200 ms readiness threshold, it cannot be aborted by incoming visual information.
   - Closed-loop sensory corrections only become effective at **300 to 500 ms**, enabling the second phase of the action to adapt to opponent displacement.
3. **Interaction and Simultaneity:**
   - Actions initiated within **100 to 150 ms** of each other are physically and cognitively simultaneous, operating without mutual feedback and resulting in concurrent collisions.
   - Deceptive maneuvers (feints) introduce a **200 to 400 ms** bottleneck delay (PRP), paralyzing the defender's capacity to counter the subsequent real attack.
   - Gross tactical disruptions induce an OODA reset requiring **450 to 700 ms** before voluntary action can resume.
4. **Stress Modulation:** In life-threatening combat, acute sympathetic arousal does not grant heightened temporal resolution. Real-time cognitive processing remains strictly bound to these millisecond limits, while prefrontal suppression strips away fine motor precision, locking the actor into rapid gross-motor executions within a compressed 1.5–3 second operational action window.

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
9. **Fraisse, P.** (1963). _The Psychology of Time_. New York: Harper & Row.
10. **Fraisse, P.** (1984). "Perception and estimation of time." _Annual Review of Psychology_, 35(1), 1–37. DOI: 10.1146/annurev.ps.35.020184.000245.
11. **Franklin, D. W., & Wolpert, D. M.** (2008). "Specificity of reflex adaptation for task-relevant variables." _Journal of Neuroscience_, 28(52), 14167–14175. DOI: 10.1523/JNEUROSCI.4406-08.2008.
12. **Grossman, D.** (1996). _On Killing: The Psychological Cost of Learning to Kill in War and Society_. Little, Brown and Company.
13. **Herzog, M. H., Kammer, T., & Scharnowski, F.** (2016). "Time Slices: What Is the Duration of a Percept?" _PLOS Biology_, 14(4), e1002433. DOI: 10.1371/journal.pbio.1002433.
14. **Hick, W. E.** (1952). "On the rate of gain of information." _Quarterly Journal of Experimental Psychology_, 4(1), 11–26. DOI: 10.1080/17470215208416600.
15. **Keele, S. W., & Posner, M. I.** (1968). "Processing of visual feedback in rapid movements." _Journal of Experimental Psychology_, 77(1), 155–158. DOI: 10.1037/h0025754.
16. **Logan, G. D., & Cowan, W. B.** (1984). "On the ability to inhibit thought and action: A theory of an act of control." _Psychological Review_, 91(3), 295–327. DOI: 10.1037/0033-2909.91.3.295.
17. **Pashler, H.** (1994). "Dual-task interference in simple tasks: data and theory." _Psychological Bulletin_, 116(2), 220–244. DOI: 10.1037/0033-2909.116.2.220.
18. **Pöppel, E.** (1988). _Mindworks: Time and Conscious Experience_. Boston: Harcourt Brace Jovanovich.
19. **Pöppel, E.** (1997). "A hierarchical model of temporal perception." _Trends in Cognitive Sciences_, 1(2), 56–61. DOI: 10.1016/S1364-6613(97)01008-5.
20. **Pöppel, E.** (2009). "Pre-semantically defined temporal windows for cognitive processing." _Philosophical Transactions of the Royal Society B: Biological Sciences_, 364(1525), 1887–1896. DOI: 10.1098/rstb.2009.0015.
21. **Pruszynski, J. A., Kurtzer, I., & Scott, S. H.** (2008). "Rapid motor responses are exquisitely tuned to the task." _Nature Neuroscience_, 11(10), 1104–1106. DOI: 10.1038/nn.2184.
22. **Pruszynski, J. A., King, G. L., Boisse, L., Zhou, H., Flanagan, J. R., & Scott, S. H.** (2010). "Fast visuomotor responses in human elbow muscles define a dynamic control system." _Journal of Neurophysiology_, 103(1), 168–179. DOI: 10.1152/jn.00697.2009.
23. **Repp, B. H.** (2005). "Sensorimotor synchronization: A review of the tapping literature." _Psychological Bulletin_, 131(6), 969–1016. DOI: 10.1037/0033-2909.131.6.969.
24. **Schleidt, M., Eibl-Eibesfeldt, I., & Pöppel, E.** (1987). "A universal constant in temporal segmentation of human short-term behavior." _Naturwissenschaften_, 74(6), 289–290. DOI: 10.1007/BF00366416.
25. **Schmidt, R. A., & Lee, T. D.** (2019). _Motor Control and Learning: A Behavioral Emphasis_ (6th ed.). Champaign, IL: Human Kinetics.
26. **Schultze-Kraft, M., Birman, D., Rusconi, M., Allefeld, C., Görgen, K., Dähne, S., Blankertz, B., & Haynes, J. D.** (2016). "The point of no return in vetoing self-initiated movements." _Proceedings of the National Academy of Sciences (PNAS)_, 113(4), 1080–1085. DOI: 10.1073/pnas.1513569112.
27. **Siddle, B. K.** (1995). _Sharpening the Warrior's Edge: The Psychology & Science of Training_. Belleville, IL: PPCT Research Publications.
28. **Stetson, C., Fiesta, M. P., & Eagleman, D. M.** (2007). "Does time really slow down during a frightening event?" _PLoS ONE_, 2(12), e1295. DOI: 10.1371/journal.pone.0001295.
29. **Welford, A. T.** (1952). "The 'psychological refractory period' and the timing of high-speed performance: A review and a theory." _British Journal of Psychology_, 43(1), 2–19. DOI: 10.1111/j.2044-8295.1952.tb00322.x.
30. **White, P. A.** (2017). "The three-second 'subjective present': A critical review and a new proposal." _Psychological Bulletin_, 143(7), 735–756. DOI: 10.1037/bul0000104.
31. **Wittmann, M.** (2011). "Moments in time." _Frontiers in Integrative Neuroscience_, 5, 66. DOI: 10.3389/fnint.2011.00066.
32. **Zacks, J. M., Speer, N. K., Swallow, K. M., Braver, T. S., & Reynolds, J. R.** (2007). "Event perception: a mind-brain perspective." _Psychological Bulletin_, 133(2), 273–293. DOI: 10.1037/0033-2909.133.2.273.
33. **Zelaznik, H. N., Hawkins, B., & Kisselburgh, L.** (1983). "Rapid visual feedback processing in single-aiming movements." _Journal of Motor Behavior_, 15(3), 217–236. DOI: 10.1080/00222895.1983.10735298.

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

[^poppel-2009-temporal-integration]:
    source: poppel-2009-presemantically-defined-temporal-windows
    locator: "p. 1887 ([extracted.md#L3](../sources/verisimilitude/poppel-2009-presemantically-defined-temporal-windows/extracted.md#L3))"
    quote: "The other mechanism refers to pre-semantic integration in the temporal range of approximately 2–3 s. ... universal process of temporal integration underlying the mental machinery. This process is believed to be basic for maintenance and change of perceptual identity. Owing to the omnipresence of this kind of temporal segmentation, it is suggested to use this process for a pragmatic definition of the states of being conscious or the ‘subjective presence’."
    status: theoretical_hypothesis
    vetting_note: "tdimiduk: Pöppel explicitly frames this as a theoretical 'pragmatic definition' and conceptual operating range rather than a proven biological primitive. See White (2017) for systematic critique."

[^poppel-2009-subjective-present]:
    source: poppel-2009-presemantically-defined-temporal-windows
    locator: "p. 1891 ([extracted.md#L79](../sources/verisimilitude/poppel-2009-presemantically-defined-temporal-windows/extracted.md#L79))"
    quote: "universal integration process is automatic and pre-semantic, i.e. it is not determined by what is processed, but it creates a temporal window within which conscious activities can be implemented. Owing to the omnipresence of this phenomenon, it can also be used as a pragmatic definition of the subjective present"
    status: theoretical_hypothesis
    vetting_note: "From Section 4 of Pöppel (2009), titled 'a speculation on the purpose of pre-semantic integration'."

[^white-2017-critique-subjective-present]:
    source: "White, P. A. (2017). The three-second 'subjective present': A critical review and a new proposal. Psychological Bulletin, 143(7), 735–756."
    locator: "Abstract / pp. 735, 750–752"
    quote: "The hypothesis that there is a subjective present with a duration of approximately 3 s was evaluated across a range of research topics... Most research findings are not consistent with the hypothesis. What positive evidence there is can be explained in terms of specific processing mechanisms rather than a general temporal integration process... temporal integration occurs on multiple time scales, and no duration is uniquely privileged."
    status: peer_reviewed_review

[^herzog-2016-time-slices]:
    source: "Herzog, M. H., Kammer, T., & Scharnowski, F. (2016). Time Slices: What Is the Duration of a Percept? PLOS Biology, 14(4), e1002433."
    locator: "Abstract / pp. 2–4"
    quote: "We propose a two-stage model: a first, quasi-continuous, unconscious processing stage of high temporal resolution is followed by a second, discrete conscious stage with much lower temporal resolution. ... integration occurs within a discrete time window (up to 400 ms) before the percept is consciously rendered."
    status: peer_reviewed_model

[^repp-2005-synchronization-ceiling]:
    source: "Repp, B. H. (2005). Sensorimotor synchronization: A review of the tapping literature. Psychological Bulletin, 131(6), 969–1016."
    locator: "Section on Rate Limits, p. 972"
    quote: "The longest IOI [inter-onset interval] at which 1:1 synchronization is possible without mental subdivision is around 1,800 ms... At slower tempos, tapping becomes reactive rather than anticipatory, and subjects must resort to internal counting or movement strategies to bridge the interval."
    status: peer_reviewed_review

[^wittmann-2011-moments-in-time]:
    source: "Wittmann, M. (2011). Moments in time. Frontiers in Integrative Neuroscience, 5, 66."
    locator: "Section: Three levels of temporal integration, pp. 2–5"
    quote: "Three distinct levels of temporal integration can be differentiated: (1) functional moments on the millisecond scale (sub-100 ms), (2) experienced moments on the multi-hundred-millisecond to multi-second scale (~300 ms to ~3 s) binding sensory Gestalts, and (3) mental presence lasting multiple seconds sustained by working memory and interoceptive self-awareness."
    status: peer_reviewed_taxonomy

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
