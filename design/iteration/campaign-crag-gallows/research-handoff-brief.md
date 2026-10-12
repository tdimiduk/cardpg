---
title: "Research Handoff Brief: Calibrating the Time Economy & Vigilance Dynamics"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: true
---

# Research Handoff Brief: Calibrating the Time Economy & Vigilance Dynamics

## Executive Summary for Incoming Agent

This handoff brief is prepared for a dedicated, clean research session. Its goal is to provide full context, established architectural decisions, relevant files, and explicit research questions to calibrate the **Grounded Time Economy** of _The Delve of Crag-Gallows_ and _caRdPG_.

In our prior session, we established a foundational design pivot: **in-game time should be tracked in direct, realistic physical units (minutes, hours, days) rather than abstract card-turn counters**, with digital tabletop automation handling scheduled clock intervals and noise interrupts.

We established initial working baselines—**30 minutes for delve checks/effort flushes** and **60 minutes for wilderness checks**—marked explicitly as **tentative**. Your mission in the clean session is to conduct empirical research to stress-test, refine, and ground these numbers against human biomechanics, cognitive vigilance decay, speleological transit physics, and subterranean acoustics.

---

## 1. Core Mechanics & Design Context

### The Engine

- **Deck as Stamina:** Each character has a symmetrical 24-card deck representing their health, physical reserves, and tactical capability.
- **Adventuring Time & Ready Hand:** Outside combat (Crisis Time), players do not hold cards. Instead, they set a **Vigilance Dial (0 to 4 cards)** on the table as a **Ready Hand** (up to 1 card can be an active face-up guard stance).
- **The Effort Cycle:** Sustaining alertness flushes the Ready Hand to the expended pile, forcing a redraw. At vigilance 4, each Effort Cycle discards 4 cards (burning through 8 cards/hour under a 30-min cycle). After roughly 2–3 hours of continuous high vigilance, a character hits an automatic **Fatigue Cycle** (shuffling fatigue cards into the deck).
- **Marching at Ease (Dial 0):** Burns 0 cards on Effort Cycles, but entering surprise or Crisis Time leaves the player with an empty hand (0 cards).
- **The Breather:** A 15-minute pause allowing characters to perform a proportional fatigue cycle (adding 1 fatigue if $<12$ cards expended; 2 fatigue if $\ge 12$) and ignore armor Burden if unbuckling.
- **Dual-Trigger Clocks:**
  - _Scheduled:_ Elapsed chronometer time crossing thresholds (e.g., every 30m in delve, every 60m in wild).
  - _Interrupt:_ Actions bearing tags like `[Loud]` (sledgehammer breach, bone horns) or `[Exposed]` immediately trigger an out-of-turn clock draw.

---

## 2. Key Questions for the Clean Research Session

Your research should focus on four distinct quantitative tracks. Avoid pop-history tropes and focus strictly on empirical, peer-reviewed data per `.agent/standards/empirical_research_standards.md`.

### Track 1: Biomechanics & Cognitive Limits of Sustained Vigilance

1. **Isometric Weapon & Shield Hold Endurance:**
   - What is the physiological limit of holding an active combat guard (1.2 kg sword, 2.5 kg spear, 3–5 kg strapped/boss shield held high and ready) before tremor, muscular fatigue, and reaction time degradation occur?
   - At what minute mark does performance significantly decline without lowering arms?
2. **Sensory Vigilance in Absolute Darkness:**
   - Review literature on sustained attention in high-stress, low-stimulus environments (e.g., Mackworth clock vigilance tests, military night perimeter watches, subterranean exploration).
   - In a dark cave where auditory cues (clicks, scrapes) are the sole warning of lethal ambush, how long can peak auditory attention be maintained before attentional lapses occur?
3. **Effort Cycle Interval Calibration:**
   - Does our tentative **30-minute interval** accurately match the threshold where maintaining high readiness (Vigilance Dial 4) exhausts acute reserves, or should it be adjusted to 20 or 45 minutes?

### Track 2: Subterranean & Mountain Locomotion Kinetics

1. **Subterranean Traversal Speeds:**
   - What are empirical travel speeds (meters/minute or km/hour) documented in historical mine rescues, speleological cave surveys, or military tunnel warfare across:
     - Dry, even limestone quarry floors vs.
     - Low-clearance timber adits (duck-walking, stoop-walking) vs.
     - Waist-deep flooded mine sumps with submerged rubble?
2. **Scree & Ravine Ascent:**
   - What is the metabolic cost and realistic transit time of ascending 20°–30° loose shale/scree slopes carrying 20–30 kg of field gear?
3. **Room Traversal Calibration:**
   - Does 5–10 minutes per delve room and 45–60 minutes per wilderness trail leg hold up to physical realities?

### Track 3: Acoustic Dynamics & Alert Horizons in Hard-Rock Mines

1. **Decibel Output of Exploratory & Forcible Actions:**
   - Quantify sound pressure levels (dB) for:
     - Sledgehammer or pickaxe striking iron mine rails / mortared stone ($\sim 115\text{--}125\text{ dB}$).
     - Clattering tin cans / bone chimes ($\sim 65\text{--}75\text{ dB}$).
     - Bone horn / whistle blasts ($\sim 100\text{--}115\text{ dB}$).
     - Delicate lockpicking and wire snipping ($\sim 40\text{--}50\text{ dB}$).
2. **Acoustic Wave Transmission in Stone Shafts:**
   - How rapidly does sound attenuate around 90° rock corners, down vertical shafts, and through damp air?
3. **Alert Horizon Rules:**
   - When an action has the `[Loud]` tag, what is the realistic radius (in rooms/meters) of immediate sentry detection?

### Track 4: Frontier Portable Light: Combustion & Atmospheric Costs

1. **Torch & Lantern Burn Lifespans:**
   - What are empirical burn times, fuel weights, and wind thresholds for pine pitch/resin torches, tallow candles, and oil lanterns?
2. **Oxygen Depletion & Gas Hazards:**
   - How rapidly does an open flame consume oxygen in an unventilated dead-end adit compared to a human at rest or under exertion?
   - How does open flame interact with pooling blackdamp ($CO_2 / N_2$)?

---

## 3. Essential Workspace Context & Files

Before launching subagents or querying databases, read these existing files:

### Scenario & Clock Design Files

- [`design/iteration/campaign-crag-gallows/README.md`](README.md): Vision and architecture of the testbed scenario.
- [`design/iteration/campaign-crag-gallows/environment-and-inhabitants.md`](environment-and-inhabitants.md): Full zone topology, monsters, hazards, and color checks.
- [`design/iteration/campaign-crag-gallows/living-clocks.md`](living-clocks.md): Concepts for Wilderness, Site Activity, and Macro Haven clocks.
- [`design/iteration/campaign-crag-gallows/location-card-schema.md`](location-card-schema.md): Data schemas for Location, Travel, and Clock cards with concrete YAML examples.
- [`design/iteration/campaign-crag-gallows/software-requirements-checklist.md`](software-requirements-checklist.md): The technical requirements for chronometer and deck tracking.
- [`design/iteration/campaign-crag-gallows/verisimilitude-study-agenda.md`](verisimilitude-study-agenda.md): Detailed 5-track study plan.

### Core Rules & Precepts

- [`design/rules/core-rules.md`](../../rules/core-rules.md): Ready Hand, Vigilance Dial, Effort Cycles, Fatigue Cycles (lines 82–106).
- [`design/rules/modules/the-breather.md`](../../rules/modules/the-breather.md): The Breather 15-minute rest procedure.
- [`design/philosophy/design-precepts.md`](../../philosophy/design-precepts.md): Core engine philosophy, 10x rule, casual realism.

### Existing Relevant Research Reports in the Repo

- [`design/research/reports/exertion-recovery-dynamics/report.md`](../../research/reports/exertion-recovery-dynamics/report.md): Quantitative data on EPOC, glycogen replenishment (5–10 mmol/kg/hr), and daily sustainable metabolic ceiling (2.5x BMR).
- [`design/research/reports/functional-decline-under-physical-hardship/report.md`](../../research/reports/functional-decline-under-physical-hardship/report.md): Impact of cold-water immersion, load carriage, and sleep deprivation.
- [`design/research/synthesis/subterranean-gases-and-blackdamp-toxicity.md`](../../research/synthesis/subterranean-gases-and-blackdamp-toxicity.md): Empirical gas physics and flame smothering thresholds.

---

## 4. Research Methodology & Standards for Incoming Agent

1. **Invoke the `empirical_researcher` Subagent:**
   - Use the `empirical_research_subagents` skill (`.agent/skills/empirical_research_subagents/SKILL.md`) to invoke the `empirical_synthesizer` persona.
   - Persona is read-only (`enable_write_tools: false`), focused strictly on quantitative metrics (seconds, Joules, dB, METs, clinical/biomechanical data).
2. **Follow Literature Sourcing Hierarchy (`.agent/standards/empirical_research_standards.md`):**
   - Check local archive first.
   - For web queries, use NCBI Bookshelf / StatPearls, PubMed Central (PMC HTML articles), Internet Archive, and government monographs (NIOSH/OSHA/CDC).
   - **Never curl commercial academic publishers directly** (Elsevier, Springer, Wiley) to prevent HTTP 403 blocks.
3. **Output Deliverables:**
   - Save the comprehensive clinical research report under `design/research/reports/time-economy-and-vigilance/report.md` (or relevant directory).
   - Include **Functional Impact Tables** mapping elapsed vigilance time and terrain types to physical performance decrements.
   - Provide concrete, actionable recommendations:
     - Confirmed or revised Effort Cycle intervals (e.g. "Maintain 30 min as baseline, but add X rule for knee-deep wading").
     - Clear dB thresholds and room-distance horizons for `[Loud]` tags.
     - Exact burn-rate parameters for torches and lanterns.
