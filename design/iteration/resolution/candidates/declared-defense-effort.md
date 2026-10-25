---
title: "Candidate Resolution Mechanic: Declared Defense Effort"
doc_type: iteration
track: ludology
origin: AI drafted from Anh's proposal
epistemic_status:
  confidence: medium
  vetted_by_human: false
---

# Candidate Resolution Mechanic: Declared Defense Effort

## Concept Overview

Proposed by Anh as an exploration to increase defender interactivity during Crisis Time defenses.

Instead of flipping blindly until the incoming `Strength` is met, the defender observes the incoming `(Strength, Color)` and **declares upfront how much effort they commit to the defense**, expressed as the exact number of cards they intend to flip.

1. **Declaration:** Defender states: _"I commit $K$ cards to this defense."_
2. **Execution:** The defender flips exactly $K$ cards and sums their values in the attack's Color.
3. **Evaluation:**
   - **Nominal Success (Sum $\ge$ Strength):** The attack is parried, blocked, or avoided without severe acute complications. However, large declarations carry **Accepted Costs** (stamina burn, positional concessions, or armor strain).
   - **Under-Declaration / Something Goes Wrong (Sum < Strength):** The defense breaks down. The defender continues flipping cards from their deck until the incoming Strength is finally met. The number of additional cards required to bridge the gap determines the severity of the suffered consequence.

---

## Mechanical Details & Explorations

### 1. The Cost of Declaration

Relying solely on the fatigue cost of flipping cards is insufficient to deter players from declaring massive numbers (since 1 flip is $\sim 1/24\text{th}$ of an endurance cycle; see [Pitfall 2](../pitfalls.md)). Therefore, declaring high effort must incur tangible tactical trade-offs:

- **Positional & Tactical Costs:** Dropping prone to duck under a blow, yielding ground (forced disengagement obstacle), or rattling guard.
- **Accepted Menu Options:** High declarations (e.g. 6–8+ cards) might require picking an accepted cost from a tactical menu (e.g., accepting a mild footing penalty or yielding initiative) to guarantee avoiding physical trauma.
- **Free Effort Thresholds:** Perhaps effort equal to the attacker's Action Stack size is "free" before accepted costs begin.

### 2. Failure Resolution ("Something Goes Wrong")

If the declared flip total falls short of the incoming Strength:

- The defender was caught mid-maneuver or overconfident.
- The defender continues flipping cards from the deck until Strength is met.
- The **overage flips** directly determine consequence severity (e.g., 1–2 extra flips = Severity 1; 3–4 extra flips = Severity 2; 5+ extra flips = Severity 3 / Crisis Clock).

---

## Critical Analysis & Pitfall Audit

| Pitfall / Criterion                |      Assessment       | Key Tension                                                                                                                                                                                                                                                                                                       |
| :--------------------------------- | :-------------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pitfall 1: Decisive Conclusion** |    ⚠️ **Warning**     | Without hard caps on declarations or compounding tactical penalties, defenders can consistently over-declare to avoid ever taking lasting physical trauma, dragging fights out indefinitely.                                                                                                                      |
| **Pitfall 2: False Dilemmas**      |   ⚠️ **High Risk**    | If accepting costs is optional or milder than failing, a dominant declaration tier will quickly emerge. If flipping cards is the only cost, players will burn deck flips every time.                                                                                                                              |
| **Pitfall 3: Armor Realism**       |   ❓ **Unresolved**   | It is unclear what equipped armor does in this system: does it provide "free" declared cards, subtract from incoming Strength, or reduce the severity of overage flips?                                                                                                                                           |
| **Table AP & Card Counting**       | ❌ **Severe Failure** | Strongly incentivizes **deck card-counting and continuous probability math**. Players pause every defense to count remaining 4s and 5s in their 24-card deck to compute their exact odds of hitting Strength with $K$ flips. While automated in a VTT, this causes severe analysis paralysis at a physical table. |
| **Scale Invariance**               |   ✅ **Preserved**    | Measuring effort by card counts rather than flat subtraction preserves numerical scaling across character progression.                                                                                                                                                                                            |

---

## Brainstorming Seeds & Next Steps

To make Declared Defense Effort viable, future design iterations must solve:

1. **The Anti-AP Solution:** How can the declaration choice be made intuitive (e.g. choosing between 2 or 3 distinct posture stances: _Light Parry [2 cards]_, _Braced Block [4 cards]_, _All-Out Defense [6 cards + Prone]_) rather than open-ended integer declaration ($K \in [1..12]$)?
2. **Armor Integration:** How does armor modify the declaration economy without breaking scale invariance?
3. **Escalation Driver:** What ensures that repeated high declarations steadily drive combat to a decisive conclusion?
