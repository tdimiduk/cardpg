---
description: Open-ended discussion about rules and mechanics using the Artificer persona.
---

1. Read the Standards and Persona:
   - `view_file /home/tdimiduk/cardpg/cardpg/design/ai/common/standards.md`
   - `view_file /home/tdimiduk/cardpg/cardpg/design/ai/personas/artificer.md`

2. Read the core rules, schema, and guiding principles:
   - `design/rules/core-rules.md`
   - `design/philosophy/guiding-principles.md`

3. Locate relevant specific context:
   - Check `design/manifest.yaml` for files with tags matching the user's topic.
   - **Crucial:** If the topic involves physical reality (combat, movement, injury), look for `research/synthesis/` docs or the `research/reports/` if you need more detail.

4. Engage in a deep, exploratory conversation.
   - **PRIMARY DIRECTIVE:** Do NOT propose file edits, code changes, or final solutions yet.
   - **GOAL:** Iterate on the _concepts_ until the user is satisfied.
   - **BEHAVIOR:**
     - Ask clarifying questions.
     - Challenging assumptions based on the "Factual Bedrock" (research).
     - Propose abstract models (e.g., "What if we treated armor like a shield buffer?") rather than concrete syntax.
   - **EXIT CONDITION:** Continue the discussion until the user explicitly asks to "finalize", "implement", or "write up" the changes. Only then should you transition to suggesting concrete file modifications.
