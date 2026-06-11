#!/usr/bin/env python3
import os
import re
import yaml
import statistics
from pathlib import Path
from typing import List, Dict, Any

PROJECT_ROOT = Path(__file__).resolve().parents[3]
DATA_DIR = PROJECT_ROOT / "data" / "cards"
OUTPUT_FILE = PROJECT_ROOT / "data" / "math-baseline.md"

# Known legacy characters to exclude entirely
LEGACY_PCS = {"marina", "stary"}

def load_yaml(path: Path) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        try:
            return yaml.safe_load(f) or {}
        except Exception as e:
            print(f"Error parsing YAML {path}: {e}")
            return {}

def parse_attack_modifier(attack_str: Any) -> int:
    if not isinstance(attack_str, str):
        return 0
    first_line = attack_str.split('\n')[0].strip()
    # Matches Str = {Red} + 2 or Str = {Yellow} - 1 or Str = |x| + 3
    match = re.search(r'Str\s*=\s*(?:\{[a-zA-Z]+\}|\|[a-zA-Z]+\|)\s*([+-])\s*(\d+)', first_line, re.IGNORECASE)
    if match:
        sign = match.group(1)
        val = int(match.group(2))
        return val if sign == '+' else -val
    return 0

def classify_card(card: Dict[str, Any]) -> str:
    # 1. Attack
    if 'attack' in card and card['attack']:
        return 'Attack'
    
    name = str(card.get('name', '')).lower()
    rules = card.get('rules', [])
    if isinstance(rules, str):
        rules = [rules]
    rules_lower = [str(r).lower() for r in rules if r]
    
    # 2. Defense
    def_keywords = ['defend', 'defense', 'parry', 'guard', 'shield', 'fend', 'block']
    if any(k in name for k in def_keywords) or any(any(k in r for k in def_keywords) for r in rules_lower):
        return 'Defense'
        
    # 3. Buff
    buff_keywords = ['inspire', 'draw', 'recover', 'heal', 'gain', 'add', 'bonus', 'strength +', 'resource for', '+ when', 'heal someone']
    if any(k in name for k in buff_keywords) or any(any(k in r for k in buff_keywords) for r in rules_lower):
        return 'Buff'
        
    # 4. Utility
    return 'Utility'

def get_avg_card_stat(deck: List[Dict[str, Any]]) -> float:
    if not deck:
        return 0.0
    total = 0
    for card in deck:
        stats = card.get("stats", {})
        total += stats.get("red", 0)
        total += stats.get("yellow", 0)
        total += stats.get("blue", 0)
    return total / (len(deck) * 3)

def analyze_actor(data: Dict[str, Any], path: Path) -> Dict[str, Any]:
    deck = data.get("deck", [])
    items = data.get("items", []) or []
    nature = data.get("nature", []) or []
    
    # 1. Card stats
    reds = [card.get("stats", {}).get("red", 0) for card in deck]
    yellows = [card.get("stats", {}).get("yellow", 0) for card in deck]
    blues = [card.get("stats", {}).get("blue", 0) for card in deck]
    
    # 2. Cost distribution
    cost_counts = {
        "resource": 0,  # omitted
        "0": 0,
        "1": 0,
        "2": 0,
        "3": 0,
        "4+": 0
    }
    for card in deck:
        cost = card.get("cost")
        if cost is None:
            cost_counts["resource"] += 1
        else:
            try:
                c_val = int(cost)
                if c_val == 0:
                    cost_counts["0"] += 1
                elif c_val == 1:
                    cost_counts["1"] += 1
                elif c_val == 2:
                    cost_counts["2"] += 1
                elif c_val == 3:
                    cost_counts["3"] += 1
                else:
                    cost_counts["4+"] += 1
            except ValueError:
                # Fallback if cost is not integer
                cost_counts["resource"] += 1

    # 3. Card type composition
    composition = {"Attack": 0, "Defense": 0, "Buff": 0, "Utility": 0}
    for card in deck:
        c_type = classify_card(card)
        composition[c_type] += 1
        
    # 4. Defense & Resilience
    innate_def = 1
    innate_res = 1
    for n in nature:
        if isinstance(n, dict):
            if "defense" in n and n["defense"] is not None:
                innate_def = max(innate_def, n["defense"])
            if "resilience" in n and n["resilience"] is not None:
                innate_res = max(innate_res, n["resilience"])
                
    armor_def = 0
    for item in items:
        if isinstance(item, dict) and "defense" in item and item["defense"] is not None:
            armor_def = max(armor_def, item["defense"])
            
    peak_def = max(innate_def, armor_def)
    
    # 5. Attack modifiers
    modifiers = []
    for card in deck:
        if 'attack' in card and card['attack']:
            modifiers.append(parse_attack_modifier(card['attack']))
            
    return {
        "name": data.get("name", path.stem),
        "reds": reds,
        "yellows": yellows,
        "blues": blues,
        "cost_counts": cost_counts,
        "composition": composition,
        "innate_def": innate_def,
        "innate_res": innate_res,
        "armor_def": armor_def,
        "peak_def": peak_def,
        "modifiers": modifiers,
        "card_count": len(deck),
        "avg_card_stat": get_avg_card_stat(deck)
    }

def main():
    print("Starting Card Data Analysis...")
    
    # Load PCs
    pc_dir = DATA_DIR / "pc"
    pc_files = [f for f in pc_dir.glob("*.yaml") if not f.name.endswith(".reformatted") and f.stem not in LEGACY_PCS]
    pcs = [analyze_actor(load_yaml(f), f) for f in pc_files]
    
    # Load Monsters
    monster_dir = DATA_DIR / "monsters"
    monster_files = [f for f in monster_dir.glob("*.yaml") if not f.name.endswith(".reformatted")]
    monsters = [analyze_actor(load_yaml(f), f) for f in monster_files]
    
    # Classify monsters into tiers based on average card stat
    tier1_monsters = []  # AvgStat < 2.5
    tier2_monsters = []  # 2.5 <= AvgStat < 4.0
    tier3_monsters = []  # AvgStat >= 4.0
    
    for m in monsters:
        if m["avg_card_stat"] < 2.5:
            tier1_monsters.append(m)
        elif m["avg_card_stat"] < 4.0:
            tier2_monsters.append(m)
        else:
            tier3_monsters.append(m)
            
    groups = {
        "Player Characters (Active)": pcs,
        "Monster Tier 1 (Minions / Easy)": tier1_monsters,
        "Monster Tier 2 (Elites / Standard)": tier2_monsters,
        "Monster Tier 3 (Apex / Bosses)": tier3_monsters
    }
    
    markdown = []
    markdown.append("# Card System Mathematical Baseline & Statistical Analysis\n")
    markdown.append("This document provides a rock-solid mathematical summary of the active Player Character (PC) decks and monster decks currently defined in the database. It is intended to serve as a design anchor for calibrating action resolution, difficulty thresholds, and combat dynamics.\n")
    markdown.append("> [!NOTE]")
    markdown.append("> **Monsters Tier Grouping:** Monsters are grouped dynamically into three tiers based on their average card stat:")
    markdown.append("> * **Tier 1 (Minions / Easy):** Average card stat < 2.5 (e.g. Goblin, Zombie, Lizard Warrior)")
    markdown.append("> * **Tier 2 (Elites / Standard):** Average card stat between 2.5 and 4.0 (e.g. Wasp Queen, Cave Bat, Wolf)")
    markdown.append("> * **Tier 3 (Apex / Bosses):** Average card stat >= 4.0 (e.g. Spark Dragon, Troll, Basilisk)\n")
    
    # Section 1: Averages by Color
    markdown.append("## 1. Averages by Color\n")
    markdown.append("This table shows the **Mean, Median, and Maximum** values of {Red}, {Yellow}, and {Blue} resource values printed on individual cards, pooled across all decks in each tier.\n")
    markdown.append("| Cohort / Tier | Metric | {Red} Value | {Yellow} Value | {Blue} Value |")
    markdown.append("| :--- | :--- | :---: | :---: | :---: |")
    
    for name, actors in groups.items():
        if not actors:
            continue
        all_r = [val for a in actors for val in a["reds"]]
        all_y = [val for a in actors for val in a["yellows"]]
        all_b = [val for a in actors for val in a["blues"]]
        
        mean_r, med_r, max_r = statistics.mean(all_r), statistics.median(all_r), max(all_r)
        mean_y, med_y, max_y = statistics.mean(all_y), statistics.median(all_y), max(all_y)
        mean_b, med_b, max_b = statistics.mean(all_b), statistics.median(all_b), max(all_b)
        
        markdown.append(f"| **{name}** | Mean | {mean_r:.2f} | {mean_y:.2f} | {mean_b:.2f} |")
        markdown.append(f"| (Decks: {len(actors)}) | Median | {med_r:.1f} | {med_y:.1f} | {med_b:.1f} |")
        markdown.append(f"| | Max | {max_r} | {max_y} | {max_b} |")
        
    markdown.append("\n")
    
    # Section 2: Card Cost Distributions
    markdown.append("## 2. Card Cost Distributions\n")
    markdown.append("This section shows the average number of cards per deck (of standard 24 cards) that fall into each play cost category. *Resource/Passive* cards do not have a cost field specified in the YAML.\n")
    markdown.append("| Cohort / Tier | Resource / Passive | Cost 0 | Cost 1 | Cost 2 | Cost 3 | Cost 4+ |")
    markdown.append("| :--- | :---: | :---: | :---: | :---: | :---: | :---: |")
    
    for name, actors in groups.items():
        if not actors:
            continue
        avg_res = statistics.mean([a["cost_counts"]["resource"] for a in actors])
        avg_0 = statistics.mean([a["cost_counts"]["0"] for a in actors])
        avg_1 = statistics.mean([a["cost_counts"]["1"] for a in actors])
        avg_2 = statistics.mean([a["cost_counts"]["2"] for a in actors])
        avg_3 = statistics.mean([a["cost_counts"]["3"] for a in actors])
        avg_4plus = statistics.mean([a["cost_counts"]["4+"] for a in actors])
        
        markdown.append(f"| **{name}** | {avg_res:.1f} | {avg_0:.1f} | {avg_1:.1f} | {avg_2:.1f} | {avg_3:.1f} | {avg_4plus:.1f} |")
        
    markdown.append("\n")
    
    # Section 3: Deck Composition
    markdown.append("## 3. Deck Composition Ratios\n")
    markdown.append("The average classification breakdown of cards in a standard 24-card deck. Classification is rule-based (Attacks have explicitly defined attack logic, Defenses have defend/guard keywords, Buffs provide draw/heal/bonus effects, and Utilities contain general movement/skill actions).\n")
    markdown.append("| Cohort / Tier | Attacks | Defenses | Buffs / Boosts | Utility / Skills |")
    markdown.append("| :--- | :---: | :---: | :---: | :---: |")
    
    for name, actors in groups.items():
        if not actors:
            continue
        avg_atk = statistics.mean([a["composition"]["Attack"] for a in actors])
        avg_def = statistics.mean([a["composition"]["Defense"] for a in actors])
        avg_buf = statistics.mean([a["composition"]["Buff"] for a in actors])
        avg_utl = statistics.mean([a["composition"]["Utility"] for a in actors])
        
        markdown.append(f"| **{name}** | {avg_atk:.1f} | {avg_def:.1f} | {avg_buf:.1f} | {avg_utl:.1f} |")
        
    markdown.append("\n")
    
    # Section 4: Defense Thresholds
    markdown.append("## 4. Defense Thresholds\n")
    markdown.append("This table details the average and range (Min - Max) of **Innate Defense, Equipped Armor Defense, Peak Active Defense**, and **Resilience** across each cohort.\n")
    markdown.append("| Cohort / Tier | Innate Defense | Equipped Armor | Peak Active Defense | Resilience |")
    markdown.append("| :--- | :---: | :---: | :---: | :---: |")
    
    for name, actors in groups.items():
        if not actors:
            continue
        
        inn_def_list = [a["innate_def"] for a in actors]
        arm_def_list = [a["armor_def"] for a in actors]
        peak_def_list = [a["peak_def"] for a in actors]
        res_list = [a["innate_res"] for a in actors]
        
        avg_inn_def, min_inn, max_inn = statistics.mean(inn_def_list), min(inn_def_list), max(inn_def_list)
        avg_arm_def, min_arm, max_arm = statistics.mean(arm_def_list), min(arm_def_list), max(arm_def_list)
        avg_peak_def, min_peak, max_peak = statistics.mean(peak_def_list), min(peak_def_list), max(peak_def_list)
        avg_res, min_res, max_res = statistics.mean(res_list), min(res_list), max(res_list)
        
        markdown.append(f"| **{name}** | {avg_inn_def:.1f} ({min_inn}-{max_inn}) | {avg_arm_def:.1f} ({min_arm}-{max_arm}) | {avg_peak_def:.1f} ({min_peak}-{max_peak}) | {avg_res:.1f} ({min_res}-{max_res}) |")
        
    markdown.append("\n")
    
    # Section 5: Attack Power Modifiers
    markdown.append("## 5. Attack Modifiers (\"Static Plus\")\n")
    markdown.append("Analysis of flat bonuses added to attacks (e.g. `+2` in `{Red}: Str = {Red} + 2`). This modifier represents static combat training or weapon impact that is independent of card resource values.\n")
    markdown.append("| Cohort / Tier | Total Attacks | Mean Modifier | Median Modifier | Max Modifier |")
    markdown.append("| :--- | :---: | :---: | :---: | :---: |")
    
    for name, actors in groups.items():
        if not actors:
            continue
        all_mods = [mod for a in actors for mod in a["modifiers"]]
        if not all_mods:
            markdown.append(f"| **{name}** | 0 | 0.00 | 0.0 | 0 |")
            continue
        
        mean_m = statistics.mean(all_mods)
        med_m = statistics.median(all_mods)
        max_m = max(all_mods)
        
        markdown.append(f"| **{name}** | {len(all_mods)} | {mean_m:+.2f} | {med_m:+.1f} | {max_m:+} |")
        
    markdown.append("\n")
    
    # Detailed breakdown per actor
    markdown.append("## Appendix: Detailed Decks Directory\n")
    markdown.append("Below is the specific breakdown of each parsed character and monster deck used to compile the stats above.\n")
    
    for g_name, actors in groups.items():
        markdown.append(f"### {g_name}\n")
        markdown.append("| Name | Cards | Avg Card Stat | Innate Def/Res | Armor Def | Peak Def | Attacks | Flat Mod Mean |")
        markdown.append("| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |")
        for a in sorted(actors, key=lambda x: x["name"]):
            inn_df_rs = f"{a['innate_def']}/{a['innate_res']}"
            avg_m = statistics.mean(a["modifiers"]) if a["modifiers"] else 0.0
            markdown.append(f"| {a['name'].capitalize()} | {a['card_count']} | {a['avg_card_stat']:.2f} | {inn_df_rs} | {a['armor_def']} | {a['peak_def']} | {len(a['modifiers'])} | {avg_m:+.2f} |")
        markdown.append("\n")

    # Save to file
    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(markdown))
        
    print(f"Baseline statistics generated successfully at: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
