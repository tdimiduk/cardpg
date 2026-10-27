---
title: "Design Brief: Crisis Round Duration and Phrase Cadence"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
  vetting_notes: "Drafted following empirical synthesis on cognitive temporal integration, ATP-PCr energetics, and deck cycle calibration."
related_files:
  - "design/rules/core-rules.md"
  - "design/philosophy/design-precepts.md"
  - "design/research/synthesis/action-duration-and-perceptual-present.md"
  - "design/research/synthesis/combat-timelines-and-tempos.md"
  - "design/research/synthesis/dynamics-of-duel.md"
---

# Design Brief: Crisis Round Duration and Phrase Cadence

## Purpose of this Working Session Track

To establish a concrete, evidence-based time duration for a single round of **Crisis Time**, calibrate it against our 24-card deck engine and human physiology, and evaluate whether the historical martial concept of the **"Phrase" (or "Phrase of Arms")** should be formally integrated into our rules vocabulary.

---

## 1. Concrete Duration: The 2.0 to 3.0 Second Consensus

Based on converging empirical research across cognitive neuroscience, exercise physiology, and comparative tabletop ludology, this brief establishes the target calibration:

> **1 Crisis Round = 2 to 3 Seconds (centered at ~2.5 Seconds)**

```
       0.2s            0.5s            0.8s                      2.5s                     15.0s
--------|---------------|---------------|--------------------------|------------------------|---------> Time
   Motor Point     Choice Reaction   Voluntary Stroke      "THE SUBJECTIVE PRESENT"      ATP-PCr Exhaustion
   of No Return       + EMD Delay       Completion            (One Intentional Act)       (First Deck Cycle)
```

### The Three Converging Pillars

1. **Neurobiological Reality (The "Subjective Present"):**
   - Research by Ernst Pöppel and Paul Fraisse demonstrates that human consciousness automatically integrates sensory inputs and motor commands into discrete temporal chunks of **2.0 to 3.0 seconds**.
   - Across isolated global hunter-gatherer and modern cohorts, **93% of spontaneous intentional behavioral units** (gestures, tool manipulations, gaze shifts) cluster between 2.0 and 3.0 seconds.
   - An intentional "gestalt" action (a gather step and strike, a covering beat and retreat step, or a burst of movement) naturally occupies this exact window. Under 1 second, human actions are isolated ballistic twitches; beyond 3 seconds, unified apprehension disintegrates into retrospective memory.

2. **Physiological & Deck Cycle Alignment:**
   - In active combat, an engaged character draws 2 cards in the Plan Step and flips 3 to 4 cards during defense (because attackers concentrate high-value cards and printed modifiers, while defenders flip randomly). This consumes **~5 to 6 cards per round**.
   - In a 24-card deck, this triggers the first Fatigue Cycle at **Round 4.5 to 5** (~11–13 seconds).
   - Because the 2 newly added [[Fatigue]] cards enter the expended pile and are shuffled into a fresh 26-card deck, the delayed dilution effect means the character does not reliably draw or flip those Fatigue cards until **Round 6 to 8** (**~15 to 20 seconds**).
   - This **matches real-world physiology to the second**: the human anaerobic phosphagen system (ATP-PCr) provides maximal explosive power for **0 to 15 seconds**, after which the glycolytic burn sets in and fine motor accuracy degrades.

3. **Tabletop Pacing & Temporal Ratio:**
   - In 2.5-second rounds, a complete, decisive skirmish (15 to 30 seconds of real-world violence) takes **6 to 12 rounds**.
   - Because CardPG uses simultaneous declaration and resolution (Plan -> Resolve -> Cleanup) with zero sequential turn waiting, a round takes **~30 to 45 seconds of physical table time**.
   - A 6-to-8 round combat resolves in **5 to 10 minutes of table play**, cycling a 24-card deck once or twice.

---

## 2. Evaluating the Term "Phrase" (Phrase of Arms)

In historical fencing (both modern and classical European martial arts), a **phrase d'armes** (phrase of arms) is defined as a continuous sequence of offensive, defensive, and counter-offensive actions executed without a cessation of tempo or a break in engagement.

### Pros of Adopting "Phrase"

- **Martial Verisimilitude:** "Phrase" immediately communicates to players why they only get to do "one thing" in a round. A phrase is not a static 1-second jab or a 6-second laundry list of disjointed maneuvers; it is a single, coherent, rhyming exchange (e.g., _feint, parry, riposte_).
- **Simultaneity Framing:** It reinforces that both participants are engaged in the _same_ phrase together, rather than taking turns in a queue.
- **Narrative Depth:** It elevates the game's vocabulary beyond generic RPG terminology ("turn", "round") to reflect the rhythm and choreography of melee.

### Cons & Tabletop Friction

- **Learned Vocabulary Barrier:** "Round" is the universal tabletop gaming standard. Replacing "Round" entirely with "Phrase" risks confusing new players or sounding overly academic/pretentious.
- **Non-Combat Crisis Fit:** Crisis Time is also used for chases, environmental hazards (a collapsing tunnel), and intense social confrontations. Calling a round of a courtroom argument or a burning building collapse a "phrase of arms" is jarring.

### Structural Recommendation: "The Crisis Round (Phrase)"

We recommend retaining **Round** as the primary mechanical container in procedural rules, while introducing **"The Phrase"** as the conceptual and narrative definition of Crisis Time:

- In `core-rules.md`: _"Crisis Time resolves second-by-second struggles in simultaneous rounds. Each round represents a **phrase of action** lasting roughly 2 to 3 seconds—a single breath of intense focus where each participant commits to one coherent maneuver."_
- In `players-guide.md`: Use "Phrase of Arms" to explain the rhythm of combat, hand management, and why movement and striking are unified into a single action stack.

---

## 3. Key Tensions & Working Hypotheses

### Tension 1: Card Spend Variance in Skirmish vs. Duel — [ACTIVE HYPOTHESIS]

- In a 1-on-1 duel, both fighters spend cards symmetrically. In a 3-on-1 focus fire, a lone defender flips cards against three separate attacks, burning through their entire deck in a single 2.5-second round.
- _Hypothesis:_ This natural deck burn elegantly models historical small-group dynamics: outnumbering a defender makes survival near-impossible without needing special "gang up" rules.

### Tension 2: Non-Combat Crisis Pacing — [OPEN]

- In an urban debate or high-stakes puzzle, does a 2–3 second temporal definition hold, or is Crisis Time in social encounters a more abstracted psychological pulse?

---

## 4. Next Steps & Deliverables

- [ ] Update `design/rules/core-rules.md` Section 3 to explicitly anchor Crisis Time rounds at roughly 2 to 3 seconds ("a phrase of action").
- [ ] Incorporate the "Phrase of Arms" concept into `design/rules/players-guide.md` to ground player decision-making.
- [ ] Cross-reference round duration in `design/research/synthesis/combat-timelines-and-tempos.md`.
