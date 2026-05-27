---
description: Research tasks focusing on physiological and physical facts (design prompts, synthesize topics, vet sources)
---

# Research Workflow

This unified workflow handles all research tasks. The user's prompt determines the mode.

## Delegating to Subagent

- **`research_analyst`**: For deep scientific or physiological fact-finding, vetting academic/historical texts, or drafting research prompts, delegate to the `research_analyst` subagent (Lead Technical Researcher) to maintain academic focus and quantitative rigor in a separate research sandbox.

## 1. Load Context

- `view_file /home/tdimiduk/cardpg/cardpg/design/ai/common/standards.md`
- `view_file /home/tdimiduk/cardpg/cardpg/design/ai/common/empirical_research_standards.md`

Adhere to the **Lead Technical Researcher** guidelines and principles.

## 2. Determine Mode from User Request

| Mode              | Trigger Keywords                                      | Behavior                                                                                                                                                            |
| ----------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Design Prompt** | "research prompt", "deep research", "set up research" | Draft a detailed prompt for Deep Research tool. Focus on quantitative data. Create directory at `design/research/reports/<slug>/` with `prompt.md` and `meta.yaml`. |
| **Synthesize**    | "synthesize", "summarize research", "what do we know" | Cross-reference existing reports in `design/research/`. Highlight Physical Constraints and Physiological Limits. Reject abstract trivia.                            |
| **Vet Source**    | "vet", "evaluate source", "is this good"              | Critique source for Tangible Materiality. Good = physics/biology/mechanics. Bad = mythology/lineage/symbolism. Output Material Analysis + Database Entry YAML.      |

## 3. Execute Per Mode

### Design Prompt Mode

1. Slugify topic → directory name
2. Create `design/research/reports/<slug>/`
3. Write `prompt.md` with research questions focusing on numbers, timelines, physical consequences
4. Write `meta.yaml` with date and tool info

### Synthesize Mode

1. Scan `design/research/synthesis/` and `design/research/reports/`
2. Extract hard constraints
3. Output summary prioritizing quantitative facts

### Vet Source Mode

1. Analyze provided text/URL
2. Output:

   ````markdown
   ### Material Analysis

   **Focus:** [Physics/Biology vs. History]
   **Rigor:** [Academic vs. Pop-History]

   ### Database Entry

   ```yaml
   - type: [book/article]
     title: "..."
     description: "Contains quantitative data on..."
     vetting:
       - date: "[YYYY-MM-DD]"
         author: "Lead Technical Researcher"
         summary: "..."
   ```
   ````

## 4. If Mode Unclear

Ask: "What research task—design a prompt, synthesize existing research, or vet a source?"
