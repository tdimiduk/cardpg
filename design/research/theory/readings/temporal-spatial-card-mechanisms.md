---
title: "Literature Note: Granular Tempos, Non-Interrupt Spatial Engagement, and Physical Card Action Tracking"
doc_type: "literature-note"
track: "ludology"
origin: "Gemini 3.8 Flash (Antigravity)"
epistemic_status:
  confidence: "high"
  audited_by: "Gemini 3.8 Flash (Antigravity)"
  vetted_by_human: false
  vetting_notes: "Comparative ludological analysis of tabletop RPGs, wargames, and tactical card systems modeling short time intervals (1-3s), non-interrupt spatial control, and zero-token multi-round card tracking."
related_files:
  - "design/iteration/crisis-round-duration-and-phrase-cadence-brief.md"
  - "design/iteration/movement-area-control-and-reach-priority-brief.md"
  - "design/iteration/action-stack-accumulation-for-extended-actions-brief.md"
  - "design/research/synthesis/combat-timelines-and-tempos.md"
  - "design/research/synthesis/combat-spacing-and-reach.md"
  - "design/research/synthesis/tactical-movement.md"
  - "design/rules/core-rules.md"
  - "design/rules/modules/selective-commitment.md"
---

# Literature Note: Granular Tempos, Non-Interrupt Spatial Engagement, and Physical Card Action Tracking

## Executive Summary

This report investigates three interconnected mechanical challenges in tactical tabletop game design:

1. **Short Round Durations (1–3 Seconds):** The ludological trade-offs between ultra-fine simulation (GURPS, RuneQuest/Mythras, The Riddle of Steel, Burning Wheel, Tick Systems) and tabletop pacing, analyzing why granular systems either succeed in creating martial tension or collapse into bookkeeping paralysis.
2. **Spatial Engagement & Interception without 'Attacks of Opportunity':** How games resolve the "frozen world" anomaly of turn-based systems—screening allies, blocking corridors, and halting rushing foes—without resorting to legalistic unilateral interrupts like D&D's Attacks of Opportunity.
3. **Ergonomic Multi-Round Action Tracking via Physical Cards:** How card-driven and tactical board games track multi-second/multi-round actions (drawing a warbow, reloading a crossbow, channeling a ritual, stabilizing an arterial bleed) cleanly on the table, eliminating token clutter and spreadsheet accounting through card-native ergonomics.

Finally, this report translates these empirical ludological lessons into actionable systems recommendations tailored to CardPG's 24-card deck engine, simultaneous round structure, and defender-centric resolution.

---

## 1. Short Round Durations (1–3 Seconds) & Granular Tempos

In traditional tabletop RPGs (e.g., D&D, Pathfinder), combat rounds last 6 seconds. Within this window, a character takes an entire sequence of complex actions (running 30 feet, drawing a weapon, casting a spell, making two attacks) while other combatants remain stationary statues. When designers seek greater verisimilitude, they compress the round duration down to 1–3 seconds or abandon cyclical rounds for continuous ticks. Below is an analytical breakdown of how five distinct tactical paradigms execute this, their mechanical benefits, and their failure modes.

### 1.1 GURPS 4e: The 1-Second Strict Simulation

#### Mechanics

- **Temporal Unit:** Strict 1-second rounds.
- **Turn Structure:** Unilateral initiative order, but each turn represents only 1 second of physical activity.
- **Maneuver System:** A combatant chooses exactly one maneuver per second: _Move_, _Step and Attack_, _All-Out Attack_, _All-Out Defense_, _Aim_, _Ready_, _Evaluate_, _Wait_, or _Feint_.
- **Movement:** Movement is calculated in yards per second (`Basic Move`, typically 5–6 yd/s for an unarmored human). Standard attacks allow only a 1-yard "Step" before or after the strike. Full sprinting requires dedicated _Move_ maneuvers.
- **Defense:** "Active Defenses" (Dodge, Parry, Block) are rolled reactively outside the character's turn without consuming future turns (unless using All-Out options).

#### Mechanical Benefits

- **High-Fidelity Physical Modeling:** Matches real-world kinematics. Bullet velocities, falling speeds, weapon swings, and human acceleration match textbook physics.
- **Elimination of Turn Teleportation:** A warrior cannot dash 30 feet across a room and stab someone before that person can draw a knife. Every yard of movement is accounted for in real time.
- **Tactical Granularity:** Weapon preparation matters. Drawing a sword from a scabbard takes 1 second (`Ready`); cocking a crossbow takes multiple seconds; aiming a rifle provides incremental accuracy bonuses for up to 3 seconds.

#### Failure Modes & Table Friction

- **The 1-Yard Movement Slog:** If two swordfighters start 10 yards apart, closing the distance requires two full seconds of doing nothing but taking the _Move_ maneuver, followed by a _Step and Attack_ on second 3. At a table with 4 players and 6 opponents, this produces multiple entire rounds where players simply announce "I move 5 yards" and pass. The game stalls during approach.
- **Severe Temporal Dilation (The 1000:1 Real-Time Ratio):** A 10-second skirmish (a brief exchange of 3 strikes, a parry, and a grapple) typically takes 2 to 3 hours of tabletop dice rolling. Every 1-second turn requires: declaring a maneuver, rolling attack (3d6), rolling active defense (3d6), rolling hit location (3d6), rolling damage, subtracting DR, and rolling shock/knockdown checks.
- **Player Disengagement on Multi-Second Maneuvers:** A musketeer reloading for 15 seconds, or a sniper aiming for 3 seconds, must sit through 3 to 15 tabletop rounds declaring "I Ready" or "I Aim", contributing zero active decisions for 30–60 minutes of real time.
- **The "Wait" Maneuver Cascade:** Because 1 second is so brief, players frequently declare the _Wait_ maneuver (a conditional interrupt: _"If he steps into the doorway, I shoot"_). When multiple characters declare _Wait_, the GM must adjudicate nested priority contests based on Perception and Basic Speed, bogging the game down in rules debates.

---

### 1.2 Mythras / RuneQuest 6: 3–5s Rounds with Action Points & Pulses

#### Mechanics

- **Temporal Unit:** Rounds represent 3 to 5 seconds, capturing a complete "combat exchange" or "phrase of arms."
- **Action Points (APs):** Each character has 2 to 4 APs per round, derived from Dexterity and Intelligence.
- **Cyclical Pulses:** Play proceeds in sequential "Pulses" around the table. On Pulse 1, each combatant with APs remaining may spend 1 AP to act. On Pulse 2, characters with remaining APs act again, until everyone has spent their APs.
- **Reactive AP Consumption:** _Active Defenses (Parrying, Evading) cost 1 AP._ If you are attacked and choose to parry, you must spend 1 of your precious APs.
- **Differential Success ("Special Effects"):** Attack and Parry rolls are opposed (d100 roll-under). The degree of success is compared (Critical > Success > Failure > Fumble). The side that achieves a superior level of success gains one or more _Special Effects_ (e.g., _Trip Opponent_, _Disarm_, _Impale_, _Bypass Armor_, _Overextend_, _Pin Weapon_). Crucially, if the defender wins the roll, the _defender_ inflicts the Special Effect (e.g., immediate riposte or blind).

#### Mechanical Benefits

- **The Natural "Phrase of Arms":** 3–5 seconds is the exact duration of a historical fencing exchange (approach, attack, bind/parry, riposte). It avoids the micro-slog of GURPS while preserving tactical depth.
- **Organic Solution to Action Economy & Mobbing:** Because defending costs APs, outnumbering an opponent is naturally lethal. A master swordsman with 3 APs fighting three bandits (2 APs each) will be forced to spend all 3 APs parrying the first three attacks, leaving them with zero APs to attack or defend against subsequent strikes. No arbitrary "gang-up" bonus rules are needed.
- **Defensive Agency and Counter-Strokes:** Parrying is not passive damage reduction; a great defense directly punishes the attacker through counter-effects without requiring a separate turn.

#### Failure Modes & Table Friction

- **The "Turtle Meta" (AP Paranoia):** Because an attack costs 1 AP and defending costs 1 AP, aggressive players frequently discover that attacking first leaves them defenseless against an opponent with equal or higher APs. This creates an emergent pathology where players refuse to initiate attacks, waiting passively for the enemy to attack and overextend.
- **Bookkeeping Overhead Across Pulses:** The GM and players must continuously track remaining APs across multiple pulses per round for every creature on the board. For a battle with 6 goblins and 4 PCs, tracking AP counts on paper or with tokens creates significant table friction.
- **Initiative & Pulse Churn:** Modifiers from fatigue, encumbrance, or severe wounds that reduce APs mid-round disrupt the pulse sequence, forcing recalculation of turn order on the fly.

---

### 1.3 The Riddle of Steel (TRoS) & Blade of the Iron Throne: Split-Second Tempos & Simultaneous Pool Allocation

#### Mechanics

- **Temporal Unit:** Combat rounds are 1–2 second split-second "Exchanges," divided into two discrete "Tempos" (First Tempo, Second Tempo).
- **Combat Pool (CP):** A character's sole resource is their Combat Pool (a pool of d10s derived from Reflexes, Agility, and Weapon Proficiency). CP represents physical stamina, situational awareness, and momentum.
- **Simultaneous Initiative (Red/White Dice):** At the beginning of an exchange, both combatants secretly conceal and simultaneously reveal a colored die:
  - **Red Die:** Aggressive Intent (seizing the _Vor_ / initiating an attack).
  - **White Die:** Defensive / Cautious Intent (waiting in the _Nach_).
  - _Red vs. White:_ The Red combatant attacks; the White combatant must defend.
  - _White vs. White:_ Both fighters hesitate, circle, or test distance. Both regain lost CP.
  - _Red vs. Red:_ Both fighters lunge simultaneously! The fighter with the longer weapon reach strikes first; if reach is equal or within the dynamic window, simultaneous double-strikes (mutual death) occur.
- **Dice Pool Splitting:** Before rolling, combatants must blind-allocate their CP between attacks and defenses across both Tempos. Allocating 8 dice to an opening cut leaves only 4 dice to defend against a counter-stroke or fuel a second tempo riposte.
- **Margin of Success to Lethality:** Every die that beats the target number adds directly to a catastrophic damage rating, looked up on anatomical wound tables that inflict immediate Shock, Pain, and Blood Loss.

#### Mechanical Benefits

- **Supreme Psychological Verisimilitude:** TRoS captures the raw, terrifying psychology of historical dueling better than any other system. The Red/White reveal forces players to experience the visceral fear of committing to a strike versus protecting their life.
- **Fluid Martial Dynamics (_Vor_, _Nach_, _Indes_):** The transition from defense to offense is organic. Parrying with a high margin of success preserves dice that immediately carry over into a devastating riposte in the Second Tempo.
- **Elimination of Hit Point Bloat:** Fights are short, sharp, and decisive (often ending in 1–2 exchanges).

#### Failure Modes & Table Friction

- **Severe Mental Math & Blind-Bidding Friction:** Players must mentally calculate complex probabilities under pressure (opponent weapon length, TNs, fatigue penalties, maneuver costs) while blind-bidding dice across two tempos.
- **Strict Duels-Only Scalability Collapse:** The system works brilliantly in 1-on-1 duels, but completely falls apart in multi-combatant melees. A GM managing 4 or 5 combatants simultaneously engaged with 4 players cannot run simultaneous dice bidding and Red/White reveals across multiple intersecting pairs without complete cognitive overload.
- **The Lethality Cliff:** A single mistake in dice allocation results in permanent dismemberment or instant death, making character survival over long narrative campaigns precarious.

---

### 1.4 Burning Wheel: Scripted Volleys

#### Mechanics

- **Temporal Unit:** The "Fight!" system divides a round into 3 equal "Volleys" (each representing roughly 1–2 seconds).
- **Simultaneous Scripting:** Before any dice are cast or actions resolved, all participants secretly write down (or lay out action cards for) their 3 actions—one action per volley. Actions are drawn from a technical catalog: _Strike_, _Great Strike_, _Block_, _Counterstrike_, _Avoid_, _Feint_, _Lock_, _Push_, _Snapshot_, _Draw Weapon_, _Cast Spell_, etc.
- **Step-by-Step Simultaneous Reveal:**
  - Players reveal their scripted action for Volley 1 simultaneously.
  - The interaction is looked up on the **Fight Interaction Matrix**:
    - _Strike vs. Strike:_ Both test attack; both can hit simultaneously.
    - _Feint vs. Block:_ Feint automatically bypasses and defeats the Block, landing a free hit!
    - _Block vs. Strike:_ Opposed roll; leftover block successes generate defensive positioning.
    - _Avoid vs. Strike:_ Defender rolls Avoid against all incoming attacks in that volley.
  - Repeat for Volley 2, then Volley 3.

#### Mechanical Benefits

- **Zero Downtime During Planning:** Every player is actively engaged during the scripting phase. No one waits for their turn while others act.
- **Rewarding Predictive Martial Mastery:** Models martial psychology through anticipation and reads. Predicting that an opponent will turtle behind a shield and scripting a _Feint_ yields immense tactical satisfaction.
- **High Dramatic Tension on Reveal:** The moment scripts are flipped over generates immense excitement and dread.

#### Failure Modes & Table Friction

- **Analysis Paralysis & Scripting Friction:** Trying to anticipate what an opponent will do 3 steps ahead across dozens of potential action pairings is mentally exhausting, especially for new players.
- **The "Committed Silliness" / Whiff Phenomenon:** Because actions are locked in advance, unexpected outcomes in Volley 1 render subsequent volleys absurd. If Combatant A trips and falls in Volley 1, but Combatant B scripted three _Avoid_ maneuvers, Combatant B spends Volleys 2 and 3 diving away from an opponent lying face-down on the floor.
- **Matrix Lookup Fatigue:** Adjudicating the Fight matrix requires constant table lookups. Unless players memorize dozens of interaction pairs, gameplay grinds to a halt to check rules references.

---

### 1.5 Continuous / Tick Systems: Feng Shui Shots, Exalted 2e Ticks, & HackMaster 5e

#### Mechanics

- **Temporal Unit:** Eliminates cyclical "rounds" entirely. Combat is tracked along a continuous linear timeline of "Ticks" or "Shots" (typically 1 tick = 1 second).
- **The Time Track:** A circular wheel or linear numbered track (e.g., 0 to 60) sits on the table. Tokens representing characters and NPCs occupy positions on this track.
- **Action Delays (Speed):** The GM announces the current tick. Whoever is on that tick acts. Every action has a "Speed" (Delay) in ticks:
  - A light dagger stab: 3 ticks.
  - A standard arming sword swing: 4 ticks.
  - A heavy two-handed maul blow: 6 ticks.
  - Aiming and loosing a bow: 5 ticks.
  - Casting an incantation: 7 ticks.
- **Token Advancement:** Upon executing an action, the combatant's token is moved forward on the track by the action's Speed. The GM then advances the count to the next lowest tick occupied by a character.
- **HackMaster 5e Count-Up:** In HackMaster, the GM literally counts up out loud: _"One... two... three... four..."_ Movement is continuous (1 yard per tick), weapons have reach and speed delays, and damage triggers trauma delays.

#### Mechanical Benefits

- **Natural Representation of Weapon Weight & Speed:** Light weapons genuinely attack faster than massive weapons. A rogue with twin daggers can strike twice in the time it takes an ogre to swing a greatclub once.
- **Organic Multi-Round Action Interruption:** Actions taking multiple seconds (casting a spell, drawing a bow) occupy a span of ticks. If an enemy strikes the caster on tick 4 of a 7-tick cast, the interruption resolves naturally without artificial "counterspell" interrupts.
- **Fluid Locomotion:** Movement flows continuously rather than in 30-foot teleportation bursts.

#### Failure Modes & Table Friction

- **Physical Tracker Fragility:** Tick systems require an active tabletop tracker (shot counter, clock wheel, pegboard). If a token is bumped, shifted, or misplaced, the temporal state of the entire encounter is corrupted.
- **Unequal Table Engagement (The Slow Weapon Tax):** A player who swings a 6-tick two-handed weapon takes one action and then sits idle while a 3-tick dual-wielding ally takes two complete action cycles, rolling dice and making decisions while the heavy weapon wielder waits.
- **The "Tick Chorus" Conversational Fatigue:** The GM chanting numbers continuously (_"Tick 12... anyone? Tick 13... anyone? Tick 14..."_) becomes aurally grating and feels like operating air-traffic control rather than narrating an exciting battle.
- **Defense Value (DV) Shredding & Flurry Exploits (The Exalted 2e Disaster):** In Exalted 2e, a character's static defense refreshed on their action tick. However, each incoming attack between ticks reduced their defense by -1. This produced degenerate "flurry" builds where attackers made 5 rapid strikes in 1 tick, stripping the target's defense to zero on strike 2 and obliterating them on strikes 3–5.

---

### 1.6 Comparative Summary of Granular Round Systems

| System                                        | Round / Interval Duration        | Initiative / Turn Model                      | Core Benefit                                                 | Primary Failure Mode                                                  | Table Overhead Rating                    |
| :-------------------------------------------- | :------------------------------- | :------------------------------------------- | :----------------------------------------------------------- | :-------------------------------------------------------------------- | :--------------------------------------- |
| **GURPS 4e**                                  | 1 Second                         | Unilateral cyclical turns                    | Unmatched physical realism; textbook mechanics               | 1-yard movement slog; 1000:1 real-to-simulated time ratio             | **Extreme** (Math & checks per second)   |
| **Mythras**                                   | 3–5 Seconds                      | Cyclical pulses by APs                       | Realistic fencing "phrase"; outnumbering is naturally lethal | "Turtle meta" (hoarding APs); tracking APs across pulses              | **High** (Multi-pulse tracking)          |
| **Riddle of Steel**                           | 1–2 Seconds                      | Simultaneous Red/White dice & 2 Tempos       | True martial psychology; lethal stakes; reach dynamics       | Blind-bidding mental math; complete collapse in group combat          | **High** (Duels only)                    |
| **Burning Wheel**                             | 1–2s per Volley (3-Volley round) | Simultaneous 3-action scripting              | Zero planning downtime; predictive outplaying                | Scripting paralysis; "committed silliness" when targets move          | **Extreme** (Interaction matrix lookups) |
| **Continuous Ticks** _(Exalted / HackMaster)_ | Continuous (1 tick = ~1s)        | Linear time track / action delay advancement | Natural weapon speed modeling; smooth interrupts             | Wheel/tracker fragility; DV-shredding exploits; tick counting fatigue | **High** (Tracker dependency)            |

---

## 2. Spatial Engagement & Interception without Turn-Based 'Attacks of Opportunity'

### The Core Problem: The "Frozen World" Anomaly

Turn-based combat engines with unilateral turns (such as D&D 3e, 4e, 5e and Pathfinder) suffer from a fundamental simulation flaw: **time stops for all other combatants while the active player acts.** During a creature's turn, an enemy can sprint 30 feet, weave around three heavily armed knights, kill an unarmored wizard in the backline, and end their turn—while the knights stand frozen like statues.

To patch this absurdity, D&D introduced the **"Attack of Opportunity" (AoO)**. However, AoO is a clunky, legalistic band-aid:

1. **Unilateral Reaction Flaw:** It forces reactionary dice rolling on someone else's turn, interrupting the flow of play.
2. **Action Economy Exploitation:** In 5e, a character gets only one Reaction per round. Once a cheap goblin runs past the knight and draws the knight's single reaction attack, five more hobgoblins can run right past that same knight with absolute impunity. The knight's spatial control is mechanically exhausted by a single distraction.
3. **Counter-Intuitive Triggers:** AoOs trigger on _leaving_ a square, not entering it. You can sprint directly toward a spearman's face with impunity, but stepping backward away from a dagger gets you stabbed.
4. **Grid Dependency:** It turns tactical play into a legalistic geometry puzzle of measuring 5-foot squares, disengage actions, and line-of-sight edges.

How do systems that reject unilateral AoOs solve the problem of spatial control, screening allies, and intercepting rushers?

---

### 2.1 Simultaneous Movement & Engagement Locks (Wargames & Warhammer)

#### Mechanics

- **Engagement Range / Zone of Control (ZoC):** Every model projects an engagement bubble around its base (typically 1 inch or base contact).
- **The "Melee Lock":** When a model enters an enemy's engagement range, it is **locked in melee**. It cannot move any further during that turn.
- **Prohibition on Passing Through:** A model cannot move within engagement range of an enemy model unless it declared a direct charge against that model. You cannot "slide past" a defender to reach someone behind them; the physical presence of their engagement bubble creates an impassable wall.
- **Screening via Unit Coherency:** In Warhammer 40k and Age of Sigmar, infantry models deployed in a line with 2-inch coherency gaps create an unbroken zone of denial. Because opposing models cannot pass between bases without entering engagement range, a screen of cheap infantry physically prevents enemy cavalry or monsters from reaching backline artillery.
- **Charge Reactions:** When a unit is charged, it may declare an immediate reaction: _Hold_ (brace for impact), _Stand & Shoot_ (unleash defensive ranged fire before contact), or _Flee_ (fall back, risking rout).
- **Disengagement Penalties:** Once locked, the only way to move away is to dedicate an entire turn to a _Fall Back / Disengage_ action, which forfeits all offensive output for the turn and often allows the opponent a pursuit or consolidation move.

#### Strengths & Weaknesses

- **Strengths:** Utterly transparent, binary board states. Zero out-of-turn interrupt rolls. A frontline defender reliably defends because their engagement bubble is a hard physical barrier.
- **Weaknesses:** The "Tarpit" phenomenon. A single 2-point goblin touching the foot of an 800-point dragon locks the dragon in place for an entire round. In small-scale RPG skirmishes, engagement locks can feel too rigid and gamey without nuanced opposed checks.

---

### 2.2 Movement Commitment & Pre-Committed Interception Checks

#### Mechanics

- **Pre-Committed Overwatch / Interdiction (Chain of Command, Battlegroup, Infinity):** Instead of granting free reactive attacks to anyone who moves nearby, a combatant must spend their action to actively enter a **Guarding / Overwatch Stance**.
  - A soldier holding an Overwatch marker covers a specific arc or corridor.
  - When an enemy enters that corridor, the overwatching soldier resolves their attack _before_ the moving soldier can complete their action.
  - If no enemy enters, the action was still consumed watching the door. Spatial control requires active dedication of time and focus; you do not get it for free while also swinging a sword.
- **The "Guard" Maneuver (Legend of the Five Rings 5e):**
  - L5R uses Range Bands (Range 0: Grapple, Range 1: Melee, Range 2: Spear/Polearm, Range 3: Close Ranged, Range 4–5: Long Ranged).
  - A samurai may spend an action to declare a **Guard Action** targeting an ally within Range 0–1.
  - Until the samurai's next turn, any enemy who attempts to attack that ally or close into Range 0–1 of that ally is automatically intercepted: the attack is redirected to the guarding samurai, or the enemy is locked at Range 1 with the samurai.
- **Opposed Interception Contests (Savage Worlds):**
  - In Savage Worlds, if a character attempts to move past an unengaged opponent, the defender can declare an Interception.
  - Rather than a free unpunished attack, this resolves as an opposed Athletics / Agility check. Success stops the rusher in their tracks and binds them into melee; failure allows the rusher to slide past.

#### Strengths & Weaknesses

- **Strengths:** Promotes intentional tactical roles. A player who wants to "tank" or screen the squishy scholar actively plays a Guard or Intercept action, creating meaningful trade-offs between dealing damage and protecting allies.
- **Weaknesses:** If opposed checks are rolled for every step of movement, table time slows down.

---

### 2.3 Facing, Reach Advantage, and Simultaneous Collision / Tackle Declarations

#### Historical Martial Treatises (Liechtenauer, Silver, Swetnam)

In historical European martial arts, spatial control is not an "opportunity attack after someone runs past." It is governed by **Measure (_Mensa_) and Reach Advantage**:

1. If an unarmored fighter holding a dagger tries to sprint past a fighter holding a 2.5-meter spear, they must pass through the spearman's _Krieg_ (Threatened Range).
2. The spear point commands the space. To move past the spearman, the dagger wielder must physically push past the point.
3. If the dagger wielder simply sprints forward, the spearman doesn't "react after they pass"—the spearman thrusts forward, impaling the rusher before the rusher's dagger can physically reach striking distance.

#### Mechanics in Modern Systems (Mythras & GURPS Martial Arts)

- **Reach as an Impassable Barrier:**
  - In Mythras, weapon reach is categorized into discrete tiers: _Touch_, _Short_ (Dagger), _Medium_ (Arming Sword), _Long_ (Longsword, Bastard Sword), _Very Long_ (Spear), _Extremity_ (Pike).
  - When a shorter-weapon combatant approaches a longer-weapon combatant, the longer weapon holds **Reach Advantage**.
  - The long-weapon combatant strikes **first** as the shorter weapon enters their range.
  - If the long-weapon attack succeeds, the target is struck and held at distance. To close inside the spear's reach, the shorter combatant must spend an AP to execute a _Close Distance_ maneuver (parrying or beating the weapon aside). Until they successfully close, they cannot physically attack the spearman!
- **Simultaneous Collision / Tackle Declarations:**
  - In simultaneous round systems (such as CardPG or Burning Wheel), movement is an explicit action declared during the planning phase.
  - If Player A declares: _"Maneuver: Sprint past the Vanguard to attack the Healer,"_ and the Vanguard declares: _"Action: Bodyguard / Intercept rusher,"_ both actions reveal at the exact same moment.
  - The Vanguard does not need an out-of-turn "reaction." The Vanguard's declared action directly intercepts the rusher's vector during the Resolve Step.
  - An opposed check (Strength vs. Speed) resolves the collision. If the Vanguard wins, the rusher is tackled, shoved back, or locked in melee at the Vanguard's position, and their attack on the Healer is completely invalidated.

---

## 3. Ergonomic Multi-Round Action Tracking via Physical Cards

### The Challenge: Beyond Single-Turn Actions

In real combat, significant tactical actions do not happen in 1–2 seconds:

- Nocking, drawing, aiming, and loosing a 100+ lb military warbow: **6.0 – 10.0 seconds** (2 to 3 rounds).
- Cocking and reloading a windlass heavy crossbow: **10.0 – 15.0 seconds** (4 to 5 rounds).
- Chanting and channeling a complex arcane incantation: **6.0 – 12.0 seconds** (2 to 4 rounds).
- Hemostasis / packing a catastrophic arterial wound with a tourniquet: **15.0 – 30.0 seconds** (5 to 10 rounds).
- Prying open an iron portcullis or clearing a collapsed timber: **10.0 – 20.0 seconds** (4 to 7 rounds).

Traditional tabletop games track multi-round durations using pencil-and-paper tally marks or loose cardboard/plastic tokens (e.g., placing 3 "aim" or "charge" tokens on a card and removing 1 per round).

#### The Failure Modes of Token Tracking:

- **Tabletop Clutter & Spillage:** Loose tokens slide around, get knocked off character sheets by stray dice rolls, and clutter the physical play space.
- **Memory & Accounting Overhead:** _"Did I remove my token at the start of this turn, or did I forget to remove it last turn?"_ Tracking multiple countdown tokens across 4 players and multiple NPCs induces constant table disputes.
- **Anti-Elegance:** Forcing a game engine to rely on loose plastic tokens undermines the tactile elegance of card-driven design.

How do leading card-driven and tactical board games track multi-round durations using **pure card ergonomics**?

---

### 3.1 Card Exhaustion, Orientation, and Rotation Clocks

#### Games

_Magic: The Gathering_, _Mage Knight_, _Marvel Champions_, _Arkham Horror LCG_, _Spire's End_, _Tainted Grail_.

#### Mechanics

- **Binary State Tapping (0° vs. 90°):**
  - **0° (Vertical / Ready):** The card is available for use.
  - **90° (Horizontal / Exhausted):** The card has been committed or fired and is recovering.
  - In _Mage Knight_, basic action cards can be rotated sideways to represent a weak, generic +1 maneuver, or kept upright for their powerful printed text.
  - In _Arkham Horror LCG_, an Asset card is "Exhausted" (turned sideways) when activated, remaining sideways until the Upkeep Phase.
- **The 4-Edge Rotation Clock (Quarter-Turn Tracking):**
  - Used in _Spire's End_ and _Tainted Grail_.
  - A single card has 4 stages or numbers printed on its four edges:
    - **Top Edge:** Stage 1 (Initiating / Charging)
    - **Right Edge:** Stage 2 (Mid-Channel / Aiming)
    - **Bottom Edge:** Stage 3 (Fully Primed / Ready to Release)
    - **Left Edge:** Stage 4 (Spent / Expended)
  - As rounds advance, the player simply rotates the card 90 degrees clockwise so that the current active stage faces forward (toward the opponent or player).
  - When the final stage is reached, the card triggers its grand effect and is discarded.

#### Ergonomic Analysis

- **Pros:** Completely zero-token! 100% card-native. Clear at a glance across the table.
- **Cons:** Limited to a maximum of 4 discrete stages. Requires dedicated graphic design and layout. Can be accidentally disturbed if someone bumps the playmat.

---

### 3.2 Face-Down Countdown Stacks ("Under-Card Stacks" / Sunk Stamina)

#### Games

_Netrunner_ (hosting and advancement mechanics), _Conquest of Nerath_, _Magic: The Gathering_ (Suspend / Hideaway mechanics), _Android: Infiltration_, _Yomi_.

#### Mechanics

- **The "Depletion / Sinking" Stack:**
  - When playing a multi-round action (e.g., _Crossbow Windlass Reload: 2 Rounds_), the player places the Action Card face up in their active play area.
  - The player takes cards from their hand (or flips them from the top of their draw deck) and places them **face-down beneath the active card** equal to the required duration (e.g., 2 face-down cards).
  - During the Cleanup Step of each subsequent round, the player slides **1 face-down card out from underneath** and discards it to their expended pile.
  - When the final under-card is removed, the Action Card is fully resolved! The crossbow is loaded, the spell detonates, or the wound is bound.
- **The "Accumulation / Charging" Stack:**
  - Conversely, an ongoing Action Card sits in the active area. Each round the player dedicates their focus to it, they slide 1 card from their hand or deck face-down underneath it.
  - When the stack reaches the printed threshold (e.g., 3 cards), the accumulated energy unleashes.

#### Ergonomic & Ludological Analysis

- **Zero Component Footprint:** Eliminates all external tokens. The cards _themselves_ are the counter mechanism.
- **Tactile & Visual Clarity:** The physical thickness of the card stack under the Action Card provides immediate, tactile feedback of how much effort and time remain. Everyone at the table can instantly see that the archer is midway through a heavy draw.
- **Integration with Deck Stamina:** In deck-building or card-depletion engines (like CardPG), placing cards face-down under an action physically locks up the character's deck resources. This naturally simulates the fact that a character spending 3 rounds reloading a windlass crossbow has tied-up hands and reduced mental focus to react or defend!

---

### 3.3 Multi-Stage / Split Cards & Sliding Layouts

#### Games

_Gloomhaven_, _Aeon's End_, _Arkham Horror LCG_, _Pathfinder ACG_.

#### Mechanics

- **Top/Bottom Split Phasing:**
  - In _Gloomhaven_, every card has a Top Action and a Bottom Action. Players can weave actions across rounds, using one half for setup/movement and the other half for the payoff.
  - Some cards have persistent tracker tracks printed directly on the card with checkbox nodes (e.g., 4 charge icons).
- **Card Tucking / Sliding Splay:**
  - A card is tucked partially underneath an item card, character dashboard, or another action card.
  - As stages advance, the card is slid downward or sideways, exposing successive icon bands or rules text.
  - _Example:_ Tucking an `Aim` card under a `Longbow` item card. Round 1: Exposes `Stage 1 (+1 Strength)`. Round 2: Slid further to expose `Stage 2 (+3 Strength, Piercing)`. Round 3: Released.

#### Ergonomic Analysis

- **Pros:** Highly structured, zero confusion about what rules apply at each stage.
- **Cons:** Requires rigid physical board space and careful sliding manipulation; less practical on crowded tables.

---

### 3.4 Persistent Stances, Channeling, and "The Right to Abort"

#### Games

_Gloomhaven_ (Active Area Persistent Cards), _BattleCON / Exceed_ (Sustained Stances and Continuous Boosts), _Warhammer Underworlds_.

#### Mechanics

- **Active Zone Persistence:**
  - When played, the Action Card does not discard during Cleanup. It moves to the player's "Active Stance Area" in front of their deck.
  - The card remains face-up on the table, continuously projecting its effect (e.g., `Shield Wall Stance: +1 Defense to adjacent allies`, or `Drawing Warbow: Preparing heavy shot`).
- **Vulnerability & Interruption:**
  - While maintaining an active multi-round card, the character is physically and cognitively committed.
  - If the character suffers an attack, takes [[Impact]], or is forced to play a defense card, the active multi-round card is subjected to an **Interruption Check**:
    - _Voluntary Abort:_ The player may choose to break concentration, discarding the active card to safely defend from hand.
    - _Enduring the Blow:_ The player refuses to break concentration, facing the attack with only baseline/innate defense, gambling their physical safety to keep the multi-round action alive.

#### Ergonomic Analysis

- **Ludonarrative Harmony:** Seamlessly models the tension of drawing a heavy warbow or chanting an arcane ritual while an enemy swings an axe at your head.
- **Player Agency:** Aligns with informed risk: the player is never arbitrarily forced into failure, but must choose whether the payoff is worth suffering catastrophic injury.

---

## 4. Actionable Synthesis & Design Recommendations for CardPG

CardPG possesses a uniquely suited mechanical engine to solve these three design challenges:

1. **The 24-Card Universal Deck:** Stamina, health, skill, and presence of mind are all unified in a single 24-card deck.
2. **Defender-Centric Resolution:** The entity facing pressure flips cards; attackers set Strength.
3. **Simultaneous Crisis Time:** Rounds are executed in parallel: **Plan Step** (secret commitment of an Action Stack or Pass) -> **Resolve Step** (simultaneous reveal and resolution) -> **Cleanup Step**.
4. **Three Action Colors:** Red (Force/Endurance), Yellow (Speed/Precision), Blue (Intellect/Discipline).

Below are concrete, actionable mechanics for CardPG derived from this research.

---

### Recommendation 1: Calibrate Crisis Time to 2–3 Seconds ("The Phrase of Arms")

#### The Finding

- 1-second rounds (GURPS) cause the "1-yard movement slog" and turn-dilation paralysis.
- 6–10 second rounds (D&D) dissolve weapon reach, footwork, and tactical tempos into an abstract blur.
- 2–3 seconds (the Liechtenauer fencing phrase / _Vor-Nach-Indes_ exchange) is the optimal temporal unit for tactical tabletop combat.

#### Implementation in CardPG

- Formally calibrate **1 Round of Crisis Time = 2 to 3 seconds of narrative time.**
- Within this 2–3 second window:
  - A combatant can execute one complete tactical phrase: a gather-step and cut, a parry-riposte, a short sprint into guard, or a protective screen.
  - Actions that take 4 to 10 seconds (drawing a 120-lb warbow, loading a heavy crossbow, applying a tourniquet, prying open a grate) are explicitly authored as **Multi-Round Actions (2 to 3 Rounds)**.

---

### Recommendation 2: Spatial Control via Simultaneous Declarations, Reach Priority, and Engagement Locks (No AoO)

Because CardPG utilizes **Simultaneous Play**, the "frozen world" anomaly of D&D does not exist. An enemy cannot sprint past a standing defender while time is stopped, because the defender commits their action at the exact same moment.

To handle spatial control, screening, and interception cleanly without reactionary interrupts, CardPG should adopt three unified spatial mechanics:

#### 1. Measure & Reach Priority (_Krieg_ Entry)

- As established in `combat-spacing-and-reach.md`, weapons command **Static Reach** and **Dynamic Reach** (_Krieg_).
- When an enemy declares movement that crosses through a defender's _Krieg_ (such as trying to rush an ally behind the defender):
  - **Reach Priority:** If the defender plays an Attack or Ward action with a longer weapon (e.g., Two-Handed Spear, Reach 2.5m vs. Dagger/Sword, Reach 1.4m), the defender's attack resolves **first** during the Resolve Step.
  - If the defender's strike generates [[Impact]] or inflicts a Consequence, the rusher's forward momentum is halted at spear-point (Consequence-driven failure!). The rusher is stopped cold in _Zufechten_ and cannot reach the ally.

#### 2. The `Intercept` Maneuver (Active Screening)

- Rather than getting free passive opportunity attacks, a defender who wants to screen an ally plays an **Intercept** or **Guard** Action Stack during the Plan Step (typically a `Yellow` or `Red` action):
  - **Rules Text:** `Action: Guard / Intercept (Cost X) -> Choose an adjacent ally. Any melee attack targeting that ally this round is redirected to you. If an enemy attempts to move past your position, they are locked in Melee with you.`
  - This preserves deliberate player agency: screening is an active, heroic commitment of attention, not a passive legalistic tax.

#### 3. The Bind & Engagement Lock (_Krieg_ Lock)

- When two combatants are at _Krieg_ (in melee contact), they are **Engaged**.
- As established in `tactical-movement.md`, turning your back and running away is the moment of greatest physical vulnerability. Therefore:
  - A combatant cannot simply declare a standard move away from an engaged opponent.
  - To safely disengage, the player must play a **Covering Action** (such as `Disengage`, `Beat & Retreat`, or `Shove`) that creates an empty tempo.
  - If a player declares movement away without a covering action, their opponent's declared attack this round gains an automatic **+3 Strength modifier** (Major Leverage / Unguarded Target), and resolves against the fleeing character's unarmored rear.

---

### Recommendation 3: Zero-Token Multi-Round Action Tracking via "Under-Card Depletion Stacks"

CardPG should completely reject loose cardboard/plastic countdown tokens. Instead, multi-round actions should be tracked natively using the character's cards:

#### The Mechanism: "Under-Card Depletion Stack"

When an Action Card has a duration greater than 1 round (e.g., `Duration: 2 Rounds`), it uses the **Under-Card Stack**:

1. **Commitment (Plan Step of Round 1):**
   - The player plays the Action Card face up into their Active Zone.
   - Along with any normal card Cost, the player places **1 card face-down beneath the Action Card** for each additional round required (e.g., a 2-round action places 1 under-card; a 3-round action places 2 under-cards). These cards come from the player's hand (or the top of their draw deck if specified by the card).
   - The Action Card remains in the Active Zone during the Cleanup Step; it is _not_ discarded.
2. **Advancement (Cleanup Step of Round 2+):**
   - During the Cleanup Step of each subsequent round where the character maintains focus, the player slides **1 face-down card out from underneath** and discards it to their expended pile.
3. **Resolution (The Climax):**
   - When the last under-card has been discarded (or at the start of the round when the stack is empty), the Action Card triggers its completed effect during the Resolve Step!
   - Once triggered, the Action Card discards to the expended pile as normal.

#### Card Ergonomics Diagram: The Under-Card Stack

```
Round 1 (Plan): Play Action Card + Tuck 2 Under-Cards
+---------------------------+
| HEAVY WARBOW: FULL DRAW   |  <- Face-Up Action Card
| Cost: 1 | Duration: 2 Rds |
+===========================+
| [ Face-Down Under-Card 1 ] |  <- Tucked underneath (Sunk Stamina)
+---------------------------+
| [ Face-Down Under-Card 2 ] |  <- Tucked underneath (Sunk Stamina)
+---------------------------+

Round 2 (Cleanup): Discard Under-Card 1 to Expended Pile. (1 under-card remains)
Round 3 (Resolve): Empty stack! Release shot with +6 Strength (Piercing).
```

#### Why This Mechanism Perfectly Fits CardPG:

- **Zero Loose Tokens:** The table remains completely free of dice, beads, or wooden cubes.
- **Tactile & Visual Feedback:** The physical thickness of the card stack under the Action Card provides immediate, intuitive feedback of the remaining duration.
- **Ludonarrative Sunk Stamina:** Placing cards face-down under an action physically locks up the character's deck resources. This mechanically models that drawing a 120-lb warbow or packing an arterial bleed consumes physical stamina and hands, leaving the character with fewer cards in hand to defend or maneuver.
- **The Right to Abort (Informed Risk):** If an enemy charges the archer while they have 2 under-cards locked up, the archer is not helpless. The player holds the agency to **Abort**: discard the warbow and under-cards to their expended pile, instantly freeing their hands to play a defensive Action Stack or flip freely from deck!

---

### Concrete Card Schemas for Multi-Round Actions

Below are three archetype card designs illustrating how this system operates in play:

#### 1. Ranged Martial: Heavy Warbow Full Draw

```yaml
name: "Military Warbow: Deliberate Draw"
color_strengths: { red: 3, yellow: 4, blue: 1 }
cost: 1
type: "Crisis Action"
keywords: ["Attack", "Ranged", "Duration: 2"]
rules_text: >
  Plan: Place this card in your Active Zone with 1 card from hand face-down beneath it.
  While active, you cannot take Melee actions or move.
  When the under-card is discarded during Cleanup:
  Next Round Resolve: Unleash a devastating shot. Strength = {Yellow} + 6 (Piercing).
  If you suffer Severity 2+ Consequence while active, this action is Aborted.
```

#### 2. Technical Medical: Pressure Dressing / Hemostasis

```yaml
name: "Emergency Hemostasis"
color_strengths: { red: 2, yellow: 2, blue: 4 }
cost: 1
type: "Crisis Action / Narrative Task"
keywords: ["Task", "Medical", "Duration: 3"]
rules_text: >
  Plan: Target an adjacent ally with an active [Arterial Bleed] or [Severe Trauma] Condition.
  Place this card in your Active Zone with 2 cards from deck face-down beneath it.
  While active, you and the patient must remain stationary.
  When the last under-card is discarded during Cleanup:
  Resolve: Downgrade the patient's Condition to [Stabilized Wound].
  You may voluntarily Abort this card at any time to defend.
```

#### 3. Defensive Martial: Spear Brace & Intercept

```yaml
name: "Spear Wall: Impaling Brace"
color_strengths: { red: 4, yellow: 2, blue: 2 }
cost: 1
type: "Crisis Action"
keywords: ["Stance", "Reach", "Duration: 1"]
rules_text: >
  Plan: Place this card in your Active Zone (Orientation: 90° Tapped).
  Passive: You command Dynamic Reach (2.5m).
  Trigger (Resolve): If an enemy attempts to enter your Krieg or target an adjacent ally:
  Resolve your strike first! Strength = {Red} + 2.
  If the target suffers any Consequences, their movement is halted at your spear tip.
  Cleanup: Rotate upright and discard to expended pile.
```

---

## 5. Conclusion & Next Steps

By synthesizing the best practices of historical simulation and modern card-driven tabletop design, CardPG can cleanly resolve short intervals, spatial control, and multi-round actions without incurring the mechanical traps that have plagued older systems:

1. **Pacing:** Fixing Crisis Time rounds to **2–3 seconds** captures the visceral drama of a martial fencing phrase without GURPS's 1-yard movement slog or HackMaster's tick-counting fatigue.
2. **Spatial Control:** Replacing unilateral "Attacks of Opportunity" with **Simultaneous Reach Priority**, **Active Guard Stacks**, and **Krieg Engagement Locks** honors real-world martial physics while eliminating immersion-breaking reaction loopholes.
3. **Ergonomics:** Replacing loose cardboard tokens with **Face-Down Under-Card Countdown Stacks** maintains CardPG's 24-card physical elegance, using the deck itself as the clock, the stamina sink, and the risk engine.

### Recommended Next Actions

- [ ] Incorporate the **2–3 Second Crisis Round Calibration** into `design/rules/core-rules.md`.
- [ ] Author an official rules module: `design/rules/modules/spatial-engagement-and-reach.md` defining _Krieg_ locks, Reach Priority, and active Intercept stacks.
- [ ] Draft an authoring guideline in `design/authoring/card-schemas-and-syntax.md` specifying the syntax and standard rules text for `Duration: X` Under-Card Stacks.
