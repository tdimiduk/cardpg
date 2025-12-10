---
description: Ingest design changes discussed externally (Web Gemini).
---

1.  **Capture the Outcome**
    Paste the detailed summary or final proposal from your external session into a temporary file.
    ```bash
    # Example
    view_file design/discussions/my_feature_proposal.md
    ```

2.  **Review and Refine**
    Use the *Code Persona* or *Artificer Persona* to validate the imported text against the current rules.
    *(e.g., "Review this proposal for conflicts with core-rules.md")*

3.  **Integrate**
    Once validated, move the content to its permanent home in `design/rules/`, `design/ideation/` or `design/research/`.
    - Update `design/manifest.yaml` to include the new file.
