# Card System Mathematical Baseline & Statistical Analysis

This document provides a rock-solid mathematical summary of the active Player Character (PC) decks and monster decks currently defined in the database. It is intended to serve as a design anchor for calibrating action resolution, difficulty thresholds, and combat dynamics.

> [!NOTE]
> **Monsters Tier Grouping:** Monsters are grouped dynamically into three tiers based on their average card stat:
>
> - **Tier 1 (Minions / Easy):** Average card stat < 2.5 (e.g. Goblin, Zombie, Lizard Warrior)
> - **Tier 2 (Elites / Standard):** Average card stat between 2.5 and 4.0 (e.g. Wasp Queen, Cave Bat, Wolf)
> - **Tier 3 (Apex / Bosses):** Average card stat >= 4.0 (e.g. Spark Dragon, Troll, Basilisk)

## 1. Averages by Color

This table shows the **Mean, Median, and Maximum** values of {Red}, {Yellow}, and {Blue} resource values printed on individual cards, pooled across all decks in each tier.

| Cohort / Tier                          | Metric | {Red} Value | {Yellow} Value | {Blue} Value |
| :------------------------------------- | :----- | :---------: | :------------: | :----------: |
| **Player Characters (Active)**         | Mean   |    2.98     |      2.49      |     2.68     |
| (Decks: 7)                             | Median |     3.0     |      2.0       |     3.0      |
|                                        | Max    |      6      |       5        |      6       |
| **Monster Tier 1 (Minions / Easy)**    | Mean   |    2.83     |      1.38      |     1.36     |
| (Decks: 6)                             | Median |     3.0     |      1.5       |     1.0      |
|                                        | Max    |      6      |       4        |      5       |
| **Monster Tier 2 (Elites / Standard)** | Mean   |    3.51     |      3.22      |     2.66     |
| (Decks: 17)                            | Median |     3.0     |      3.0       |     2.0      |
|                                        | Max    |      8      |       8        |      7       |
| **Monster Tier 3 (Apex / Bosses)**     | Mean   |    6.10     |      4.70      |     3.63     |
| (Decks: 7)                             | Median |     6.0     |      4.0       |     3.0      |
|                                        | Max    |     12      |       10       |      8       |

## 2. Card Cost Distributions

This section shows the average number of cards per deck (of standard 24 cards) that fall into each play cost category. _Resource/Passive_ cards do not have a cost field specified in the YAML.

| Cohort / Tier                          | Resource / Passive | Cost 0 | Cost 1 | Cost 2 | Cost 3 | Cost 4+ |
| :------------------------------------- | :----------------: | :----: | :----: | :----: | :----: | :-----: |
| **Player Characters (Active)**         |        10.0        |  1.4   |  4.3   |  4.3   |  1.4   |   2.6   |
| **Monster Tier 1 (Minions / Easy)**    |        3.3         |  0.0   |  2.2   |  13.0  |  2.5   |   3.0   |
| **Monster Tier 2 (Elites / Standard)** |        7.8         |  0.9   |  3.3   |  6.3   |  3.4   |   2.4   |
| **Monster Tier 3 (Apex / Bosses)**     |        7.6         |  1.7   |  6.1   |  5.3   |  3.0   |   0.3   |

## 3. Deck Composition Ratios

The average classification breakdown of cards in a standard 24-card deck. Classification is rule-based (Attacks have explicitly defined attack logic, Defenses have defend/guard keywords, Buffs provide draw/heal/bonus effects, and Utilities contain general movement/skill actions).

| Cohort / Tier                          | Attacks | Defenses | Buffs / Boosts | Utility / Skills |
| :------------------------------------- | :-----: | :------: | :------------: | :--------------: |
| **Player Characters (Active)**         |  12.1   |   4.4    |      2.9       |       4.6        |
| **Monster Tier 1 (Minions / Easy)**    |  20.7   |   0.7    |      0.0       |       2.7        |
| **Monster Tier 2 (Elites / Standard)** |  16.2   |   2.3    |      0.3       |       5.2        |
| **Monster Tier 3 (Apex / Bosses)**     |  16.7   |   0.9    |      0.6       |       5.9        |

## 4. Defense Thresholds

This table details the average and range (Min - Max) of **Innate Defense, Equipped Armor Defense, Peak Active Defense**, and **Resilience** across each cohort.

| Cohort / Tier                          | Innate Defense | Equipped Armor | Peak Active Defense | Resilience |
| :------------------------------------- | :------------: | :------------: | :-----------------: | :--------: |
| **Player Characters (Active)**         |   2.0 (2-2)    |   2.0 (0-5)    |      2.9 (2-5)      | 3.0 (3-3)  |
| **Monster Tier 1 (Minions / Easy)**    |   2.2 (2-3)    |   0.0 (0-0)    |      2.2 (2-3)      | 2.0 (2-2)  |
| **Monster Tier 2 (Elites / Standard)** |   2.4 (2-4)    |   0.0 (0-0)    |      2.4 (2-4)      | 2.0 (2-2)  |
| **Monster Tier 3 (Apex / Bosses)**     |   2.7 (2-3)    |   0.0 (0-0)    |      2.7 (2-3)      | 2.0 (2-2)  |

## 5. Attack Modifiers ("Static Plus")

Analysis of flat bonuses added to attacks (e.g. `+2` in `{Red}: Str = {Red} + 2`). This modifier represents static combat training or weapon impact that is independent of card resource values.

| Cohort / Tier                          | Total Attacks | Mean Modifier | Median Modifier | Max Modifier |
| :------------------------------------- | :-----------: | :-----------: | :-------------: | :----------: |
| **Player Characters (Active)**         |      85       |     +1.92     |      +2.0       |     +10      |
| **Monster Tier 1 (Minions / Easy)**    |      124      |     +1.86     |      +3.0       |      +4      |
| **Monster Tier 2 (Elites / Standard)** |      276      |     +2.47     |      +2.0       |      +7      |
| **Monster Tier 3 (Apex / Bosses)**     |      117      |     +4.15     |      +4.0       |     +10      |

## Appendix: Detailed Decks Directory

Below is the specific breakdown of each parsed character and monster deck used to compile the stats above.

### Player Characters (Active)

| Name           | Cards | Avg Card Stat | Innate Def/Res | Armor Def | Peak Def | Attacks | Flat Mod Mean |
| :------------- | :---: | :-----------: | :------------: | :-------: | :------: | :-----: | :-----------: |
| Culorn         |  24   |     2.92      |      2/3       |     0     |    2     |   11    |     +3.00     |
| Vallhach       |  24   |     2.92      |      2/3       |     0     |    2     |   12    |     +2.00     |
| Berserker      |  24   |     2.22      |      2/3       |     3     |    3     |   11    |     +1.45     |
| Shield-fighter |  24   |     2.62      |      2/3       |     3     |    3     |   12    |     +1.83     |
| Squire         |  24   |     2.69      |      2/3       |     5     |    5     |   13    |     +1.85     |
| Swashbuckler   |  24   |     2.76      |      2/3       |     3     |    3     |   12    |     +1.67     |
| Wizard         |  24   |     2.89      |      2/3       |     0     |    2     |   14    |     +1.71     |

### Monster Tier 1 (Minions / Easy)

| Name         | Cards | Avg Card Stat | Innate Def/Res | Armor Def | Peak Def | Attacks | Flat Mod Mean |
| :----------- | :---: | :-----------: | :------------: | :-------: | :------: | :-----: | :-----------: |
| Ant soldier  |  24   |     2.33      |      2/2       |     0     |    2     |   24    |     +1.50     |
| Goblin       |  24   |     1.50      |      2/2       |     0     |    2     |   24    |     -0.75     |
| Ice screamer |  24   |     2.39      |      2/2       |     0     |    2     |   16    |     +3.00     |
| Sky zombie   |  24   |     1.29      |      2/2       |     0     |    2     |   24    |     +2.88     |
| Troglodyte   |  24   |     2.33      |      3/2       |     0     |    3     |   12    |     +2.00     |
| Zombie       |  24   |     1.29      |      2/2       |     0     |    2     |   24    |     +3.00     |

### Monster Tier 2 (Elites / Standard)

| Name                | Cards | Avg Card Stat | Innate Def/Res | Armor Def | Peak Def | Attacks | Flat Mod Mean |
| :------------------ | :---: | :-----------: | :------------: | :-------: | :------: | :-----: | :-----------: |
| Ant queen           |  24   |     3.06      |      2/2       |     0     |    2     |   20    |     +2.00     |
| Bread wolf          |  24   |     2.64      |      2/2       |     0     |    2     |   24    |     +2.83     |
| Cake slicer         |  24   |     2.61      |      2/2       |     0     |    2     |   16    |     +2.25     |
| Cave bat            |  24   |     3.18      |      2/2       |     0     |    2     |   12    |     +1.67     |
| Crystal shard       |  24   |     3.58      |      4/2       |     0     |    4     |   14    |     +2.50     |
| Evil chef           |  24   |     2.61      |      2/2       |     0     |    2     |   16    |     +2.50     |
| Gazinia             |  24   |     3.81      |      2/2       |     0     |    2     |   15    |     +4.00     |
| Gingerbread soldier |  24   |     3.39      |      3/2       |     0     |    3     |   10    |     +0.00     |
| Infernal troglodyte |  24   |     2.67      |      3/2       |     0     |    3     |   12    |     +3.00     |
| Lizard warrior      |  24   |     2.58      |      3/2       |     0     |    3     |   13    |     +3.08     |
| Stone spirit        |  24   |     3.36      |      2/2       |     0     |    2     |   17    |     +3.29     |
| Wasp queen          |  24   |     3.83      |      2/2       |     0     |    2     |   20    |     +2.20     |
| Wasp soldier        |  24   |     2.50      |      2/2       |     0     |    2     |   24    |     +1.50     |
| Water spirit        |  24   |     3.43      |      3/2       |     0     |    3     |   14    |     +3.43     |
| Weakness warrior    |  24   |     3.46      |      2/2       |     0     |    2     |   15    |     +2.20     |
| Wind spirit         |  24   |     3.89      |      2/2       |     0     |    2     |   10    |     +2.20     |
| Wolf                |  24   |     2.64      |      2/2       |     0     |    2     |   24    |     +2.83     |

### Monster Tier 3 (Apex / Bosses)

| Name               | Cards | Avg Card Stat | Innate Def/Res | Armor Def | Peak Def | Attacks | Flat Mod Mean |
| :----------------- | :---: | :-----------: | :------------: | :-------: | :------: | :-----: | :-----------: |
| Basilisk           |  24   |     5.11      |      2/2       |     0     |    2     |   18    |     +4.00     |
| Bear               |  24   |     5.04      |      3/2       |     0     |    3     |   20    |     +5.80     |
| Gingerbread knight |  24   |     4.53      |      3/2       |     0     |    3     |   10    |     +3.00     |
| Minotaur           |  24   |     4.62      |      3/2       |     0     |    3     |   16    |     +5.12     |
| Rainbow incarnate  |  24   |     4.83      |      2/2       |     0     |    2     |   16    |     +1.00     |
| Spark dragon       |  24   |     4.49      |      3/2       |     0     |    3     |   22    |     +4.05     |
| Troll              |  24   |     5.04      |      3/2       |     0     |    3     |   15    |     +5.33     |
