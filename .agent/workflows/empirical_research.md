---
description: Empirical research workflow covering gap analysis, literature harvesting, quantitative synthesis, and verisimilitude auditing
---

# Empirical Research Workflow

This workflow guides all empirical research tasks across CardPG, connecting design requirements to the project's factual bedrock.

---

## 1. Context & Standards

Before executing, load the core standards:

- `view_file <workspace_root>/.agent/standards/standards.md`
- `view_file <workspace_root>/.agent/standards/empirical_research_standards.md`
- Check `design/research/sources/README.md` if operating on vault bundles.

---

## 2. Determine Mode from Request

| Mode               | Trigger Keywords                                                                | Subagent & Strategy                                                    | Behavior                                                                                                                                                             |
| :----------------- | :------------------------------------------------------------------------------ | :--------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`gap_analysis`** | "gap analysis", "assess gaps", "what are we missing", "research agenda"         | **Main Agent Direct Execution**                                        | Audit design requirements against `design/research/index.yaml` and catalogs. Isolate ungrounded assumptions and formulate quantitative research questions.           |
| **`harvest`**      | "find sources", "harvest", "archive paper", "ingest source", "look up research" | **Delegate to `source_harvester`** (`enable_write_tools: true`)        | Searches open-access repositories (Tier 1/2), executes `archive_source.py ingest --commit`, verifies extraction, and registers catalog YAML.                         |
| **`synthesize`**   | "synthesize", "extract metrics", "summarize research", "build synthesis"        | **Delegate to `empirical_synthesizer`** (`enable_write_tools: false`)  | Reads local `sources/<track>/<slug>/extracted.*` text files. Extracts hard numbers (METs, Joules, timescales, failure modes) and drafts structured reference tables. |
| **`audit`**        | "fact check", "audit verisimilitude", "is this realistic", "check rules"        | **Delegate to `verisimilitude_auditor`** (`enable_write_tools: false`) | Cross-examines proposed mechanics against `design/research/synthesis/`. Flags Gross Violations vs. Casual Realism stylization.                                       |

---

## 3. Execution Procedures

### Mode: `gap_analysis` (Main Agent)

1. **Scope the Subsystem:** Identify the physical interactions, materials, or environmental hardships involved in the active mechanic or module.
2. **Catalog Audit:** Check `design/research/verisimilitude-sources.yaml`, `design/research/ludology-sources.yaml`, and `design/research/synthesis/` for existing coverage.
3. **Formulate Questions:** Output a structured research agenda defining:
   - Primary physical phenomenon (e.g. cold-water immersion, rock spalling, draft horse pull limits)
   - Specific quantitative metrics needed (Joules, failure curves, recovery duration, metabolic cost in METs)
   - Target source types (Tier 1 primary manual, experimental archaeology, or Tier 2 clinical/extension bulletin).

### Mode: `harvest` (Subagent: `source_harvester`)

1. Define and invoke `source_harvester` via `invoke_subagent` (`enable_write_tools: true`).
2. The subagent follows the 5-tier open-access hierarchy (Internet Archive, land-grant Extension bulletins, CDC/NIOSH, StatPearls, PMC).
3. The subagent runs:
   ```bash
   python3 design/research/sources/scripts/archive_source.py ingest \
     --url "<url>" \
     --track <verisimilitude|ludology|ephemera> \
     --slug <author-year-topic> \
     --section <target_section> \
     --epistemic-grade <grade> \
     --description "<summary of empirical data>" \
     --register-catalog \
     --commit
   ```
4. Subagent verifies `extracted.txt` / `extracted.md` via `view_file` to ensure non-empty text extraction, confirms catalog registration output, and reports back.
5. If the document is blocked by an interactive CAPTCHA or commercial paywall, escalate per the Human-in-the-Loop Sourcing Escalation Protocol.

### Mode: `synthesize` (Subagent: `empirical_synthesizer`)

1. Define and invoke `empirical_synthesizer` via `invoke_subagent` (`enable_write_tools: false`).
2. Pass the path to the vaulted bundle text (e.g. `design/research/sources/verisimilitude/<slug>/extracted.txt`).
3. Subagent reads the source text, extracts quantitative parameters, and returns a draft synthesis.
4. **Parent Ingestion:** The parent agent reviews the output and integrates it into a living document in `design/research/synthesis/<topic>.md` (or a point-in-time report under `design/research/reports/<slug>/`).
5. Ensure epistemic frontmatter is complete (`origin`, `doc_type`, `epistemic_status`, `vetted_by_human: false`).

### Mode: `audit` (Subagent: `verisimilitude_auditor`)

1. Define and invoke `verisimilitude_auditor` via `invoke_subagent` (`enable_write_tools: false`).
2. Provide the draft rules or card text, along with pointers to relevant syntheses in `design/research/synthesis/`.
3. Subagent applies the Rubric from `.agent/standards/empirical_research_standards.md`:
   - **Gross Violations:** Inverted physics/biology, pop-history tropes, zero-consequence severe hardship, scale/timeline incoherence.
   - **Casual Realism:** Valid discrete quantization, tabletop card compression, heroic dynamic range.
4. Subagent returns an objective audit report recommending adjustments to harmonize mechanics with reality without sacrificing playability.

---

## 4. Human Escalation Boundary

When a needed source cannot be obtained automatically:

- **Web UI Gate / CAPTCHA:** Request that the user download the file via browser and ingest with `archive_source.py ingest --file ... --commit`.
- **Paywall:** Check for open-access preprints/reviews first. If none exist and the document is foundational, log to `design/research/sources/DEFERRED_ACQUISITIONS.md` or request institutional library retrieval as a last resort.
