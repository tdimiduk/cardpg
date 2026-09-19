# Resolution System Pitfalls & Anti-Patterns

## Document Purpose

Authoritative catalog of recurring mechanical failure modes, degenerate incentives, and tabletop friction points discovered across _caRdPG_ resolution iterations (from legacy _Defend from Hand_ and _Allowed Severity Tables_, to canon _Defense + Resilience_, to _Consequence Pool / "I Cut, You Choose"_, and exploratory alternatives).

This document serves as a companion to [resolution-design-constraints.md](resolution-design-constraints.md). While the constraints define what the engine must achieve, this catalog details the subtle, cascading ways mechanics break down when tested against real table play, card economy math, and player psychology. Any new resolution proposal must be audited against these pitfalls before adoption.

---

## 1. Systemic Context: The Card Economy & Timescales

To understand why resolution mechanics fail, designers must first understand two foundational realities of _caRdPG_'s card engine:

### 1.1. In-Combat vs. Cross-Combat Fatigue Dynamics

- **The 24-Card Endurance Clock:** A character's 24-card deck is primarily an endurance and resource-tracking mechanism **across encounters and during exploration**, not an immediate combat finisher.
- **The Turn Horizon:** In Crisis Time, players draw 2 cards per round. Without attacks, a fresh deck lasts 12 rounds before cycling. Even when sustaining an attack each round costing ~2 defensive flips, a combatant consumes ~4 cards per round, yielding **~6 rounds of intense combat before a single Fatigue Cycle occurs**.
- **Discard Inefficacy:** When a Fatigue Cycle finally triggers, it adds 2 `Fatigue` cards (plus Burden) to the deck. This pollutes it some, but it's more of a minor degredation than a crushing setback and characters should be able to function relatively fine through several fatigue cycles.
- **The Math of a Single Flip:** A single card flipped from deck to defend represents $\sim 1/24\text{th}$ of an endurance cycle. It is a minor stamina expense.

### 1.2. Pacing Goal: Dynamic Flow and Decisiveness, Not Arbitrary Round Caps

- **Combat Must Not Drag:** The design goal is not an arbitrary mandate (e.g., "every combat must end in 3–6 rounds"). Rather, rounds must be **lightweight, simultaneous, and tactically dynamic**.
- If turns resolve rapidly without procedural friction, a 7-to-8 round duel is exciting and engaging.
- The failure mode is **procedural drag**: when a 3-round skirmish takes 45 minutes of real time because players are solving coin-partition math, managing multiple physical trauma decks, or rifling through boxes to tutor specific upgrade cards mid-fight.
- Combat should feel decisive when appropriate, adapt to the narrative stakes of the scene, and cleanly drive to conclusion without artificial stagnation.

---

## 2. The Core Mechanical Pitfalls

---

### Pitfall 1: The Stagnation Trap (The Fight That Never Ends)

_(Formerly referenced as GC1)_

- **The Anti-Pattern:** A resolution mechanic that lacks a reliable, vertical mechanism to conclude a fight, or allows a combatant to stall indefinitely.
- **How It Manifests:**
  - **The Infinite Parry Loop:** Defenders can always flip more cards from their deck to absorb incoming Strength, relying on mid-action reshuffles to keep going. Because Fatigue cards only dilute the discard, an uncapped flip system allows a defender to absorb attacks endlessly unless an unmitigated trauma clock intervenes.
  - **Horizontal Traps & Ceiling Caps:** Consequence systems where attacks top out at "moderate injuries" or horizontal status tags without an explicit, escalating bridge to incapacitation or narrative defeat.
  - **Out-Healing the Attacker:** In-combat tactical recoveries that allow characters to clear conditions or reset defenses faster than an attacker can re-apply them.
- **The Audit Test:** _If a defender has cards in their deck and consistently chooses the safest defensive option, does the combat mathematically drive toward a decisive conclusion within a reasonable number of exchanges?_

---

### Pitfall 2: The False Dilemma & Degenerate Defensive Choices

_(Formerly referenced as GC2)_

- **The Anti-Pattern:** Offering a defensive choice or menu where one branch is mathematically, tactically, or psychologically dominant, turning a supposed "tactical trade-off" into a no-brainer or a noob trap.
- **How It Manifests:**
  - **Deck Flips vs. Real Trauma (The Fatigue Cost Illusion):** Offering a choice like _"Flip 2 more cards from your deck OR suffer an on-table wound/consequence."_ Because a single flip is only $\sim 1/24\text{th}$ of an endurance cycle and fatigue cards go to discard, no rational player will accept a lasting physical impairment, loss of actions, or vulnerability tag to save 2 flips. Players will burn through their entire deck before voluntarily taking a wound.
  - **The Mandatory Fold:** Offering a "Push Your Luck" mechanic with a fixed bailout (e.g., _"keep flipping and risk lethal Tier 4, OR fold right now and take a fixed Tier 2"_). Against high-strength attacks, folding becomes mandatory, eliminating all tension and flatlining combat into identical Tier 2 outcomes.
- **The Audit Test:** _In a tense life-or-death crisis, would a rational player ever choose the alternate branch, or does one option completely overshadow the other?_

---

### Pitfall 3: The "Crack the Shell" Trap (Big Attack Dominance)

_(Formerly referenced as GC3)_

- **The Anti-Pattern:** Requiring incoming attacks to exceed a high static threshold (e.g., Guard rating, Armor Soak, high Defense number) before any mechanical progress is made.
- **How It Manifests:**
  - **Invalidating Probing Attacks:** If an attack must exceed a threshold of 6 to do anything, an attack of Strength 4 or 5 bounces completely with zero effect. The attacker wasted cards and an entire turn.
  - **The "Save for the Knockout" Meta:** When small attacks do nothing, players quickly realize that making probing attacks, feints, or minor strikes is mathematically suboptimal. The only viable strategy becomes hoarding cards across multiple turns to unleash one massive, overwhelming alpha-strike.
  - **Armor as an Impenetrable Wall:** High armor turns combat into a binary state: complete immunity until someone hits an exorbitant number, at which point the armor wearer collapses instantly.
- **The Audit Test:** _Does a minor, low-strength attack by a secondary combatant (like a goblin minion or an off-hand dagger jab) make tangible, incremental progress toward weakening the target, or does it completely bounce?_

---

### Pitfall 4: The Mono-Color Fallacy (Card Anatomy Blindness)

_(Formerly referenced as GC4)_

- **The Anti-Pattern:** Designing rules that assume a card has an atomic, single-color identity (e.g., "draw a Red card," "discard a Blue card," or "Red counters Yellow").
- **How It Manifests:**
  - In _caRdPG_, **every single card in the 24-card deck has printed values for all three Colors** (`Red`, `Yellow`, and `Blue`). There is no such thing as a "Red card"; there are only cards that might have Red 5, Yellow 2, and Blue 1.
  - Rules requiring color matching or color triangles break down when evaluating a card that has equal or multi-attribute stats (e.g., a card with Red 3, Yellow 3, Blue 3).
  - Forcing players to compare, multiply, or cross-reference all three numbers on every drawn or flipped card introduces severe arithmetic friction and cognitive drag at the table.
- **The Audit Test:** _Does the mechanic treat cards as having a single color, or does it respect the universal tri-color anatomy without requiring multi-value calculation matrices?_

---

### Pitfall 5: Scale Invariance Breakage & Parameter Desynchronization

- **The Anti-Pattern:** Introducing static numerical thresholds, flat soak values, or subtraction math that only functions when card values are in the low single digits (1–5).
- **How It Manifests:**
  - **Breaking Character Progression:** As characters advance, they upgrade the numbers on their cards (e.g., values scale from 2–3 to 5–8). If a defensive threshold is hardcoded (e.g., "Armor absorbs 2 flat damage"), attacks quickly blow past it, making defensive gear obsolete unless every piece of equipment and enemy stat scales in complex mathematical lockstep.
  - **Breaking Macro-Scale Play:** _caRdPG_ is architected to allow macro-scale entities (an entire army, a fortified keep, a faction) to use a 24-card deck with numbers in the 100s or 1,000s using the **exact same core rules**. The canon engine achieves this because `Impact` is measured by the **count of cards flipped**, not a subtracted numerical difference (an army-scale attack of Strength 800 met by cards averaging 250 still flips ~3 cards, generating 3 Impact).
  - Mechanics that rely on absolute numerical subtraction ($\text{Strength} - \text{Armor}$) break scale invariance; mechanics that rely on ratios, card counts, or proportional thresholds preserve it.
- **The Audit Test:** _Does this resolution formula produce the exact same outcome and pacing if all numbers on cards and challenges are multiplied by 10 or 100?_

---

### Pitfall 6: Action-Gear Hard Coupling (The Disarm Brick)

- **The Anti-Pattern:** Printing specific weapon stakes, damage types, or mechanical weapon properties directly onto Action Cards in the 24-card deck.
- **How It Manifests:**
  - Action cards represent a character's **learned martial and mental capabilities** (footwork, timing, focus, techniques). Gear (weapons, shields, armor) lives as **equipment cards on the table**.
  - If an Action Card in your deck says _"Heavy Mace Crush: Inflicts Concussion,"_ and your character is disarmed, drops their mace, or switches to a rapier or improvised torch, that card becomes dead, nonsensical, or unplayable.
  - Players must be able to switch weapons, pick up items from the battlefield, or fight unarmed without having to rebuild or sleeve their 24-card deck mid-session.
- **The Audit Test:** _If a character is disarmed of their primary weapon, can they still legally and narratively play their deck's Action Cards using their fists, a shield, or an improvised club?_

---

### Pitfall 7: Pseudo-Hit-Points (The Linear Attrition Trap)

- **The Anti-Pattern:** Replacing hit points with an abstract counter or card-locking mechanism that behaves identically to hit points while adding extra table bookkeeping.
- **How It Manifests:**
  - Declaring that "taking 5 locked cards" or "accumulating 6 generic wound tokens" means defeat.
  - Every attack merely chips away 1 counter regardless of weapon profile, hit quality, or anatomical focus.
  - Symmetrical design breaks down: fighting a swarm of 6 goblin minions either requires tracking 30 individual card locks, or requires inventing ad-hoc, asymmetric exception rules for monsters.
- **The Audit Test:** _Does this mechanic produce qualitative, differentiated tactical hurdles that change how a character fights, or is it just an HP bar wearing a disguise?_

---

### Pitfall 8: The Combinatorial / Integer Partition Trap

- **The Anti-Pattern:** Asking players to spend variable currency (such as Impact) across multiple card tiers against a pool size threshold $N$, creating mathematical paradoxes.
- **How It Manifests:**
  - **The Single-Card Purchase Trap:** If buying a Severity 3 card costs 3 Impact, but the defender's pool size is $N = 2$, spending all 3 Impact on the high-severity card leaves 1 unfilled slot that defaults to a "No Consequence" blank. The defender picks the blank, meaning a massive 3-Impact strike deals **0 harm**.
  - Attackers are penalized for buying powerful strikes and must instead solve integer partition puzzles mid-fight (e.g., knowing that spending $1 + 1$ or $2 + 1$ is mathematically superior to buying a single big hit).
  - Players should be immersed in dramatic martial choices, not mid-turn coin-change optimization.
- **The Audit Test:** _Can a player inadvertently invalidate their own successful attack by choosing what intuitively seems like the most powerful option?_

---

### Pitfall 9: Mid-Combat Tutoring & Multi-Deck Rifling (10x Rule Violation)

- **The Anti-Pattern:** Requiring players to search through separate physical decks, card boxes, or lookup tables in the middle of Crisis Time to find specific upgraded conditions.
- **How It Manifests:**
  - Escalating a condition (e.g., `Off Balance` $\to$ `Knocked Prone` $\to$ `Sundered Armor`) forces players to halt combat, pick up separate Severity 1, 2, or 3 decks, rifle through them to find the named card, place it on the table, and reshuffle.
  - Managing multiple trauma decks alongside character decks, hands, tableaus, and status decks clutters physical table space and shatters dramatic momentum.
  - **The 10x Rule:** Complexity in the core rulebook costs 10x card complexity. Any resolution system that requires extensive procedural deck manipulation mid-round violates this precept.
- **The Audit Test:** _Can condition escalation be resolved in place (via multi-tier cards, tracking clips, or simple status flips) without rifling through face-down decks during combat?_

---

### Pitfall 10: The Feel-Bad Deck Lock

- **The Anti-Pattern:** Permanently or semi-permanently removing cards from a character's cycling deck due to a random defensive flip.
- **How It Manifests:**
  - In an unarmored skirmish or early exchange, an unlucky flip locks a player's best Action or highest-stat card into an "Injury zone" for the rest of the adventure.
  - This disproportionately harms younger or casual players, who feel punished for trying to participate. It creates a death spiral where a character becomes progressively less interesting to play as their fun options are stripped away.
  - Status Cards added to a deck (`Fatigue`, `Minor Wound`) dilute draws and add friction without deleting a character's core identity cards.
- **The Audit Test:** _Does suffering harm take away a player's core deck options early in a session, or does it impose tactical hurdles and deck dilution that can be actively managed?_

---

## 3. The Resolution Proposal Audit Checklist

Before any resolution mechanic is advanced to full proposal status, it must pass this 10-point audit:

|   #    | Check                        | Key Question                                                                                 |
| :----: | :--------------------------- | :------------------------------------------------------------------------------------------- |
| **1**  | **Decisive Conclusion**      | Does the mechanic cleanly drive to a conclusion without relying on infinite parry loops?     |
| **2**  | **No Dominant Menus**        | Does it avoid offering "deck flips vs. real wounds" false dilemmas?                          |
| **3**  | **Probing Attacks Matter**   | Do small attacks advance the combat state rather than bouncing off a static threshold?       |
| **4**  | **Tri-Color Compliance**     | Does the mechanic respect that every card has Red, Yellow, and Blue values?                  |
| **5**  | **Scale Invariance**         | Does the math hold if card numbers scale to double digits or army-level hundreds?            |
| **6**  | **Equipment Decoupling**     | Can characters be disarmed or swap gear without breaking their deck's Action Cards?          |
| **7**  | **Qualitative Harm**         | Does harm produce tangible, differentiated conditions rather than pseudo-HP counters?        |
| **8**  | **No Combinatorial Traps**   | Does spending effort/impact avoid integer partition paradoxes where big hits deal 0 harm?    |
| **9**  | **Zero Mid-Combat Tutoring** | Can resolution proceed without rifling through separate card decks mid-round?                |
| **10** | **Identity Preservation**    | Does the mechanic avoid locking or deleting a player's favorite cards on early random flips? |
