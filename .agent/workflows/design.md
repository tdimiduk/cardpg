---
description: Game design work focusing on systems rules and mechanics (discuss, audit, create, refactor, or write)
---

# Design Workflow

This unified workflow handles all game design tasks. The user's prompt determines the mode.

## Delegating to Subagent

For auditing rules, brainstorming under Discuss mode, or drafting player-facing guidelines, delegate to the `game_systems_designer` subagent (Lead Systems Designer) defined in [.agent/skills/tabletop_rules_subagents/SKILL.md](file:///home/tdimiduk/cardpg/cardpg/.agent/skills/tabletop_rules_subagents/SKILL.md). This ensures strict compliance with our Core Design Patterns (Defender-Centric, Simultaneity, etc.) without cluttering your core developer workspace.

If the subagent is not yet defined in this conversation, define it first using `define_subagent` following [.agent/skills/tabletop_rules_subagents/SKILL.md](file:///home/tdimiduk/cardpg/cardpg/.agent/skills/tabletop_rules_subagents/SKILL.md) with the following configuration:

- **Name**: `game_systems_designer`
- **Description**: Specialized in mechanical rules design, systems audit, mathematical balance, and ludonarrative harmony.
- **System Prompt**:

  ```markdown
  Role: Tabletop Systems Designer & Mathematician.
  Mission: Audit and draft tabletop mechanics, model probability distributions, and balance card economy per design precepts and systems standards.

  ### Scope & Duties:

  - Audit existing rules under `design/rules/` for structural consistency.
  - Draft new mechanics under Discuss, Create, or Refactor modes.
  - Enforce the mapping of design intent into expressive VTT systems with plausible paths to physical streamlining.

  ### Core Design Patterns:

  - **Defender-Centric Resolution**: Active targets resolve outcomes and determine consequences.
  - **Simultaneity of Action**: Multi-party resolution in parallel without rigid initiative stacks.
  - **Deck as Life**: Resource costs paid via hand discards; cumulative wear/trauma paid via Fatigue, Wound, or Strain cards in deck.
  - **Success at a Cost**: Avoid binary pass/fail outcomes; focus on trade-offs.
  - **Digital-First & Physical Streamlining**: Playtesting occurs primarily in the custom VTT. Physical tabletop ergonomics is a "nice to have" rather than a hard blocker during active design and exploration. Build rich mechanics in the VTT first with clear paths to physical streamlining later. Shuffled decks require identical card backs. Avoid analysis paralysis.
  ```

- **Model**: `inherit` (Preserves the user's active session model without unbudgeted escalations)
- **Tool Access**: Enable Write Tools: `true`, MCP Tools: `true`, Subagent Tools: `false`

## 1. Load Context

- `view_file <workspace_root>/.agent/standards/standards.md`
- `view_file <workspace_root>/.agent/standards/systems_design_standards.md`

Adhere to the **Lead Systems Designer** guidelines and principles.

## 2. Determine Mode from User Request

| Mode         | Trigger Keywords                       | Behavior                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ------------ | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Discuss**  | "discuss", "explore", "what if"        | Open-ended conversation. Do NOT propose file edits yet. Challenge assumptions. Ask clarifying questions. Only transition to concrete changes when user says "finalize" or "implement".                                                                                                                                                                                                                                                                                                      |
| **Audit**    | "audit", "review", "check consistency" | Cross-reference `design/rules/` against `design/philosophy/` and `design/research/`. Use the Rules Verification Triangle (`game_systems_designer` for math/economy, `rulebook_adversary` for exploits/friction, and `verisimilitude_auditor` for physical plausibility per [.agent/skills/tabletop_rules_subagents/SKILL.md](file:///home/tdimiduk/cardpg/cardpg/.agent/skills/tabletop_rules_subagents/SKILL.md)). Produce a Consistency Report highlighting mechanical or factual issues. |
| **Create**   | "new mechanic", "design", "model"      | Consult `design/research/synthesis/` for factual grounding. Apply Core Design Patterns. Provide 2 options with Design Notes if open-ended.                                                                                                                                                                                                                                                                                                                                                  |
| **Refactor** | "update", "refactor", "fix rule"       | Locate the rule in `design/rules/`. Propose a targeted diff (Old → New) that reconciles with new facts.                                                                                                                                                                                                                                                                                                                                                                                     |
| **Write**    | "write", "draft", "player-facing"      | Draft prose for players/GMs. Identify tone from context. Enclose final draft in code block.                                                                                                                                                                                                                                                                                                                                                                                                 |

## 3. Locate Relevant Context

- Check `design/index.yaml` for files with matching tags.
- For physical mechanics (combat, movement, injury), consult `design/research/synthesis/` or `design/research/reports/`.

## 4. Execute Per Mode

Follow the behavior for the determined mode above.

### Index Synchronization Rule

If your execution creates, renames, archives, or deletes files under `design/`, run `cabal run tools-hs:exe:audit-index -- --fix` (or `audit-index --fix`) to ensure the registry and epistemic frontmatter are clean (enforced automatically at commit via pre-commit).

## 5. If Mode Unclear

Ask: "What mode should I work in—discuss, audit, create, refactor, or write?"
