---
name: legacy_report_upgrade
description: Protocol for auditing, harvesting sources, synthesizing, and retiring legacy research reports in design/research/reports/.
---

# Legacy Research Report Upgrade & Retirement Workflow

Use this workflow to migrate legacy Gemini Deep Research reports in `design/research/reports/<slug>/` up to current project standards, grounding all durable conclusions in vaulted, machine-auditable primary literature and retiring superseded report directories to Git history.

---

## Core Principles

1. **Evidentiary Rigor:** Discard pop history, Reddit threads, Quora answers, commercial blogs, and YouTube shorts. Replace them with Tier 1/2 sources (peer-reviewed physiology/biomechanics, historical craft treatises, experimental archaeology) per [.agent/standards/empirical_research_standards.md](file:///.agent/standards/empirical_research_standards.md).
2. **Domain Purity (Zero Rules Bleed):** Syntheses in `design/research/synthesis/` document physical and biological reality only (forces, timescales, metabolic costs, failure curves). They must never prescribe card mechanics, card names, deck rules, or tabletop phases.
3. **Machine-Audited Quotes:** All empirical parameters in the resulting synthesis must be anchored using structured GFM footnotes with exact verbatim quotes and `status: unverified`, checked via `./scripts/audit-citations`.
4. **Epistemic Transparency (The Delta Review):** Never silently discard or change a parameter that rules might depend on. Explicitly document what held up, what shifted, what was discredited, and what game mechanics are impacted.
5. **Clean Working Tree:** Once all valid conclusions are captured in living syntheses and references repointed, the legacy report folder is deleted from the active working tree (`git rm -r`) so it lives strictly in Git history and cannot attract or confuse AI agents.

---

## Step 1: Claim & Source Triage (Audit)

Inspect `design/research/reports/<slug>/report.md` and its companion `prompt.md`.

1. **Catalog Extracted Claims:** List all discrete quantitative values, timescales, biomechanical claims, and conclusions presented in the report.
2. **Audit Supporting Citations:** Categorize each cited source against the Evidentiary Quality Hierarchy:
   - **Vault Candidates (Tier 1/2):** Genuine peer-reviewed papers, academic monographs, or clinical modules (e.g., Askew 2011, Jaquet 2015, IAAF kinematic studies).
   - **Qualified Practitioner Trials (Tier 4 / Gray Literature):** If academic literature is silent or sparse, assess passionate amateur tests (HEMA videos, warbow speed trials, traditional craft tests) against the **4-Filter Gray Literature Rubric**:
     1. _Primary Observation vs. Hearsay:_ Must show real physical measurement (high-speed camera, load cell, chronograph, timed sets).
     2. _Apparatus Authenticity:_ Authentic replicas and period technique (e.g., 100+ lb warbow, 3–4 lb sword), not recreational sporting toys or stage props.
     3. _Commercial / SEO Neutrality:_ Motivated by historical/martial inquiry, not sales/marketing (reject escape rooms, party venues, ad-driven listicles).
     4. _Methodological Transparency:_ Documents reps, conditions, and known limitations.
        If qualified, ingest into Track C (`sources/ephemera/` or `verisimilitude/`) with `--epistemic-grade practitioner_trial`.
   - **Disqualified / Junk:** Forum threads without raw trials (Reddit/Quora opinions), commercial SEO blogs (e.g., axe-throwing parlor marketing), unsourced wikis, or pop-history video essays.
   - **Unvetted Inferences:** Numerical estimates (often given confidence scores 1–5) that lack empirical support or generalize from a single anecdotal case.
   - **Zero-Evidence Rule:** If a claim only exists in disqualified sources and lacks Tier 1–4 backing, **never invent fake precision**. Convert it into a qualitative operational constraint or explicitly flag it as an open research gap.
3. **Check Existing Vault Coverage:** Inspect `design/research/verisimilitude-sources.yaml` and `design/research/sources/` to see if suitable literature is already archived locally.
4. **Define Acquisition Targets:** Identify specific Tier 1/2 open-access papers, treatises, or clinical studies needed to substantiate valid claims or replace disqualified sources.

---

## Step 2: Literature Harvesting & Vault Ingestion

For literature not yet in the local vault:

1. **Invoke `source_harvester`:**
   - Model: `flash`
   - Directives: Follow [.agent/skills/empirical_research_subagents/SKILL.md](file:///.agent/skills/empirical_research_subagents/SKILL.md).
   - **Prompt Hygiene (Domain Purity):** Never mention "CardPG", card mechanics, or tabletop rules in subagent prompts. Frame requests purely around physical or biological phenomena (e.g., _"Retrieve open-access studies on the kinematics and release velocity of historical throwing axes and javelins"_).
2. **Automated Ingestion:**
   Execute via CLI:
   ```bash
   python3 design/research/sources/scripts/archive_source.py ingest \
     --url "<url>" \
     --track verisimilitude \
     --slug <slug> \
     --section "<section>" \
     --epistemic-grade "<grade>" \
     --description "<summary>" \
     --register-catalog \
     --commit
   ```
3. **Extraction Verification:** Inspect the resulting `design/research/sources/verisimilitude/<slug>/extracted.txt` (or `.md`) to ensure clean text was captured (no paywall splashes or Cloudflare challenge pages).
4. **Human Escalation:** If a critical paper is behind a hard paywall or interactive gate, follow the escalation protocol in `empirical_research_standards.md` (check open preprints first, log in `DEFERRED_ACQUISITIONS.md` or request browser download if essential).

---

## Step 3: Synthesis Generation & Footnote Anchoring

1. **Target Document Identification:**
   - Check `design/research/synthesis/` to see if a matching living synthesis already exists (e.g., `combat-timelines-and-tempos.md`, `tactical-movement.md`).
   - If an existing synthesis contains unanchored tables copied from the legacy report, update it in place.
   - If no synthesis exists for this topic, create a new document in `design/research/synthesis/<topic>.md`.
2. **Quantitative Parameter Extraction:**
   - Delegate extraction to `empirical_synthesizer` (`Model: "flash"`, `enable_write_tools: false`) or draft inline if bounded.
   - Extract hard numbers (timescales in seconds, forces, Joules, metabolic costs in METs, failure kinetics).
   - Format into clean reference tables and physical taxonomies.
3. **Structured Claim Citations (GFM Footnotes):**
   Anchor all factual claims using extended GFM footnote YAML blocks:
   ```markdown
   [^slug-concept]:
       source: <exact-kebab-slug-in-sources>
       locator: "p. <num> / section <name>"
       quote: "<exact verbatim text from extracted.\*>"
       status: unverified
   ```
   _Invariant:_ Always set `status: unverified`. Never set `status: confirmed` or claim human vetting.
4. **Machine Verification:**
   Run the citation auditor to verify all verbatim quotes against primary vault text:
   ```bash
   ./scripts/audit-citations
   ```
   Fix any typographic or sequence mismatches until verification passes cleanly.

---

## Step 4: Epistemic Delta & Mechanics Impact Audit

Before retiring the legacy report, compile an **Epistemic Delta Report** presented directly to the user:

```markdown
### Epistemic Delta: <Legacy Report Title>

| Action / Parameter       | Legacy Report Claim (Source) | Verified Empirical Reality (Vault Quote)         | Status             | Active Design Impact                           |
| :----------------------- | :--------------------------- | :----------------------------------------------- | :----------------- | :--------------------------------------------- |
| **Example: Axe Throw**   | 1.5–2.5 s (Grab Axxes blog)  | 0.8–1.2 s delivery (Smith 2018, p. 4)            | Corrected (Faster) | Reduces action cost in Melee Phase from 2 to 1 |
| **Example: Knife Throw** | 0.29 s (Police Chief blog)   | Unsupported for combat draw; 1.0–1.4 s realistic | Discredited        | Closes 0-tempo interrupt loophole              |
```

Categories for the **Status** column:

- **Confirmed:** Supported by Tier 1/2 literature with minimal variance from legacy estimate.
- **Corrected:** Supported by Tier 1/2 literature, but with significant numerical or mechanical divergence.
- **Discredited / Unsupported:** Based entirely on SEO blogs, forum speculation, or gamified tropes with zero scientific backing.
- **Data Gap:** Literature could not be retrieved; logged as an open research gap.

Highlight any downstream effects on active card data (`data/cards/`), math baselines (`data/math-baseline.md`), or rules modules (`design/rules/`).

---

## Step 5: Repoint References & Retire Legacy Report

1. **Backlink Audit & Repointing:**
   Find every active file referencing the legacy report:
   ```bash
   git grep -n "reports/<slug>" design/
   ```
   Update each link:
   - In `design/research/synthesis/*.md`: Update `related_files` and inline links to point to the new/updated synthesis in `synthesis/`.
   - In `design/iteration/*.md` or `design/rules/*.md`: Repoint links to the new synthesis.
2. **Update Catalogs:**
   - In `design/research/index.yaml`: Remove the legacy report entry under `research_reports` or mark it as superseded. Ensure the updated synthesis document is fully registered.
   - In `design/research/README.md`: Remove the report from the active empirical reports table, or move its entry to a `Retired Reports (Superseded)` section referencing its git commit.
3. **Verify Index Integrity:**
   ```bash
   ./scripts/audit-index
   ```
4. **Retire Report to Git History:**
   Remove the legacy report directory from the repository working tree:
   ```bash
   git rm -r design/research/reports/<slug>
   ```
5. **Commit the Retirement:**
   ```bash
   git commit -m "research: retire legacy report <slug> to git history, superseded by synthesis/<topic>"
   ```
   Report the commit hash and summary of upgraded assets to the user.
