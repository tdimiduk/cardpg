# Empirical Research Standards

This document defines the quantitative research standards for establishing the "Factual Bedrock" of CardPG. All research reports, prompt definitions, and verisimilitude database entries must adhere to these guidelines to ensure that gameplay mechanics are grounded in objective reality.

---

## 1. Core Objective

The central directive of CardPG research is **Tangible Materiality**. Research must focus on the observable cause-and-effect relationship of physical stress, biomechanics, and environmental forces on the human body and objects.

---

## 2. Vetting and Analysis Criteria

To maintain professional scientific rigor, all harvested data and sources must be vetted against the following criteria:

### A. Prioritization of Quantitative Metrics

Research must focus on empirical, functional metrics:

- **Forces:** Joules, impact velocity, shear stress.
- **Physiological Costs:** Calories, metabolic expenditure, aerobic vs. anaerobic fatigue thresholds.
- **Timescales:** Time in seconds for physical movements, combat recovery times, trauma onset curves.
- **Material Properties:** Tensile strength, weight in kilograms, thickness in millimeters.

### B. Rejection of Abstract Trivia

Research must actively screen out subjective, anecdotal, or non-functional information, including:

- Narrative and mythological lineages.
- Symbolism, heraldry, and cultural folklore.
- Pure historical dates or lineage listings that do not explain _what happens to a physical body or object under stress_.

### C. observational Rigor

Source vetting must distinguish between high-quality academic research (e.g., experimental archaeology, biomechanical journals, clinical trauma databases) and popular history or gamified tropes.

---

## 3. Standard Research Artifact Formats

All research outputs must utilize one of the standard formats:

1. **Research Report (`report.md`):** A clinical, objective, and academic review summarizing raw historical or physiological data with clear source citations. Stored under `design/research/reports/` as immutable point-in-time harvesting runs.
2. **Living Research Synthesis (`synthesis/*.md`):** Actionable design frameworks and consequence databases (e.g., `armor.md`, `consequences-combat.md`) translating empirical data into practical gameplay reference tables. Updated in place with epistemic frontmatter.
3. **Literature Note (`theory/readings/*.md`):** Structural, analytical notes on secondary game design theory essays, post-mortems, and critical analyses (e.g., `exploration-is-logistics.md`), analyzing how external mechanics work and adapting their insights to CardPG's card economy.
4. **Deep Research Prompt (`prompt.md`):** A highly specific, quantitative set of instructions and focus questions designed for harvesting empirical data on a new topic.
5. **Source Database Entry (`YAML`):** A structured entry under `design/research/` detailing vetted publications with descriptive metadata and rigorous verisimilitude scores (e.g., `verisimilitude-sources.yaml`) or game design theory touchstones.

---

## 4. Literature Sourcing, Ingestion Hierarchy & Human Escalation

When seeking empirical grounding for consequences, mechanisms, and physiological thresholds, researchers and AI agents must follow this verified retrieval hierarchy to maximize access while avoiding CLI bot-detection blocks:

### A. Automated Ingestion Hierarchy (Open-Access Tiers)

1. **Internet Archive (`archive.org`):**
   - Direct PDF curl: `curl -sL "https://archive.org/download/<id>/<id>.pdf" -o ...`
   - Unchallenged public-domain access for historical craft treatises, early engineering manuals, and legal history (e.g., Pollock & Maitland).
2. **University Agricultural & Veterinary Extension Bulletins:**
   - Bulletins from land-grant universities (Purdue, UMN, NDSU, TAMU, Penn State, Iowa State) are open access and easily ingested via `curl` (PDF) or `trafilatura -u` (HTML).
   - Ideal for toxicology, crop/grain pathology, feed spoilage, and animal husbandry.
3. **Federal Repositories & Government Standards (CDC Stacks, FDA, USDA ARS, NIOSH, OSHA):**
   - CDC Stacks (`stacks.cdc.gov`) provides direct PDF downloads of NIOSH occupational health monographs (e.g., NIOSH Pub. 97-141).
   - FDA and USDA technical inspection guides extract cleanly via `trafilatura -u`.
4. **NCBI Bookshelf (StatPearls & NLM Books):**
   - Extract full-text clinical modules via `trafilatura -u "https://www.ncbi.nlm.nih.gov/books/NBK<ID>/"`.
   - Comprehensive for clinical wound healing, thermal burns, amputation stump closure, psychiatric emergency panic management, and ocular photokeratitis.
5. **PubMed Central (PMC):**
   - Extract full-text open-access studies and reviews via `trafilatura -u "https://pmc.ncbi.nlm.nih.gov/articles/PMC<ID>/"`.
   - **Crucial Rule:** Never attempt to curl binary PDFs from PMC directly via CLI, as PMC redirects binary PDF requests to an HTML splash/challenge page.

### B. Anti-Patterns & Gate Avoidance
- **Never curl commercial academic publishers directly:** Elsevier (ScienceDirect), SpringerLink, Wiley, MDPI, and Taylor & Francis actively block automated CLI user-agents (`curl`, `urllib`, `requests`) with HTTP 403 or Cloudflare/Akamai bot challenges.
- **Do not burn tokens looping on blocked CLI requests:** If a direct curl fails with a 403 or CAPTCHA, switch immediately to an open-access equivalent or invoke the human escalation protocol.

### C. Human-in-the-Loop Sourcing Escalation Protocol

Agents are fully empowered to request human assistance when acquiring vital research documents, following these boundaries:

1. **Web UI Access (Gate / CAPTCHA Bypass):**
   - If a specific, high-value document is public or open-access but guarded by an interactive web UI gate (e.g., Cloudflare verification, interactive CAPTCHA, or complex download forms that defeat CLI tools), **the agent should ask the human to download the file**.
   - The human can retrieve the file via a desktop browser and place it directly into `design/research/sources/verisimilitude/` (or `ludology/`).
   - *Scale Guideline:* This is intended for specific, targeted documents that unlock key empirical verifications—not for bulk harvesting hundreds of files.
2. **Institutional Library Access (Paywall Retrieval — Last Resort):**
   - The human has institutional library access that can penetrate academic paywalls.
   - *Constraint:* Because library retrieval is manual and high-friction, it is strictly a **last resort**. Agents must first exhaust open-access preprints, PMC reviews, government reports, and extension literature. Only request library retrieval if no adequate open-access substitute exists for a foundational factual requirement.

