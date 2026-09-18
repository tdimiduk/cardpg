# Master Execution Plan: Empirical Grounding of Consequence Databases (Backlog: WP5–WP8)

## 1. Executive Summary & Operational Baseline

The goal of this initiative is to eliminate all placeholder citations (`_None_`) across the `design/research/synthesis/` consequence databases, grounding every entry in empirical, open-access literature (historical craft manuals, clinical trauma datasets, agricultural/veterinary extension bulletins, government occupational standards, and peer-reviewed physiology papers).

### Current Repository Status

- **Dual Repository Architecture:**
  - **Root Repo (`tdimiduk/cardpg`):** Tracks design synthesis files and metadata catalogs.
  - **Nested Git Vault (`design/research/sources/`):** Standalone Git repository (gitignored by root) storing all raw source PDFs, markdown captures, and historical texts. Clean working tree.
- **Pre-Harvested Vault Status:**
  - **19 empirical source documents** have been successfully downloaded and committed to the nested vault at `design/research/sources/verisimilitude/` (commit `6dbde80`).
  - An active **Deferred Acquisition Queue** has been checked into the sources repository as [`design/research/sources/DEFERRED_ACQUISITIONS.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/sources/DEFERRED_ACQUISITIONS.md) to manage paywalled items and bot-protected mirrors for human retrieval.
- **Completed Pilot (WP1–WP4):**
  - Standard epistemic frontmatter implemented across all synthesis files.
  - Symmetric catalogs created: [`design/research/verisimilitude-sources.yaml`](file:///home/tdimiduk/cardpg/cardpg/design/research/verisimilitude-sources.yaml) and [`design/research/ludology-sources.yaml`](file:///home/tdimiduk/cardpg/cardpg/design/research/ludology-sources.yaml).
  - Pilot WP4 completed: all 8 placeholders in [`consequences-logistics.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-logistics.md) grounded in empirical literature; confidence elevated to `"high"`.
- **Remaining Backlog:** 25 placeholder citations across 4 synthesis documents:
  1. [`consequences-crafting.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-crafting.md) (10 items)
  2. [`consequences-social.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-social.md) (8 items)
  3. [`consequences-arcane.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-arcane.md) (5 items)
  4. [`consequences-combat.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-combat.md) (2 items)

---

## 2. Hard-Won Lessons Learned & Operational Guardrails

Incoming agents executing this plan must adhere strictly to these operational guardrails:

### 1. The Prettier Pre-Commit Hook Loop

The root repository enforces a pre-commit hook that runs `prettier` over modified Markdown and YAML files.

- **Symptom:** `git commit` fails with code 1 and messages like `files were modified by this hook`.
- **Cause:** Prettier automatically adjusts column alignments in Markdown tables and indentation in YAML.
- **Resolution:** Do not revert changes or panic. Simply re-stage the modified files and repeat the commit:
  ```bash
  git add design/research/verisimilitude-sources.yaml design/research/synthesis/<target-file>.md
  git commit -m "<commit message>"
  ```

### 2. Harvest Hierarchy & Anti-Paywall Rules

Per [`.agent/standards/empirical_research_standards.md`](file:///home/tdimiduk/cardpg/cardpg/.agent/standards/empirical_research_standards.md#4-literature-sourcing-ingestion-hierarchy--human-escalation), commercial publishers (Elsevier, Springer, Wiley, MDPI, APA) and certain government endpoints (DTIC, OSHA.gov via CloudFront) aggressively block automated CLI scrapers (`curl`, `urllib`) with HTTP 403 or Cloudflare challenge screens. Never waste time attempting to curl commercial paywalls. Instead, strictly utilize this hierarchy:

| Tier       | Source Category                                     | Ingestion Method                                                                           | Typical Target Domains                                                                                     |
| :--------- | :-------------------------------------------------- | :----------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------- |
| **Tier 1** | **Internet Archive & Legal Treatises**              | Direct PDF `curl -sL` or Open Legal Portals                                                | Historical craft, metallurgy, wheelwrighting, legal treatises.                                             |
| **Tier 2** | **University Agricultural / Veterinary Extensions** | Direct PDF/HTML `curl -sL` or `trafilatura -u`                                             | Purdue, UMN, NDSU, Penn State, TAMU, Iowa State bulletins (toxicology, pathology, feed).                   |
| **Tier 3** | **Federal Repositories (CDC Stacks, NIOSH)**        | PDF curl from `stacks.cdc.gov` or `cdc.gov/niosh`                                          | Occupational health (NIOSH 97-141, NIOSH 98-126, Pub 2009-113 electrical safety).                          |
| **Tier 4** | **NCBI Bookshelf (StatPearls)**                     | Full-text extraction via `trafilatura -u "https://www.ncbi.nlm.nih.gov/books/NBK<ID>/"`    | Clinical wound healing, thermal burns, amputations, blast injuries, psychiatric panic, ocular trauma.      |
| **Tier 5** | **PubMed Central (PMC)**                            | Full-text extraction via `trafilatura -u "https://pmc.ncbi.nlm.nih.gov/articles/PMC<ID>/"` | Peer-reviewed open-access reviews (photokeratitis, friction blisters, welding UV irradiance, social pain). |

> [!WARNING]
> **Never download binary PDFs directly from PubMed Central via CLI.** PMC redirects direct binary PDF requests to an HTML splash challenge. Always use `trafilatura -u "https://pmc.ncbi.nlm.nih.gov/articles/PMC<ID>/"` to extract clean, full-text Markdown.
> **Never curl OSHA.gov directly via CLI.** OSHA.gov uses CloudFront and blocks automated user-agents with 403. Use CDC/NIOSH endpoints (`cdc.gov/niosh` or `stacks.cdc.gov`) instead.

### 3. Human-in-the-Loop Sourcing Escalation Protocol

_(Enshrined in [`design/research/sources/README.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/sources/README.md) and [`design/research/sources/DEFERRED_ACQUISITIONS.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/sources/DEFERRED_ACQUISITIONS.md))_

Agents are explicitly authorized and encouraged to defer to human assistance when encountering paywalls or interactive CAPTCHAs:

1. **Web UI Access (Gate / CAPTCHA Bypass):** If an open-access source or government document is guarded by an interactive web UI gate (e.g. Cloudflare verification, interactive CAPTCHAs, or complex download forms), log the item in `DEFERRED_ACQUISITIONS.md`. The human will download it via desktop browser and place it into `design/research/sources/verisimilitude/`.
2. **Institutional Library Access (Paywall Retrieval — Last Resort):** The human has institutional library access that can penetrate commercial academic paywalls. Agents must first verify that no open-access preprint, PMC review, government monograph, or extension bulletin exists before requesting paywalled retrieval.

### 4. Bidirectional Index Integrity & Epistemic Schema

- **Strict Frontmatter:** Every consequence database frontmatter must include `"design/research/verisimilitude-sources.yaml"` in its `related_files` list. Failure to do so causes `python3 tools/audit_index.py --strict` to fail.
- **Local Markdown Links:** Table citations must use absolute local links pointing to the nested vault:  
  `[Author (Year)](file:///home/tdimiduk/cardpg/cardpg/design/research/sources/verisimilitude/<kebab-filename>.<ext>)`
- **Catalog Schema:** Every entry in `verisimilitude-sources.yaml` must adhere strictly to the schema, including `epistemic_grade` and a structured `vetting` block.

---

## 3. Top-Level Catalog Section Definitions

Incoming agents must instantiate the following new top-level YAML headers in [`design/research/verisimilitude-sources.yaml`](file:///home/tdimiduk/cardpg/cardpg/design/research/verisimilitude-sources.yaml):

```yaml
---
modeling_crafting_materials_metallurgy:
  description: >
    Empirical literature supporting historical metallurgy, workshop hazards, thermal trauma, toxic chemical exposure, and repetitive craft strain.
  sources:
    - type: ...
---
modeling_social_psychology_legal:
  description: >
    Empirical sociology, behavioral economics, neurobiology of social stress, and historical jurisprudence supporting relational fallout, ostracism, and outlawry.
  sources:
    - type: ...
---
modeling_arcane_sensory_electrotrauma:
  description: >
    Biomechanical and physiological analogues supporting speculative arcane stressors, including electrical arc discharges, neuro-otology acoustic fatigue, vestibular disorientation, and heterotopic tissue calcification.
  sources:
    - type: ...
```

---

## 4. Detailed Work Package Specifications

### Work Package 5: Crafting, Labor & Downtime (`consequences-crafting.md`)

- **Synthesis File:** [`design/research/synthesis/consequences-crafting.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-crafting.md)
- **Catalog Section:** `modeling_crafting_materials_metallurgy` in `design/research/verisimilitude-sources.yaml`

#### Batch 5A: Strains, Minor Cuts & Ocular Glare (Items 1–5)

| Item | Consequence Name            | Empirical Source & Author                                                                                                                           | URL / Ingestion Method & Status                                                    | Local Filename (Archived in Vault)                  | Quantitative Grounding & Calibration Guidance                                                                                                                                                                                                                                                                                                                     |
| :--- | :-------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------- | :-------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | **Forge Burn**              | Walker, N. J., & King, K. C. (2023), _Acute and Chronic Thermal Burn Evaluation and Management_, StatPearls                                         | `https://www.ncbi.nlm.nih.gov/books/NBK430730/`<br>_(Archived in Vault)_           | `walker-2023-thermal-burn-evaluation-management.md` | Superficial partial-thickness thermal burns involve papillary dermis with intact skin appendages. Tri-zonal injury (coagulation, stasis, hyperemia). Heals via re-epithelialization in 10–15 days with minimal scarring. Requires clean moist dressing and cooling. Calibrate: Onset 18, Terminal 35, Recovery 22.                                                |
| 2    | **Sore Fingers**            | Rushton, R., & Richie, D. (2024), _Friction Blisters: A New Paradigm to Explain Causation_, J. Athl. Train.                                         | `https://pmc.ncbi.nlm.nih.gov/articles/PMC10783477/`<br>_(Archived in Vault)_      | `rushton-2024-friction-blister-causation.md`        | Repetitive shear strain exceeding epidermal elastic yield point creates intraepidermal tearing in the _stratum spinosum_. Fluid fills the void within 2 hours. Resolves in 12–24h with cessation of shear stress, warm soak, and rest. Calibrate: Onset 6, Terminal -, Recovery 8.                                                                                |
| 3    | **Minor Cut / Singe**       | Ozgok Kangal, M. K., & Regan, N. L. (2023), _Physiology, Wound Healing_, StatPearls                                                                 | `https://www.ncbi.nlm.nih.gov/books/NBK535406/`<br>_(Archived in Vault)_           | `ozgok-kangal-2023-physiology-wound-healing.md`     | Wound repair phases: hemostasis (minutes), inflammation (neutrophils/macrophages 24–48h), proliferative keratinocyte migration (starts within hours, basal cell division at day 3), remodeling. Re-epithelializes in 3–5 days; scar tensile recovery continues for weeks. Calibrate: Onset 16, Terminal 25, Recovery 14.                                          |
| 4    | **Repetitive Wrist Strain** | Bernard, B. P. (Ed.) (1997), _Musculoskeletal Disorders and Workplace Factors_, NIOSH Pub. 97-141                                                   | `https://stacks.cdc.gov/view/cdc/21745/cdc_21745_DS1.pdf`<br>_(Archived in Vault)_ | `bernard-1997-niosh-musculoskeletal-disorders.pdf`  | Cyclic hammer recoil and forceful repetitive grip induce tenosynovitis of wrist flexor/extensor tendon sheaths and carpal tunnel compression (OR 2.0–5.5 under combined force and repetition). Requires 2–3 weeks of joint splinting and active rest. Calibrate: Onset 26, Terminal 45, Recovery 35.                                                              |
| 5    | **Eye Strain (Arc Eye)**    | Takahashi, J., et al. (2020), _Comprehensive analysis of hazard of ultraviolet radiation emitted during arc welding of cast iron_, J. Occup. Health | `https://pmc.ncbi.nlm.nih.gov/articles/PMC6970392/`<br>_(Archived in Vault)_       | `takahashi-2020-arc-welding-uv-hazard.md`           | Effective UV irradiance at 500 mm ranges from 0.045 to 2.2 mW/cm². ACGIH daily threshold ($3\text{ mJ/cm}^2$ at 270 nm) is exceeded in 1.4 to 67 seconds of unprotected exposure. Causes corneal epithelial nuclear fragmentation and desquamation; symptoms emerge in 6–12h and resolve in 24–72h with dark rest. Calibrate: Onset 33, Terminal 45, Recovery 24. |

#### Batch 5B: Severe Trauma, Inhaled Toxins & Explosions (Items 6–10)

| Item | Consequence Name        | Empirical Source & Author                                                                       | URL / Ingestion Method & Status                                          | Local Filename (Archived in Vault)                  | Quantitative Grounding & Calibration Guidance                                                                                                                                                                                                                                                                                                                                                                                           |
| :--- | :---------------------- | :---------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------- | :-------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 6    | **Scalded Palm**        | Walker, N. J., & King, K. C. (2023) & clinical burn literature                                  | (Shared with NBK430730)<br>_(Archived in Vault)_                         | `walker-2023-thermal-burn-evaluation-management.md` | Deep partial-thickness burn reaching reticular dermis from boiling liquid splash. Dermal appendages partially destroyed; re-epithelialization slow (3–5 weeks) requiring circumferential growth from wound margins. High risk of hypertrophic scarring and contractures. Calibrate: Onset 44, Terminal 60, Recovery 48.                                                                                                                 |
| 7    | **Inhaled Toxic Fumes** | StatPearls / CDC NIOSH (2023), _Metal Fume Fever and Smelting Fumes_                            | `https://www.ncbi.nlm.nih.gov/books/NBK545228/`<br>_(Archived in Vault)_ | `statpearls-2023-metal-fume-fever.md`               | Inhalation of zinc oxide / lead / sulfur dioxide vapors from smelting ores. Induces inflammatory cytokine cascade (TNF-alpha, IL-6) in pulmonary alveoli. Latency 4–8h, followed by intense chills, fever, metallic taste, dyspnea, and risk of noncardiogenic pulmonary edema. Resolves in 24–48h if mild, or weeks if chemical pneumonitis develops. Calibrate: Onset 58, Terminal 85, Recovery 55.                                   |
| 8    | **Third-Degree Burn**   | Walker, N. J., & King, K. C. (2023), _Acute and Chronic Thermal Burn Evaluation and Management_ | (Shared with NBK430730)<br>_(Archived in Vault)_                         | `walker-2023-thermal-burn-evaluation-management.md` | Full-thickness burn destroying entire epidermis and dermis into subcutaneous fat. Coagulated, thrombosed microvasculature; leathery, insensitive white or black eschar. Cannot re-epithelialize without excision and autografting; results in permanent contractures without clinical debridement. Calibrate: Onset 78, Terminal 95, Recovery 85.                                                                                       |
| 9    | **Amputated Fingers**   | StatPearls / Clinical Hand Surgery (2023), _Traumatic Digit Amputation and Stump Closure_       | `https://www.ncbi.nlm.nih.gov/books/NBK538289/`<br>_(Archived in Vault)_ | `statpearls-2023-digit-amputation.md`               | Severe mechanical crushing or shearing in machinery/stamp mills resulting in loss of phalanges. Critical warm ischemia time is 6–8 hours. Requires surgical hemostasis, bone contouring, and primary myoplastic flap closure. Bone union and scar maturation require 8–12 weeks; permanent loss of fine motor dexterity. Calibrate: Onset 82, Terminal 95, Recovery 95.                                                                 |
| 10   | **Forge Explosion**     | Garner, J., et al. / StatPearls (2023), _Blast Injuries_                                        | `https://www.ncbi.nlm.nih.gov/books/NBK430914/`<br>_(Archived in Vault)_ | `statpearls-2023-blast-injuries.md`                 | Catastrophic physical steam explosion triggered by entrapment of liquid water beneath molten metal or boiler overpressure. Instantaneous superheating causes rapid phase transition with $>1000\times$ volume expansion in milliseconds, creating shockwaves and high-velocity molten metal projectiles. Primary blast lung trauma and secondary penetrative burns; high fatality rate. Calibrate: Onset 98, Terminal 100, Recovery 95. |

---

### Work Package 6: Social, Psychological & Legal Consequences (`consequences-social.md`)

- **Synthesis File:** [`design/research/synthesis/consequences-social.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-social.md)
- **Catalog Section:** `modeling_social_psychology_legal` in `design/research/verisimilitude-sources.yaml`

#### Batch 6A: Interpersonal Stress, Ostracism & Deception (Items 1–4)

| Item | Consequence Name               | Empirical Source & Author                                                                                                                          | URL / Ingestion Method & Status                                              | Local Filename (Archived in Vault)             | Quantitative Grounding & Calibration Guidance                                                                                                                                                                                                                                                                                                                                                 |
| :--- | :----------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------- | :--------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | **Public Humiliation**         | Allen, A. P., et al. (2014), _The Trier Social Stress Test: Principles and practice_, Neurobiol. Stress / PMC4287841                               | `https://pmc.ncbi.nlm.nih.gov/articles/PMC4287841/`<br>_(Archived in Vault)_ | `allen-2014-trier-social-stress-test.md`       | Quantitative synthesis of TSST protocols demonstrating that social-evaluative threat (uncontrollable public failure) triggers large cortisol surges (2–3x baseline) peaking at 20–30 min post-stressor with recovery taking 60–90 min, accompanied by sympathetic flushing and acute cognitive disruption. Calibrate: Onset 15, Terminal 30, Recovery 18 (narrative healing: days to 1 week). |
| 2    | **Fumbled Greeting**           | Goffman, E. (1967), _Interaction Ritual: Essays on Face-to-Face Behavior_ / Schegloff (1977) conversational repair                                 | Deferred to Human Retrieval (see `DEFERRED_ACQUISITIONS.md`)                 | `goffman-1967-interaction-ritual.pdf`          | Sociological dynamics of "face" and interpersonal deference. A failed greeting violates opening turn sequences, generating immediate social awkwardness and cognitive interference, cleared rapidly (minutes to hours) by corrective rituals or social withdrawal. Calibrate: Onset 8, Terminal -, Recovery 6.                                                                                |
| 3    | **Ostracized (Cold Shoulder)** | Eisenberger, N. I. (2012), _The neural bases of social pain: Evidence for shared representations with physical pain_, Psychosom. Med. / PMC3273616 | `https://pmc.ncbi.nlm.nih.gov/articles/PMC3273616/`<br>_(Archived in Vault)_ | `eisenberger-2012-neural-bases-social-pain.md` | Functional neuroimaging establishes that social exclusion activates the dorsal anterior cingulate cortex (dACC) and anterior insula—the exact neural regions processing physical distress. Chronic exclusion triggers depressive withdrawal and cognitive fatigue. Calibrate: Onset 24, Terminal 40, Recovery 28.                                                                             |
| 4    | **Exposed Lie**                | Schweitzer, M. E., Hershey, J. C., & Bradlow, E. T. (2006), _Promises and Lies: Restoring Violated Trust_, Organ. Behav. Hum. Decis. Process.      | UPenn ScholarlyCommons<br>_(Archived in Vault)_                              | `schweitzer-2006-restoring-violated-trust.pdf` | Empirical game theory shows that deceptive trust breaches cause immediate collapse in bilateral cooperation. Trust damaged by untruthfulness never fully recovers to pre-breach baselines, requiring extensive costly signaling and penance over weeks. Calibrate: Onset 35, Terminal 65, Recovery 52.                                                                                        |

#### Batch 6B: Severe Psychological Trauma & Outlawry (Items 5–8)

| Item | Consequence Name               | Empirical Source & Author                                                                                  | URL / Ingestion Method & Status                                              | Local Filename (Archived in Vault)                   | Quantitative Grounding & Calibration Guidance                                                                                                                                                                                                                                                                                                      |
| :--- | :----------------------------- | :--------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------- | :--------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 5    | **Blackmail Threat**           | McEwen, B. S. (2012), _Brain on stress: How the social environment gets under the skin_, PNAS / PMC3406828 | `https://pmc.ncbi.nlm.nih.gov/articles/PMC3406828/`<br>_(Archived in Vault)_ | `mcewen-2012-brain-on-stress-social-environment.md`  | Anticipatory dread and chronic social threat induce continuous HPA-axis activation, elevated basal glucocorticoids, hippocampal dendritic atrophy, sleep architecture fragmentation, and degraded executive decision-making over weeks. Calibrate: Onset 32, Terminal 60, Recovery 45.                                                             |
| 6    | **Acute Panic Attack**         | StatPearls / Psychiatry (2023), _Panic Disorder Emergency Management_, NBK430973                           | `https://www.ncbi.nlm.nih.gov/books/NBK430973/`<br>_(Archived in Vault)_     | `statpearls-2023-panic-disorder-emergency.md`        | Acute amygdala overdrive producing extreme autonomic storm: heart rate spikes to 140+ bpm, hyperventilation induces hypocapnic respiratory alkalosis (paresthesia, carpopedal spasm, depersonalization). Peak severity in 10 minutes; resolving in 1–2 hours with exhaustion. Calibrate: Onset 45, Terminal - (acute non-escalating), Recovery 22. |
| 7    | **Exile / Banishment Verdict** | Pollock, F., & Maitland, F. W. (1898), _The History of English Law Before the Time of Edward I_, Vol. 2    | Deferred to Human Retrieval (see `DEFERRED_ACQUISITIONS.md`)                 | `pollock-maitland-1898-history-english-law-vol2.pdf` | Legal history of medieval abjuration of the realm and banishment. Extinguishes civil personality within the jurisdiction; loss of communal reciprocal protection; forced departure via prescribed routes on pain of summary death. Calibrate: Onset 75, Terminal 90, Recovery 85.                                                                  |
| 8    | **Declaration of Wolf's Head** | Pollock, F., & Maitland, F. W. (1898) (Chapters on Outlawry / _Caput Gerat Lupinum_)                       | (Shared with Pollock & Maitland 1898 Vol. 2)                                 | `pollock-maitland-1898-history-english-law-vol2.pdf` | Total revocation of legal status under medieval common law. The outlaw is equated to a wild wolf (_caput gerat lupinum_): may be slain on sight with impunity, property forfeited to the crown, communal _hue and cry_ mandated. Reversal requires sovereign pardon. Calibrate: Onset 95, Terminal 100, Recovery 95.                               |

---

### Work Package 7: Arcane & Alchemical Consequences (`consequences-arcane.md`)

- **Synthesis File:** [`design/research/synthesis/consequences-arcane.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-arcane.md)
- **Catalog Section:** `modeling_arcane_sensory_electrotrauma` in `design/research/verisimilitude-sources.yaml`

| Item | Consequence Name               | Empirical Source & Author                                                                                    | URL / Ingestion Method & Status                                                                      | Local Filename (Archived in Vault)                         | Quantitative Grounding & Calibration Guidance                                                                                                                                                                                                                                                                                                                                                                                   |
| :--- | :----------------------------- | :----------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------- | :--------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1    | **Singed Sleeves**             | CDC / NIOSH (2009), _Electrical Safety: Safety and Health for Electrical Trades_, Pub. 2009-113              | `https://www.cdc.gov/niosh/docs/2009-113/pdfs/2009-113.pdf`<br>_(Archived in Vault)_                 | `cdc-niosh-2009-electrical-safety.pdf`                     | Low-energy electrical arc discharges produce rapid thermal radiant pulses (temperatures exceeding 5000°C at the spark core). Natural wool carbonizes without melting, while linen scorches at >250°C. Superficial contact burns; cleared with garment replacement and minor first-aid (1–3 days). Calibrate: Onset 8 (aligns with Minor 1–10 exemplar in line 28), Terminal -, Recovery 5.                                      |
| 2    | **Alchemical Nausea**          | Horn, C. C., et al. (2014), _Why Is the Neurobiology of Nausea and Vomiting So Important?_, Auton. Neurosci. | `https://pmc.ncbi.nlm.nih.gov/articles/PMC4112079/`<br>_(Archived in Vault)_                         | `horn-2014-neurobiology-nausea-vomiting.md`                | Ingestion of chemical irritants activates the chemoreceptor trigger zone (area postrema in the floor of the fourth ventricle) via vagal afferents. Triggers gastric dysrhythmia, retrograde peristalsis, and autonomic emesis. Clears within 12–24h once toxin is cleared. Calibrate: Onset 25, Terminal 45, Recovery 18.                                                                                                       |
| 3    | **Mana Static (Ringing Mind)** | StatPearls / Neuro-otology (2023), _Acoustic Trauma, Tinnitus, and Sensory Processing_, NBK430809            | `https://www.ncbi.nlm.nih.gov/books/NBK430809/`<br>_(Archived in Vault)_                             | `statpearls-2023-tinnitus-auditory-processing.md`          | Acute sensory overstimulation exhausts cortical inhibitory gating mechanisms (GABAergic thalamic interneurons). Results in persistent phantom auditory perception (tinnitus), cognitive fatigue, and photophobia. Resolves in 24–48h with sensory deprivation and rest. Calibrate: Onset 28, Terminal 40, Recovery 22.                                                                                                          |
| 4    | **Runic Backlash**             | Meyers, C., et al. (2019), _Heterotopic Ossification: A Comprehensive Review_, Bone Res.                     | `https://pmc.ncbi.nlm.nih.gov/articles/PMC6400965/`<br>_(Archived in Vault)_                         | `meyers-2019-heterotopic-ossification-review.md`           | Used as the empirical analog for arcane petrification/stiffness: rapid pathobiological formation of mature lamellar bone within extra-skeletal soft tissues and muscles following neuro-electrical trauma. Causes joint stiffness and localized mobility restriction. Calibrate: Onset 50 (aligns with Severe 31–60 exemplar in line 30), Terminal 70, Recovery 55.                                                             |
| 5    | **Planar Distortion Shock**    | FAA (2020), _Spatial Disorientation: Why You Shouldn't Fly by the Seat of Your Pants_                        | `https://www.faa.gov/pilots/safety/pilotsafetybrochures/media/spatiald.pdf`<br>_(Archived in Vault)_ | `faa-2020-spatial-disorientation-vestibular-illusions.pdf` | Sudden perturbation of vestibular apparatus: conflict between semicircular canal endolymph momentum and otolith gravity sensing (Coriolis cross-coupling). Triggers acute vertigo, postural instability, nystagmus, spatial agnosia, and sympathetic cold sweating. Clears in 6–24 hours upon return to stable reference frame. Calibrate: Onset 68 (aligns with Critical 61–90 exemplar in line 31), Terminal 85, Recovery 35. |

---

### Work Package 8: Combat & Blast Trauma (`consequences-combat.md`)

- **Synthesis File:** [`design/research/synthesis/consequences-combat.md`](file:///home/tdimiduk/cardpg/cardpg/design/research/synthesis/consequences-combat.md)
- **Catalog Section:** `modeling_armor_weapons_combat` in `design/research/verisimilitude-sources.yaml`

| Item | Consequence Name            | Empirical Source & Author                                                                                     | URL / Ingestion Method & Status                                                  | Local Filename (Archived in Vault)                    | Quantitative Grounding & Calibration Guidance                                                                                                                                                                                                                                                                                                                                                                    |
| :--- | :-------------------------- | :------------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------- | :---------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | **Ringing Ears (Tinnitus)** | CDC / NIOSH (1998), _Criteria for a Recommended Standard: Occupational Noise Exposure_, Pub. 98-126           | `https://stacks.cdc.gov/view/cdc/5923/cdc_5923_DS1.pdf`<br>_(Archived in Vault)_ | `niosh-1998-occupational-noise-exposure-criteria.pdf` | Near-field blast overpressure and heavy metallic impacts on shields exceed 140–160 dB Peak Sound Pressure Level (SPL). Triggers mechanical shearing of cochlear stereocilia and metabolic exhaustion of hair cells, producing a Temporary Threshold Shift (TTS) and acute tinnitus. Resolves in 24–72 hours; acute non-escalating trauma. Calibrate: Onset 22, Terminal - (non-escalating), Recovery 18.         |
| 2    | **Stiff Neck**              | Panjabi, M. M., et al. / StatPearls (2023), _Cervical Acceleration-Deceleration (Whiplash) Injury_, NBK546644 | `https://www.ncbi.nlm.nih.gov/books/NBK546644/`<br>_(Archived in Vault)_         | `statpearls-2023-cervical-whiplash-biomechanics.md`   | Rapid cervical extension-flexion kinematic load from blunt shield, projectile, or helmet impacts. Produces myofascial micro-tearing of the sternocleidomastoid, trapezius, and splenius cervicis, as well as facet capsular ligament sprain. Muscle spasms intensify over 12–24h (Terminal 45); complete recovery requires 3–6 weeks of progressive mobilization. Calibrate: Onset 28, Terminal 45, Recovery 32. |

---

## 5. Standard Operating Procedure for Incoming Agents

For each batch in WP5–WP8, execute the following workflow:

### Step 1: Literature Availability Check

The 19 primary documents listed above are **already pre-harvested and committed** in `design/research/sources/verisimilitude/`. Verify file presence before making any network calls:

```bash
ls -lh design/research/sources/verisimilitude/<target-filename>
```

If a new or supplementary file is required, follow the Tier 1–Tier 5 harvest hierarchy using `curl -sL` or `trafilatura -u`.

### Step 2: Register in Source Catalog

Open [`design/research/verisimilitude-sources.yaml`](file:///home/tdimiduk/cardpg/cardpg/design/research/verisimilitude-sources.yaml). Append the new source entries under their respective sections with full schema (`type`, `title`, `author`, `year`, `doi_or_url`, `local_archive`, `epistemic_grade`, `description`, and `vetting` blocks).

### Step 3: Update Synthesis Database

Open the target consequence synthesis markdown file:

1. Replace all `_None_` placeholders in the target rows with local links:  
   `[Author (Year)](file:///home/tdimiduk/cardpg/cardpg/design/research/sources/verisimilitude/<filename>)`
2. Update the _Physiological / Factual Basis_ and _Realistic Healing_ columns with concrete empirical mechanisms and numbers.
3. Ensure Onset, Terminal, and Recovery Difficulty scores match the domain calibration brackets.
4. Ensure frontmatter lists `"design/research/verisimilitude-sources.yaml"` in `related_files`.
5. Update frontmatter epistemic status: `confidence: "high"`, `vetted_by_human: false`, and detailed `vetting_notes`.

### Step 4: Execute Automated Audit Gate

Run the strict audit script:

```bash
python3 tools/audit_index.py --strict
```

_The command must exit code 0 with `PASS: Index and frontmatter synchronization checks passed.`_

### Step 5: Commit Root Repository

Stage and commit root changes, handling the Prettier pre-commit hook if triggered:

```bash
git add design/research/verisimilitude-sources.yaml design/research/synthesis/<file>.md
git commit -m "feat(design): ground <domain> consequences in empirical literature (<Batch Name>)"
# If commit fails due to Prettier modifications, re-add and re-commit:
git add design/research/verisimilitude-sources.yaml design/research/synthesis/<file>.md
git commit -m "feat(design): ground <domain> consequences in empirical literature (<Batch Name>)"
```
