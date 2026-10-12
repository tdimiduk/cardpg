---
title: "Research Agenda: Verisimilitude & Empirical Grounding of the Time Economy"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: true
---

# Research Agenda: Verisimilitude & Empirical Grounding of the Time Economy

This document establishes the structured agenda for empirical research and mathematical modeling to calibrate the **Time Economy** of _The Delve of Crag-Gallows_ and future exploration campaigns in _caRdPG_.

---

## 1. Status of Current Pacing Baselines

The current operational intervals are adopted as **tentative working hypotheses** to validate core game flow:

| Scale                  | Environment                   | Current Tentative Baseline | Planned Function                                   | Status                                       |
| :--------------------- | :---------------------------- | :------------------------- | :------------------------------------------------- | :------------------------------------------- |
| **Tactical / Crawl**   | Quarry Terraces & Lower Mines | **30 Minutes**             | Site Activity Clock draw & Ready Hand Effort flush | **Tentative** (Pending Research Track 1 & 2) |
| **Wilderness / March** | Mountain Ravines & Trails     | **60 Minutes**             | Wilderness Clock draw & Forced March Effort flush  | **Tentative** (Pending Research Track 2 & 5) |
| **Macro / Haven**      | Fortified Steading & Town     | **24 Hours**               | Macro Haven Clock draw & Convalescence step        | **Tentative** (Pending Research Track 5)     |

These figures feel playable and intuitive for game pacing, but require rigorous empirical stress-testing against physiological, physical, and historical data to ensure true _ludonarrative harmony_.

---

## 2. Research Tracks & Quantitative Investigation Topics

### Track 1: Biomechanics & Cognitive Limits of Sustained Vigilance

_Target Question:_ How long can a human sustain combat-ready guard and sensory hyper-vigilance in a dark, hostile environment before physiological and cognitive degradation occurs?

- **Isometric Muscular Load of Weapon Guard:**
  - Quantify the endurance limits of holding a drawn weapon (e.g. 1.2 kg arming sword, 2.5 kg polearm) and braced shield (3–5 kg strapped or boss-held) in high/active guard.
  - At what minute mark do muscular tremor, forearm fatigue, and slowed parry latency manifest?
  - Does switching between Ready Hand sizes (4 vs 2 vs 0) accurately mirror the metabolic difference between active guard, slung weapons, and marching at ease?
- **Attentional Fatigue & Sensory Decrement:**
  - Review human performance literature on sustained vigilance tasks (e.g., Mackworth clock vigilance studies, military night sentry protocols, sensory deprivation in caves).
  - In total darkness where auditory cues are the primary defense, how long can peak auditory attention be sustained before mental fatigue causes acoustic target misses?
  - _Calibration Goal:_ Determine whether an Effort Cycle flush every **20, 30, or 45 minutes** best reflects true human endurance limits.

### Track 2: Subterranean vs. Mountain Overland Traversal Speeds

_Target Question:_ What are realistic distance-to-time ratios for traversing unlit, fractured mine galleries vs steep scree trails while carrying 20–30 kg of gear?

- **Caving & Mine Exploration Locomotion:**
  - Review historical records of 19th-century mine rescue teams and modern speleological survey speeds.
  - How dramatically does speed drop between:
    - Dry limestone quarry floor.
    - Low-clearance timber adit (stoop-walking / duck-walking).
    - Waist-deep flooded sump with submerged debris.
- **Scree & Ravine Ascent Kinetics:**
  - Quantify metabolic energy expenditure (METs and kcal/hr) of ascending 20–30 degree shifting shale slopes under load.
  - Evaluate the time penalty of cautious footing vs the risk of sprains during fast scrambles.
  - _Calibration Goal:_ Verify that traversing nodes $U1 \rightarrow U2 \rightarrow L1$ realistically consumes 5–15 minutes per section.

### Track 3: Acoustic Transmission & Alert Radii in Hard-Rock Mines

_Target Question:_ How far do specific percussive sounds travel through subterranean rock adits, and what constitutes a realistic alert threshold for `[Loud]` actions?

- **Acoustic Wave Propagation in Tunnel Networks:**
  - Sound transmission differences between line-of-sight stone drifts, right-angle tunnel junctions, and backfilled cave-ins.
  - Decibel output and decay distance of:
    - Sledgehammer striking iron mine rails ($\sim 115\text{--}125\text{ dB}$).
    - Dropping a bucket of rocks or rusted ore cart.
    - Bone whistle / horn blast ($\sim 100\text{--}110\text{ dB}$).
    - Chiseled mortar and picking rusted locks ($\sim 45\text{--}55\text{ dB}$).
- **Inhabitant Alert Horizons:**
  - Does a sledgehammer breach at $U1$ naturally alert sentries at $U2$? Does it penetrate down the shaft to $L1$?
  - _Calibration Goal:_ Define standard distance/node horizons for the `[Loud]` tag so interrupt draws feel physically plausible.

### Track 4: Portable Frontier Light Sources: Fuel, Combustion & Air Quality

_Target Question:_ What are the exact burn times, fuel weights, wind vulnerabilities, and atmospheric impacts of pitch torches, tallow candles, and oil lanterns?

- **Combustion Rates & Practical Lifespans:**
  - Pine pitch / resin torches: actual burn time per torch weight (commonly cited 30–60 minutes; verify against historical re-enactment and metallurgical data).
  - Tallow candles vs beeswax vs vegetable oil lamps (colza, whale oil): weight vs duration.
- **Atmospheric Depletion in Confined Underground Spaces:**
  - Oxygen consumption rate of open flame torches vs human respiration.
  - Carbon monoxide and soot generation in unventilated dead-end adits.
  - Synergy with subterranean gases (blackdamp: carbon dioxide / nitrogen pooling).
  - _Calibration Goal:_ Establish baseline consumable timers (e.g. Torch = 45m or 60m; Lantern = 4h per flask).

### Track 5: Ecology Dynamics & Inhabitant Patrol Cadence

_Target Question:_ What are natural patrol frequencies, sleep-wake cycles, and predatory tracking rhythms for wolves and subterranean scavengers?

- **Goblin Social Organization & Shift Lengths:**
  - For opportunistic scavenger bands, what is a plausible watch-shift duration? (e.g. 2-hour vs 4-hour watches; frequency of bickering and dereliction of duty).
- **Mountain Wolf Pack Tracking Kinetics:**
  - How rapidly does a wolf pack close ground upon picking up a human scent trail or hearing clattering scree slides from the valley below?
  - _Calibration Goal:_ Calibrate the distribution of passive shift cards vs sudden ambushes in the Site and Wilderness Clock decks.

---

## 3. Deployment Plan for Research Subagents

To investigate these questions without polluting the main design context or relying on pop-history assumptions, future dedicated research tasks will leverage our specialized subagents:

1. **`empirical_researcher` Subagent Task 1: Sustained Vigilance & Isometric Guard Fatigue**
   - Query physiological journals for isometric muscle endurance curves of braced arms carrying 3–5 kg shields and attentional vigilance decay rates in darkness.
2. **`empirical_researcher` Subagent Task 2: Subterranean Locomotion & Mine Acoustics**
   - Extract empirical speleological transit speeds under varied subterranean conditions and acoustic decibel decay curves in hard-rock mine adits.
3. **`game_systems_designer` Subagent Task 3: Deck Economy Integration & Attrition Curves**
   - Translate the verified physical timelines into card draw frequencies and deck attrition rates to ensure players experience the intended push-your-luck tension without degenerate failure spirals.
