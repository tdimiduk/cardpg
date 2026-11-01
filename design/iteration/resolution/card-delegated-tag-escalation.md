---
title: "Exploration: Delegating Tag Escalation to Card Text"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Exploration: Delegating Tag Escalation to Card Text

## Document Purpose

This document explores how **tag-based harm escalation** can be moved out of `core-rules.md` and delegated directly to **card rules text**, honoring the **10x Rule of Core Complexity** (`design/philosophy/design-precepts.md`):

> _"Complexity in the core rulebook costs **10x** as much as complexity distributed on specific cards. The core engine procedures in `core-rules.md` must remain minimal, tactile, and intuitive to teach in two minutes."_

It directly addresses **Question 4** from [evaluation.md](candidates/consequence-pool-tag-escalation/evaluation.md):

> _"Can any more of the rules for the proposal be delegated to card rules instead of needing to be in the core rules?"_

---

## 1. The Problem: Flowchart Bloat in Core Rules

In both the [Consequence Pool Proposal](candidates/consequence-pool-tag-escalation/proposal.md) and earlier tag-matching drafts, the core rulebook was forced to specify an intricate procedural engine:

- Tag matching taxonomies (`Vulnerable: [Tags]`).
- Physical tracking gestures ("Place Tier $K$ candidate onto condition to draw Tier $K+1$, then scoop back to curate").
- Cross-tier escalation chains and redraw fallbacks for duplicate binary states.

While mechanically sound, putting this machinery into `core-rules.md` risks **Pitfall 11: The Patchwork Trap (Flowchart Bloat)**. A new player reading the rulebook must mentally parse the entire tag escalation algorithm before ever playing their first round.

---

## 2. The Core Rulebook Baseline (What Remains)

If tag escalation is delegated to cards, what is the absolute minimum that `core-rules.md` needs to say?

```markdown
### Facing a Challenge: Consequences

1. **Calculate Impact:** Cards flipped to meet Strength form your flipped stack; card count = Impact ($I$).
2. **Armor / Soak:** If Impact is less than your domain defense rating or pool size, the blow is soaked (**0 cards drawn**).
3. **Suffer Consequence:** If Impact reaches or exceeds the threshold, draw a consequence card from the appropriate domain Severity 1 deck and place it face up in front of you.
4. **Follow Card Rules:** If you have active condition cards in play, apply their printed rules text.
```

That is **four sentences**. It can be taught in 30 seconds. All the tactical drama, vulnerability exploitation, and anatomical escalation occur because players simply read and obey the cards on the table.

---

## 3. Four Card-Delegated Escalation Patterns

---

### Pattern 1: Escalation via Passive Text on Condition Cards

Instead of a universal "Step 3: Exploit Vulnerabilities" algorithm in core rules, **each condition card tells you how it compromises your defenses**.

#### Examples:

```yaml
- name: Poor Footing
  severity: 1
  tags: [positioning]
  rules:
    - passive: The Impact of your physical defenses is +1.
    - action: Regain Footing (Tuck 2 cards from hand) -> Remove this.
```

> _Why this works:_ `+1 Impact` naturally causes subsequent attacks to hit harder, crossing armor soak thresholds without needing a special "shell-cracking" rule!

```yaml
- name: Knocked Prone
  severity: 2
  tags: [positioning]
  rules:
    - passive: >
        Your physical Consequence Pool Size is reduced by 1 (min 1).
        When you suffer a consequence from a melee attack, draw from Severity 3 instead of Severity 1.
    - action: Struggle to Feet (Place 1 card from hand on top of this. At start of round, expend it and remove this).
```

> _Why this works:_ Prone targets don't need a core rule for tag matching; the card explicitly dictates: _"When you suffer a consequence from a melee attack, draw from Severity 3."_

```yaml
- name: Cracked Ribs
  severity: 2
  tags: [torso]
  rules:
    - passive: Whenever you suffer a [torso] or [exertion] consequence, upgrade it to Severity 3.
```

> _Why this works:_ Localized anatomical trauma: taking another blow to an already fractured rib cage immediately pushes the injury into catastrophic thoracic trauma (`Sucking Chest Wound` / `Internal Bleeding`).

---

### Pattern 2: Escalation via Attack & Weapon Keywords

In martial reality, escalation is often driven by the **attacker actively exploiting an opening**, not just the defender's passive state. Attack cards and weapon cards can carry printed keywords that trigger off active tags on the defender:

#### Examples on Action / Weapon Cards:

- **Heavy Flanged Mace (`[Crush]`):**
  > _"If the target has an active `[armor]` or `[positioning]` condition, this attack ignores armor soak and inflicts +1 Severity."_
- **Rapier Thrust (`[Finesse, Pierce]`):**
  > _"If the target has an active `[sensory]` or `[positioning]` condition, this attack's Impact is +2."_
- **Executioner's Strike (`[Finisher]`):**
  > _"If the target has any Tier 2 or Tier 3 condition, any consequence inflicted is drawn from the Severity 4 (Defeat) deck."_

#### Why This Is Powerful:

1. **Zero Core Rules Overhead:** The core rules never need to define "how weapons exploit wounds."
2. **Differentiated Weapon Identities:** A mace exploits broken armor; a spear exploits prone posture; a dagger exploits blinded opponents. Each weapon feels distinct through standard card text.

---

### Pattern 3: In-Place Pip Tracks on Consolidated Cards

As explored in [consolidated-tiered-cards-and-triage.md](candidates/retired/consolidated-tiered-cards-and-triage.md), condition cards feature a printed 3-tier escalation track:

```
+-----------------------------------------------------+
| SHATTERED BALANCE                 [Tag: positioning] |
+-----------------------------------------------------+
| [o] Sev 1: Poor Footing                             |
|   Passive: The Impact of your defenses is +1.       |
+-----------------------------------------------------+
| [ ] Sev 2: Off Balance                              |
|   Passive: Cannot play Defend cards from hand.      |
+-----------------------------------------------------+
| [ ] Sev 3: Knocked Prone                            |
|   Passive: Attacks against you gain +2 Impact.      |
+-----------------------------------------------------+
| Escalation Rule: If you suffer another positioning  |
| consequence while this card is active, advance the  |
| marker +1 Pip instead of drawing a new card.        |
+-----------------------------------------------------+
```

#### Why This Is Powerful:

- The entire escalation procedure is self-contained on the face of the card.
- **Zero mid-combat deck tutoring:** No picking up Severity 2 or Severity 3 decks to find upgrade cards.
- The player merely moves a wooden cube or paperclip slider down the card.

---

### Pattern 4: Explicit "Escalates To:" Pointers

For standalone cards across separate decks, cards can feature an explicit upgrade pointer:

```yaml
- name: Ringing Ears
  severity: 1
  tags: [head, sensory]
  rules:
    - passive: Blue actions cost +1 card from hand.
    - escalates: If you suffer another [head] consequence, replace this with Mild Concussion (Severity 2).
```

When an attacker inflicts a consequence with the `[head]` tag, the table looks at the card already in play: it literally tells the defender which card replaces it.

---

## 4. Multi-Domain Flexibility

When escalation is delegated to cards, **non-combat domains gain complete freedom** without cluttering combat rules:

- **Social Encounters:**
  ```yaml
  - name: Exposed Contradiction
    severity: 1
    tags: [social, rhetoric]
    rules:
      - passive: Your social pool size is reduced by 1.
      - escalates: If you suffer another [rhetoric] consequence, replace this with Discredited (Severity 2).
  ```
- **Environmental Hazards:**
  ```yaml
  - name: Hypothermia (Mild)
    severity: 1
    tags: [environmental, cold]
    rules:
      - passive: You cannot regain Vigilance during short rests.
      - escalates: If exposed to sub-zero weather for 1 hour, advance to Frostbite (Severity 2).
  ```

Neither of these needs to know about weapon Pierce, armor soak, or combat positioning. They leverage the universal engine seamlessly.

---

## 5. Architectural Recommendation

| Mechanism                              | Core Rulebook Footprint |      Card Text Overhead       |              Ergonomics at the Table               |
| :------------------------------------- | :---------------------: | :---------------------------: | :------------------------------------------------: |
| **Procedural Step in Core Rules**      |    High (~1–2 pages)    |  Low (cards only have tags)   | Moderate (requires following multi-step algorithm) |
| **Pattern 1: Condition Passives**      |        **Zero**         |   Low (1 sentence per card)   |  ⭐⭐⭐⭐⭐ (Read card in play; do what it says)   |
| **Pattern 2: Attack Keywords**         |        **Zero**         | Low (printed on attack cards) |    ⭐⭐⭐⭐⭐ (Attacker calls out their bonus)     |
| **Pattern 3: Consolidated Pip Tracks** |        **Zero**         |  Medium (3 tiers on 1 card)   |      ⭐⭐⭐⭐⭐ (Advance pip marker in place)      |

### The Verdict:

Adopt **Pattern 1 (Condition Passives) paired with Pattern 3 (Consolidated Pip Tracks)**.

- Keep `core-rules.md` down to a clean, minimal procedure.
- Let conditions modify incoming Impact, pool thresholds, or tier draws directly via their printed `Passive:` text.
- This fully satisfies the **10x Rule**, protects against rules bloat, and makes resolution instinctive.
