# **A Biomechanical and Tactical Analysis of Pre-Modern Combat Locomotion for Rules-Based Modeling**

## **Executive Summary**

This report presents a detailed, evidence-based investigation into the functional dynamics of tactical movement in small-scale, pre-modern European combat. The primary objective is to furnish a quantitative and qualitative framework suitable for the development of high-fidelity, rules-based models and simulations. The analysis synthesizes data from three principal domains: modern biomechanics and sports science, which provide quantitative performance metrics; primary historical combat manuals (*Fechtbücher*), which offer tactical context and specific techniques; and modern military studies, which serve as analogues for loaded movement and small-unit tactics.  
The investigation establishes quantitative estimates for combat locomotion speeds and their associated metabolic energy costs, providing distinct values for unarmored combatants and those equipped with a full plate harness (approximately 25-30 kg). It deconstructs historical footwork into a functional lexicon, analyzing each technique's specific purpose in managing distance, time, and angle. Furthermore, the report examines the critical and often-overlooked mechanics of disengagement and the fighting retreat, proposing models for both individual and small-group actions.  
Key findings indicate that plate armor, while offering excellent mobility for its level of protection, imposes a severe metabolic penalty, increasing the energy cost of locomotion by a factor of 1.9 to 2.3 compared to being unarmored. This fundamentally alters the energetic landscape of a fight, making all movement metabolically expensive and prioritizing tactical efficiency. Combat speeds are similarly affected, with the most significant penalty observed in initial acceleration rather than theoretical top speed. The analysis of historical footwork reveals a sophisticated, integrated system where movement and offensive action are intrinsically linked, powered by core body mechanics. Finally, the report concludes that successful disengagement is not a passive retreat but an offensive action that creates a momentary tactical window, and that coordinated group retreats are high-skill maneuvers contingent on discipline and training. All quantitative findings are consolidated in a final summary table designed for direct implementation.  
---

## **KRA-1: The Biomechanics and Energetics of Combat Locomotion**

This section establishes the foundational quantitative data for movement, focusing on the cause-and-effect relationship between equipment (specifically plate armor), movement type, and the resulting performance outcomes in terms of speed and energy expenditure. By grounding these estimates in modern scientific research, a robust baseline for modeling can be established.

### **1.1 Combat Speeds: A Quantitative Framework**

To construct a realistic model of combat mobility, it is essential to move beyond qualitative descriptions and establish concrete velocity estimates. The following analysis provides these estimates for distinct modes of movement, first establishing an unarmored baseline derived from modern athletic analogues and then applying evidence-based modifiers to account for the specific biomechanical burdens of a full plate harness.

#### **Establishing the Unarmored Baseline**

The physical capabilities of a trained pre-modern combatant can be reasonably analogized to those of a modern team-sport athlete. Unlike elite Olympic sprinters, whose performance represents the absolute peak of human potential in a specialized task 1, team-sport athletes are trained for explosive, multi-directional, and short-duration sprints from various stances, which is more representative of a combat environment.  
Data from GPS tracking in sports such as American football shows that high-level perimeter players can exceed a velocity of 6.4 m/s almost immediately after 5 meters of sprinting and often possess a maximum sprinting speed (MSS) exceeding 9.4 m/s.2 This provides a realistic upper bound for an unarmored, trained individual's explosive potential. For more sustained tactical movement, modern military definitions are highly applicable. A fast jog, or "double time," is standardized at a cadence of 180 steps per minute, resulting in a speed of approximately 2.7 m/s.3 The threshold for what is considered "High Speed Running" (HSR) in a tactical context is often set at 5.5 m/s.4

#### **The Impact of Armor (25-30kg Plate Harness)**

Direct quantitative data on the sprint speeds of 15th-century men-at-arms is nonexistent. However, a robust proxy can be developed by analyzing modern sports science research on resisted sprint training. A 25-30 kg plate harness on an 80 kg individual represents an additional load of 31-37% of their body mass. In athletic studies, loads are classified by the velocity decrement they cause, with a "heavy" load inducing a 15-30% reduction in speed.5 A study specifically on football players found that carrying a load greater than 32% of body mass resulted in a running velocity decrease of approximately 23%, a 24% decrease in stride length, and a 20% increase in ground contact time.6  
Crucially, the nature of armor's load distribution makes it more debilitating than an equivalent mass carried in a backpack. Peer-reviewed studies by Askew et al. demonstrated that the energetic cost of locomotion in armor is significantly higher than trunk loading alone, primarily due to the increased energy required to swing the mass-laden limbs and the restrictive effect of the cuirass on breathing mechanics.7 This is further supported by modern load carriage research, which identifies the mechanical compression of the thorax and the inertial forces on the shoulder girdle as significant factors that compromise exercise capacity.10 This unique distribution justifies applying a velocity penalty at the higher end of the 20-30% range observed in resisted sprint studies.  
A critical consideration for modeling is that the primary impact of this heavy, limb-distributed load is on *acceleration*, not necessarily maximum velocity. Combat engagements are defined by short, explosive bursts over distances of 5-15 meters. At these distances, even trained athletes are still in their acceleration phase.2 The ability to generate the high initial horizontal force required for rapid acceleration is precisely what is most compromised by a heavy resistive load. Therefore, the penalty of armor is most acute when a combatant attempts to seize the initiative with a sudden charge, making it significantly harder to close distance explosively.

#### **Quantitative Estimates for Movement Modes**

Based on the synthesis of these sources, the following speed ranges are proposed for modeling purposes:

* **Cautious Walk/Advance:** A deliberate, guarded pace used when approaching a threat or moving in formation.  
  * **Unarmored:** 1.5 \- 1.8 m/s. This range is anchored by the U.S. military's "quick time" march speed of 1.5 m/s and the more demanding "forced march" speed of 1.8 m/s.3  
  * **Armored:** 1.0 \- 1.4 m/s. Studies on loaded walking show that the optimal (most energetically efficient) speed remains remarkably consistent at around 1.0-1.3 m/s, even with heavy loads.11 This suggests that while an armored man  
    *could* walk faster, he would do so at a disproportionate energy cost, making this range a sustainable tactical pace.  
* **Tactical Jog/Trot:** A sustained movement speed faster than a walk, used to cover ground more quickly while retaining the ability to react.  
  * **Unarmored:** 2.7 \- 4.0 m/s. The lower bound is defined by the military "double time" of 2.7 m/s.3 The upper bound represents a faster, but still sustainable, tactical jog.  
  * **Armored:** 2.0 \- 3.0 m/s. This is derived by applying a conservative \~25% velocity penalty to the unarmored baseline, reflecting the significant biomechanical disruption of jogging with limb-loaded mass.  
* **Explosive Sprint/Charge (over 5-15 meters):** A maximal-effort, anaerobic burst intended to close with an enemy or evade a sudden threat.  
  * **Unarmored:** 7.0 \- 8.5 m/s. This represents a realistic acceleration phase velocity for a trained, non-specialist sprinter, falling short of the peak speeds achievable only at longer distances.2  
  * **Armored:** 5.0 \- 6.5 m/s. This range is derived by applying a 25-30% velocity penalty to the unarmored baseline. This significant reduction reflects the direct findings on heavy resistive loads and accounts for the unique challenges of accelerating with armor's distributed mass.5

### **1.2 The Energy Cost of Movement**

The capacity to perform tactical actions is finite, governed by a combatant's physiological endurance. Quantifying the energy cost of different actions allows for a realistic model of fatigue. The standard unit for this is the Metabolic Equivalent of Task (MET), where 1 MET represents the energy expenditure of an individual at rest, equivalent to an oxygen consumption of 3.5 ml/kg/min or approximately 1 kilocalorie per kilogram of body weight per hour.13

#### **The Energetic "Tax" of Armor**

The most significant factor influencing combat energetics is the presence of armor. While historical accounts and modern reconstructions confirm that a well-fitted harness allows for a remarkable range of motion 15, it imposes a severe metabolic penalty. A landmark 2011 study published in the  
*Proceedings of the Royal Society B* by Askew et al. is the foundational source for quantifying this cost. The researchers had subjects walk and run on a treadmill while wearing a replica 15th-century plate harness. They found that the net metabolic cost of locomotion was dramatically increased:

* **Walking in armor was 2.1 to 2.3 times more energetically expensive** than unloaded walking at the same speed.  
* **Running in armor was 1.9 times more energetically expensive** than unloaded running at the same speed.7

This increase is substantially greater than what would be expected from simply carrying the additional mass. The study concluded that the extra cost is primarily due to the energy required to move the weighted limbs and the constraining effect of the armor on the wearer's breathing mechanics.8  
This finding fundamentally reframes the tactical problem for an armored combatant. It is not simply that sprinting is harder; it is that *every* movement, even a simple repositioning step, carries a massive energetic tax. An unarmored fighter can reposition with footwork at a moderate aerobic cost (e.g., a brisk walk at 3.5-5.0 METs), allowing their anaerobic systems to recover from a high-intensity burst of strikes.18 For an armored combatant, that same repositioning step now operates at a much higher metabolic rate (e.g.,  
3.5×2.3=8.05 METs), an intensity level approaching that of jogging or light combat itself. There is no "low cost" option; every action is a significant drain on a finite energy reserve. This creates a powerful tactical imperative for the armored combatant to be exceptionally efficient with their movement, favoring stable guards and decisive, committed actions over constant, probing footwork.

#### **Comparative Cost of Combat Actions**

To place the cost of armored movement in context, it must be compared to the cost of other combat actions. The *Compendium of Physical Activities* provides MET values for modern combat sports that serve as excellent proxies:

* **Moderate-Pace Martial Arts:** Activities such as judo, jujitsu, karate, and kickboxing at a moderate pace are rated at **10.3 METs**.20 This value can serve as a proxy for the average intensity of a sustained weapon-based exchange involving footwork, probing attacks, and defensive actions.  
* **High-Intensity Combat:** Vigorous activities like competitive boxing or wrestling can have significantly higher peak energy demands, well in excess of 10 METs.21 These serve as a proxy for short, maximal-effort anaerobic bursts, such as a flurry of powerful strikes, a takedown attempt, or a close-range grappling exchange (  
  *Zogho Stretto*).

Analysis of the energy systems used in modern Olympic combat sports reveals that while the overall activity is predominantly fueled by the aerobic system (contributing 62-90% of energy), the decisive, high-power scoring actions are fueled by the anaerobic ATP-PCr and glycolytic systems.23 This highlights a critical dynamic: the aerobic system functions as the "battery" that allows a fighter to sustain activity and, crucially, to recover between the anaerobic bursts that actually win the fight.  
The profound implication of armor's energetic tax is that it attacks this aerobic "battery." By making even simple walking and repositioning metabolically costly, it severely curtails an armored fighter's ability to recover between high-intensity exchanges. An unarmored opponent can use mobility to force the armored combatant into repeated, costly repositioning, effectively draining their endurance without ever needing to land a decisive blow. A functional model should reflect this by applying the metabolic cost multiplier to all forms of locomotion undertaken in armor, thereby simulating the relentless attrition it imposes on the wearer's stamina.  
---

## **KRA-2: A Taxonomy of Tactical Footwork**

Footwork is the engine of pre-modern martial arts. It is the physical mechanism through which tactical theory is translated into action. A combatant who cannot control their own position relative to their opponent cannot effectively attack or defend. This section deconstructs the core footwork techniques described in historical European martial arts (*HEMA*) manuals, creating a functional lexicon suitable for a rules-based system.

### **2.1 The Purpose of Footwork: Managing Measure, Time, and Angle**

The historical masters did not view footwork as mere locomotion but as the primary tool for manipulating the fundamental elements of a duel. Any analysis must be framed within their conceptual understanding of the fight.

* **Measure (Distance):** The 15th-century Italian master Fiore dei Liberi explicitly divides combat into two primary distances, or "plays." *Zogho Largo* (wide play) is the measure at which long weapons can strike with their edge and point. At this range, physical contact is limited to the opponent's weapon or perhaps their forward arm. *Zogho Stretto* (narrow play or close play) is the range of grappling (*abrazare*) and dagger combat, where body-to-body contact, throws, and hilt-strikes become possible.24 Footwork is the sole mechanism for deliberately transitioning between these two tactical states. A passing step forward might close from  
  *Largo* to *Stretto*, while a backward step creates the space to return to wide play.  
* **Time (Tempo):** The 16th-century German master Joachim Meyer frames the fight as a contest of initiative. He defines three temporal states: the *Vor* ("before"), where one acts first and forces the opponent to react; the *Nach* ("after"), where one is forced to react to the opponent's action; and the *Indes* ("during" or "meanwhile"), which is the instantaneous moment of opportunity within an exchange to launch a counter-action.25 Footwork, particularly deceptive or "stolen" steps, is a key tool for seizing the  
  *Vor* by provoking a premature reaction from the opponent, thereby creating an opening to be exploited *Indes*.  
* **Angle:** A consistent principle across nearly all historical European systems is the importance of gaining an advantageous angle on the opponent. This typically involves moving "offline"—that is, off the direct line connecting the two combatants. The tactical goal is twofold: to place oneself in a position where one can strike a vulnerable target (such as the opponent's side or back) while simultaneously moving one's own body out of the path of their most direct counter-attack.27

### **2.2 A Functional Lexicon of Combat Steps**

The historical manuals describe a small but versatile set of fundamental steps. While terminology varies between masters and traditions, the functional mechanics are largely universal.

* **The Passing Step (Fiore: *Passare*; Meyer: *Schritt*)**  
  * **Description:** The most natural form of bipedal locomotion, where the rear foot moves forward past the lead foot, advancing the body by one full pace. The reverse action, passing backward, is also used.28  
  * **Tactical Goal:** This is the primary action for making large, committed changes in linear distance. A forward passing step is the foundation of a committed lunge or charge, intended to close from outside measure to striking range. A backward passing step is used for a full retreat, creating significant separation.  
* **The Traverse / Offline Step (Meyer: *Triangle Step*)**  
  * **Description:** A step in which the rear foot moves diagonally and to the side, often stepping behind the lead foot's initial position. This traces a triangular path on the ground. Meyer also describes a "double triangle step," where the lead foot is then repositioned to re-establish a stable stance at the new angle.26  
  * **Tactical Goal:** This is the quintessential technique for gaining an angular advantage. It is a single, efficient action that is both defensive and offensive. By moving the body offline, it voids the opponent's linear attack, causing it to fall short or pass harmlessly. Simultaneously, it opens up a new line of attack to the opponent's flank. It is the physical embodiment of the principle of attacking and defending in a single tempo.  
* **The Gather Step (Fiore: *Accressere/Discressere*)**  
  * **Description:** A shuffle step. To advance (*accressere*), the front foot moves forward a short distance, and the rear foot is then drawn up behind it. To retreat (*discressere*), the rear foot moves back, and the front foot is then drawn back to its original distance.28  
  * **Tactical Goal:** This step is for making small, precise adjustments to *measure* without the commitment of a full passing step. It allows a fighter to probe, to "ride the edge" of the opponent's range, testing reactions and maintaining a perfect distance from which to launch an attack or execute a defense. It is a tool of patience and control.  
* **The Stolen Step (Meyer: *Gebrochene oder Gestohlene Schritt*)**  
  * **Description:** A feigned step. The combatant initiates the movement of a forward step, but before the foot is planted and weight is committed, it is quickly withdrawn to its starting position or moved into a different action.25  
  * **Tactical Goal:** This is a pure tool for manipulating tempo and perception. It is designed to bait the opponent into a premature reaction. By seeing the initiation of a step, the opponent may commit to a parry or a counter-attack. When the step "fails" to land, their action is wasted, leaving them momentarily out of position or overextended—the perfect *Indes* moment for the true attack to be launched.

It is a fundamental error to model these footwork techniques as discrete "movement actions" that are separate from "attack actions." The historical sources and modern practice make it clear that they are a unified system of body mechanics. Meyer states, "All combat happens vainly, no matter how artful it is, if the steps for it are not executed correctly".30 The power of a cut does not come from the arms; it is generated from the rotation of the hips and the transfer of body weight that is initiated by the step.27 A traverse step, for example, is not something one does  
*before* a thwart cut (*Zwerchauw*); the step itself is what enables the hip rotation that powers the cut. Therefore, a robust model should link movement and attack types. An "Attack with Passing Step" should be a distinct action with different properties (e.g., more power, more commitment, longer range) than a "Standing Attack." An "Attack with Traverse Step" should inherently possess both offensive and defensive modifiers, reflecting the functional reality that the step *is* the engine of the technique.  
---

## **KRA-3: The Mechanics of Disengagement**

Disengagement from an active opponent in melee range (*Zogho Stretto* or *Krieg*) is one of the most dangerous and tactically complex problems a combatant can face. It is not a simple matter of choosing to move away; an opponent with a sharp weapon will not passively allow their target to turn and leave. A successful disengagement requires the deliberate creation of a tactical window—a void or an "empty tempo"—where the opponent is physically or mentally unable to press their advantage for the fraction of a second needed to create separation.

### **3.1 Creating Separation: The Problem of the "Empty Tempo"**

The core challenge of disengagement is that turning one's back on an armed and aggressive opponent is suicidal. The act of turning to run presents an unarmored, undefended target and is the moment of greatest vulnerability. Therefore, a combatant must first execute a "covering action" that neutralizes the immediate threat before any retreat can begin.  
This tactical reality has important implications for modeling. As seen in analyses of modern tabletop and computer wargames, mechanics that allow a unit to disengage from melee freely, without cost or consequence, are often perceived as unrealistic and strategically unbalanced. Such rules tend to advantage the loser of a combat exchange, allowing them to nullify the winner's success by simply withdrawing without penalty.31 A functional model of pre-modern combat must represent disengagement as a difficult, risky, and deliberate act that is contingent on success, not a default option.

### **3.2 A Catalogue of Covering Actions**

The historical manuals describe a variety of techniques designed to create the necessary "empty tempo" for a safe withdrawal. These are not passive or defensive moves; they are active, often aggressive, actions performed *on* the opponent to force an opening.

* **Weapon Control Actions:** These techniques focus on neutralizing the opponent's primary weapon.  
  * **The Bind and Wind:** This involves using the strong of one's own blade to control the opponent's weaker blade section (*binden*). From this position of leverage, one can then "wind" (*winden*), using the hilt to pivot the point and lever the opponent's weapon offline, creating a brief window to step away while their weapon is misaligned.25  
  * **The Strong Parry/Beat:** This is not a delicate deflection but a powerful, percussive strike against the opponent's blade. The goal is to physically displace their weapon so forcefully that it disrupts their posture and balance, forcing them to take a moment to recover their guard before they can attack again.28  
* **Physical Control Actions:** These techniques bypass the opponent's weapon to act directly on their body.  
  * **The Shove/Push (*Absetzen*):** A common technique in both armored and unarmored combat is to use the off-hand (or the shoulder in armor) to deliver a powerful shove to the opponent's chest, face, or weapon arm. This physically creates distance, breaks their structure, and can put them off-balance, providing a clear opportunity to retreat.25  
  * **Pommel/Crossguard Strike:** At close range, the hilt of the sword becomes a potent impact weapon. A sharp strike to the opponent's helmet, face, or hands can cause a moment of disorientation, pain, or shock sufficient to allow for a disengagement.29  
* **Voiding and Timing Actions:** These techniques rely on superior timing and footwork to create separation.  
  * **The Voiding Step:** This involves executing a rapid backward or offline step (such as a backward gather step or a traverse step) at the precise instant the opponent initiates their attack. The goal is to cause their attack to fall short as they overextend into the now-empty space. This action simultaneously creates distance and leaves the opponent in a poor position to immediately pursue.24 This requires excellent perception and reaction time.

A crucial conclusion from this analysis is that successful disengagement should not be modeled as a simple "move" action. It is the *result* of a successful tactical maneuver. A combatant does not simply "disengage"; they execute a shove, a beat, or a well-timed void, and *if that action is successful*, the outcome is separation. This suggests a more realistic modeling approach where the "Disengage" option only becomes available after a successful preceding action check (e.g., a contested "Shove" check, a "Bind" check, or a reactive "Evade" check). A failure on this initial check would mean the combatant fails to create the necessary opening and remains locked in the melee. This correctly frames disengagement not as a guaranteed safety valve, but as a difficult and uncertain gambit.  
---

## **KRA-4: The Dynamics of a Fighting Retreat**

A fighting retreat is a controlled, deliberate movement away from an enemy while maintaining a defensive posture and the ability to engage threats. It is distinct from a panicked rout. This section analyzes the biomechanics and tactical challenges of this maneuver for both an individual combatant and a small, coordinated group.

### **4.1 The Individual Retreat: Biomechanics and Trade-offs**

For an individual, moving backward while facing an opponent is tactically far superior to turning and running, as it keeps one's weapon and armor oriented toward the threat. However, this safety comes at a significant biomechanical and energetic cost.

* **Energetic Cost:** Research into backward locomotion consistently shows that it elicits significantly higher cardiorespiratory and metabolic responses compared to forward locomotion at the same speed. Backward running and walking require greater muscle activation, particularly in the quadriceps and anterior lower-limb muscles, and demand more complex neuromuscular coordination.34 In practical terms, moving backward is substantially more fatiguing than moving forward.  
* **Speed Penalty:** The altered kinematics of backward movement, including a shorter stride length and a different pattern of muscle recruitment, inherently make it slower and less efficient than forward movement. While a precise universal penalty is difficult to establish, a speed reduction of **30-40% relative to equivalent forward movement** is a conservative and justifiable estimate for modeling purposes. A combatant simply cannot retreat backward as quickly as they can advance forward.  
* **Stability and Coordination:** Backward locomotion is less stable. The inability to see the ground directly behind increases the risk of tripping on uneven terrain or obstacles. It requires a higher degree of proprioception and balance, which can be compromised under the stress of combat.34

These factors combine to make an individual fighting retreat a difficult and short-lived proposition. It is a temporary measure to create a brief window of space, not a sustainable method of travel. An opponent pressing forward will almost always have a speed and energy advantage over an opponent moving backward.

### **4.2 The Small-Group Retreat: Analogues from Modern Tactics**

Detailed historical descriptions of small-unit melee tactics are exceptionally rare. The chaos of combat was not conducive to the kind of granular observation needed to document such maneuvers. However, the underlying principles of fire and movement are timeless. Modern infantry tactics for breaking contact, developed for firearm-based combat, offer excellent functional analogues for how a trained, disciplined group of pre-modern combatants might have conducted an orderly retreat. The historical precedent for cycling fresh troops to the front in larger formations suggests that the core concepts were understood.35

* **The "Peel" Maneuver (Breaking Contact):**  
  * **Description:** The peel is a tactic used by a small unit to disengage from a superior or overwhelming force while maintaining continuous pressure. The unit forms a line or column facing the enemy. One at a time, typically starting from one end of the line, a combatant ceases their engagement, moves rapidly to the rear of the formation, and establishes a new position. As soon as they are clear, the next combatant in line repeats the process. This creates a "peeling" or "rolling" withdrawal that allows the unit to move away while a majority of its members are always engaging the enemy.36  
  * **Pre-Modern Analogue:** In a pre-modern context, "suppressive fire" would not be automatic weapon fire but a continuous volley of threatening actions. For a group of four spearmen, this might involve the three in the line maintaining a hedge of spear points, making threatening jabs and feints, while the fourth man peels to the rear. For a mixed group, knights or men-at-arms could provide the "covering" action by engaging pursuers, while archers or crossbowmen peel back to a new firing position. The goal is the same: to make it too dangerous for the enemy to mount an unopposed, all-out rush.  
* **"Bounding Overwatch" (Retreating Across Open Ground):**  
  * **Description:** This is a more deliberate, leapfrogging retreat tactic used when moving across terrain that offers intermittent cover, and when contact is expected but not necessarily constant. The group divides into at least two elements (e.g., Element A and Element B). Element A takes up a defensive position and provides "overwatch"—observing the enemy and being prepared to engage any threats. Under their cover, Element B "bounds" (moves rapidly) back to a new position of cover. Once Element B is set and has established its own overwatch, they signal for Element A to bound back past them to the next position. This continues until the unit has fully withdrawn.38  
  * **Pre-Modern Analogue:** This tactic is highly applicable to a small, mixed-weapon group. Imagine two men-at-arms and two longbowmen needing to retreat across a field with scattered trees. The men-at-arms could take a defensive stance behind one tree, engaging any pursuers who get too close. The longbowmen could bound back 40 meters to the next patch of cover. Once set, they could provide covering fire with their bows, forcing pursuers to keep their heads down while the men-at-arms bound back to join them.

The successful execution of these coordinated maneuvers is entirely contingent on high levels of training, discipline, and clear communication under extreme duress. Modern military units drill these tactics relentlessly until they become second nature.37 The noise, fear, and chaos of pre-modern melee would make the necessary communication and cohesion incredibly difficult to maintain. A single individual moving at the wrong time, failing to provide adequate covering action, or panicking could cause the entire maneuver to collapse, resulting in the group being isolated and destroyed piecemeal. Therefore, a realistic model should treat these coordinated retreats as high-difficulty actions. Their execution could be governed by a "Discipline," "Morale," or "Leadership" check, with failure resulting not in an orderly withdrawal but in a disorganized rout, where each individual is left to fend for themselves. This correctly positions these tactics as the hallmark of elite, professional soldiers, not untrained levies.  
---

## **V. Quantitative Summary for Modeling**

This table consolidates the key quantitative estimates derived from the preceding analysis. It is designed to provide a data-centric foundation for the development of a rules-based model of pre-modern tactical combat, translating the report's findings into directly implementable parameters.

| Parameter | Unarmored Value | Armored (Plate) Value | Unit | Justification / Primary Sources |
| :---- | :---- | :---- | :---- | :---- |
| **LOCOMOTION SPEED** |  |  |  |  |
| Cautious Walk/Advance | 1.5 \- 1.8 | 1.0 \- 1.4 | m/s | Military march speeds 3; Loaded walk studies 11 |
| Tactical Jog/Trot | 2.7 \- 4.0 | 2.0 \- 3.0 | m/s | Military "double time" 3; \~25% speed reduction from load |
| Explosive Sprint (5-15m) | 7.0 \- 8.5 | 5.0 \- 6.5 | m/s | Team sport athlete data 2; 25-30% speed reduction 5 |
| Backward Movement Speed | 60-70% of Forward Speed | 60-70% of Forward Speed | % | Biomechanical penalty for backward locomotion 34 |
| **ENERGETICS (METs)** |  |  |  | 1 MET \= 1 kcal/kg/hr |
| Baseline (Resting) | 1.0 | 1.0 | METs | Definition 13 |
| Walking (Unloaded/Armored) | 3.5 \- 5.0 | 8.0 \- 11.5 | METs | Standard values 18; \~2.3x multiplier for armor 7 |
| Jogging (Unloaded/Armored) | 7.0 \- 8.0 | 13.3 \- 15.2 | METs | Standard values 14; \~1.9x multiplier for armor 7 |
| High-Intensity Combat Burst | 10.0 \- 12.0+ | 10.0 \- 12.0+ | METs | Proxy from martial arts/boxing 20; Action cost is independent of armor |
| **TACTICAL MODIFIERS** |  |  |  |  |
| Disengagement Prerequisite | N/A | N/A | Check | Requires successful Covering Action (Shove, Bind, Evade) to create an "empty tempo" |
| Coordinated Retreat | N/A | N/A | Check | High-difficulty maneuver requiring Discipline/Leadership check to avoid disorganized rout |

#### **Works cited**

1. Footspeed \- Wikipedia, accessed August 30, 2025, [https://en.wikipedia.org/wiki/Footspeed](https://en.wikipedia.org/wiki/Footspeed)  
2. Speed for team sports: moving past track & field \- Sportsmith, accessed August 30, 2025, [https://www.sportsmith.co/articles/speed-for-team-sports-moving-past-track-field/](https://www.sportsmith.co/articles/speed-for-team-sports-moving-past-track-field/)  
3. The Soldier's Ideal Speed • Spotter Up, accessed August 30, 2025, [https://spotterup.com/the-soldiers-ideal-speed/](https://spotterup.com/the-soldiers-ideal-speed/)  
4. The Importance Of High Speed Running For The Physical Development Of Athletes | STATSports Locker, accessed August 30, 2025, [https://statsports.com/the-locker/the-importance-of-high-speed-running-for-the-long-term-physical-development](https://statsports.com/the-locker/the-importance-of-high-speed-running-for-the-long-term-physical-development)  
5. Best Practices for Resisted Sprint Training for Acceleration and Maximum Velocity, accessed August 30, 2025, [https://coachathletics.com.au/coaching-education/best-practices-for-resisted-sprint-training-for-acceleration-and-maximum-velocity](https://coachathletics.com.au/coaching-education/best-practices-for-resisted-sprint-training-for-acceleration-and-maximum-velocity)  
6. Resisted Sprints: Use the right weight to get faster \- American Football International, accessed August 30, 2025, [https://www.americanfootballinternational.com/resisted-sprints-use-the-right-weight-to-get-faster/](https://www.americanfootballinternational.com/resisted-sprints-use-the-right-weight-to-get-faster/)  
7. Limitations imposed by wearing armour on Medieval soldiers' locomotor performance, accessed August 30, 2025, [https://pubmed.ncbi.nlm.nih.gov/21775328/](https://pubmed.ncbi.nlm.nih.gov/21775328/)  
8. (PDF) Limitations imposed by wearing armour on Medieval soldiers ..., accessed August 30, 2025, [https://www.researchgate.net/publication/51507889\_Limitations\_imposed\_by\_wearing\_armour\_on\_Medieval\_soldiers'\_locomotor\_performance](https://www.researchgate.net/publication/51507889_Limitations_imposed_by_wearing_armour_on_Medieval_soldiers'_locomotor_performance)  
9. Metabolic cost of locomotion across a range of speeds for walking and... \- ResearchGate, accessed August 30, 2025, [https://www.researchgate.net/figure/Metabolic-cost-of-locomotion-across-a-range-of-speeds-for-walking-and-running-in-armour\_fig2\_51507889](https://www.researchgate.net/figure/Metabolic-cost-of-locomotion-across-a-range-of-speeds-for-walking-and-running-in-armour_fig2_51507889)  
10. Physiological impact of load carriage exercise: Current understanding and future research directions \- ResearchGate, accessed August 30, 2025, [https://www.researchgate.net/publication/365079109\_Physiological\_impact\_of\_load\_carriage\_exercise\_Current\_understanding\_and\_future\_research\_directions](https://www.researchgate.net/publication/365079109_Physiological_impact_of_load_carriage_exercise_Current_understanding_and_future_research_directions)  
11. 5.2 Combining slope and loads \- Internet Archaeology, accessed August 30, 2025, [https://intarch.ac.uk/journal/issue36/5/5-2.html](https://intarch.ac.uk/journal/issue36/5/5-2.html)  
12. Optimal speed as a function of walking speed and load. The mass-specific net cost of locomotion ( C net \- ResearchGate, accessed August 30, 2025, [https://www.researchgate.net/figure/Optimal-speed-as-a-function-of-walking-speed-and-load-The-mass-specific-net-cost-of\_fig1\_8080271](https://www.researchgate.net/figure/Optimal-speed-as-a-function-of-walking-speed-and-load-The-mass-specific-net-cost-of_fig1_8080271)  
13. Metabolic equivalent of task \- Wikipedia, accessed August 30, 2025, [https://en.wikipedia.org/wiki/Metabolic\_equivalent\_of\_task](https://en.wikipedia.org/wiki/Metabolic_equivalent_of_task)  
14. Calories Burned/METs Calculator, accessed August 30, 2025, [https://metscalculator.com/](https://metscalculator.com/)  
15. Mobility in Medieval Plate Armor \- BenjaminRose.com, accessed August 30, 2025, [https://www.benjaminrose.com/post/mobility-in-medieval-plate-armor/](https://www.benjaminrose.com/post/mobility-in-medieval-plate-armor/)  
16. How much more difficult is it to move and fight while wearing armour? \- Reddit, accessed August 30, 2025, [https://www.reddit.com/r/medieval/comments/191jkvq/how\_much\_more\_difficult\_is\_it\_to\_move\_and\_fight/](https://www.reddit.com/r/medieval/comments/191jkvq/how_much_more_difficult_is_it_to_move_and_fight/)  
17. Mobility in Medieval Knight Plate Armor \- YouTube, accessed August 30, 2025, [https://www.youtube.com/watch?v=nVbCzmqQgPI](https://www.youtube.com/watch?v=nVbCzmqQgPI)  
18. METLevels of Common Recreational Activities \- HyperSites, accessed August 30, 2025, [https://media.hypersites.com/clients/1235/filemanager/MHC/METs.pdf](https://media.hypersites.com/clients/1235/filemanager/MHC/METs.pdf)  
19. Use Metabolic Equivalents (METs) to Calculate Calories Burned \- Howdy Health, accessed August 30, 2025, [https://howdyhealth.tamu.edu/use-metabolic-equivalents-mets-to-calculate-calories-burned/](https://howdyhealth.tamu.edu/use-metabolic-equivalents-mets-to-calculate-calories-burned/)  
20. 2011 Compendium of Physical Activities \- LWW, accessed August 30, 2025, [https://cdn-links.lww.com/permalink/mss/a/mss\_43\_8\_2011\_06\_13\_ainsworth\_202093\_sdc1.pdf](https://cdn-links.lww.com/permalink/mss/a/mss_43_8_2011_06_13_ainsworth_202093_sdc1.pdf)  
21. Supplementary table 1 – reported exercises and there classification, accessed August 30, 2025, [https://jnnp.bmj.com/content/jnnp/89/11/1224/DC1/embed/inline-supplementary-material-1.pdf?download=true](https://jnnp.bmj.com/content/jnnp/89/11/1224/DC1/embed/inline-supplementary-material-1.pdf?download=true)  
22. Caloric Cost of Traditional Martial Arts Training \- American Society of Exercise Physiologists, accessed August 30, 2025, [https://www.asep.org/asep/asep/Glass.doc](https://www.asep.org/asep/asep/Glass.doc)  
23. Energy System Contributions during Olympic Combat Sports: A Narrative Review \- PMC, accessed August 30, 2025, [https://pmc.ncbi.nlm.nih.gov/articles/PMC9961508/](https://pmc.ncbi.nlm.nih.gov/articles/PMC9961508/)  
24. Wide and Close Play in Armizare, the Martial Tradition of Fiore dei Liberi |, accessed August 30, 2025, [https://chivalricfighting.wordpress.com/2014/04/13/wide-and-close-play-in-armizare-the-martial-tradition-of-fiore-dei-liberi/](https://chivalricfighting.wordpress.com/2014/04/13/wide-and-close-play-in-armizare-the-martial-tradition-of-fiore-dei-liberi/)  
25. Joachim Meyer \~ Wiktenauer, the world's largest library of HEMA ..., accessed August 30, 2025, [https://wiktenauer.com/wiki/Joachim\_Meyer](https://wiktenauer.com/wiki/Joachim_Meyer)  
26. Meyer Rapier: German Sidesword Fencing \- James Colton, accessed August 30, 2025, [https://www.jamescolton.com/articles/meyer-rapier/](https://www.jamescolton.com/articles/meyer-rapier/)  
27. Tag: Fiore Dei Liberi \- Fight like Fiore \- WordPress.com, accessed August 30, 2025, [https://fightlikefiore.wordpress.com/tag/fiore-dei-liberi/](https://fightlikefiore.wordpress.com/tag/fiore-dei-liberi/)  
28. Fiore de'i Liberi/Sword in Two Hands \~ Wiktenauer, the world's ..., accessed August 30, 2025, [https://wiktenauer.com/wiki/Fiore\_de%27i\_Liberi/Sword\_in\_Two\_Hands](https://wiktenauer.com/wiki/Fiore_de%27i_Liberi/Sword_in_Two_Hands)  
29. Back to Basics 1 – Fundamentals and Footwork in Meyer \- Scholar Victoria, accessed August 30, 2025, [https://scholarvictoria.com/2016/02/25/back-to-basics-1-footwork-in-meyer/](https://scholarvictoria.com/2016/02/25/back-to-basics-1-footwork-in-meyer/)  
30. Footwork in Meyer \- Art of the Sword, accessed August 30, 2025, [http://artofthesword.blogspot.com/2012/03/fundamental-technique-31.html](http://artofthesword.blogspot.com/2012/03/fundamental-technique-31.html)  
31. 'Disengage' in combat resolution feels off? \- \+ WARHAMMER \- The Bolter and Chainsword, accessed August 30, 2025, [https://bolterandchainsword.com/topic/386421-disengage-in-combat-resolution-feels-off/](https://bolterandchainsword.com/topic/386421-disengage-in-combat-resolution-feels-off/)  
32. Disengage should take a full action \- Larian Studios forums, accessed August 30, 2025, [https://forums.larian.com/ubbthreads.php?ubb=showflat\&Number=744331](https://forums.larian.com/ubbthreads.php?ubb=showflat&Number=744331)  
33. Rapier Phases of the Fight : r/Hema \- Reddit, accessed August 30, 2025, [https://www.reddit.com/r/Hema/comments/1ic198r/rapier\_phases\_of\_the\_fight/](https://www.reddit.com/r/Hema/comments/1ic198r/rapier_phases_of_the_fight/)  
34. Key characteristics of backward running compared to forward ..., accessed August 30, 2025, [https://www.researchgate.net/figure/Key-characteristics-of-backward-running-compared-to-forward-running-at-relative-and\_fig4\_323496335](https://www.researchgate.net/figure/Key-characteristics-of-backward-running-compared-to-forward-running-at-relative-and_fig4_323496335)  
35. In ancient warfare, how were fresh troops able to rotate to the front lines in the midst of battle? : r/history \- Reddit, accessed August 30, 2025, [https://www.reddit.com/r/history/comments/8kv6nx/in\_ancient\_warfare\_how\_were\_fresh\_troops\_able\_to/](https://www.reddit.com/r/history/comments/8kv6nx/in_ancient_warfare_how_were_fresh_troops_able_to/)  
36. Peel (tactic) \- Wikipedia, accessed August 30, 2025, [https://en.wikipedia.org/wiki/Peel\_(tactic)](https://en.wikipedia.org/wiki/Peel_\(tactic\))  
37. Tactics \- Movement \- UNITAF Force Manual (FM), accessed August 30, 2025, [https://unitedtaskforce.net/training/sop/basic-infantry/peel](https://unitedtaskforce.net/training/sop/basic-infantry/peel)  
38. Bounding overwatch \- Wikipedia, accessed August 30, 2025, [https://en.wikipedia.org/wiki/Bounding\_overwatch](https://en.wikipedia.org/wiki/Bounding_overwatch)  
39. Bounding Overwatch \- Karmakut's Squad Guides \- YouTube, accessed August 30, 2025, [https://www.youtube.com/watch?v=JDUCx9cz\_Ds](https://www.youtube.com/watch?v=JDUCx9cz_Ds)