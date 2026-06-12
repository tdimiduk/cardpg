# Exploration Consequence Database

This file serves as a structured, rules-independent database of environmental hazards, travel-related hardship, and traversal injuries for **caRdPG**, grounded in clinical medicine, physical sciences, and wilderness research.

Refer to the central [Consequence Database Hub](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequence-database.md) for general guidelines.

---

## Domain-Specific Calibration Brackets

### Onset Impact (1-100) - Traversal and Survival:

- **1–10 (Minor)**: Minor traversal nuisance or discomfort. Damp clothing, dust in eyes, slight orientation confusion (e.g., Slipping on Wet Grass, Dust in Eyes).
- **11–30 (Moderate)**: Impaired travel pace or minor exposure. Light dehydration, noticeable muscle strain, or joint bruising that restricts movement speed (e.g., Bruised Tailbone, Mild Dehydration, Grade I Ankle Sprain).
- **31–60 (Severe)**: Severe traversal injury or moderate environmental exposure. Prevents rapid movement; requires active shelter, halts travel, or forces cargo/load abandonment (e.g., Grade II Ankle Sprain, Established Trench Foot, Class II Dehydration).
- **61–90 (Critical)**: Life-threatening wilderness emergency. Severe hypothermia, acute disease (dysentery/malaria), major fall trauma, or dangerous beast-trap capture (e.g., Deep Pit Fall, Severe Dysentery, Moderate Hypothermia).
- **91–100 (Fatal)**: Immediate fatality or unavoidable wilderness exposure death (e.g., Freezing to death, falling off high cliff/abyss, catastrophic quicksand/suffocation).

### Recovery Difficulty (1-100) - Traversal and Survival:

- **1–10 (Trivial)**: Resolves naturally in minutes/hours with dry socks, a short rest, or basic shelter.
- **11–30 (Minor)**: Resolves in hours to 1 week with basic field first-aid, a warm fire, dry sleep, or standard rehydration (e.g., Minor Foot Sprain, Catching Up on Sleep).
- **31–60 (Moderate)**: Resolves in 1 week to 2 months; requires wilderness survival rest, splinting, or clinical recovery from exposure/infections (e.g., Grade II Sprain, Severe Dysentery recovery).
- **61–90 (Major)**: Resolves in months to a year; requires long-term convalescence in a settlement, complex bone setting, or rare active antidotes/herbs.
- **91–100 (Permanent)**: Permanent impairment (amputating a frostbitten toe, permanent respiratory/organ damage from drowning/exposure).

---

## Environmental, Traversal, and Survival Consequences

| Consequence Name                     | Tags                     | Likely Causes / Triggers                                                                                | Physiological / Factual Basis (Verisimilitude)                                                      | Sensory / Narrative Description                                                          | Onset Impact (1-100) | Terminal Impact (1-100) | Realistic Healing / Clearing Process                                       | Recovery Difficulty (1-100) | Citations                                                                                                                                    |
| :----------------------------------- | :----------------------- | :------------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------- | :------------------: | :---------------------: | :------------------------------------------------------------------------- | :-------------------------: | :------------------------------------------------------------------------------------------------------------------------------------------- |
| **Sprained Wrist**                   | Physical, Arms           | Bracing a fall with hands, twisting under a heavy load, climbing accidents, wrestling lock.             | Torn or stretched ligaments around wrist joints. Limits grip strength and fine motor skills.        | A sudden wrenching twist followed by sharp, throbbing heat and rapid swelling.           |          22          |            -            | Immobilization, cold compress, relative rest (1–3 weeks).                  |             35              | [report-physical-hardship](file:///home/tdimiduk/cardpg/cardpg/design/research/reports/functional-decline-under-physical-hardship/report.md) |
| **Mild Hypothermia**                 | Environmental, Cognitive | Prolonged exposure to cold wind, rain, or snow without fire/warm clothing; falling into freezing water. | Core temperature drops to 32–35°C. Uncontrollable shivering and the "apathy trap" degrade decision. | Violent, uncontrollable shivering; fingertips going numb and thoughts becoming sluggish. |          25          |           85            | Warm shelter, dry clothing, external heat source, warm fluids (1–2 hours). |             12              | [report-physical-hardship](file:///home/tdimiduk/cardpg/cardpg/design/research/reports/functional-decline-under-physical-hardship/report.md) |
| **Exhausted (Class II Dehydration)** | Physical, Exertion       | Prolonged marching in heat, intense activity under heavy armor/loads without water intake.              | 2–4% water loss combined with prolonged exertion. Physical capacity declines by 20%.                | A parched, sticky mouth, pounding headache, and muscles burning with dry fatigue.        |          28          |           70            | Rehydration, mineral replacement, deep sleep (12–24 hours).                |             15              | [report-physical-hardship](file:///home/tdimiduk/cardpg/cardpg/design/research/reports/functional-decline-under-physical-hardship/report.md) |
