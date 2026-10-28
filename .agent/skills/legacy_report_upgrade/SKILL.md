---
name: legacy_report_upgrade
description: Protocol for auditing, harvesting sources in bounded batches, synthesizing, and retiring legacy research reports in design/research/reports/.
---

# Legacy Research Report Upgrade & Retirement Workflow

Use this workflow to migrate legacy Gemini Deep Research reports in `design/research/reports/<slug>/` up to current project standards, grounding all durable conclusions in vaulted, machine-auditable primary literature and retiring superseded report directories to Git history.

To protect context tokens, prevent hallucination, and preserve prompt adherence, **this workflow is strictly chunked**: work proceeds in small batches of 1–2 sources at a time, uses subagents for context isolation, summarizes discoveries after each batch, and checkpoints progress via `scratch/distill/` so work can span clean threads.

---

## Core Principles

1. **Evidentiary Rigor:** Discard pop history, Reddit threads, Quora answers, commercial blogs, and YouTube shorts. Replace them with Tier 1/2 sources (peer-reviewed physiology/biomechanics, historical craft treatises, experimental archaeology) or qualified Tier 4 practitioner trials per [empirical_research_standards.md](file:///.agent/standards/empirical_research_standards.md).
2. **Context Window Protection via Bounded Chunks:** Never attempt an open-ended, monolithic migration in a single thread. Break acquisitions into small batches of **1–2 (max 3) sources**.
3. **Subagent Context Isolation:** Never load multi-thousand-token raw texts (`extracted.txt` / `extracted.md`) into the parent context. Offload literature harvesting to `source_harvester` and quantitative parameter/quote extraction to `empirical_synthesizer` (`Model: "flash"`). The parent agent receives only compact candidate tables and footnote blocks.
4. **Periodic Summaries & Distillation Gates:** After each chunk, stop, summarize the empirical discoveries and claim deltas, update the implementation plan in `scratch/distill/`, and offer the user an explicit gate to `/distill` and continue in a fresh thread via `/rehydrate`.
5. **Domain Purity (Zero Rules Bleed):** Syntheses in `design/research/synthesis/` document physical and biological reality only (forces, timescales, metabolic costs, failure curves). They must never prescribe card mechanics, card names, deck rules, or tabletop phases.
6. **Machine-Audited Quotes:** All empirical parameters in the resulting synthesis must be anchored using structured GFM footnotes with exact verbatim quotes and `status: unverified`, checked via `./scripts/audit-citations`.
7. **Epistemic Transparency (The Delta Review):** Never silently discard or change a parameter that rules might depend on. Explicitly document what held up, what shifted, what was discredited, and what game mechanics are impacted.
8. **Clean Working Tree:** Once all valid conclusions are captured in living syntheses and references repointed, the legacy report folder is deleted from the active working tree (`git rm -r`) so it lives strictly in Git history and cannot attract or confuse AI agents.

---

## Phase 0: Claim Triage, Batching & Phased Plan Setup

Before fetching any literature, inspect `design/research/reports/<slug>/report.md` and its companion `prompt.md`.

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
4. **Partition Acquisition Targets into Bounded Batches:**
   Group missing literature and related claims into discrete batches of **1–2 (at most 3) sources**:
   - _Batch 1:_ e.g., Weapon release velocities & flight kinematics (1–2 papers).
   - _Batch 2:_ e.g., Draw / retrieval latencies & body mechanics (1–2 papers).
   - _Batch 3:_ e.g., Target impact and penetration forces (1–2 papers).
5. **Initialize Phased Implementation Plan (`scratch/distill/plan-<slug>-upgrade.md`):**
   Format per [distill SKILL.md](file:///.agent/skills/distill/SKILL.md) Profile B:

   ```markdown
   # Implementation Plan: Upgrade Legacy Report <slug>

   ## 1. Architectural Decisions & Scope

   - Target Synthesis: `design/research/synthesis/<topic>.md`
   - Legacy Report: `design/research/reports/<slug>/`
   - Living Catalogs: `design/research/verisimilitude-sources.yaml`, `design/research/index.yaml`

   ## 2. Execution Threads

   ### Thread 1: Batch 1 (<Claim / Literature Focus>)

   **Scope:** Ingest 1–2 sources on <topic>, synthesize parameters, anchor GFM citations.

   1. Harvest: <Target paper or phenomenon> via `source_harvester`
   2. Synthesize: Extract metrics into `synthesis/<topic>.md` via `empirical_synthesizer`
   3. Verify: `./scripts/audit-citations`
   4. Checkpoint: Summarize learnings & deltas

   ### Thread 2: Batch 2 (<Claim / Literature Focus>)

   ...

   ### Thread N: Epistemic Delta, Link Repointing & Retirement

   **Scope:** Final delta review, backlink updates, index update, `git rm` legacy report.

   1. Compile Epistemic Delta table and active game mechanics impacts.
   2. Repoint all backlinks (`git grep -n "reports/<slug>"`).
   3. Update `design/research/index.yaml` and `design/research/README.md`.
   4. `./scripts/audit-index`
   5. `git rm -r design/research/reports/<slug>` and commit.

   ## 3. Verification Plan

   - `./scripts/audit-citations`
   - `./scripts/audit-index`
   ```

   Commit the plan to the scratch repo:

   ```bash
   mkdir -p scratch/distill
   [ -d scratch/distill/.git ] || git -C scratch/distill init
   git -C scratch/distill add scratch/distill/plan-<slug>-upgrade.md
   git -C scratch/distill commit -m "distill: plan upgrade for legacy report <slug>"
   ```

6. **Align with User:** Present the triage summary and proposed batch plan before launching Batch 1.

---

## Phase 1: Bounded Chunk Execution Loop (1–2 Sources per Cycle)

Execute strictly one batch at a time. Never launch multiple batches in parallel or pull forward work from future threads.

### 1. Literature Harvesting via `source_harvester`

- **Subagent:** `source_harvester` (`Model: "flash"`, `enable_write_tools: true`) following [empirical_research_subagents/SKILL.md](file:///.agent/skills/empirical_research_subagents/SKILL.md).
- **Prompt Hygiene (Domain Purity):** Never mention "CardPG", card mechanics, or tabletop rules in the subagent prompt. Frame the prompt purely around the physical phenomenon:
  > _"Retrieve and archive open-access studies on the kinematics and release velocity of historical throwing axes and javelins. Ingest via archive_source.py with --register-catalog --commit, verify clean extraction in extracted.txt, and return the slug, URL, and verification status."_
- **Ingestion Execution (Subagent):**
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
- **Context Isolation:** The subagent verifies clean extraction internally via `view_file` on `extracted.txt` and replies with a concise status report. The parent agent does **not** read `extracted.txt` into the main conversation.

### 2. Quantitative Extraction via `empirical_synthesizer`

- **Subagent:** `empirical_synthesizer` (`Model: "flash"`, `enable_write_tools: false`).
- **Input:** Path to vaulted bundle text (e.g. `design/research/sources/verisimilitude/<slug>/extracted.txt`).
- **Prompt:** Instruct the subagent to extract specific quantitative metrics (timescales in seconds, forces, Joules, METs) and draft:
  1. A structured reference table row or physical taxonomy.
  2. Extended GFM footnotes with exact verbatim quotes and `status: unverified`:
     ```markdown
     [^slug-concept]:
         source: <slug>
         locator: "p. <num> / section <name>"
         quote: "<exact verbatim text from extracted.\*>"
         status: unverified
     ```
- **Context Isolation:** All raw text processing stays within the subagent's isolated context.

### 3. Parent Ingestion & Target Synthesis Update

- Inspect existing living synthesis in `design/research/synthesis/<topic>.md` (or create if new).
- Integrate the subagent's structured table rows and GFM footnote blocks.
- **Epistemic Invariant:** Ensure `vetted_by_human: false` on substantial edits and keep all footnote statuses as `status: unverified`. Never claim human vetting.

### 4. Machine Citation Verification

Run the citation audit tool immediately:

```bash
./scripts/audit-citations
```

Fix any quote punctuation, ellipsis, or sequence mismatches until verification passes cleanly before concluding the chunk.

---

## Phase 2: Checkpoint, Learnings Summary & Distillation Gate

Once the batch is ingested, synthesized, and verified:

### 1. Present Chunk Learnings & Delta Summary

Present a clear, focused update to the user:

- **Empirical Learnings:** Key quantitative metrics, physiological realities, or material limits discovered in this batch.
- **Batch Delta:**
  - Which legacy claims were **Confirmed** (aligned with Tier 1/2 literature).
  - Which legacy claims were **Corrected** (literature diverges from legacy estimate).
  - Which legacy claims were **Discredited** (debunked blogs or pop tropes).
  - Any **Data Gaps** remaining for this sub-topic.
- **Rules Implications:** Proactively flag if a corrected or discredited value impacts an active rule, card baseline, or math document.

### 2. Update Phased Plan (`scratch/distill/plan-<slug>-upgrade.md`)

- Remove or mark the completed batch in `scratch/distill/plan-<slug>-upgrade.md`.
- Fold any newly discovered constraints, source slugs, or file anchors into upcoming thread descriptions per [distill SKILL.md](file:///.agent/skills/distill/SKILL.md).
- Commit updates to `scratch/distill/`.

### 3. The Distillation Gate (Pause & Offer Thread Handover)

**Stop tool execution.** Do not begin the next batch automatically.

Provide the user with an explicit choice:

- **Option A: Distill & Start Fresh Thread (Recommended if session is $\ge 2$ batches or context is growing):**
  Guide the user:
  > _"We have completed Batch [K] ([Topic]). I have checkpointed our progress in `scratch/distill/plan-<slug>-upgrade.md`. You can use `/distill` to refine context, then start a fresh thread and run `/rehydrate plan-<slug>-upgrade.md` to tackle Batch [K+1] with a clean context window."_
- **Option B: Continue in Current Thread:**
  If the user prefers to keep rolling in the same session, proceed to the next batch.

---

## Phase 3: Final Epistemic Delta, Link Repointing & Retirement

Only execute this phase after all source batches in the plan have been harvested, synthesized, and verified.

### 1. Epistemic Delta Report

Compile and present the complete Epistemic Delta table across all claims in the legacy report:

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

Highlight downstream effects on active card data (`data/cards/`), math baselines (`data/math-baseline.md`), or rules modules (`design/rules/`).

### 2. Backlink Audit & Repointing

Find every active file referencing the legacy report:

```bash
git grep -n "reports/<slug>" design/
```

Update each link:

- In `design/research/synthesis/*.md`: Update `related_files` and inline links to point to the new/updated living synthesis.
- In `design/iteration/*.md` or `design/rules/*.md`: Repoint links to the living synthesis.

### 3. Update Catalogs & Verify Index

- In `design/research/index.yaml`: Remove the legacy report entry under `research_reports` or mark it superseded. Ensure the living synthesis is fully registered.
- In `design/research/README.md`: Remove the report from the active empirical reports table, or move to `Retired Reports (Superseded)`.
- Verify catalog integrity:
  ```bash
  ./scripts/audit-index
  ```

### 4. Retire Report to Git History

Remove the legacy directory from the working tree and commit:

```bash
git rm -r design/research/reports/<slug>
git commit -m "research: retire legacy report <slug> to git history, superseded by synthesis/<topic>"
```

### 5. Retire Distillation Plan

Check if `scratch/distill/plan-<slug>-upgrade.md` has any remaining tasks. If fully finished:

```bash
git -C scratch/distill rm plan-<slug>-upgrade.md
git -C scratch/distill commit -m "distill: retire completed plan for <slug>"
```

Report the final commit hash and summary of upgraded assets to the user.
