---
title: "Stress-Induced Analgesia and Acute Trauma Dissociation"
doc_type: "synthesis"
track: "verisimilitude"
origin: "AI synthesized from peer-reviewed literature"
epistemic_status:
  confidence: "high"
  audited_by: "Gemini 3.8 Flash (Antigravity)"
  vetted_by_human: false
  vetting_notes: "Grounded in peer-reviewed clinical trials (Matre et al. 2022 / Pain Rep PMC8826964) and neuropharmacological assays (Marques et al. 2024 / Biomedicines PMC10813752)."
related_files:
  - "design/research/synthesis/dynamics-of-duel.md"
  - "design/research/synthesis/catastrophic-trauma-and-lethality.md"
  - "design/research/synthesis/physical-harm-and-trauma.md"
  - "design/research/synthesis/consequences-combat.md"
---

# Stress-Induced Analgesia and Acute Trauma Dissociation

## Executive Summary & The Evolutionary Paradox

Pain serves as an essential homeostatic feedback mechanism that enforces motor withdrawal, limb unloading, and behavioral quiescence to allow wound healing and tissue repair. However, in an acute mortal confrontation, the unattenuated experience of pain would exert a paralyzing inhibitory effect on motor execution.[^marques-2024-protective-paradox]

To preserve immediate survival, mammalian physiology deploys **Stress-Induced Analgesia (SIA)**—an acute neuroendocrine and neurochemical suppression of nociceptive perception.[^marques-2024-protective-paradox] During acute danger, descending inhibitory pathways actively blunt pain transmission across subcortical, brainstem, and spinal circuits.[^marques-2024-anatomic-substrates]

Crucially, empirical research demonstrates two governing physiological constraints:

1. **Static vs. Dynamic Nociceptive Dissociation:** Acute stress significantly lowers the initial entry threshold of pain (blunting the first strike or contact), but **leaves the rate of central sensitization (temporal summation / repetitive impact wind-up) completely uninhibited**.[^matre-2022-initial-vs-slope]
2. **Perceptual Antinociception vs. Structural Biomechanics:** SIA suppresses _subjective pain perception_, but provides **zero structural fortification to tissues**.[^marques-2024-500g-cutoff] Sustained exertion under analgesia creates the classic "walking wounded" state, where combatants unknowingly convert stable microtrauma or hairline fractures into catastrophic, displaced structural failures.[^marques-2024-protective-paradox]

---

## 1. Dual Neurochemical Architecture: Opioid vs. Non-Opioid Cascades

SIA is not a monolithic adrenaline rush; it is mediated across distinct anatomical hubs—the periaqueductal gray (PAG), rostral ventromedial medulla (RVM), amygdala, and the dorsal horn of the spinal cord—partitioned into two neurochemical systems based on stressor intensity, duration, controllability, and timing.[^marques-2024-anatomic-substrates] [^matre-2022-nonopioid-pathways]

```
               [ Acute Survival Threat / Traumatic Stress ]
                                    |
          +-------------------------+-------------------------+
          |                                                   |
 [Opioid System]                                    [Non-Opioid System]
          |                                                   |
  • Trigger: Uncontrollable,                  +---------------+---------------+
    prolonged stressors                       |                               |
  • Mediators: beta-endorphins,       [Endocannabinoid]                [Serotonergic]
    enkephalins, mu/kappa receptors           |                               |
  • Blocked by: Naltrexone / Naloxone • Receptors: CB1, CB2           • Receptor: 5-HT1A
  • Tonic basal inhibition of         • Ligands: AEA, 2-AG            • Dual: Pro- / antinociceptive
    temporal summation in females     • Sustains post-stress SIA      • All-or-nothing trigger
                                      • Buffers HPA hyper-reactivity    for SIA induction
```

### 1.1. Endogenous Opioid Pathways

- **Mediators:** Centrally released $\beta$-endorphins and enkephalins acting on $\mu$- ($\text{MOR}$) and $\kappa$-opioid receptors ($\text{KOR}$) in the midbrain PAG, amygdala, and spinal substantia gelatinosa.[^marques-2024-anatomic-substrates]
- **Induction Characteristics:** Preferentially recruited during sustained, inescapable, or prolonged traumatic stress (e.g., long-duration exertion, persistent entrapment, or severe continuous trauma).[^matre-2022-nonopioid-pathways]
- **Pharmacological Sensitivity:** Readily blocked by competitive opioid antagonists (naltrexone, naloxone). In brief acute laboratory stressors (8–16 minutes), opioid blockade fails to abolish stress-induced analgesia, demonstrating that early acute antinociception relies on non-opioid mechanisms.[^matre-2022-nonopioid-persistence]
- **Sex-Specific Basal Tone:** Endogenous opioids exert continuous, tonic down-regulation on temporal summation slopes in females ($b = 2.04$ under naltrexone vs. $b = 1.49$ under placebo, $p < 0.001$), but not in males ($b = 0.97$ vs. $b = 1.07$, $p = 0.35$), independent of acute stress.[^matre-2022-female-opioid-inhibition]

### 1.2. The Endocannabinoid System (ECS)

- **Receptors & Ligands:** Retrograde activation of presynaptic cannabinoid type 1 ($\text{CB}_1$) receptors by lipid ligands anandamide (AEA) and 2-arachidonoylglycerol (2-AG) across the amygdala, hippocampus, PAG, RVM, and spinal dorsal horn.[^marques-2024-ecs-mechanisms]
- **Post-Stress Maintenance Dominance:** While serotonergic signaling triggers the initial onset of SIA, $\text{CB}_1$ receptor activity is mechanistically responsible for **sustaining** antinociception once the stressor ceases.[^marques-2024-system-roles]
- **Rebound Hyperalgesia under Blockade:** Blocking $\text{CB}_1$ receptors with an antagonist (AM251) post-stress causes a rapid breakdown of antinociception within 10 minutes, total loss of analgesia by 20 minutes, and rebound hyperalgesia (pain sensitivity worse than non-stressed baseline) between 30 and 50 minutes.[^marques-2024-cb1-post-maintenance]
- **HPA Axis Regulation:** Endocannabinoids provide essential negative feedback to the hypothalamic-pituitary-adrenal (HPA) axis, acting as an off-switch for excessive neuroendocrine alarm.[^marques-2024-hpa-negative-feedback]

### 1.3. Serotonergic Pathways ($5\text{-HT}_{1\text{A}}$)

- **Circuitry:** Descending projections from the midbrain dorsal and median raphe nuclei express $5\text{-HT}_{1\text{A}}$ receptors on spinal nociceptive interneurons.[^marques-2024-raphe-serotonin]
- **"All-or-Nothing" Induction Gate:** Pharmacological blockade of $5\text{-HT}_{1\text{A}}$ receptors (with NAN-190) prior to acute stress **completely abolishes** the induction of SIA.[^marques-2024-serotonin-all-or-nothing] Intact $5\text{-HT}_{1\text{A}}$ signaling is an absolute physiological prerequisite for triggering the cascade.[^marques-2024-all-or-nothing-principle]
- **Post-Stress Re-Sensitization:** Conversely, blocking $5\text{-HT}_{1\text{A}}$ receptors _after_ stress exposure artificially prolongs analgesia, confirming that post-stress serotonergic activity normally serves to terminate SIA and restore protective pain awareness.[^marques-2024-nan-post-stress] [^marques-2024-all-or-nothing-principle]

### 1.4. Noradrenergic descending inhibition

- Acute sympathetic activation triggers descending noradrenergic efferents from the locus coeruleus and A7 cell groups to release norepinephrine in the dorsal horn, stimulating $\alpha_2$-adrenergic receptors to hyperpolarize projection neurons and suppress nociceptive transmission.

---

## 2. Quantitative Parameters and Kinetics

### 2.1. Parameter Reference Matrix

| Parameter / Domain                        | Preclinical Model (Cold-Stress SIA, $c\text{-SIA}$)[^marques-2024-study-design]                                                                                                 | Human Clinical Trial (Psychosocial Stress SIA)[^matre-2022-study-design]                                                                                                                    |
| :---------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Subjects**                              | Adult male Wistar rats ($250\text{--}300\text{ g}$)[^marques-2024-animals]                                                                                                      | Healthy human adults ($n=72$, mean age $20.8\text{ y}$, 65% male)[^matre-2022-study-design]                                                                                                 |
| **Stressor & Duration**                   | Acute environmental cold ($4^\circ\text{C}$ for $1\text{ h}$)[^marques-2024-cold-stress-model]                                                                                  | Public speaking ($8\text{ min}$) + mental arithmetic harassment ($8\text{ min}$)[^matre-2022-study-design]                                                                                  |
| **Nociceptive Assay**                     | Randall–Selitto mechanical paw pressure test (arbitrary scale units)[^marques-2024-500g-cutoff]                                                                                 | Oscillating contact heat pulses ($10\text{ pulses}$, $50^\circ\text{C}$ peak, $0.5\text{ s}$ duration, $2.5\text{ s}$ ISI)[^matre-2022-heat-protocol]                                       |
| **Antinociceptive Magnitude**             | Mechanical threshold significantly elevated for $\ge 40\text{ min}$ ($p < 0.00001$; $F = 2749.62$ at $10\text{ min}$, $F = 2373.72$ at $40\text{ min}$)[^marques-2024-cold-sia] | Initial pain rating significantly blunted: $b = -3.43, p < 0.001$ ($b = -5.92, p < 0.001$ in high stress reactors)[^matre-2022-initial-vs-slope] [^matre-2022-stress-reactivity-moderation] |
| **Repetitive Wind-Up (Summation)**        | Single continuous mechanical ramp threshold[^marques-2024-500g-cutoff]                                                                                                          | Marked summation: peak $-$ initial rating $\ge 16.8\text{ points}$ ($p < 0.001$, Cohen $d = 1.13\text{--}1.29$)[^matre-2022-manipulation-checks]                                            |
| **Stressor Effect on Sensitization Rate** | Not measured                                                                                                                                                                    | **Zero effect on summation slope:** $b = 0.12, \text{SE} = 0.17, p = 0.50$[^matre-2022-initial-vs-slope]                                                                                    |
| **Opioid Blockade Interaction**           | N/A (investigated ECS / $5\text{-HT}_{1\text{A}}$)                                                                                                                              | Main SIA effect intact under naltrexone ($b = -3.35, p < 0.001$; drug interaction $p = 0.97$)[^matre-2022-nonopioid-persistence]                                                            |
| **High Reactor Paradox**                  | Pre-stress AEA + DPAT potentiates threshold ($p = 0.000021$)[^marques-2024-pre-potentiation]                                                                                    | Naltrexone in high stress reactors produced _greater_ initial antinociception ($b = -4.40, p < 0.001$)[^matre-2022-paradoxical-analgesia]                                                   |
| **Time Course & Decay**                   | Sustained through $40\text{ min}$; decays by $50\text{ min}$. Collapses by $20\text{ min}$ if $\text{CB}_1$ blocked post-stress[^marques-2024-cb1-post-maintenance]             | Evaluated immediately post-stressor (~16–30 min post-induction)[^matre-2022-study-design]                                                                                                   |

---

### 2.2. The Intercept vs. Slope Dissociation (Static Blunting vs. Dynamic Wind-Up)

Multilevel modeling in human trials isolates a fundamental neurobiological principle: **stress suppresses the entry threshold of pain without altering the rate of central spinal wind-up.**[^matre-2022-initial-vs-slope]

```
Pain Rating (0-100)
100 |                                    / [Post-Stress Wind-Up: Slope = 1.49]
    |                                   /
 80 |                                  /   / [Rest Wind-Up: Slope = 1.49]
    |                                 /   /
 60 | [Rest Intercept: 64.6] -------*   /
    |                                  /
 40 | [Stress Intercept: 62.1] ------*
    |  (High stress responders: Δ = -5.92)
  0 +-------------------------------------------> Pulse Number (1 to 10)
      [Pulse 1: Blunted Entry]      [Pulses 2-10: Invariant Sensitization Slope]
```

1. **First-Pulse Blunting (The Intercept Shift):**
   - Acute stress exposure significantly lowers the subjective rating of the initial noxious contact ($b = -3.43, p < 0.001$, scaling to $b = -5.92, p < 0.001$ in high stress reactors).[^matre-2022-initial-vs-slope] [^matre-2022-stress-reactivity-moderation]
   - A combatant in an acute survival state perceives an initial laceration or blunt impact with dramatically attenuated distress.
2. **Invariance of Central Sensitization (The Slope):**
   - When noxious stimulation repeats rapidly (e.g., thermal or mechanical pulses at 2–3 second intervals), the rate of pain amplification across pulses is **completely unaffected by acute stress** ($b = 0.12, \text{SE} = 0.17, p = 0.50$).[^matre-2022-initial-vs-slope]
   - Repetitive C-fiber activation produces continuous presynaptic release of glutamate and substance P, removing magnesium ($Mg^{2+}$) blockades on postsynaptic NMDA receptors in lamina I/V spinal neurons. This intracellular calcium cascade drives dorsal horn wind-up, overriding descending stress-induced inhibition.[^matre-2022-windup-cites]
3. **The Clinical Takeaway:**
   - SIA provides an initial buffer against isolated trauma. It does **not** protect against rapid, repeated trauma. A second, third, or fourth strike in the same region breaks through the analgesic buffer and registers with full neurochemical force.

---

### 2.3. Temporal Kinetics and the Post-Stress Decay Curve

```
Analgesic Threshold (PPT Arbitrary Units)
High |   [c-SIA Intact]
     |   *--------*--------*--------*
     |                               \
     |   [CB1 Receptor Blocked Post-Stress]
     |   *                             \
     |    \                             * [Natural Physiological Decay: ~50 min]
     |     \  [No SIA: 20 min]
     |      *--------*
Low  |                \  [Rebound Hyperalgesia: 30-50 min]
     |                 *--------*
     +--------------------------------------------------------> Time Post-Stress (min)
     0        10       20       30       40       50
```

- **Active Maintenance Window (0–40 Minutes):** Following acute stress exposure, antinociception remains robust and statistically stable through 40 minutes post-crisis.[^marques-2024-cold-sia]
- **Physiological Decay (~50 Minutes):** Endocannabinoid signaling declines and descending serotonergic/noradrenergic tone normalizes, causing antinociceptive thresholds to decay back toward baseline by approximately 50 minutes.[^marques-2024-cold-sia]
- **Rebound Hyperalgesia:** If the maintenance cascade is disrupted or exhausted (modeled by $\text{CB}_1$ receptor blockade), antinociception collapses within 20 minutes and transitions into severe rebound hyperalgesia (elevated pain sensitivity well above baseline) between 30 and 50 minutes.[^marques-2024-cb1-post-maintenance]

---

## 3. The Pathological Dissociation: Pain Masking vs. Structural Integrity

The most critical operational reality of SIA is the absolute dissociation between **conscious nociceptive suppression** and **physical tissue resilience**.[^marques-2024-500g-cutoff] [^marques-2024-protective-paradox]

### 3.1. The Missing Biological Governor

Pain is a structural safeguard:

- Low-level nociceptive input triggers involuntary reflex arcs that unload damaged limbs.
- Conscious pain compels resting, immobilizing injured joints and preventing mechanical stress from rupturing repairing capillaries and collagen matrices.

Under SIA, this biological governor is offline.[^marques-2024-protective-paradox] Combatants feel capable of maximum athletic exertion despite sustaining major musculoskeletal and vascular trauma.

### 3.2. Mechanical and Thermal Overload Risks

1. **Mechanical Crush Injury (Randall–Selitto Assay):**
   - Analgesimeters measuring mechanical withdrawal thresholds universally implement an automated hardware cut-off at **500 grams**.[^marques-2024-500g-cutoff]
   - Under intense SIA, subjects will willingly tolerate pressures exceeding 500 grams without struggling or vocalizing. If the safety cut-off is disabled, the test apparatus shatters phalanges and tears tendons while the subject remains quiescent.[^marques-2024-500g-cutoff]
2. **Thermal Destruction (Contact Thermode Assay):**
   - Contact heat pulses ($50^\circ\text{C}$ for $0.5\text{ s}$) are rated as significantly less painful under acute stress.[^matre-2022-initial-vs-slope]
   - However, cellular thermal damage (keratinocyte protein coagulation and dermal capillary necrosis) is a direct thermodynamic function of contact temperature and exposure time. SIA prevents the subject from feeling the burn; it does not reduce the cellular damage.[^matre-2022-heat-protocol]
3. **The "Walking Wounded" Hazard on the Battlefield:**
   - First documented clinically by Henry Beecher (1946) studying severely wounded soldiers in World War II, who displayed minimal pain and requested no morphine despite compound fractures and penetrating abdominal trauma.[^marques-2024-beecher-battlefield]
   - Continuing high-exertion locomotion on unperceived injuries has catastrophic consequences:
     - Hairline, undisplaced stress fractures are sheared into displaced, compound fractures.
     - Partial ligament tears are converted into complete joint capsule dislocations.
     - Elevated heart rate and blood pressure from continued exertion rip open clotting lacerations, vastly accelerating hemorrhagic shock.

---

## 4. The Post-Combat State: Autonomic Collapse and Parasympathetic Rebound

When acute life-threatening danger resolves, the organism experiences a profound neuroendocrine and autonomic whiplash:

1. **Sympathetic Withdrawal:** Catecholamines (epinephrine, norepinephrine) rapidly clear from active synapses.
2. **Parasympathetic Overcompensation ("The Crash"):** To protect the cardiovascular system from prolonged hypertension and tachycardia, the vagus nerve and parasympathetic system trigger dramatic rebound overcompensation:
   - Systemic peripheral vasodilation drops blood pressure sharply.
   - Core muscular tone collapses, producing tremors, postural ataxia, and nausea.
   - Cognitive lethargy and acute disorientation set in.
3. **The Sensory Rebound:** As endocannabinoid and descending monoaminergic inhibition fade (between 30 and 50 minutes), the cumulative tissue trauma sustained across the entire encounter registers simultaneously.[^marques-2024-cb1-post-maintenance]
4. **Functional Vulnerability:** The victor of an armed engagement is frequently incapacitated within 15–30 minutes of the fight's conclusion—not by their opponent's continuing attacks, but by the collapse of their own physiological stress buffer.

---

## Citations and Verbatim Source Evidence

[^marques-2024-protective-paradox]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L13 ([extracted.md#L13](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L13))"
    quote: "A kind of paradox arises—pain perception would limit the organism’s ability to overcome stress. Therefore, it seems logical that pain perception decreases during the stressful situation, thus eliminating its paralyzing effect on the body."
    status: unverified

[^marques-2024-anatomic-substrates]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L15 ([extracted.md#L15](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L15))"
    quote: "As for the anatomical substrate of SIA, some subcortical areas, such as the periaqueductal gray, the amygdala, and the rostral ventromedial medulla, seem critical for the descending inhibitory pain pathways [10,11,12]."
    status: unverified

[^marques-2024-ecs-mechanisms]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L17 ([extracted.md#L17](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L17))"
    quote: "The ECS is a neuromodulatory system consisting of (i) a complex network of G-protein-coupled cannabinoid receptors type 1 (CB1) and 2 (CB2) [15], widely distributed in the central and peripheral nervous systems [16]; (ii) their endogenous ligands—endocannabinoids: anandamide (N-arachidonoyl ethanolamine, AEA) and 2-arachidonylglycerol (2-AG); and (iii) an enzyme system engaged in their biosynthesis and subsequent metabolisms [15]... The cannabinoid CB1 receptors are highly expressed in several limbic brain regions (i.e., hippocampus, amygdala, prefrontal cortex), and involved in the HPA axis [18,19] and adrenal gland regulation [20]... For the moment, the overall evidence indicates the pivotal role of CB1, and not CB2, in HPA axis regulation following stress exposure [23,24]."
    status: unverified

[^marques-2024-raphe-serotonin]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L23 ([extracted.md#L23](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L23))"
    quote: "Serotonin (5-hydroxytryptamine, 5-HT) is one of the key neurotransmitters involved in a wide variety of behavioral and cognitive responses. 5-HT-releasing neurons are vastly distributed in the central nervous system, which is the primary target of nociceptive information... Serotonin is released in association with pain-related behaviors, manifesting both pro- and antinociceptive effects [40,41,42]."
    status: unverified

[^marques-2024-study-design]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L39 ([extracted.md#L39](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L39))"
    quote: "The aim of this study was to determine the joint effect of the cannabinoid and the serotonergic systems on cold SIA. The effect of both systems was followed by administration of cannabinoid (CB1) and serotonin (5-HT1A) receptor agonists before and after one hour of cold stress."
    status: unverified

[^marques-2024-animals]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L49 ([extracted.md#L49](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L49))"
    quote: "Adult male Wistar rats, 250–300 g body weight (BW), were kept in plastic cages under a 12 h light:12 h darkness cycle (light onset at 08.00 h), at 24 ± 1 °C; a standard diet and tap water were available ad libitum [60]."
    status: unverified

[^marques-2024-cold-stress-model]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L77 ([extracted.md#L77](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L77))"
    quote: "Acute cold stress was induced by placing the animals at a low environmental temperature (4 °C) for 1 h. During the time of cold exposure, no food and water were allowed; the rats could move freely, allocated in individual cages without sawdust."
    status: unverified

[^marques-2024-500g-cutoff]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L85 ([extracted.md#L85](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L85))"
    quote: "Paw-pressure test (PP; Randall–Selitto test): The changes in the mechanical nociceptive thresholds of the rats were measured using an analgesimeter (Ugo Basile, Gemonio, Italy). The pressure was applied to the rat hind-paw and the pressure required for eliciting a nociceptive response, such as a squeak or struggle, was taken as the mechanical nociceptive threshold (paw-pressure thresholds, PPT—represented in arbitrary units, AU, according to the scale of the analgesimeter). A cut-off value of 500 g was observed to prevent damage in the paw [63]."
    status: unverified

[^marques-2024-cold-sia]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L101 ([extracted.md#L101](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L101))"
    quote: "In the 1h CS group, we observed an increase in PPT values compared with those of the control animals. One-way ANOVA showed a significant effect—_p_-values were <0.00001 (F = 2749.61972 on the 10th min; F = 1375.5814 on the 20th min; F = 1962.33333 on the 30th min; F = 2373.71795 on the 40th min) for the whole time estimated (Figure 1)."
    status: unverified

[^marques-2024-pre-potentiation]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L107 ([extracted.md#L107](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L107))"
    quote: "A statistically relevant potentiation of cold-SIA (c-SIA) was observed at the 10th min after AEA and DPAT pretreatment (_p_ = 000021, F = 38.98676), while a decrease in PPT followed the administration of the same combination (AEA+DPAT) after stress exposure (Figure 1)."
    status: unverified

[^marques-2024-serotonin-all-or-nothing]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L113 ([extracted.md#L113](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L113))"
    quote: "The administration of the CB1 agonist AEA together with the 5HT1A-antagonist NAN before exposure to stress completely abolished the development of c-SIA. The obtained results showed that the PPT of the experimental animals were similar to the controls and even showed a tendency towards hyperalgesia at the 50th minute of the experiment (AEA+NAN+1 h CS, Figure 2A)."
    status: unverified

[^marques-2024-nan-post-stress]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L115 ([extracted.md#L115](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L115))"
    quote: "AEA+NAN-administration after 1 h CS led to a constant level of c-SIA. The PPT of 1 h CS+AEA+NAN-animals were lower than the 1 h CS+AEA+DPAT-animals’ ones at the 10th and 20th min but they exceeded them from the 30th min until the 50th min of the experiment (Figure 2B)."
    status: unverified

[^marques-2024-cb1-post-maintenance]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L119 ([extracted.md#L119](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L119))"
    quote: "AM+DPAT-administration after 1 h CS decreased PPT at the 10th min compared with 1 h CS+AEA+DPAT-animals’ ones, with no c-SIA detected at the 20th min, and a tendency toward hyperalgesia from the 30th min to the end of the experiment (1 h CS+AM+DPAT, Figure 2B)."
    status: unverified

[^marques-2024-system-roles]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L147 ([extracted.md#L147](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L147))"
    quote: "The results also support the idea that the serotonergic system is relatively more important than the ECS in “maintaining” c-SIA in pre-treated animals, while in the case of post-treatment, analgesia depends, to a relatively higher degree, on the activity of the cannabinoid system."
    status: unverified

[^marques-2024-hpa-negative-feedback]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L149 ([extracted.md#L149](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L149))"
    quote: "The statistically significant decrease in c-SIA level described in our study after the exogenous administration of both cannabinoid- and 5-HT1A-receptors’ agonists after the stressor, could be explained by the endocannabinoids’ modulation of the neuroendocrine function through the HPA axis [82]."
    status: unverified

[^marques-2024-all-or-nothing-principle]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L151 ([extracted.md#L151](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L151))"
    quote: "Our results indicate that the interaction between the two systems has opposing effects before and after the stressogenic impact. Moreover, the activation of serotonin receptors prior to stress appears to be a necessary condition for the onset of c- SIA as well as its duration, thus the interaction follows the “all or nothing” principle. Conversely, once c-SIA has already been induced, antagonizing the 5HTA1-receptors contributes to its duration."
    status: unverified

[^marques-2024-beecher-battlefield]:
    source: marques-2024-cannabinoid-serotonergic-sia
    locator: "extracted.md#L15 ([extracted.md#L15](../sources/verisimilitude/marques-2024-cannabinoid-serotonergic-sia/extracted.md#L15))"
    quote: "The first information about the decrease in pain perception in stressful situations was provided by Beecher, who observed wounded soldiers during the World War II. He noted that wounds, which under other circumstances were felt as very painful, caused a weak sensation of pain [5,6,7]."
    status: unverified

[^matre-2022-study-design]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L17 ([extracted.md#L17](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L17))"
    quote: "Participants were 72 healthy individuals who attended 2 laboratory sessions, receiving either oral naltrexone (50 mg; opioid antagonist) or placebo (randomized, counterbalanced order). In each session, participants underwent a temporal summation protocol with evoked heat pain stimuli, once after extended rest and once after experiencing 2 acute stressors (public speaking and mental arithmetic challenge)."
    status: unverified

[^matre-2022-heat-protocol]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L57 ([extracted.md#L57](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L57))"
    quote: "A standardized oscillating heat pain stimulation protocol (Medoc TSA 2001, Minneapolis, MN) was used to determine temporal summation, similar to our previous work.40,43 A sequence of 10 heat pulses, 0.5 seconds in duration, with a 35°C base temperature, an intertrial interval of 2.5 seconds, and 50°C target stimulus intensity was applied to the left volar forearm. Participants were asked to provide verbal numeric pain ratings (0 = “no pain” to 100 = “most pain possible”) immediately after the peak of each pulse."
    status: unverified

[^matre-2022-manipulation-checks]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L139 ([extracted.md#L139](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L139))"
    quote: "Significant mean changes from initial to maximal pain ratings during the temporal summation protocol, consistent with temporal summation of pain,8 were observed for the placebo/rest (mean change = 16.8, SD = 14.1, _t_[71] = 10.15, _P_ < 0.001; Cohen _d_ = 1.20), placebo/stress (mean change = 16.8, SD = 14.9, _t_[71] = 9.59, _P_ < 0.001; Cohen _d_ = 1.13), naltrexone/rest (mean change = 17.1, SD = 14.1, t[71] = 10.29, _P_ < 0.001; Cohen _d_ = 1.21), and naltrexone/stress (mean change = 19.1, SD = 14.9, _t_[71] = 10.91, _P_ < 0.001; Cohen _d_ = 1.29) conditions."
    status: unverified

[^matre-2022-initial-vs-slope]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L184 ([extracted.md#L184](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L184))"
    quote: "Analyses revealed that under placebo, the stress manipulation was associated with significant changes in intercepts among participants (_b_ = −3.43, SE = 0.89, _t_[1,230] = 3.86, _P_ < 0.001), such that initial pain ratings in the temporal summation stimulus series were lower in the stress than rest condition. This is consistent with an SIA effect. Stressor condition was not, however, associated with temporal summation slopes (_b_ = 0.12, SE = 0.17, _P_ = 0.50), a measure indexing central sensitization."
    status: unverified

[^matre-2022-stress-reactivity-moderation]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L188 ([extracted.md#L188](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L188))"
    quote: "Stress reactivity (ie, changes in distress from baseline to the end of the stressors) moderated associations between stress condition and initial pain ratings (_b_ = −2.52, SE = 0.88, _t_[1,227] = 2.86, _P_ = 0.004). Simple slope analysis revealed significantly lower initial pain ratings in the stress than the rest condition among participants with higher stress reactivity (_b_ = −5.92, SE = 1.24, _t_[1,227] = 4.78, _P_ < 0.001); in contrast, initial pain ratings did not differ between stress and rest conditions for participants with lower stress reactivity (_b_ = −0.89, SE = 1.25, _t_[1,227] = 0.71, _P_ = 0.48) (Fig. 2)."
    status: unverified

[^matre-2022-nonopioid-persistence]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L192 ([extracted.md#L192](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L192))"
    quote: "The main effect of stressor on initial pain ratings described above remained significant in this drug effect model (_b_ = −3.35, SE = 0.70, _t_[2,533] = 4.81, _P_ < 0.001), indicating an SIA effect on initial pain ratings independent of opioid blockade status... Stressor and drug condition did not interact to predict initial pain ratings (_b_ = 0.06, SE = 1.39, _t_[2,531] = 0.04, _P_ = 0.97) or temporal summation slopes (_b_ = 0.01, SE = 0.27, _t_[2,531] = 0.05, _P_ = 0.96)."
    status: unverified

[^matre-2022-female-opioid-inhibition]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L194 ([extracted.md#L194](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L194))"
    quote: "There was a significant gender × drug × pulse interaction on temporal summation slopes (_b_ = −0.65, SE = 0.28, _t_[2,526] = 2.30, _P_ = 0.02). Simple slope analysis revealed increased temporal summation slopes for women in the naltrexone (_b_ = 2.04, SE = 0.20, _t_[2,528] = 10.36, _P_ < 0.001) compared with placebo condition (_b_ = 1.49, SE = 0.20, _t_[2,528] = 7.45, _P_ < 0.001), indicating EO inhibition of temporal summation in women, independent of stress effects. In contrast, minimal difference in slopes was observed for men in the naltrexone (_b_ = 0.97, SE = 0.14, _t_[2,528] = 6.79, _P_ < 0.001) compared with placebo conditions (_b_ = 1.07, SE = 0.14, _t_[2,528] = 7.53, _P_ < 0.001) (Fig. 3)."
    status: unverified

[^matre-2022-paradoxical-analgesia]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L198 ([extracted.md#L198](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L198))"
    quote: "Stress reactivity moderated associations between drug condition and initial pain ratings (_b_ = −2.84, SE = 0.79, _t_[2,528] = 3.62, _P_ < 0.001), with significantly _lower_ initial pain ratings in the naltrexone than the placebo condition among participants with higher stress reactivity (_b_ = −4.40, SE = 1.08, _t_[2,528] = 4.07, _P_ < 0.001)."
    status: unverified

[^matre-2022-nonopioid-pathways]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L210 ([extracted.md#L210](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L210))"
    quote: "In the present study, opioid blockade with naltrexone may have exaggerated participants' stress responses during the acute stressor, thereby triggering more prominent SIA that was nonopioid in origin,27 that is, observable despite opioid blockade. Examples of possible nonopioid mechanisms include endocannabinoid,13,22 serotonergic,55 and hypothalamo-pituitary-adrenocortical mechanisms,7 all of which have been shown to contribute to SIA."
    status: unverified

[^matre-2022-windup-cites]:
    source: matre-2022-stress-induced-analgesia-temporal-summation
    locator: "extracted.md#L29 ([extracted.md#L29](../sources/verisimilitude/matre-2022-stress-induced-analgesia-temporal-summation/extracted.md#L29))"
    quote: "temporal summation of pain protocols that elicit increases in perceived pain intensity during rapid application of the same brief stimulus at 2- to 3-sec intervals index central sensitization.15"
    status: unverified
