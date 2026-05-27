---
description: Game design work focusing on systems rules and mechanics (discuss, audit, create, refactor, or write)
---

# Design Workflow

This unified workflow handles all game design tasks. The user's prompt determines the mode.

## Delegating to Subagent

- **`game_systems_designer`**: For auditing rules, brainstorming under Discuss mode, or drafting player-facing guidelines, delegate to the `game_systems_designer` subagent (Lead Systems Designer). This ensures strict compliance with our Core Design Patterns (Defender-Centric, Simultaneity, etc.) without cluttering your core developer workspace.

## 1. Load Context

- `view_file /home/tdimiduk/cardpg/cardpg/design/ai/common/standards.md`
- `view_file /home/tdimiduk/cardpg/cardpg/design/ai/common/systems_design_standards.md`

Adhere to the **Lead Systems Designer** guidelines and principles.

## 2. Determine Mode from User Request

| Mode         | Trigger Keywords                       | Behavior                                                                                                                                                                               |
| ------------ | -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Discuss**  | "discuss", "explore", "what if"        | Open-ended conversation. Do NOT propose file edits yet. Challenge assumptions. Ask clarifying questions. Only transition to concrete changes when user says "finalize" or "implement". |
| **Audit**    | "audit", "review", "check consistency" | Cross-reference `design/rules/` against `design/philosophy/` and `design/research/`. Produce a Consistency Report highlighting ludonarrative dissonance.                               |
| **Create**   | "new mechanic", "design", "model"      | Consult `design/research/synthesis/` for factual grounding. Apply Core Design Patterns. Provide 2 options with Design Notes if open-ended.                                             |
| **Refactor** | "update", "refactor", "fix rule"       | Locate the rule in `design/rules/`. Propose a targeted diff (Old → New) that reconciles with new facts.                                                                                |
| **Write**    | "write", "draft", "player-facing"      | Draft prose for players/GMs. Identify tone from context. Enclose final draft in code block.                                                                                            |

## 3. Locate Relevant Context

- Check `design/manifest.yaml` for files with matching tags.
- For physical mechanics (combat, movement, injury), consult `design/research/synthesis/` or `design/research/reports/`.

## 4. Execute Per Mode

Follow the behavior for the determined mode above.

## 5. If Mode Unclear

Ask: "What mode should I work in—discuss, audit, create, refactor, or write?"
