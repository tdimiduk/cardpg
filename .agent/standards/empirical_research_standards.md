# Empirical Research Standards

This document defines the quantitative research standards for establishing the "Factual Bedrock" of CardPG. All research reports, prompt definitions, source vault bundles, and verisimilitude database entries must adhere to these guidelines to ensure that gameplay mechanics are grounded in objective reality.

---

## 1. Core Objective & Scope

The central directive of CardPG research is **Tangible Materiality**. Research must focus on the observable cause-and-effect relationship of physical stress, biomechanics, material properties, and environmental forces on the human body, objects, and ecosystems.

### Comprehensive Domain Scope

Research is not limited to combat trauma. It establishes the factual grounding across all game subsystems:

- **Biomechanical & Trauma:** Impact forces, hemorrhage and hypoxia timelines, metabolic costs (METs), fatigue onset, wound pathology, cold-water immersion kinetics.
- **Material Science & Craft Engineering:** Metallurgy, tensile limits, friction, wear patterns, traditional craft manuals (wheelwrighting, ropemaking, leather/harness making, masonry, mining).
- **Environmental & Industrial Physics/Chemistry:** Subterranean atmospheres (blackdamp, firedamp), acoustics and transmission, corrosion, electrical hazards, thermal exposure, toxicity.
- **Agriculture, Pathology & Veterinary Science:** Food preservation/water activity, grain/feed spoilage, pack animal pathology, biological vectors.
- **Cognitive & Neurological Stress:** Sensory disorientation (vestibular illusions), sustained vigilance degradation, acute panic physiology, acoustic trauma/tinnitus, social stress/trust dynamics.
- **Ludological Grounding (Track B):** Structural game design theory, resource logistics, post-mortems, and player dynamics.

---

## 2. Evidentiary Quality Hierarchy

All literature and data must be vetted against this strict hierarchy to prevent gamified tropes and pop-history from corrupting the design baseline:

### Tier 1: Grounded Empirical & Direct Observation (Highest Authority)

- **Primary Craft Manuals & Historical Treatises:** Authentic period technical texts detailing direct workshop or field techniques (e.g., Sturt's _Wheelwright's Shop_, Chapman's _Ropemaking_, Pollock & Maitland's legal history, historical fechtbücher for martial technique and tempo).
- **Experimental Archaeology, Ballistics & Metallurgy:** Rigorous empirical testing on historical replicas and materials under controlled scientific conditions (e.g., Alan Williams' _The Knight and the Blast Furnace_, modern armoring impact trials).
- **Clinical Medicine, Emergency Pathology & Physiology:** Peer-reviewed medical literature, clinical reference modules, and experimental human trials (e.g., StatPearls, Haldane's mine toxicology, modern sports physiology, hypothermia immersion protocols).

### Tier 2: Technical Secondary & Government Literature (High Authority)

- **University Agricultural & Veterinary Extension Bulletins:** Land-grant university research (Purdue, UMN, NDSU, TAMU, Penn State, Iowa State) providing verified data on toxicology, grain rot, animal illness, and soil/weather degradation.
- **Government Standards & Occupational Health Monographs:** NIOSH monographs, CDC Stacks, OSHA standards, FDA technical inspection guides, FAA flight physiology bulletins.
- **Peer-Reviewed Historical & Ludological Scholarship:** Academic papers in history, archaeology, or formal game design analysis (e.g., _Journal of Medieval History_, MDA framework papers).

### Tier 3: Contextual Secondary Literature (Use with Caution)

- **General Non-Fiction & Modern Overviews:** High-level history books or engineering overviews. Any concrete mechanical claim taken from Tier 3 must be traced back to its Tier 1 or Tier 2 citations.

### Disqualified Literature (Strictly Rejected)

- **Tabletop RPG Tropes & Gamified Conventions:** "Studded leather armor," 10 lb swords, instantaneous recovery, hit point bloat, or treating rapiers as flimsy fencing foils.
- **Pop-History Internet Summaries & Unsourced Wikis:** Unverified blog posts, YouTube video essays, and Wikipedia articles that synthesize unvetted folklore.
- **Abstract Narrative Trivia:** Purely chronological timelines, dynastic genealogies, symbolic heraldry, or mythological folklore that do not explain what happens to a physical body, object, or system under stress.

---

## 3. Literature Sourcing, Vault Archival & Ingestion Protocol

When seeking empirical grounding, agents follow a local-first retrieval hierarchy and archive discovered sources into the project vault:

### A. Local-First Invariant

Before querying external search engines or downloading remote files, agents must always inspect existing local assets:

1. Check `design/research/verisimilitude-sources.yaml` and `design/research/ludology-sources.yaml`.
2. Inspect derived text files in `design/research/sources/<track>/<slug>/extracted.*` using `view_file`.
3. If an archived source covers the question, cite it directly.

### B. Automated Ingestion Hierarchy (Open-Access Tiers)

When acquiring new literature, prioritize automated access through open repositories:

1. **Internet Archive (`archive.org`):** Direct PDF downloads for public-domain historical manuals, early craft treatises, and legal history.
2. **University Agricultural & Veterinary Extension Bulletins:** Open-access PDFs via `curl` or HTML via `trafilatura -u`.
3. **Federal Repositories (CDC Stacks, FDA, USDA, NIOSH, FAA):** Direct PDF downloads of government monographs and technical inspection guides.
4. **NCBI Bookshelf (StatPearls & NLM Books):** Full-text clinical modules extracted via `trafilatura -u "https://www.ncbi.nlm.nih.gov/books/NBK<ID>/"`.
5. **PubMed Central (PMC):** Open-access peer-reviewed studies extracted via `trafilatura -u "https://pmc.ncbi.nlm.nih.gov/articles/PMC<ID>/"`. _(Never curl binary PDFs from PMC directly via CLI due to HTML splash challenges)._

### C. Gate Avoidance & Anti-Patterns

- **Never curl commercial academic publishers directly:** Elsevier (ScienceDirect), SpringerLink, Wiley, MDPI, and Taylor & Francis actively block automated CLI user-agents (`curl`, `urllib`, `requests`) with HTTP 403 or Cloudflare/Akamai bot challenges.
- **Do not burn tokens looping on blocked requests:** If a direct fetch fails with a 403 or CAPTCHA, switch immediately to an open-access equivalent or invoke the human escalation protocol.

### D. Vault Purity Standard

- The `design/research/sources/` directory is an independent git repository strictly reserved for **direct, authentic scrapes and deterministic extractions** (`metadata.yaml`, `source.<ext>`, `extracted.<ext>`).
- **Zero AI Commentary in Sources:** Never place AI-authored notes, summaries, or interpretations inside `sources/`.
- All ingestion must be performed via the canonical script:
  ```bash
  python3 design/research/sources/scripts/archive_source.py ingest \
    --url "<url>" \
    --track <verisimilitude|ludology|ephemera> \
    --slug <author-year-topic> \
    --commit
  ```

### E. Human-in-the-Loop Sourcing Escalation Protocol

1. **Web UI Access (Gate / CAPTCHA Bypass):**
   - If a specific, high-value document is public or open-access but guarded by an interactive web gate (Cloudflare, CAPTCHA, or complex download form), **the agent asks the human to download the file via desktop browser**.
   - The human retrieves the file and ingests it via `archive_source.py ingest --file <path> --slug <slug> --commit`.
2. **Institutional Library Access (Paywall Retrieval — Last Resort):**
   - The human has institutional library access that can penetrate academic paywalls.
   - _Constraint:_ This is strictly a **last resort**. Agents must first exhaust open-access preprints, PMC reviews, government reports, and extension literature. If deferred, log the item in `design/research/sources/DEFERRED_ACQUISITIONS.md`.

---

## 4. Standard Research Artifact Formats

1. **Source Vault Bundle (`design/research/sources/<track>/<slug>/`):** Authentic capture and deterministic text extraction (`metadata.yaml`, `source.<ext>`, `extracted.<ext>`).
2. **Source Database Entry (`verisimilitude-sources.yaml` / `ludology-sources.yaml`):** Structured catalog entry with bibliographic metadata, `local_archive` pointer, `epistemic_grade`, and vetting summary.
3. **Living Research Synthesis (`design/research/synthesis/*.md`):** Updated in place with epistemic frontmatter. Translates empirical metrics into game-ready reference tables, failure modes, and MET costs.
4. **Research Report (`design/research/reports/<slug>/`):** Immutable point-in-time harvesting runs for major standalone research mandates (`prompt.md`, `meta.yaml`, `report.md`).
5. **Literature Note (`design/research/theory/readings/*.md`):** Analytical notes deconstructing external game design essays and adapting their insights to CardPG.

---

## 5. Research Gap Assessment Protocol

Before designing a new rule, subsystem, or module, agents assess whether the system has adequate factual bedrock:

1. **Inventory Operational Assumptions:** What physical interactions, materials, environmental stresses, or physiological limits does this mechanic touch?
2. **Cross-Reference Existing Vault:** Scan `design/research/index.yaml` and `verisimilitude-sources.yaml`. Does an existing synthesis or vaulted source supply empirical numbers?
3. **Isolate Factual Gaps:** Formulate precise, quantitative research questions:
   - What are the physical thresholds? (e.g., at what temperature does hypothermia impair dexterity?)
   - What are the timescales? (e.g., how long does it take for a draft horse to recover from muscle strain?)
   - What are the energetic/material costs? (e.g., how many METs does ascending a 45-degree talus slope consume?)
4. **Trigger Sourcing:** If gaps exist, dispatch `source_harvester` or consult the parent agent before finalizing mechanical values.

---

## 6. Verisimilitude Audit Rubric: Gross Violations vs. Casual Realism

When auditing game mechanics, cards, or rules modules, agents must distinguish between unacceptable factual falsehoods and intentional, playability-focused abstractions:

### Gross Violations (Must Be Flagged & Corrected)

1. **Inverted Physics or Physiology:** Rules where physical cause-and-effect operates backwards (e.g., heavy armor causing instant drowning without struggle, bludgeoning plate armor with an unaugmented sword edge causing crushing trauma without half-swording, or falling 30 feet onto stone being shaken off in one round with zero consequence).
2. **Gamified / Pop-History Tropes:** Mechanics perpetuating Hollywood or RPG myths (e.g., studded leather armor, 10 lb greatswords, swords slicing through iron maille, daggers penetrating solid breastplates, or treating torches as lasting 1 hour in stagnant blackdamp).
3. **Zero-Consequence Hardship:** High-strain activities (e.g., forced marching 14 hours in freezing sleet, sprinting in full armor, or performing continuous heavy labor while dehydrated) having no cumulative metabolic or cognitive fatigue consequence.
4. **Scale & Timeline Incoherence:** Long-term physiological processes happening instantaneously (e.g., healing a fractured femur in 8 hours of sleep, or forging a steel axe in 20 minutes without fuel).

### Casual Realism / Conscious Stylization (Accepted & Encouraged)

1. **Discrete Quantization:** Abstracting continuous real-world spectrums into discrete tabletop buckets (e.g., grouping weapon reach into Close / Melee / Reach bands; grouping temperatures into Temperate / Cold / Extreme Cold).
2. **Tactile Tabletop Compression:** Modeling complex biochemical or metabolic systems with intuitive physical card mechanics (e.g., paying physical exertion via card discards or taking Fatigue cards into the deck rather than tracking individual kilocalories).
3. **Defender-Centric Pacing:** Abstracting multi-second duel exchanges into crisp simultaneous card plays to preserve tabletop tension and agency.
4. **Heroic Dynamic Range:** Allowing protagonists to endure and overcome severe physical hardship at the upper limits of real human athletic and mental endurance, without reducing the game to a monotone grimdark death spiral.
