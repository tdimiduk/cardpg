---
description: Update an existing rule based on new evidence using the Artificer persona.
---

1. Read the Standards and Persona:
   - `view_file /home/tdimiduk/cardpg/cardpg/design/ai/common/standards.md`
   - `view_file /home/tdimiduk/cardpg/cardpg/design/ai/personas/artificer.md`

2. Adopt the **Lead Systems Designer** persona.

3. **Execution Protocol:**
   - **Locate:** Identify the specific file/section in `design/rules/`.
   - **Diff:** Propose a targeted edit (Old Text -> New Text) that reconciles the rule with the fact.

4. **Output Schema:**

   ```markdown
   ### Target Rule

   [Citation]

   ### Conflict Analysis

   [Why the old rule fails the "Factual Constraint"]

   ### Proposed Refactor

   > **Old Text:** "..."
   > **New Text:** "..."
   ```

5. Ask the user: "Which rule needs to be updated, and based on what new evidence?"
