---
title: "Benchmark Scenario: The Harbor Charter & The Cobblestone Ambush"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Benchmark Scenario: The Harbor Charter & The Cobblestone Ambush

## Scenario Overview

This scenario traces a full urban adventuring day in the coastal free city of Marrow-Bay. The protagonists—an aristocratic envoy with sharp rhetorical training and a seasoned sellsword bodyguard—are working on behalf of an allied provincial merchant league to ratify a contested maritime trade charter. Standing against them is the Gilded Consortium, an entrenched syndicate of monopolists, corrupt port bailiffs, and alley cutthroats who intend to kill the charter in the morning council, eliminate the envoys if defeated in debate, and purge incriminating harbor ledgers by nightfall.

The arc spans morning reconnaissance, high-stakes political debate, deadly street violence, evening espionage, and dead-of-night recovery. It is designed to test how a resolution engine handles seamless transitions across **Social**, **Combat**, **Exploration**, and **Downtime** pillars, specifically examining how universal fatigue and domain-sensitive consequence bleed propagate across diverse narrative contexts.

---

## Beat 1: Morning Casing & Leverage Gathering

### Narrative Context & Stakes

The morning fog clings to the timber wharves of Marrow-Bay. The Guildhall council convenes at noon. The envoy and bodyguard have four hours to gather corroborating customs manifests, identify which council magistrates are wavering, and secure a set of counter-stamped harbor seals to validate their legal petition.

Rather than kicking down doors or making premature accusations, the pair works the district with professional discipline. The envoy quietly tracks down an old naval quartermaster drinking tea in a dockside coffeehouse to secure inside knowledge of harbor corruption, while the bodyguard tails an under-clerk of the customs house through the fish-market to observe his routines and pocketbook habits. Finally, they use contacts in the waterfront tally-clerk guild to acquire a set of authentic magistrate transit seals.

### Actions & Colors Tagged

- `Gather Information` ([[Yellow]] - Social): Discreetly tailing the customs clerk through crowded docks and listening to warehouse gossip.
- `Study a Target` ([[Blue]] - Downtime / Social): Methodically analyzing Guildmaster Vance's past voting records and public vulnerabilities.
- `Find a Contact` ([[Yellow]] - Social): Navigating the waterfront network to locate the retired naval quartermaster.
- `Acquire Asset` ([[Yellow]] - Downtime): Securing an official municipal transit seal and authenticated toll register.

### Pacing Mode

`General Action (Adventuring Time)`. The characters are competent specialists performing methodical preparation over hours; the question is not whether they find anything, but how clean their intelligence is, how much stamina they burn doing so, and whether their inquiries tip off the syndicate.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Complete success. The quartermaster provides decisive testimony; the customs clerk's bribe trail is verified without his knowledge; authentic seals are acquired. The party enters the council with strong leverage and fresh minds.
- **Minor Friction:** Moderate effort expended. The seal requires an exorbitant gratuity or collateral promise; the customs clerk notices he is being watched and ducks into a guild office, putting Vance's staff on mild alert; the heroes burn significant morning focus and legwork.
- **Severe Consequence:** Active complication. The quartermaster is frightened and demands physical protection; the tail is spotted by syndicate scouts; the acquired seal is flagged as missing by noon, forcing the envoys to enter the council hall knowing their opponents are forewarned and hostile.

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **Universal Effort vs. Reserved Focus:**
   - Methodical footwork, discreet shadowing, and intense cross-referencing drain real biological stamina and mental sharpness. If the heroes push hard to acquire every piece of leverage, how does that universal effort limit their stamina in the high-pressure debate in Beat 2?
   - Should an engine treat physical, social, and mental exertion as drawing from the same underlying well of endurance, or does casing a market only fatigue your legs while leaving your rhetoric entirely fresh?
2. **Leverage as Narrative Table Assets:**
   - When the heroes acquire an official seal or blackmail manifests through General Actions, how does the engine carry those assets into a subsequent Crisis?
   - Does leverage simply act as narrative permission to make stronger arguments, or should it mechanically absorb friction and deflect rebuttals?

---

## Beat 2: Midday Guildhall Charter Debate

### Narrative Context & Stakes

The Great Timber Guildhall is packed with merchant elders, shipwright captains, and watching citizens. Guildmaster Vance presides from the high dais, backed by syndicate legalists. The debate over the Open Harbor Charter is structured under ancient municipal rules: three formal exchanges of rhetoric, evidence, and public rebuttal before the magistrate council votes.

The envoy takes the floor to dismantle the syndicate's monopolistic tariffs, presenting the acquired ledgers and appealing to the merchant captains' sense of civic prosperity. When Vance attempts to smear the envoy's patrons as foreign agitators, the bodyguard steps in with precise procedural interruptions and veiled hints of the clerk's captured testimony, goading Vance into an intemperate outburst. The tension is palpable; the council chamber feels like a gladiatorial arena where words draw real blood.

### Actions & Colors Tagged

- `Present a Formal Argument` ([[Blue]] - Social): Structuring a rigorous legal and economic case proving the syndicate's illegal port surcharges.
- `Appeal to Passion` ([[Red]] - Social): Rousing the unaligned merchant captains by invoking the founding charter of the free port and civic honor.
- `Goad into Action` ([[Yellow]] - Social): Slipping a sharp, barbed insinuation into a recess remark to trick Vance into a reckless procedural error.
- `Maintain Composure` ([[Blue]] - Social): Resisting Vance’s vitriolic personal attacks and retaining absolute poise under intense public scrutiny.
- `Engage in a Standoff` ([[Blue]] - Social): Staring down the syndicate's chief advocate across the clerk’s table during a tense procedural vote.

### Pacing Mode

`Crisis (Crisis Time)`. A high-tension, round-by-round social confrontation where momentum swings rapidly, stakes are immediate, and both sides deploy active rhetoric and psychological leverage to sway the bench before time expires.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Total rhetorical victory. Vance is goaded into contempt of the council; the Open Harbor Charter is ratified by an overwhelming majority; the syndicate is discredited in open court.
- **Minor Friction:** Partial victory with costly compromises. The charter passes, but burdened with concessions and compromise tariffs; the debate is grueling and mentally exhausting; Vance loses the vote but retains enough standing to engineer immediate retribution.
- **Severe Consequence:** Bitter procedural defeat or narrow victory accompanied by total public humiliation. Vance's advocates successfully smear the envoy’s credentials; the envoy is formally reprimanded for insolence; the council deadlocks; the envoys leave the hall publicly tainted and viewed with suspicion by the populace.

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **The Crucial Decoupling Principle (Social Shame vs. Bodily Lethality):**
   - If the envoy is thoroughly humiliated, outmaneuvered, and verbally disgraced in Beat 2, **why must this outcome NEVER make them physically fragile or easier to stab to death in Beat 3?**
   - Having one's pride crushed, being mocked by dock elders, or suffering a reputational penalty does not soften a warrior’s bone structure, dull their parrying reflex, or reduce their physical hit capacity. An engine that naively reduces general "durability" or universal defense pools based on social failure creates absurd ludonarrative dissonance.
2. **Universal Fatigue vs. Bodily Trauma:**
   - While social defeat does not make your skin softer, spending two hours under relentless psychological pressure, screaming over hecklers, and maintaining a rigid poker face _does_ induce universal fatigue. How should an engine represent that the heroes are mentally drained and running low on universal stamina without making them trivially easy to kill in an ambush?
3. **Psychological Momentum:**
   - Does winning or losing a debate change a character’s stance? If humiliated, are they recklessly aggressive (`[[Red]]`), guarded and hesitant (`[[Blue]]`), or simply eager to put steel into anyone who looks at them sideways?

---

## Beat 3: Afternoon Cobblestone Alley Ambush

### Narrative Context & Stakes

Leaving the guildhall through the narrow, rain-slick alleys of the Old Tallow district, the envoys take a shortcut toward their safehouse. The fog has thickened, muffling sound. From shadowy doorways and elevated fire-escapes, six syndicate bravos and footpads step forward with iron-tipped bludgeons, curved saps, and concealed daggers. They have no interest in debate; their orders are to retrieve the documents, break the envoy's fingers, and leave both foreigners bleeding in the gutters.

The bodyguard reacts with trained instinct, drawing steel before the nearest ruffian can close, using the narrow alley walls to prevent flanking, while the envoy uses dirt and streetwise brawling to keep attackers off their flank.

### Actions & Colors Tagged

- `Make a Lightning Draw` ([[Yellow]] - Combat): Clearing scabbard and cutting down the first ambusher before the trap can fully snap shut.
- `Avoid Harm` ([[Yellow]] - Combat): Ducking beneath a weighted cudgel strike and rolling across wet cobblestones.
- `Hold a Position` ([[Red]] - Combat): Planting boots in a 4-foot archway gap to protect the envoy and deny the bravos their numerical advantage.
- `Dirty Trick` ([[Yellow]] - Combat): Kicking a barrel of fish-brine into an attacker's knees and throwing soot into a cutthroat's eyes.
- `Assess Fighting Style` ([[Blue]] - Combat): Recognizing the footpads' dockside brawling tells to predict and intercept a coordinated pincer maneuver.

### Pacing Mode

`Crisis (Crisis Time)`. High-lethality, second-by-second physical combat with severe stakes of life, limb, and permanent incapacitation.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Decisive tactical triumph. The bodyguard holds the archway cleanly; two bravos are neutralized in seconds; the remaining ruffians break and flee into the fog; the party escapes without a scratch.
- **Minor Friction:** Battered survival. The ambushers are driven off, but the bodyguard absorbs heavy blows: bruised ribs, a deep muscle contusion on the shield arm, a torn greatcoat, and dented armor. Both characters are winded and bleeding from minor scratches.
- **Severe Consequence:** Grievous trauma. The envoy is struck hard with a bludgeon, suffering a ringing concussion (`Cranial Trauma / Concussion`); the bodyguard takes a deep blade slash to the thigh or forearm (`Lacerated Tendon / Severe Wound`); the bravos are repelled only after a desperate struggle that draws city watch whistles.

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **Asymmetric Bleed into the Next Scene (Physical Wounds Bleed Forward):**
   - While social defeat from Beat 2 did not make the heroes easier to stab here, physical trauma suffered in this alley **heavily and directly impairs the subsequent social and infiltration scene in Beat 4**.
   - If the envoy took a ringing concussion from a bludgeon, how does that brain trauma affect their ability to maintain charming dinner banter (`Navigate a Social Event`) or notice guards whispering (`Assess a Situation`) at the banquet two hours later?
   - If the bodyguard has a sliced forearm, how does that hand tremor and pain bleed into delicate manual tasks like `Pick a lock` or `Painstaking Search`?
2. **Equipment Decoupling vs. Bodily Damage:**
   - If the bodyguard’s cuirass was hammered out of shape or their coat was slashed to ribbons, they can simply strip off the dented armor and change into a clean tunic before attending the Harbormaster's banquet.
   - How should an engine distinguish between **gear degradation** (which can be shed or bypassed when changing contexts) and **bodily trauma** (which travels inescapably with the flesh)?
3. **Compounded Daily Attrition:**
   - The party has now resolved two intense Crises (one intellectual/social, one life-or-death physical). How does the engine signal that their reserves are severely depleted without locking them into an inescapable failure spiral for the evening?

---

## Beat 4: Evening Banquet & Vault Infiltration

### Narrative Context & Stakes

Night has fallen over Marrow-Bay. The Harbormaster hosts his annual Equinox Gala at his walled cliffside residence. This is the envoys' only opportunity: while the guests, guildmasters, and city magistrates drink spiced wine in the grand ballroom, the Harbormaster’s personal study and iron vault upstairs contain the secret ledger that ties Vance’s syndicate directly to piratical extortion on the coast.

The party splits tasks to maximize their strengths. The envoy—nursing whatever bruises or mental strain remain from the day—attends the gala in formal court dress, charming nobles, keeping Vance distracted, and creating social cover. Meanwhile, the bodyguard slips through the second-floor service corridors, bypasses household patrols, picks the intricate mechanical lock of the private study, and methodically searches for the false-bottomed desk drawer.

### Actions & Colors Tagged

- `Navigate a Social Event` ([[Yellow]] - Social): Mingling seamlessly among wealthy patrons, delivering witty pleasantries, and reading the room.
- `Master a Persona` ([[Blue]] - Social): Adopting the facade of an unbothered, slightly tipsy foreign dignitary to disarm suspicious councilors.
- `Create a Distraction` ([[Yellow]] - Social): Staging a dramatic toast or spilling wine over an inquisitive bailiff to draw eyes away from the grand staircase.
- `Pick a lock` ([[Yellow]] - Exploration): Quietly manipulating the tumblers of the heavy oak-and-brass door to the private archives.
- `Painstaking Search` ([[Blue]] - Exploration): Systematically inspecting bookshelves, hearth mantels, and desk moldings under a shielded candle to find the hidden lockbox.

### Pacing Mode

`General Action (Adventuring Time)`. High tension and severe consequence potential, but operating over the course of an hour through parallel covert actions rather than round-by-round combat rounds.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Flawless heist. The envoy commands the room's attention; the bodyguard picks the vault lock without a scratch, secures the ledger, and relocks the door; both slip away cleanly before the gala concludes.
- **Minor Friction:** Close call with complications. The lock is stubborn, forcing the bodyguard to force a secondary latch, leaving faint tool marks; the envoy is forced to drink heavily or make risky political commitments to keep the Harbormaster distracted; minor suspicion raised.
- **Severe Consequence:** Alarm and hasty extraction. A patrol dog or wandering guard discovers the study door ajar; the bodyguard is forced to grab the ledger and dive out a second-story rain gutter into the garden; the envoy must cover the escape under intense social interrogation, barely avoiding immediate arrest while syndicate guards seal the exits.

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **Parallel Domains & Interlocking Fallout:**
   - The two characters are operating in completely different domains simultaneously (one in high-society Social navigation, one in covert Exploration burglary).
   - If the burglar makes noise or takes too long upstairs, how does that mechanical friction spill into the social room downstairs (e.g., guards whispering to the host, increased tension, sudden need for an emergency social distraction)?
   - If the socialite slips up and loses the host's attention, how does that shorten the burglar's window or trigger an unexpected patrol?
2. **The Price of Earlier Physical Harm:**
   - If the burglar is suffering from `Bruised Ribs` or `Trembling Hands` from the alley brawl, how does the engine make picking the lock feel precarious and costly without simply saying "you automatically fail"?
   - Does physical pain force higher stamina expenditure, burn extra time, or risk louder noise?

---

## Beat 5: Night Downtime & Covering Tracks

### Narrative Context & Stakes

Midnight. The rain pours steadily over the slate roofs of Marrow-Bay. The envoys have reunited at a quiet safehouse near the canal: cold mutton, dry bread, a crackling peat fire, and the signed extortion ledger drying on the table. The day's work is done, but the fallout of their actions now hangs over them. The city watch is patrolling the Old Tallow district following the afternoon brawl, Vance's men are checking inns for wounded foreigners, and both heroes are exhausted in body and spirit.

The night is spent tending wounds, mending torn leather, bribing the safehouse keeper to keep watch, burning scraps of notes, and taking a quiet hour of restorative rest to preserve their sanity and purpose.

### Actions & Colors Tagged

- `Reduce Scrutiny` ([[Yellow]] - Downtime): Dispersing coin through trusted intermediaries to redirect harbor watch inquiries toward rival smugglers.
- `Indulge Vice (Speed / Intellect)` ([[Yellow]] / [[Blue]] - Downtime): Playing high-stakes cards or cataloging decrypted letters over mulled wine to shed the day's stress.
- `Maintain Gear` ([[Yellow]] - Downtime): Hammering out pauldron dents, sharpening notched blades, and oiling rain-soaked leather harnesses.

### Pacing Mode

`Downtime`. Slow, restorative pacing where time is spent managing long-term consequences, recovering spent stamina, repairing gear, and mitigating faction heat before the next chapter begins.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Safehouse remains undiscovered; city scrutiny drops; minor bruises are dressed cleanly; armor repaired; full night of restful sleep restores baseline stamina.
- **Minor Friction:** Scrutiny is only partially dampened; local watchmen remain suspicious of the district; medical supplies run low; some lingering physical aches persist into morning.
- **Severe Consequence:** Syndicate informants track the courier used to bribe the watch; the safehouse is identified; the night's rest is cut short by shouts in the courtyard, forcing an early dawn escape with unrecovered wounds and lingering fatigue.

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **Asymmetric Downtime Recovery Rates:**
   - In a grounded heroic world, what recovers overnight, and what persists?
   - Routine universal fatigue (burning through physical and mental energy) should largely flush with a warm meal and a solid sleep. But what about a concussion? A cracked rib? A destroyed municipal reputation?
   - How should an engine differentiate between **fleeting fatigue** (which flushes across a single good night's sleep) and **structural trauma / social infamy** (which requires dedicated clinical care, time, or political maneuvers to heal)?
2. **Gear Maintenance as Decoupled Recovery:**
   - Repairing armor requires oil, hammer, and time. If downtime is interrupted, does an unrepaired shield or notched blade carry mechanical friction forward, independent of the hero's biological health?

---

## Summary Evaluation Rubric for Engine Designers

When validating a candidate resolution engine against this scenario, ensure it answers these core design questions cleanly:

| Invariant                    | Design Challenge                                                                                                      | Narrative Test                                                                                                                  |
| :--------------------------- | :-------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------ |
| **Universal Fatigue**        | Do mental debate, physical combat, and stealth burglary draw upon a shared, understandable stamina pool?              | Does an envoy who argued passionately all morning feel genuinely weary when running across roofs that night?                    |
| **No "Embarrassment Kills"** | Does suffering public humiliation or political reprimand in social debate avoid reducing physical survivability?      | When jumped by cutthroats, does the discredited envoy parry with full physical reflex, unaffected in their bones by the insult? |
| **Downward Wound Bleed**     | Does physical bodily trauma suffered in combat realistically impair subsequent social and fine-motor tasks?           | Does a ringing concussion or slashed forearm make high-society conversation and lockpicking visibly harder and more perilous?   |
| **Gear / Body Separation**   | Can damaged armor and shredded clothing be removed without penalizing social standing or unarmed agility?             | Does taking off a battered breastplate allow a hero to enter a formal banquet without being penalized by its dents?             |
| **Mode Coupling**            | Does successful casing or leverage acquisition in General Actions create direct, intuitive advantages in Crisis Time? | Does the acquired harbor seal provide concrete defensive or tactical utility during the council debate?                         |
