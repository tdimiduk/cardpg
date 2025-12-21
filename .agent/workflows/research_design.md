---
description: Design a research prompt and initialize the report directory.
---

1. **Input**: target "Research Topic"

2. **Context**:
   - `view_file /home/tdimiduk/cardpg/cardpg/design/ai/common/standards.md`
   - `view_file /home/tdimiduk/cardpg/cardpg/design/ai/personas/chronicler.md`
   - Adopt the **Lead Technical Researcher** persona.

3. **Drafting**:
   - Create a detailed prompt for a Deep Research tool.
   - **Goal**: Hunt for **Quantitative Data**.
   - **Constraint**: Ensure KRAs (Key Research Areas) ask for numbers, timelines, and physical consequences, not general history.

4. **Execution**:
   - **Slugify** the topic to create a directory name (e.g., `armor_effectiveness`).
   - **Create Directory**: `run_command` to make `design/research/reports/<slug>`.
   - **Write Prompt**: Write the drafted prompt content to `design/research/reports/<slug>/prompt.md`.
   - **Write Metadata**: Write the following to `design/research/reports/<slug>/meta.yaml`:
     ```yaml
     report_date: {YYYY-MM-DD}
     generation_details:
       tool: "Gemini 3 Pro with Deep Research"
       prompt_file: "prompt.md"
     ```

5. **Conclusion**:
   - Notify the user that the report skeleton is ready for Deep Research execution.