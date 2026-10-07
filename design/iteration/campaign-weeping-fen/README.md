---
title: "Scenario Workshop: The Outlaw of Weeping Fen"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# Scenario Workshop: The Outlaw of Weeping Fen

This directory contains the active design sketch and structural outline for **"The Outlaw of Weeping Fen"**, a short, complete campaign scenario designed as a primary development benchmark for _caRdPG_. Its purpose is to guide the implementation of both rules and engine code by modeling a full, multi-scene adventure—connecting overland travel, exploration, non-combat challenges, tactical combat, and downtime recovery in our default **Grounded Heroism** setting.

---

## 1. Scenario Vision & Core Themes

_The Outlaw of Weeping Fen_ is a low-fantasy, sword-and-sorcery scenario centered on perseverance, survival, and moral ambiguity:

- **Grounded Heroism:** Violence is dangerous, physical trauma has lasting weight, and the protagonists are defined by what they can endure rather than effortless godlike power.
- **The Active Environment:** The fenland itself—its treacherous peat bogs, clinging mist, creeping damp, and sudden downpours—is an active antagonist that tests supplies, footwear, and vigilance.
- **Human Stakes over Cartoon Villains:** The conflict is not between pure good and absolute evil. It stems from feudal injustice, desperation, disease, and the friction between an isolated rural hamlet and a harsh frontier.
- **The Fast-Paced Combat Engine:** Demonstrates _caRdPG_'s core design advantage over traditional tabletop games (like D&D): simultaneous planning and card-count resolution mean combats resolve in 5–10 minutes of intense, high-stakes decision-making.

---

## 2. The Campaign Lifecycle & Architecture

The scenario exercises the three interconnected tiers of the _caRdPG_ engine:

```mermaid
flowchart TD
    subgraph Macro [Macro Loop: The Expedition Arc]
        HAVEN["Moss-Gallows Hamlet<br/>(Safe Haven: Rumors, Gear, Bounty)"] --> TRAVEL["The Sinking Causeway<br/>(Overland Travel: Weather & Tracking)"]
        TRAVEL --> SITE["The Ruined Barrow & Moated Hall<br/>(Exploration: Infiltration & Hazards)"]
        SITE --> CLIMAX["The Redoubt Confrontation<br/>(Three-Way Crisis & Resolution)"]
        CLIMAX --> CAMP["Camp / Return to Haven<br/>(Multi-Hour Rest, Clock Progression, Healing)"]
    end

    subgraph Meso [Meso Loop: Adventuring Time]
        TRAVEL --> VIG["Ready Hand Vigilance Dial (0-4)"]
        VIG --> GEN["General Actions (Obstacles & Social)"]
        GEN --> CLOCK["World Clock Deck (Time & Weather Shifts)"]
        CLOCK --> VIG
    end

    subgraph Micro [Micro Loop: Crisis Time]
        SITE --> FIGHT["Decisive Combat (Fast-Paced, Engaging Resolution)"]
        FIGHT --> PERSIST["Persistent Harm & Deck Dilution (No Full Resets)"]
        PERSIST --> SITE
    end
```

---

## 3. Workshop Directory Contents

- [narrative-arc.md](narrative-arc.md): The narrative outline, key factions, NPCs, dramatic dilemmas, and act-by-act story beats.
- [world-clock.md](world-clock.md): The narrative design and event concepts for the World Clock deck (weather, time of day, posse tracking, sickness progression).
- [challenges-and-encounters.md](challenges-and-encounters.md): High-level breakdown of the non-combat scenes, terrain hazards, and combat encounters.

---

## 4. Primary Development Targets Exposed by this Scenario

Designing and implementing this scenario directly drives the engineering and rules roadmap:

1. **Campaign / Scenario Data Model:** Moving beyond single-combat scenarios (`starter.yaml`) to multi-scene campaign definitions with transitions, locations, and narrative prompts.
2. **Persistent Actor State:** Preserving deck state, fatigue, condition cards, and equipment wear across multiple scenes and rests.
3. **Adventuring Time Engine:** Implementing the Ready Hand vigilance dial, Effort Cycles, and General Action flip-resolution outside the combat grid.
4. **The Living World Clock Engine:** A table-shared deck drawn during travel, multi-hour rests, or extended tasks that drives dynamic narrative and environmental changes.
5. **Multi-Character Dynamics:** Packaged 2-character party dynamics demonstrating mutual defense, skill assistance, and complementary roles.
