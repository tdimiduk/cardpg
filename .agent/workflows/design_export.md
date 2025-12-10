---
description: Export design context for external discussion (Web Gemini).
---

1.  **Analyze Request**
    - Identify the core topic (e.g., "Armor Mechanics", "Combat Pacing").
    - Ask: "What specific files or tags cover this topic?"

2.  **Audit Context (Agentic Step)**
    - *Agent Action:* Search `design/manifest.yaml` for relevant tags.
    - *Agent Action:* Use `grep` or `find` to locate relevant files that might be missing tags.
    - *Agent Action:* If you find relevant files that are NOT in the manifest or missing tags, propose adding them to `design/manifest.yaml` (using `tools/audit_manifest.py` logic or manual edit).

3.  **Generate Context Bundle**
    - Construct the `pack_context.py` command using found tags and specific files.
    - *Command Pattern:*
      ```bash
      ./tools/pack_context.py \
          --tag <TAG> \
          --file <REL_PATH_TO_SPECIFIC_FILE> \
          --query "<KEYWORD>" > _design_context.md
      ```

4.  **Handover**
    - Tell the user the context is ready in `_design_context.md`.
    - **Draft a Starter Prompt:** Write a concise prompt for the user to use with the external AI.
      - *Format:* "I have uploaded a context file containing [Topic Summary]. I want to discuss [Specific Question/Goal]. Please act as the Artificer persona defined in the context."
    - Provide the "Ingestion" instruction (e.g., "Use /design_ingest when you return").
