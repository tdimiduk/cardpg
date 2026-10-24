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

### Pacing Mode & Friction Band

- **Pacing Mode:** `General Action (Adventuring Time)`. The characters are competent specialists performing methodical preparation over hours; the question is not whether they find anything, but how clean their intelligence is, how much stamina they burn doing so, and whether their inquiries tip off the syndicate.
- **Friction Band:** `Routine / Low Friction`
- **Cost & Stamina Expectation:** Minimal stamina burn across four hours of disciplined groundwork. Specialist competence carries intelligence gathering cleanly; consequences are rare and strictly fleeting friction (minor legwork fatigue, small tip bribes, mild clerk suspicion).
- **Abort & Failure Dynamic:** Aborting is almost never necessary; character competence carries the scene smoothly. Pushing recklessly to squeeze a contact risks escalating attention.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Complete success. The quartermaster provides decisive testimony; the customs clerk's bribe trail is verified without his knowledge; authentic seals are acquired. The party enters the council with strong leverage and fresh minds.
- **Minor Friction:** Moderate effort expended. The seal requires an exorbitant gratuity or collateral promise; the customs clerk notices he is being watched and ducks into a guild office, putting Vance's staff on mild alert; the heroes burn significant morning focus and legwork.
- **Severe Consequence:** Active complication. The quartermaster is frightened and demands physical protection; the tail is spotted by syndicate scouts; the acquired seal is flagged as missing by noon, forcing the envoys to enter the council hall knowing their opponents are forewarned and hostile.

### Calibrated Verification Rubric

- **Unified Doom Avoidance:** Casing complications (bribes, clerk suspicion, missing seal alert) must attach to scene friction or syndicate awareness. Morning legwork strain must not consume physical wound capacity, reduce armor protection, or lower bodily trauma thresholds in Beat 3.
- **Plausible Bleed & Friction:** Strenuous investigative effort burns universal stamina, leaving less reserve focus for the midday debate. Acquired table assets (authentic transit seal, clerk manifests) convert into tangible tactical/rhetorical leverage or friction absorption in Beat 2.
- **Recovery Asymmetry:** Fleeting investigative weariness and legwork fatigue clear with a brief midday rest or meal before the council convenes, whereas alerted syndicate suspicion persists into the afternoon.

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

### Pacing Mode & Friction Band

- **Pacing Mode:** `Crisis (Crisis Time)`. A high-tension, round-by-round social confrontation where momentum swings rapidly, stakes are immediate, and both sides deploy active rhetoric and psychological leverage to sway the bench before time expires.
- **Friction Band:** `Perilous / High Friction (Social Crisis)`
- **Cost & Stamina Expectation:** Heavy focus and mental stamina burn under intense public scrutiny and aggressive syndicate rhetoric. Success demands digging deep into mental reserves and deploying acquired leverage (seals, manifests). High risk of Severity 2 social/reputational consequences (formal reprimand, deadlock, compromise tariffs).
- **Abort & Failure Dynamic:** Refusing to yield points or settle for compromise risks total public disgrace and procedural defeat. Characters can choose to abort aggressive lines of debate or concede non-essential points to preserve credibility and universal stamina.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Total rhetorical victory. Vance is goaded into contempt of the council; the Open Harbor Charter is ratified by an overwhelming majority; the syndicate is discredited in open court.
- **Minor Friction:** Partial victory with costly compromises. The charter passes, but burdened with concessions and compromise tariffs; the debate is grueling and mentally exhausting; Vance loses the vote but retains enough standing to engineer immediate retribution.
- **Severe Consequence:** Bitter procedural defeat or narrow victory accompanied by total public humiliation. Vance's advocates successfully smear the envoy’s credentials; the envoy is formally reprimanded for insolence; the council deadlocks; the envoys leave the hall publicly tainted and viewed with suspicion by the populace.

### Calibrated Verification Rubric

- **Unified Doom Avoidance:** Crucial Decoupling Invariant ("No Embarrassment Kills"). Suffering public disgrace, council reprimand, or rhetorical defeat must NEVER reduce physical wound capacity, soften bone structure, dull parrying reflexes, or make heroes fewer blade-strikes away from death in Beat 3.
- **Plausible Bleed & Friction:** Two hours of intense psychological confrontation and rhetorical defense deplete universal stamina and composure reserves, imparting tactical hesitation or reduced initiative in the alley without diminishing physical toughness.
- **Recovery Asymmetry:** Lost composure and mental agitation can be refocused through tactical rallying, adrenaline, or a breath of fresh air; formal political censure and municipal deadlocks persist indefinitely until addressed through court maneuvers.

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

### Pacing Mode & Friction Band

- **Pacing Mode:** `Crisis (Crisis Time)`. High-lethality, second-by-second physical combat with severe stakes of life, limb, and permanent incapacitation.
- **Friction Band:** `Crisis / Lethal Crucible`
- **Cost & Stamina Expectation:** Second-by-second life-or-death melee against six armed cutthroats. Direct physical bodily harm (cudgel contusions, blade lacerations, concussive trauma). Severe, rapid drain on physical stamina.
- **Abort & Failure Dynamic:** Aborting requires an active fighting retreat, vaulting alley fences, or drawing city watch whistles to break contact while conceding ground or dropping dropped baggage.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Decisive tactical triumph. The bodyguard holds the archway cleanly; two bravos are neutralized in seconds; the remaining ruffians break and flee into the fog; the party escapes without a scratch.
- **Minor Friction:** Battered survival. The ambushers are driven off, but the bodyguard absorbs heavy blows: bruised ribs, a deep muscle contusion on the shield arm, a torn greatcoat, and dented armor. Both characters are winded and bleeding from minor scratches.
- **Severe Consequence:** Grievous trauma. The envoy is struck hard with a bludgeon, suffering a ringing concussion (`Cranial Trauma / Concussion`); the bodyguard takes a deep blade slash to the thigh or forearm (`Lacerated Tendon / Severe Wound`); the bravos are repelled only after a desperate struggle that draws city watch whistles.

### Calibrated Verification Rubric

- **Unified Doom Avoidance:** Damaged armor, slashed cloaks, or dented gear must track as equipment degradation that can be shed, replaced, or repaired, rather than permanently burdening the hero's biological agility or social standing once removed.
- **Plausible Bleed & Friction:** Physical bodily trauma bleeds downward heavily into subsequent non-combat pillars: a ringing concussion impairs charming banter (`Navigate a Social Event`) and vigilance (`Assess a Situation`) at the evening banquet; a sliced forearm or bruised ribs imposes tactile drag and elevated costs on delicate lockpicking (`Pick a lock`).
- **Recovery Asymmetry:** Acute adrenaline and muscle strain subside over a short respite, but structural trauma (concussions, deep lacerations) cannot be flushed by a banquet glass of wine; they require clinical treatment, bandages, and splints to heal.

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

### Pacing Mode & Friction Band

- **Pacing Mode:** `General Action (Adventuring Time)`. High tension and severe consequence potential, but operating over the course of an hour through parallel covert actions rather than round-by-round combat rounds.
- **Friction Band:** `Perilous / High Friction`
- **Cost & Stamina Expectation:** Parallel covert burglary and high-society distraction under active guard patrols. Heavy stamina drain and nerve tension. High risk of Severity 2 consequences (guard discovery, forced escape, alerted manor).
- **Abort & Failure Dynamic:** Pushing through a stubborn vault lock risks raising the alarm; characters can abort the lockpick attempt and withdraw cleanly before guards enter the corridor, accepting an incomplete heist to avoid capture.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Flawless heist. The envoy commands the room's attention; the bodyguard picks the vault lock without a scratch, secures the ledger, and relocks the door; both slip away cleanly before the gala concludes.
- **Minor Friction:** Close call with complications. The lock is stubborn, forcing the bodyguard to force a secondary latch, leaving faint tool marks; the envoy is forced to drink heavily or make risky political commitments to keep the Harbormaster distracted; minor suspicion raised.
- **Severe Consequence:** Alarm and hasty extraction. A patrol dog or wandering guard discovers the study door ajar; the bodyguard is forced to grab the ledger and dive out a second-story rain gutter into the garden; the envoy must cover the escape under intense social interrogation, barely avoiding immediate arrest while syndicate guards seal the exits.

### Calibrated Verification Rubric

- **Unified Doom Avoidance:** Parallel operational friction remains localized or environmental: burglary slip-ups or noise aloft manifest as heightened manor alert downstairs (whispering guards, suspicious host) rather than instantaneously inflicting bodily harm on the envoy in the ballroom.
- **Plausible Bleed & Friction:** Lingering combat injuries from Beat 3 (bruised ribs, trembling hands) increase stamina costs and noise risks on delicate infiltration actions (`Pick a lock`), while social diversion downstairs directly purchases operational time and cover for the burglar upstairs.
- **Recovery Asymmetry:** Manor alert levels, suspicious guards, and tool marks on vault locks cannot be "rested away"; they remain active scene conditions until the party vacates the manor.

---

## Beat 5: Night Downtime & Covering Tracks

### Narrative Context & Stakes

Midnight. The rain pours steadily over the slate roofs of Marrow-Bay. The envoys have reunited at a quiet safehouse near the canal: cold mutton, dry bread, a crackling peat fire, and the signed extortion ledger drying on the table. The day's work is done, but the fallout of their actions now hangs over them. The city watch is patrolling the Old Tallow district following the afternoon brawl, Vance's men are checking inns for wounded foreigners, and both heroes are exhausted in body and spirit.

The night is spent tending wounds, mending torn leather, bribing the safehouse keeper to keep watch, burning scraps of notes, and taking a quiet hour of restorative rest to preserve their sanity and purpose.

### Actions & Colors Tagged

- `Reduce Scrutiny` ([[Yellow]] - Downtime): Dispersing coin through trusted intermediaries to redirect harbor watch inquiries toward rival smugglers.
- `Indulge Vice (Speed / Intellect)` ([[Yellow]] / [[Blue]] - Downtime): Playing high-stakes cards or cataloging decrypted letters over mulled wine to shed the day's stress.
- `Maintain Gear` ([[Yellow]] - Downtime): Hammering out pauldron dents, sharpening notched blades, and oiling rain-soaked leather harnesses.

### Pacing Mode & Friction Band

- **Pacing Mode:** `Downtime`. Slow, restorative pacing where time is spent managing long-term consequences, recovering spent stamina, repairing gear, and mitigating faction heat before the next chapter begins.
- **Friction Band:** `Routine / Low Friction`
- **Cost & Stamina Expectation:** Safehouse rest, wound treatment, gear repair, and bribing watchmen. Minimal stamina expenditure; primary function is flushing universal daily fatigue and stabilizing acute wounds.
- **Abort & Failure Dynamic:** Standard restorative downtime; abort dynamics do not apply unless interrupted by syndicates.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Safehouse remains undiscovered; city scrutiny drops; minor bruises are dressed cleanly; armor repaired; full night of restful sleep restores baseline stamina.
- **Minor Friction:** Scrutiny is only partially dampened; local watchmen remain suspicious of the district; medical supplies run low; some lingering physical aches persist into morning.
- **Severe Consequence:** Syndicate informants track the courier used to bribe the watch; the safehouse is identified; the night's rest is cut short by shouts in the courtyard, forcing an early dawn escape with unrecovered wounds and lingering fatigue.

### Calibrated Verification Rubric

- **Unified Doom Avoidance:** Safehouse rest must not conflate distinct recovery vectors into a single universal refill bar; resting does not automatically repair notched steel armor, nor does stitching a wound restore lost political standing in the guildhall.
- **Plausible Bleed & Friction:** Exhausted daily stamina burns are relieved by shelter, hot rations, and sleep, returning baseline energy; unresolved physical injuries (concussions, rib fractures) continue to impose friction into the following day until professionally treated.
- **Recovery Asymmetry:** Fleeting universal fatigue fully flushes across an uninterrupted night of sleep; structural bodily trauma requires medical supplies, bandages, and days of convalescence; municipal scrutiny and syndicate warrants require gold bribes, proxy contacts, and covert maneuvers to dampen.

---

## Summary Evaluation Rubric for Engine Designers

When validating a candidate resolution engine against this scenario, ensure it answers these core design checkpoints cleanly:

| Checkpoint Category            | Invariant & Challenge                                                                                                                         | Falsifiable Verification Criterion                                                                                                                         |
| :----------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Unified Doom Avoidance**     | **No "Embarrassment Kills":** Social humiliation or political reprimand must not advance physical lethality tracks.                           | When jumped by cutthroats in Beat 3, the discredited envoy parries with full physical reflex, completely unweakened in bone or flesh by the debate insult. |
| **Unified Doom Avoidance**     | **Gear / Body Separation:** Damaged armor and torn clothing can be shed or repaired without penalizing biological agility or social standing. | Taking off a battered breastplate allows a hero to enter a formal banquet without being penalized by its dents.                                            |
| **Plausible Bleed & Friction** | **Downward Wound Bleed:** Bodily trauma suffered in combat realistically impairs subsequent social and fine-motor tasks.                      | A ringing concussion or slashed forearm makes high-society banter and lockpicking visibly harder and more perilous in Beat 4.                              |
| **Plausible Bleed & Friction** | **Universal Fatigue:** Mental debate, physical combat, and stealth burglary draw upon a shared, understandable well of stamina.               | An envoy who argued passionately all morning feels genuinely weary when coordinating covert actions that night.                                            |
| **Plausible Bleed & Friction** | **Mode Coupling & Leverage:** Casing and asset acquisition in General Actions create direct advantages in Crisis Time.                        | The acquired harbor seal provides concrete defensive or tactical leverage during the council debate.                                                       |
| **Recovery Asymmetry**         | **Asymmetric Downtime Vectors:** Daily fatigue, structural wounds, and municipal heat recover through fundamentally distinct channels.        | An overnight safehouse sleep flushes daily fatigue, but cracked ribs require bandages/triage and guildhall scrutiny requires bribes/maneuvers.             |
| **Recovery Asymmetry**         | **Friction & Abort Dynamic:** Calibrated friction bands support viable player-governed aborts before catastrophic harm.                       | A burglar can abort a stubborn lockpick in Beat 4 to avoid triggering an alarm without suffering catastrophic failure.                                     |
