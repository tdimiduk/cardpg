---
title: "Non-Combat Benchmark Scenarios"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Non-Combat Benchmark Scenarios

## Document Purpose

This document defines canonical, **rules-agnostic non-combat test scenarios** for _caRdPG_.

Historically, design iteration and play traces focused overwhelmingly on physical combat (duels, armor soak, weapon strikes, and bleeding trauma). As a result, proposed resolution mechanics repeatedly over-indexed on martial concepts, violating **Pitfall 12 (Combat-Centric Hyper-Specialization)** and struggling with General Actions and non-combat pillars.

These scenarios serve as an architectural benchmark. Any proposed resolution mechanic—whether [canon core rules](../rules/core-rules.md), the [consequence pool proposal](consequence-pool-tag-escalation/), or future candidate mechanics—must be able to resolve these exact scenarios cleanly.

Individual rules implementations and mechanical traces will be written in separate trace files within their respective system directories (e.g., `consequence-pool-tag-escalation/trace-noncombat-...md`).

---

## Shared Invariants Across All Scenarios

Each scenario specifies only the settled structural invariants of _caRdPG_:

1. **Challenge Input:** An external requirement expressed as `(Strength, Color)` (e.g., `Strength 7 Blue` or `Strength 8 Yellow`).
2. **Actor Profile:** A canonical PC archetype with a 24-card deck containing standard printed tri-color values (`Red`, `Yellow`, `Blue`), their current drawn hand, and their applicable **Table Cards** (gear, tools, credentials, standing).
3. **Pacing Context:** Whether the task is an instantaneous/minutes-long **General Action** in Adventuring Time (where success is assumed and resolution determines cost/fallout) or a tense round-by-round **Crisis Time** scene.
4. **The Dramatic Spectrum:** The expected narrative and mechanical band of outcomes:
   - _Clean Success ("Saying Yes"):_ Task achieved cleanly with zero lingering friction (only minor stamina/effort expended).
   - _Success with Friction:_ Task achieved, but imposes tactical complications, temporary exhaustion, depleted resources, or noise/suspicion.
   - _Severe Setback:_ Substantial delay, damaged equipment, alerting foes, or serious systemic condition.
5. **Ludonarrative Harm Coherence (Plausible Asymmetric Bleed):** Harm or friction suffered in these scenes should be carefully evaluated for how it bleeds into other pillars:
   - Social embarrassment should not make you significantly easier to kill outright if combat breaks out (though it can put you at somewhat of a disadvantage if you are off your game and not fighting well).
   - Spraining your ankle leaping a chasm is fine to cause significant problems for you when a monster attacks.
   - Your armor getting battered mostly should not affect how you negotiate (especially if you can take it off, unless you are negotiating with people who particularly esteem pristine armor).
   - Taking a concussion in combat can and should make it harder to negotiate or research.

---

## Scenario 1: The Broken Spire Chasm (Environmental / Hazard)

### Context & Narrative Stakes

The party is navigating the wind-swept ruins of an ancient aqueduct during a freezing rainstorm. A 10-meter span has collapsed. To secure a rope line for the rest of the party, the agile Swashbuckler attempts to traverse a slippery, rotting balance beam while buffeted by mountain crosswinds. Falling means catching oneself on a lower outcrop with bruised ribs and dropped gear—or worse.

- **Mode:** Adventuring Time (General Action).
- **Challenge Input:** **Strength 20 Yellow** (Challenging; Finesse / Balance / Agility).
- **Actor Profile:** Swashbuckler (Agile 24-card deck; high Yellow average ~3.5; trained in acrobatics/footwork).
- **Applicable Table Cards:**
  - `Mountaineer's Harness & Pitons` (Tool / Gear card on table).
- **Hand Interaction Note:** Whether the 4-card face-down Ready Hand can be viewed and committed to General Actions, or if General Actions resolve strictly through deck flips + table cards, is an open engine variable (see Ready Hand working brief).

### Gameplay Goals & Decisions

1. **Resource Commitment:** How the engine allows a player to commit trained capabilities vs. relying on stamina flips from the deck.
2. **Gear Utilization:** How the `Mountaineer's Harness` provides mechanical absorption or consequence mitigation.

### Expected Spectrum of Outcomes

- **Clean Success (Routine Effort):** Crosses gracefully, drives anchor pitons into the masonry, and drops the guide rope. Effort is purely routine stamina.
- **Success at a Cost (Moderate Impact):** Makes it across, but slips midway; catches the masonry hard. Suffers `Bruised Shins`, `Rattled Nerves`, or expends a utility consumable (`Frayed Rope`).
- **Severe Complication (High Impact):** Slides off the beam and dangles by the safety tether in the freezing wind; secures the anchor only after grueling struggle. Takes an active cold/exhaustion condition (`Hypothermic Shaking`) or loses an unfastened pack into the abyss.

---

## Scenario 2: The Port Warden's Gate (Social / Negotiation in Adventuring Time)

### Context & Narrative Stakes

The party needs to enter the walled port city of Oakhaven after nightfall with an undocumented companion. The Night Warden is a tired, cynical municipal officer who dislikes trouble but is susceptible to persuasive arguments, appeals to merchant protocol, or well-placed gratuities. The goal is to obtain passage through the water-gate without an official inspection log entry or an alarm being raised.

- **Mode:** Adventuring Time (General Action — **Not Crisis Time**).
- **Challenge Input:** **Strength 25 Blue** (Logic / Legal Precedent / Bureaucratic Protocol) OR **Strength 25 Yellow** (Fast-Talk / Bribery / Charm).
- **Actor Profile:** Swashbuckler (Silver-tongued, high Yellow/Red) assisted by Wizard (High Blue/Intellect).
- **Applicable Table Cards:**
  - `Guild Transit Seal` (Standing / Credentials card on table).
  - `Purse of Silver Coin` (Consumable / Asset card on table).

### Gameplay Goals & Decisions

1. **Approach Selection:** Choose whether to argue bureaucratic exception (Blue) using the `Guild Transit Seal`, or smooth things over with fast-talking patter and coin (Yellow).
2. **Social "Armor":** How does social standing or credentials mitigate fallout?

### Expected Spectrum of Outcomes

- **Clean Success:** The warden stamps the transit manifest with a knowing nod, pocketing a standard nominal toll, and waves the party through with no official record.
- **Success at a Cost:** The warden permits passage, but demands an exorbitant "late-tide inspection levy" (expending extra coin/cards) or insists on logging the party's names, creating a delayed narrative paper trail.
- **Severe Complication:** The warden becomes suspicious, locks the iron grate, and summons the Harbor Constable. The party gets through only by creating an immediate diplomatic incident or taking a social condition (`Blacklisted at the Docks`, `Under Watch`).
- **Harm Coherence Check:** Under no circumstances should a poor roll here inflict physical wound cards (`Cracked Ribs`) or make the character easier to stab in a subsequent combat.

---

## Scenario 3: Deciphering the Alchemical Grimoire (Investigation / Research / Crafting)

### Context & Narrative Stakes

An ally has been stricken by a strange, virulent fungal blight contracted in subterranean catacombs. In a ruined apothecary's study, the Wizard attempts to decipher a damaged, coded alchemical grimoire to identify the correct reagent formula before the poison reaches the victim's heart. This represents an extended analytical and laboratory task.

- **Mode:** Adventuring Time (General Action / Extended Task).
- **Challenge Input:** **Strength 35 Blue** (Difficult; Intellect / Esoteric Lore / Discipline).
- **Actor Profile:** Wizard (Scholarly 24-card deck; high Blue average ~4.0; trained in arcane lore and academy protocol).
- **Applicable Table Cards:**
  - `Alchemical Field Kit` (Tool / Workshop card on table).
  - `Elven Lore: Herbalism` (Trait / Knowledge card on table).

### Gameplay Goals & Decisions

1. **Analytical Depth:** Committing deep intellectual focus vs. rushing under time pressure.
2. **Material Toll:** How laboratory setbacks manifest when translating textual research into physical compounds.

### Expected Spectrum of Outcomes

- **Clean Success:** The Wizard cross-references the marginalia, identifies the rare distilled tincture needed, and prepares the cure cleanly without spoiling reagents or straining mental reserves.
- **Success at a Cost:** The formula is successfully decoded, but synthesizing it consumes rare alchemical reagents, causes minor toxic backdraft (`Strained Focus`, `Throat Irritation`), or takes extra time, letting the patient slip closer to the threshold.
- **Severe Complication:** The grimoire's protective runic seal triggers, scorching key folios; the cure is deduced only through grueling trial and error, inflicting mental exhaustion (`Migraine / Arcane Burnout`) and ruining costly laboratory equipment.

---

## Scenario 4: The Cell Interrogation (Opposed Social / Crisis Time)

### Context & Narrative Stakes

The party has captured an officer of the Crimson Syndicate in a secluded safehouse. The Syndicate's strike team is scouring the district; the party has approximately two minutes (3 rounds of Crisis Time) to break the officer's resolve and extract the location of the ritual cellar before reinforcements arrive. The captive is disciplined, spiteful, and attempting to stall for time.

- **Mode:** Crisis Time (Opposed Round-based Social Confrontation).
- **Challenge Input:** Opposed Social Duel.
  - _Captive:_ Defends with **Composure / Fanaticism** (Blue/Red composure stats, baseline Composure defense).
  - _Interrogators:_ Deliver social "attacks" using `Red` (Veiled threats, intimidation), `Yellow` (Deception, false promises of immunity), or `Blue` (Dismantling their alibi, psychological leverage).
- **Actor:** Shield-Fighter (playing the intimidating muscle) or Swashbuckler (playing the manipulative negotiator).
- **Applicable Table Cards:**
  - `Captured Syndicate Insignia` (Leverage card on table: grants +2 Strength to psychological attacks).
  - `Iron Shackles` (Physical restraint on table: prevents the captive from attacking physically, forcing purely social defense).

### Gameplay Goals & Decisions

1. **Vector & Tone of Interrogation:** Selecting between aggressive psychological pressure (`Red`) vs. deceptive rapport (`Yellow`) vs. logical dismantling (`Blue`).
2. **Clock Pressure:** Resolving within 3 rounds before the exterior door is breached by Syndicate hounds.
3. **Escalation Dynamic:** How social conditions (`Rattled Composure` $\to$ `Cornered Pride` $\to$ `Broken Silence`) accumulate on the captive until they yield the secret.

### Expected Spectrum of Outcomes

- **Decisive Breakthrough (Round 1–2):** The captive realizes their betrayal is already known, breaks under pressure, and surrenders the map and passphrases.
- **Grinding Concession (Round 3):** The captive holds out until the final moment, yielding partial or cryptic coordinates just as Syndicate footsteps hit the cobblestones outside.
- **Stalemate / Deceptive Misdirection:** The captive successfully stalls out the clock, feeding the party a poisoned lead or biting a cyanide capsule/triggering an alarm.

---

## Evaluation Criteria for Resolution Mechanics

When running these scenarios through any proposed resolution system, audit against these questions:

|   #   | Check                        | Key Question                                                                                                                                                          |
| :---: | :--------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1** | **Lexicon Universality**     | Does the mechanic resolve the scene using standard core terminology (`Strength`, `Impact`, `Mitigation`, `Consequence`) without introducing ad-hoc non-combat jargon? |
| **2** | **"Saying Yes" Cleanliness** | Does a single low-impact flip or strong hand commitment resolve cleanly without forcing trivial bookkeeping on the GM?                                                |
| **3** | **Meaningful Table Cards**   | Do tools, credentials, and kits provide tangible, intuitive mechanical mitigation (similar to armor in combat) without requiring separate rule subsystems?            |
| **4** | **Domain Decoupling**        | Are the resulting consequences strictly domain-appropriate (social, mental, environmental) with zero cross-domain harm bleed?                                         |
| **5** | **Tactical Fail-Forward**    | Do complications drive the story forward with interesting hurdles rather than dead-end binary "You fail to cross the chasm"?                                          |

---

## Future Roadmap: Multi-Scene / Macro Endurance Traces

While Scenarios 1–4 serve as atomic, single-resolution benchmarks for immediate mechanics, a complete test suite also requires **lower-resolution macro traces** that span an entire multi-scene expedition (3–5 consecutive challenges/crises):

1. **Cross-Scene Attrition & Deck Dilution:** Tracking how Fatigue cycles, status cards, and unrecovered injuries progressively dilute a 24-card deck across multiple scenes.
2. **Pacing Engine Verification:** Testing the interaction between the Ready Hand Vigilance Dial (0–4 cards), Effort Cycle flushes, and short-rest recovery ([The Breather](../rules/modules/the-breather.md)) under dungeon clock pressure.
3. **Burden Drag:** Observing the cumulative aerobic cost of heavy equipment over extended exploration.

_Note:_ As noted in design discussions, these lower-resolution traces may either be detailed in this benchmark document or expanded into a dedicated proposal file (`macro-endurance-traces.md`).
