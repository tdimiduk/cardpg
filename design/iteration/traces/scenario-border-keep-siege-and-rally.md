---
title: "Benchmark Scenario: The Last Watch at Timber-Ford"
doc_type: iteration
track: ludology
origin: AI drafted
epistemic_status:
  confidence: high
  vetted_by_human: false
---

# Benchmark Scenario: The Last Watch at Timber-Ford

## Scenario Overview

This scenario traces a desperate community defense on the contested border of the River-Marches. A small frontier logging settlement, Timber-Ford, sits astride the only heavy timber wagon bridge spanning the swollen, roaring Blackwood River. A ruthless renegade warband—the Iron-Fang Host, numbering over sixty veteran marauders and siege-hounds—is marching to burn the settlement, seize the winter grain stores, and butcher any who resist.

The protagonists are a veteran frontier captain (a master of small-unit tactics and fortified defense) and an itinerant hedge-mystic (practicing practical elemental hedge-craft, weather-weaving, and trauma medicine). The arc covers twelve hours of preparation: hard physical labor fortifying the river bridge, tense community oration to rally a terrified civilian militia, a psychological standoff during a dusk parley with the enemy warlord, a brutal night-long defense of the burning barricades, and the dawn convalescence that tends to broken bodies and spiritual grief.

It is structured to test how an engine handles **environmental and communal condition bleed** (conditions that attach to a settlement or militia rather than a hero's flesh), the cost-benefit trade-offs of exhausting physical labor before combat, and the spiritual recovery of exhausted defenders.

---

## Beat 1: Morning Bridge Fortification & Trap Rigging

### Narrative Context & Stakes

Dawn breaks over Timber-Ford with the ominous smell of distant woodsmoke; outlying homesteads three leagues north are already burning. The enemy host will arrive by dusk. The wooden bridge is the hamlet’s sole choke point, but in its current state, twenty horsemen could cross it abreast and overrun the cottages in minutes.

The captain and mystic take charge of the hamlet's remaining physical resources. Over six grueling hours, the captain directs the village loggers and blacksmiths, hauling massive fallen spruce trunks from the timber mill to construct a spiked abatis across the bridgehead, digging deep caltrop ditches along the muddy banks, and reinforcing the stone tollhouse to serve as an anchor redoubt. The mystic gathers pitch, tallow, and iron chain from the smithy to craft explosive fire-pots and conceal tripwire deadfalls along the river shoals.

### Actions & Colors Tagged

- `Labor` ([[Red]] - Downtime): Hauling heavy spruce logs, felling bridge timbers, and driving heavy sharpened stakes into the riverbed.
- `Manage Holdings` ([[Red]] - Downtime): Allocating the hamlet’s scarce grain, timber, tools, and blacksmithing supplies to maximize defense efficiency.
- `Craft Intricate Items` ([[Yellow]] - Downtime): Assembling pressure-plate clay fire-pots, delayed fuses, and barbed chain tripwires.
- `Set up Camp` ([[Yellow]] - Exploration): Laying out perimeter warning lines, trip-snare bells, and concealed archer pits along the river embankment.

### Pacing Mode

`General Action / Downtime (Adventuring Time)`. Strenuous, hours-long preparation. The heroes know how to build a barricade and rig a snare; the question is how thoroughly the bridgehead is fortified, how much universal stamina they burn during the work, and what minor physical strains they accumulate before battle begins.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Pristine defensive engineering. The abatis is anchored deep; fire-traps are rigged flawlessly; ditch caltrops are hidden; heroes manage their hydration and pacing, entering the afternoon with sturdy fortifications and manageable muscle fatigue.
- **Minor Friction:** Painful physical exertion. Timber beams slip during placement, straining the captain’s back (`Stiff Lower Back`); working without gloves raises raw blisters across the mystic's hands (`Blistered Hands`); supply shortages force the party to tear down an outbuilding for extra timber.
- **Severe Consequence:** Construction mishap and overexertion. A heavy log collapses during rigging, crushing a young villager's foot and forcing the heroes to expend emergency medical supplies; time runs out before the western ford can be staked; the captain enters the afternoon physically worn down (`Exhausted Muscles / Back Strain`).

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **Pre-Crisis Physical Investment vs. Melee Readiness:**
   - Performing six hours of back-breaking physical labor (`Labor`) directly creates powerful environmental defensive assets (`Spiked Abatis`, `Concealed Caltrops`) for Beat 4.
   - However, that heavy labor expends real biological stamina. How does an engine allow players to make the deliberate tactical choice to **tire their bodies out in the morning in order to have fortified cover at night**?
   - If the captain starts the evening battle with `Blistered Hands` or a `Stiff Back`, how should those minor physical strains create tactile friction in swordplay without turning the hero into an incompetent cripple?
2. **Environmental Assets on the Table:**
   - When the heroes finish building a spiked log barrier, how should that structure exist mechanically in the subsequent combat crisis? Does it act as a barrier that enemy attacks must chew through, a zone that restricts enemy movement, or a pool of defense that the heroes can tap into while holding the bridge?

---

## Beat 2: Midday Rallying the Wavering Militia

### Narrative Context & Stakes

Noon brings a fresh wave of panic. Black columns of smoke rise from the horizon, and refugee carts from northern farms arrive with horror stories of the Iron-Fang Host’s cruelty. The sixty villagers gathered on the village green—carpenters, farmers, weavers, and youths—begin to murmur about fleeing into the deep Blackwood bogs, abandoning the settlement and its food stores to the torch.

The captain and mystic must step into the center of the panicked crowd. The captain speaks not with empty bravado, but with hard, honest soldier’s truth: explaining how the fortified bridge turns the enemy’s numbers against them, demonstrating proper spear-wall stances, and organizing the youths into archery squads. The mystic speaks to the village elders and mothers, reminding them that the freezing swamps will claim their children just as surely as raider blades, invoking the ancestral resilience of the valley pioneers.

### Actions & Colors Tagged

- `Rally a Militia` ([[Red]] - Social): Instilling iron discipline and collective purpose into frightened commoners, teaching them how to lock shields and hold ranks.
- `Influence and Inspire` ([[Blue]] - Social): Laying out the clear, logical military math of the bridgehead defense to overcome panicked defeatism.
- `Make a moving Oration` ([[Red]] - Social): Delivering a heartfelt, stirring speech that binds the villagers’ love for their homes into fierce courage.
- `Assess a Situation` ([[Yellow]] - Social): Scanning the crowd to identify ringleaders of cowardice, panic, or potential treachery before panic spreads.

### Pacing Mode

`General Action (Adventuring Time)`. An extended social and organizational effort spanning several hours. The goal is to forge a terrified mob into a functional defensive unit without fracturing community trust.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Iron resolve. The villagers take up their boar-spears and hunting bows with grim pride; watch rotations are manned with quiet discipline; morale is steadfast.
- **Minor Friction:** Fragile consensus. The elder council agrees to hold the inner ditch, but several families pack their carts and flee into the forest anyway, leaving the defensive line short-handed; the militia's courage is tenuous and easily shaken.
- **Severe Consequence:** Brittle and fractured morale. Open mutiny is prevented only by strict military threats and harsh coercion; the villagers are terrified of both the captain and the raiders (`Shaky Militia Morale`); the militia will break and flee at the first sight of enemy blood or fire.

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **Communal / Environmental Conditions vs. Bodily Conditions:**
   - If the speech goes poorly and the villagers remain terrified, the resulting consequence is `Shaky Militia Morale`.
   - **Crucial Distinction:** This condition does NOT attach to the captain’s body. The captain is not bruised, bleeding, or slower with a sword. The condition attaches to the **allied group / environment**.
   - How should an engine model conditions that afflict the battle space or allied units rather than the hero’s personal card hand or body? When an enemy attacks in Beat 4, how does poor militia morale threaten the hero’s position without lowering the hero’s personal physical resilience?
2. **Social Effort Bleeding into Stamina:**
   - Shouting, arguing with panicked elders, and commanding crowds for three hours drains emotional reserves and vocal cords. Does intense social exertion contribute to the universal fatigue that characters carry into the night?

---

## Beat 3: Dusk Parley at the Ford

### Narrative Context & Stakes

The sun sets blood-red through the spruce trees. The vanguard of the Iron-Fang Host rides out of the forest: forty armored reavers on heavy steppe horses, led by Warlord Kaelen, a scarred giant clad in blackened mail and a wolf-pelt mantle. Kaelen rides onto the northern approach of the bridge under a blackened spear acting as a flag of truce, demanding to speak with whoever holds the settlement.

The captain and mystic walk out onto the center of the wooden bridge to meet him between the two lines. Kaelen offers simple terms: open the bridge, yield forty sacks of seed-grain and four hostages, and his host will spare the houses; refuse, and every soul in Timber-Ford will be put to the sword before sunrise.

The captain confronts the warlord eye to eye. While the mystic watches the reaver scouts flanking the riverbanks, the captain uses cold military certainty to expose Kaelen’s haste, pointing out the signs that the reavers are low on supplies and desperate to cross before royal patrols arrive from the south. The parley is a psychological knife-fight: a contest of nerve to determine whose will breaks first.

### Actions & Colors Tagged

- `Assert Dominance` ([[Red]] - Social): Staring down the towering warlord, speaking with cold, unwavering martial authority that refuses to flinch in the presence of overwhelming force.
- `Issue a Challenge` ([[Red]] - Social): Publicly daring Kaelen to lead the bridge assault in person rather than sending his underlings to die on the stakes.
- `Observe and Plan` ([[Blue]] - Social / Exploration): Cold-reading Kaelen’s retinue to spot wounded horses, frayed bowstrings, and signs of internal friction within the warband.

### Pacing Mode

`General Action / High-Stakes Confrontation (Adventuring Time)`. A focused psychological standoff conducted under formal parley protocol. Minutes of quiet, lethal intensity that dictate the psychological momentum of the impending siege.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Total psychological triumph. The captain deduces Kaelen’s supply desperation and mocks his timeline; Kaelen loses his composure in front of his lieutenants, ordering a rash, uncoordinated frontal assault in anger; the militia gains surging confidence (`Steely Resolve`).
- **Minor Friction:** Stiff standoff. Neither side yields; Kaelen sees the bridge is fortified and plans a cautious, disciplined assault; the parley reveals the reavers possess incendiary arrows; terms are rejected cleanly.
- **Severe Consequence:** Psychological blow. Kaelen notices the trembling hands of the militia archers in the ditch, openly mocking their cowardice; his words echo across the river, shattering what little confidence the villagers possessed; the parley ends with Kaelen sounding war-horns for an immediate, merciless charge while the defenders are shaken.

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **Psychological Momentum into Combat:**
   - How should the outcome of a pre-battle social standoff translate into the opening round of a combat crisis?
   - If the captain rattled Kaelen’s pride, does Kaelen charge recklessly into the fire-traps without checking for tripwires? If the militia was humiliated by Kaelen’s mockery, do they suffer hesitation on their opening volley?

---

## Beat 4: Night Protracted Combat Crisis: Holding the Burning Ford

### Narrative Context & Stakes

Midnight. Total darkness broken only by torchlight, rain, and the sudden blooming of fire. The Iron-Fang Host launches a ferocious assault. War-horns blare as dismounted reavers rush the bridgehead under mantlet shields, hurling oil pots onto the abatis, while mounted scouts attempt to wade the freezing, swollen shallows downstream.

The bridgehead erupts into a cauldron of violence. The captain stands in the narrow gap in the abatis, sword and heavy shield locking out the enemy vanguard, cutting down anyone who attempts to clear the timber stakes. Behind the breastwork, the mystic channels hedge-magic to conjure sheets of rain and river-fog that smother incoming fire-arrows, while detonating the concealed fire-pots among the enemy ranks.

The fight is a grueling, multi-wave battle of endurance. When an enemy champion with a heavy greataxe shatters the captain’s shield and drives a jagged splinter through their arm, the captain must push through the searing agony to hold the threshold. Meanwhile, militia archers in the ditch waver as burning pitch splashes across the parapet.

### Actions & Colors Tagged

- `Strategic Sorcery` ([[Blue]] - Downtime / Combat): Wielding large-scale elemental weather-craft to summon blinding river-mist and downpours that snuff out enemy incendiaries.
- `Hold a Position` ([[Red]] - Combat): Planting feet in the blood-slick mud of the bridge threshold to physically deny twenty charging marauders access to the village.
- `Make a Last Stand` ([[Red]] - Combat): Standing alone in a breach when the palisade catches fire, buying time for the militia to reform the secondary line.
- `Passionate Surge` ([[Red]] - Combat): Drawing upon fierce protective devotion to the frontier settlement to ignore the agony of severe wounds and exhaustion.
- `Push Through Pain` ([[Red]] - Combat): Absorbing a staggering axe strike into armor and immediately striking back to disarm the enemy before collapsing.
- `Disarm or Sunder` ([[Yellow]] - Combat): Targeting the heavy siege-axes of the vanguard to shatter their haft and prevent them from cutting down the abatis.

### Pacing Mode

`Crisis (Crisis Time)`. High-intensity, protracted multi-round combat crisis representing hours of brutal, wave-based defensive warfare.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Resolute victory. The traps detonate perfectly; the captain fells Kaelen’s champions at the threshold; the weather magic snuffs the fire; the raiders take catastrophic casualties and rout back into the northern hills; the bridgehead holds with minimal defender loss.
- **Minor Friction:** Battered survival. The outer abatis burns down, forcing a retreat to the stone tollhouse; several villagers fall wounded; the captain suffers heavy physical punishment (`Fractured Ribs`, `Singed Armor`, `Deep Blood Loss`); the mystic is drained of all magical vitality.
- **Severe Consequence:** Agonizing near-ruin. The bridge is breached; the heroes must collapse the center wooden span with fire to save the village, dumping both friend and foe into the raging torrent; the captain survives by sheer miracle with crippling bodily trauma (`Severe Smoke Inhalation`, `Shattered Shield Arm`); half the village green is charred.

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **The Cost of "Pushing Through Pain":**
   - Actions like `Push Through Pain` and `Passionate Surge` allow heroic characters to temporarily defy biological injury and keep fighting.
   - What is the bill that comes due when the adrenaline fades in Beat 5? How does an engine allow heroes to perform desperate, miraculous feats in Crisis Time without letting those feats be free of long-term biological consequence?
2. **Protracted Defense & Deck Attrition:**
   - A siege is not a 30-second duel; it is hours of repeated clashing. How does the engine model grinding physical fatigue across multiple waves of attackers? Does the player's universal stamina progressively dilute, forcing them to rely on risky, high-effort gambits as the night wears on?

---

## Beat 5: Dawn Convalescence & Rebuilding Hope

### Narrative Context & Stakes

Dawn rises over a smoldering, silent riverbank. The survivors step out into the pale morning light: the bridge is scarred, bodies of reavers drift in the river eddies, and the village hall has been converted into a blood-stained field hospital. The smell of vinegar, boiled willow-bark tea, and burning spruce hangs thick in the air.

The immediate crisis is over, but the settlement is broken in spirit and body. The captain lies on a cot with bandaged ribs and a splinted arm, fighting off fever. The mystic, hands trembling from exhaustion, must dress horrific burns, set bones, and help grieving families prepare their dead for burial. The heroes must ensure that the surviving villagers do not fall into bitter despair or abandonment.

### Actions & Colors Tagged

- `Heal a Spiritual Wound` ([[Blue]] - Downtime): Providing profound counsel, grief rituals, and compassionate presence to villagers and allies scarred by the horror of the siege.
- `Maintain Purpose` ([[Blue]] - Downtime): Struggling through personal fever, physical agony, and survivor’s guilt to keep one's sense of duty and resolve intact.
- `Provide for the Group` ([[Red]] - Downtime): Organizing the salvage of weapons, reclaiming abandoned rations from the battlefield, and butchering fallen draft animals to replenish the hamlet’s food stores.

### Pacing Mode

`Downtime`. Somber, restorative recovery where heroes and community begin the slow process of healing biological trauma, processing emotional shock, and rebuilding fortified stability.

### Plausible Narrative Fallout Spectrum

- **Clean Outcome:** Solace and renewal. Chirurgery stabilizes the wounded; spiritual rites bring peace to the grieving; the villagers view their stand with solemn pride; the heroes begin full physical convalescence under the grateful care of the community.
- **Minor Friction:** Somber endurance. Medical supplies are exhausted, forcing painful natural recovery; the captain remains bedridden for days with fever; the village will face a hard, lean winter.
- **Severe Consequence:** Lingering spiritual desolation. Several wounded die of infection; the village elder hangs himself in despair; the captain suffers deep spiritual trauma (`Haunted Guilt / Crisis of Faith`), struggling to find meaning in the bloody survival.

### Engine Brainstorming Prompts: Coupling & Cross-Domain Bleed

1. **Spiritual and Emotional Trauma as Distinct from Biological Wounds:**
   - A crushed collarbone requires splints and bone-knitting; a shattered spirit (`Haunted Guilt`) requires fellowship, purpose, and time.
   - How should an engine represent emotional and psychological trauma incurred during a massacre? How does it differ from physical wounds, and how does the downtime pillar provide distinct avenues (`Heal a Spiritual Wound`, `Maintain Purpose`) to heal it?
2. **Community Gratitude as Systemic Recovery:**
   - Grounded heroism emphasizes the contrast between dark peril and the warm hearth. How does the gratitude and hospitality of a saved community aid in the characters' recovery?

---

## Summary Evaluation Rubric for Engine Designers

When validating a candidate resolution engine against this scenario, ensure it answers these core design questions cleanly:

| Invariant                         | Design Challenge                                                                                                            | Narrative Test                                                                                                  |
| :-------------------------------- | :-------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------- |
| **Environmental Preparation**     | Does spending morning physical stamina on labor create tangible, persistent defensive assets on the battlefield?            | Does building an abatis provide real physical cover and tactical choke points during the midnight assault?      |
| **Communal Condition Decoupling** | Do societal and morale conditions (shaky militia) attach to the scene/community rather than penalizing the hero's body?     | Does a terrified militia cause tactical chaos without making the captain's own parrying arm physically weaker?  |
| **Adrenaline vs. Aftermath**      | Do desperate feats of heroic willpower (`Push Through Pain`) carry severe biological bills that come due in downtime?       | Does ignoring a shattered arm to hold the bridge result in high fever and grueling recovery once the sun rises? |
| **Protracted Defense Attrition**  | Can the engine sustain multi-wave siege combat without devolving into either trivial grinding or immediate character death? | Do heroes feel their options narrowing as the hours of combat drag on and stamina reserves deplete?             |
| **Spiritual Convalescence**       | Does the engine provide meaningful mechanics for healing minds, grief, and purpose alongside broken bones?                  | Can an exhausted mystic spend downtime comforting a weeping elder to restore the community's resolve?           |
