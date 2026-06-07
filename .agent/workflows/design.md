---
description: Game design work focusing on systems rules and mechanics (discuss, audit, create, refactor, or write)
---

# Design Workflow

This unified workflow handles all game design tasks. The user's prompt determines the mode.

## Delegating to Subagent

For auditing rules, brainstorming under Discuss mode, or drafting player-facing guidelines, delegate to the `game_systems_designer` subagent (Lead Systems Designer). This ensures strict compliance with our Core Design Patterns (Defender-Centric, Simultaneity, etc.) without cluttering your core developer workspace.

If the subagent is not yet defined in this conversation, define it first using `define_subagent` with the following configuration:

- **Name**: `game_systems_designer`
- **Description**: Specialized in mechanical rules design, systems audit, mathematical balance, and ludonarrative harmony.
- **System Prompt**:

  ```markdown
  You are the Lead Systems Designer for CardPG. You are an expert in mathematical game balance, tabletop mechanics, and rules engineering.

  ### Scope & Duties:

  - Audit existing rules under `design/rules/` for structural consistency.
  - Draft new mechanics under Discuss, Create, or Refactor modes.
  - Enforce the absolute mapping of design intent to physical tabletop implementation.

  ### Core Design Patterns:

  - **Defender-Centric Resolution**: Active targets resolve outcomes and determine consequences.
  - **Simultaneity of Action**: Multi-party resolution in parallel without rigid initiative stacks.
  - **Deck as Life**: Resource costs paid via hand discards; cumulative wear/trauma paid via Fatigue, Wound, or Strain cards in deck.
  - **Success at a Cost**: Avoid binary pass/fail outcomes; focus on trade-offs.
  - **Table Constraints**: Must be playable on a standard physical table. Shuffled decks require identical card backs. Limit status tokens to 3 per player.
  ```

- **Tool Access**: Enable Write Tools: `true`, MCP Tools: `true`, Subagent Tools: `false`

## 1. Load Context

- `view_file <workspace_root>/.agent/standards/standards.md`
- `view_file <workspace_root>/.agent/standards/systems_design_standards.md`

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

- Check `design/index.yaml` for files with matching tags.
- For physical mechanics (combat, movement, injury), consult `design/research/synthesis/` or `design/research/reports/`.

## 4. Execute Per Mode

Follow the behavior for the determined mode above.

### Index Synchronization Rule

If your execution creates, renames, archives, or deletes files under `design/`, you MUST run `python3 tools/audit_index.py` and update the registry as documented in the [Design Index Guide](file:///home/tdimiduk/cardpg/docs/design_index_guide.md).

## 5. If Mode Unclear

Ask: "What mode should I work in—discuss, audit, create, refactor, or write?"
