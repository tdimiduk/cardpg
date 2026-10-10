---
title: "Hardship and Exertion"
doc_type: "synthesis"
track: "verisimilitude"
origin: "Gemini 2.5 Pro"
epistemic_status:
  confidence: "high"
  audited_by: "Gemini 3.8 Flash (Antigravity)"
  vetted_by_human: false
  vetting_notes: "Translates physiological research on forced marches, overuse injuries, and illness into consequence mechanics."
related_files:
  - "design/research/reports/functional-decline-under-physical-hardship/report.md"
  - "design/research/reports/exertion-recovery-dynamics/report.md"
  - "design/research/synthesis/consequences-exploration.md"
---

# Hardship and Exertion

This document translates research findings into a practical reference for designing consequences related to exertion, environmental exposure, and deprivation. It is intended to inform the creation of consequences for athletic, survival, and other non-combat General Actions.

## Core Design Insights from Research

- **Proprioceptive Failure is Debilitating:** A key finding from the research on joint injuries (like a sprained ankle) is that the most significant long-term consequence is the damage to the body's proprioceptive system—its sense of position and balance. The joint is no longer "intelligent" and is prone to re-injury. This suggests that consequences from falls or stumbles shouldn't just be about pain, but should introduce a persistent mechanical vulnerability related to balance and movement.
- **Cognitive Decline Under Exertion:** The research on forced marches clearly shows that physical fatigue is also a central nervous system phenomenon. Prolonged exertion directly degrades cognitive functions like working memory, navigation, and risk assessment. This provides a strong "casual realism" justification for consequences that are purely cognitive, such as being unable to recall details of a map or making poor tactical decisions during exploration.
- **Glycogen Depletion vs. Starvation Ketosis:** A critical finding from exercise biochemistry (Coyle et al. 1986; Askew et al. 2012) is that heavy physical exertion ($500\text{–}800\ \text{kcal/hr}$ under pack or armor) depletes intramuscular and hepatic glycogen reserves within 2 to 3 hours without carbohydrate intake. Travelers do not enter starvation ketosis (which requires 24–48 hours) during a grueling day's march; they suffer acute exercise-induced hypoglycemia ("bonking"), characterized by heavy limbs ("lead legs"), loss of motor power, and neuroglycopenic brain fog. Short 15-minute breathers restore phosphocreatine and clear lactate, but cannot restore depleted muscle glycogen without carbohydrate consumption and prolonged rest.
- **Overuse Injuries are a Countdown:** Conditions like stress fractures and trench foot don't happen suddenly. They are the result of accumulated stress and neglect. This provides a model for multi-stage consequences, where a Severity 1 "Sore Feet" consequence could, if ignored, escalate into a Severity 3 "Trench Foot" condition after further exertion, creating a dynamic of pressing one's luck.

---

## Section 1: Mobility & Overexertion

These consequences model the effects of failed athletic actions (climbing, jumping, balancing) and the cumulative toll of long-distance travel.

### 1.1 Acute Joint & Ligament Injury

These represent the immediate functional impact of a misstep, fall, or sudden twisting motion.

| Severity | Injury                            | Onset     | Functional Degradation (0-10 Scale) | Key Effects & Narrative Cues                                                                                                                                          |
| :------- | :-------------------------------- | :-------- | :---------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1        | Grade I Ankle Sprain              | Immediate | 2/10.                               | Minor pain and swelling. Can still bear weight but with discomfort. "Twisted an ankle."                                                                               |
| 2        | Grade II Ankle Sprain             | Immediate | 6/10.                               | Significant pain, swelling, and joint instability. Walking is reduced to a slow, painful hobble with support. Cannot effectively carry a pack.                        |
| 3        | Shoulder Dislocation              | Immediate | 7/10.                               | Immediate and total inability to use the affected arm. Two-handed tasks (using an axe, climbing a rope) become impossible. Severe pain limits other strenuous action. |
| 4        | Grade III Ankle Sprain / ACL Tear | Immediate | 9/10.                               | Complete ligament tear. Total loss of mobility and inability to bear weight. The joint "gives way." Effectively non-ambulatory without aid.                           |

### 1.2 Cognitive Decline from Forced March

This models the mental fatigue from prolonged, strenuous travel under load.

| Severity | Mental State                 | Onset     | Functional Degradation (0-10 Scale) | Key Effects & Narrative Cues                                                                                                                   |
| :------- | :--------------------------- | :-------- | :---------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------- |
| 1        | Onset of Cognitive Load      | 2-4 hours | 2/10.                               | Performance is maintained, but with noticeably higher mental effort. Minor navigational errors (miscounting paces, briefly losing the trail).  |
| 2        | Impaired Executive Function  | 4-8 hours | 5/10.                               | Significant reduction in accuracy for complex tasks. High risk of getting lost. Failure to notice environmental threats or signs of an ambush. |
| 3        | Severe Cognitive Degradation | 8+ hours  | 8/10.                               | Catastrophic failure of judgment. Inability to plan or adapt. Onset of "droning" behavior—moving without situational awareness.                |

### 1.3 Overuse Injuries

These represent the progressive breakdown of the body from sustained marching, particularly in poor conditions. These are ideal models for consequences that worsen over time if not addressed.

| Severity | Condition                  | Onset         | Functional Degradation (0-10 Scale) | Key Effects & Narrative Cues                                                                                                                            |
| :------- | :------------------------- | :------------ | :---------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1        | Blisters / Hot Spots       | Hours         | 2/10.                               | Painful but manageable. If left untreated, can become infected or lead to altered gait, causing other injuries.                                         |
| 2        | Stress Fracture (Initial)  | Days to Weeks | 5/10.                               | A nagging, deep pain in the bone (often shin or foot) that worsens with activity. Continued marching is possible but painful and dangerous.             |
| 3        | Trench Foot (Established)  | Days          | 8/10.                               | Feet are swollen, numb, and discolored from prolonged exposure to cold and damp. Walking becomes excruciatingly painful and functionally impossible.    |
| 4        | Stress Fracture (Complete) | Weeks         | 9/10.                               | The overuse injury progresses to a full, displaced break. Functionally identical to a traumatic leg fracture; non-ambulatory and unable to bear weight. |

### 1.4 Acute Glycogen Exhaustion & Hypoglycemia ("Bonking")

This models the rapid exhaustion of carbohydrate fuel reserves during heavy load carriage, forced marches, or sustained high-output labor, dispelling the misconception that missing a trail meal only causes fatigue after multiple days.

| Severity | Condition                     | Onset         | Functional Degradation (0-10 Scale) | Key Effects & Narrative Cues                                                                                                                                             |
| :------- | :---------------------------- | :------------ | :---------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1        | **Early Glycogen Depletion**  | 60–90 minutes | 2/10.                               | Persistent hunger, mild muscle stiffness, slight irritability, reduced peak power. Readily countered by simple trail carbohydrates.                                      |
| 2        | **Acute Bonk / Hypoglycemia** | 2–3 hours     | 6/10.                               | Intramuscular glycogen $<20\ \text{mmol/kg}$; blood glucose $<3.0\ \text{mmol/L}$. "Lead legs," severe muscle weakness, cold sweat, dizziness, tunnel vision, apathy.    |
| 3        | **Exhaustion Collapse**       | 3–5 hours     | 8/10.                               | Neuroglycopenic failure. Inability to maintain upright posture or carry gear; severe disorientation, tremors, collapse. Requires carbohydrate feeding and extended rest. |

#### Quantitative Metabolic Fuel Stores & Burn Rates:

- **Liver Glycogen:** $\approx 80\text{–}100\ \text{grams}$ ($\approx 320\text{–}400\ \text{kcal}$). Acts as the systemic blood glucose buffer to maintain central nervous system and brain function.
- **Muscle Glycogen:** $\approx 350\text{–}500\ \text{grams}$ ($\approx 1,400\text{–}2,000\ \text{kcal}$). Stored directly inside individual muscle fibers; cannot be redistributed into general circulation.
- **Armored Burn Rates:** Marching under armor or pack loads burns $500\text{–}800\ \text{kcal/hr}$ (Askew et al. 2012; US Army ADA504354). Carbohydrate oxidation consumes glycogen at $1.5\text{–}3.0\ \text{g/min}$ at $>65\%\ \text{VO}_{2\text{max}}$.
- **Depletion Window:** Intramuscular glycogen in locomotor muscles drops to near zero within **2 to 3 hours** without carbohydrate intake (Coyle et al. 1986).
- **Fasting Ketosis vs. Acute Exertion:** Catabolic ketosis requires **24 to 48 hours** of starvation. On single-day expeditions, explorers skip rations and do not enter ketosis; they suffer acute exercise-induced hypoglycemia.
- **Tactical Implication for The Breather:** A 15-minute Breather clears metabolic acidosis and restores phosphocreatine (PCr), but restoring depleted muscle glycogen requires carbohydrate intake and 24 to 48 hours of rest.

---

## Section 2: Illness & Infection

These consequences model the debilitating effects of disease contracted in the field, often from contaminated water or food.

### 2.1 Waterborne Illness (Dysentery, Giardia)

The functional impact is severe, making travel or strenuous labor impossible.

| Severity | Condition                         | Onset    | Functional Degradation (0-10 Scale) | Key Effects & Narrative Cues                                                                                                                     |
| :------- | :-------------------------------- | :------- | :---------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------- |
| 2        | Mild Dysentery                    | 1-3 days | 6/10.                               | Debilitating diarrhea, severe abdominal cramps, nausea, and fever. Strenuous labor or travel is impossible. Leads to rapid dehydration.          |
| 4        | Severe Dysentery with Dehydration | 2-4 days | 9/10.                               | All the symptoms of dysentery, compounded by the lethargy, confusion, and cardiovascular strain of severe dehydration. Completely incapacitated. |
