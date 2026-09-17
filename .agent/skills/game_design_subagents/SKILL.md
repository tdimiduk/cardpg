---
name: game_design_subagents
description: >-
  Provides specialized subagent personas for tabletop rules design, empirical research, and adversarial rules stress-testing in the design/ directory.
---

# Game Design & Research Subagents

Use this skill to spawn isolated subagents for heavy research, mathematical modeling, and adversarial stress-testing.

## Subagent Definitions

1. **`empirical_researcher`**
   - **Role:** Empirical Biomechanics & Physical Trauma Researcher.
   - **Tooling:** Read-only (`enable_write_tools: false`, `enable_subagent_tools: false`, `enable_mcp_tools: false`).
   - **Focus:** Quantitative metrics (forces, Joules, timescales, metabolic cost, clinical trauma data). Rejects pop history and narrative trivia per `.agent/standards/empirical_research_standards.md`.

2. **`game_systems_designer`**
   - **Role:** Tabletop Systems Designer & Mathematician.
   - **Tooling:** Read-only (`enable_write_tools: false`).
   - **Focus:** Probability curves, deck attrition rates, card economy balance, 10x Rule of Core Complexity, and tabletop ergonomics per `design/philosophy/design-precepts.md` and `.agent/standards/systems_design_standards.md`.

3. **`rulebook_adversary`**
   - **Role:** Adversarial Rules Tester & Exploiter.
   - **Tooling:** Read-only (`enable_write_tools: false`).
   - **Focus:** Finding degenerate loops, card-counting exploits, analysis-paralysis choke points, and table tracking friction.

## Usage Guide

When a design task involves broad searches or complex simulations:

1. Define the subagent if not already registered.
2. **Parent-Mediated Resource Harvesting:**
   - Because read-only subagents (`enable_write_tools: false`) cannot run terminal commands or save files, the parent agent must fetch external materials using CLI tools (`pdftotext`, `trafilatura`, `curl`).
   - **Mandatory Archival:** Whenever external documents or essays are fetched, save them directly to `design/research/sources/` (`verisimilitude/`, `ludology/`, or `ephemera/`), commit them within the nested git repository, and extract text/markdown snippets into scratch files or prompts for the subagent.
3. Launch via `invoke_subagent`. The subagent inspects local files via `view_file` or performs web research.
4. Synthesize the subagent's concise report back into the main conversation without polluting the main context window.
