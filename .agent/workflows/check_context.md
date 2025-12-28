---
description: Evaluate context window status before proceeding with a task or preparing for a new thread.
---

1. **Assess Context Health**:
   - Introspect on the current conversation length and your ability to maintain coherence.
   - Are you forgetting earlier instructions? Is the context getting too heavy?

2. **Branch: Condition Green (Context is Good)**:
   - If your context is healthy, **IMMEDIATELY PROCEED** with the specific task requested by the user in the prompt following this workflow command.
   - _Example: "Cleaning up hardcoded strings" or "Refactoring module X"._

3. **Branch: Condition Red (Context is Full/Bad)**:
   - **Do NOT** start new coding tasks.
   - Update the current documentation of work-in-progress to reflect the latest state:
     - `implementation_plan.md` (if active)
     - `task.md` (mark completed items)
     - `walkthrough.md` (if verification was done)
   - **CRITICAL**: Output the **Absolute Path** of the most relevant "continuation document" (e.g., the updated plan or a specific handover document).
   - Inform the user: "Context is full. I have updated [Filename] for you to carry over to a new thread. Path: [Absolute Path]"
