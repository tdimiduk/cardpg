# Factual Basis for Design: Tactical Movement & Positioning

This document translates the findings from our research on historical combat locomotion into a practical, designer-facing framework. It is intended to provide a grounded, evidence-based model for tactical movement, reinforcing the "Casual Realism" guiding principle of the game.

## The Disengagement Problem

A core finding from the research is that disengaging from an active opponent is not a simple "move away" action; it is a tactical problem that must be solved. Turning one's back on an armed opponent is the moment of greatest vulnerability. Therefore, a successful disengagement requires first creating a tactical window—an "empty tempo"—where the opponent is physically or mentally unable to press their advantage.

**Design Implication:** Disengagement should not be a default option. It should be the _result_ of a successful preceding action that creates the necessary opening.

### A Catalogue of Covering Actions

The following are historical "covering actions" used to create the window for disengagement. These should serve as inspiration for `Action Card` design.

- **Weapon Control Actions:** Techniques that neutralize the opponent's weapon.
  - **The Bind and Wind:** Using leverage to control and misalign the opponent's blade.
  - **The Strong Parry/Beat:** A powerful, percussive strike to physically displace the opponent's weapon and disrupt their posture.
- **Physical Control Actions:** Techniques that act directly on the opponent's body.
  - **The Shove/Push:** Using an off-hand or shoulder to physically create distance and break the opponent's balance.
  - **Pommel/Crossguard Strike:** A close-range strike to the head or hands to cause a moment of disorientation.
- **Voiding and Timing Actions:** Using superior footwork to cause an opponent's attack to miss, leaving them overextended.

## The Dynamics of Retreat

### Individual Fighting Retreat

Moving backward while facing a threat is safer than turning to run, but it comes at a significant biomechanical cost.

- **Speed Penalty:** Backward locomotion is inherently less efficient, with an estimated speed reduction of **30-40%** compared to forward movement.
- **Energetic Cost:** Moving backward is substantially more fatiguing than moving forward at the same speed.

**Design Implication:** A "Fighting Retreat" action should be mechanically more costly (e.g., require a higher card expenditure) than a standard forward movement.

### Small-Group Coordinated Retreat

An orderly retreat for a group is a high-skill maneuver requiring discipline and clear communication to avoid collapsing into a rout. Modern small-unit tactics provide excellent analogues for how this could be modeled.

- **The "Peel":** A rolling withdrawal where combatants take turns providing covering fire while others move to the rear. This allows the unit to disengage while still presenting a threat.
- **"Bounding Overwatch":** A leapfrogging retreat where one element provides cover from a static position while another "bounds" to a new position of cover.

**Design Implication:** These maneuvers are a perfect fit for a `Blue` (Intellect/Planning) `General Action`. A leader could attempt to "Coordinate Retreat"; success allows the group to disengage safely, while failure results in a chaotic, disorganized rout where each character is on their own.

## A Lexicon of Tactical Footwork

Footwork is the engine of historical martial arts, used to manipulate distance, time, and angle. This lexicon provides a functional basis for designing integrated actions.

| Step Type         | Description                                                  | Tactical Goal                                                                                                                                                                 |
| :---------------- | :----------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Passing Step**  | The rear foot moves forward past the lead foot.              | The primary action for making large, committed changes in linear distance. Powers a committed lunge or charge.                                                                |
| **Traverse Step** | The rear foot moves diagonally and to the side.              | The quintessential technique for gaining an angular advantage; a single action that is both defensive (voiding a linear attack) and offensive (opening a new line of attack). |
| **Gather Step**   | A shuffle step; one foot moves, then the other follows.      | For making small, precise adjustments to distance without over-committing. Ideal for probing and controlling the "edge" of an opponent's range.                               |
| **Stolen Step**   | A feigned step that is initiated but then quickly withdrawn. | Manipulates tempo and perception by baiting an opponent into a premature reaction, creating an opening when their action is wasted.                                           |

## The Energetic Cost of Movement

A combatant's capacity for action is finite, governed by their physiological endurance. The research into combat locomotion provides a robust, quantitative framework for modeling this exertion using the **Metabolic Equivalent of Task (MET)**, where 1 MET represents the energy cost of an individual at rest. This data is the foundation for modeling the game's stamina and fatigue systems.

The most critical finding is the severe metabolic penalty, or "energetic tax," imposed by wearing armor. This is a direct result of the high cost of moving armored limbs and the biomechanical inefficiency of the armor's load distribution.

### Table 1: Metabolic Energy Cost of Locomotion (Updated)

_These values are derived from the `report-metabolic-cost-of-armor` and `synthesis-armor` documents, using a baseline of ~3.0 METs for a cautious walk and ~7.5 METs for a tactical jog._

| Movement Mode     | Unarmored METs | Maille + Gambeson (~1.6x) | Plate Harness (Standard, ~2.2x) | Plate Harness (Masterwork, ~1.7x) |
| :---------------- | :------------- | :------------------------ | :------------------------------ | :-------------------------------- |
| Resting           | 1.0            | **1.0**                   | **1.0**                         | **1.0**                           |
| Cautious Walk     | ~3.0           | **~4.8**                  | **~6.6**                        | **~5.1**                          |
| Tactical Jog/Trot | ~7.5           | **~12.0**                 | **~16.5**                       | **~12.8**                         |

To contextualize these costs, the following table provides METs values for active combat, using modern combat sports as proxies.

### Table 2: Metabolic Energy Cost of Combat Actions (Proxies)

| Combat Action Type                    | METs Value       |
| :------------------------------------ | :--------------- |
| Sustained Exchange (Moderate Pace)    | **10.3**         |
| High-Intensity Burst (Maximal Effort) | **>12.0** (est.) |

**Design Implication:** The updated data reinforces a foundational principle for armored combatants: **there is no low-cost movement option**. A simple cautious walk in a standard plate harness (~6.6 METs) is a significant exertion. A tactical jog (~16.5 METs) is a maximal, unsustainable effort. This forces an armored combatant to be exceptionally efficient with their movement, creating a powerful "casual realism" justification for mechanics that impose a direct, per-action stamina cost for movement while in heavy armor. The distinction between a Standard and Masterwork harness also provides a clear mechanical advantage for higher-quality gear, directly translating into greater stamina and endurance.
