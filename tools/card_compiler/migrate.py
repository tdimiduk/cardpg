import json
import yaml
import sys
import os
import re
from typing import List, Dict, Any

def clean_text(text: str) -> str:
    if not text:
        return ""
    # Replace symbols
    text = text.replace("|x|", "{Red}")
    text = text.replace("|y|", "{Yellow}")
    text = text.replace("|z|", "{Blue}")
    return text.strip()

def parse_stats(card_data: Dict[str, Any]) -> Dict[str, int]:
    stats = {}
    for color in ['red', 'yellow', 'blue']:
        val = card_data.get(color, "")
        if val == "":
            stats[color] = 0
        else:
            try:
                stats[color] = int(val)
            except ValueError:
                stats[color] = 0
    return stats

def convert_card(card_data: Dict[str, Any]) -> Dict[str, Any]:
    new_card = {}
    new_card['name'] = card_data.get('name', 'Unknown')
    
    # Type Inference (Simple heuristic)
    action_text = card_data.get('action', '').lower()
    if 'attack' in action_text:
        new_card['type'] = 'Action'
    elif 'defend' in action_text:
        new_card['type'] = 'Defense'
    elif 'light armor' in action_text or 'heavy armor' in action_text:
        new_card['type'] = 'Item'
    elif 'pierce' in card_data.get('keywordProvide', '').lower():
        new_card['type'] = 'Item'
    else:
        new_card['type'] = 'Action' # Default
        
    # Stats
    if new_card['type'] in ['Action', 'Defense']:
        new_card['stats'] = parse_stats(card_data)
        
        # Cost
        cost_val = card_data.get('cost', "")
        if cost_val:
            try:
                new_card['cost'] = {'resources': int(cost_val)}
            except ValueError:
                pass

    # Rules / Effects
    rules = []
    
    # Action Field
    raw_action = card_data.get('action', "")
    if raw_action:
        cleaned_action = clean_text(raw_action)
        # Capitalize first letter for consistency
        cleaned_action = cleaned_action[0].upper() + cleaned_action[1:]
        rules.append(cleaned_action)
        
    # Effect Field (Append to rules or merge?)
    # For now, add as a separate rule line if it looks like a mechanic
    raw_effect = card_data.get('effect', "")
    if raw_effect:
        cleaned_effect = clean_text(raw_effect)
        rules.append(f"Effect: {cleaned_effect}")

    # Details Field
    raw_details = card_data.get('details', "")
    if raw_details:
        cleaned_details = clean_text(raw_details)
        rules.append(f"Note: {cleaned_details}")

    if rules:
        new_card['rules'] = rules

    # Flavor (None in JSON, but could use details if it's not a rule)
    
    return new_card

def migrate(json_file: str, output_dir: str):
    with open(json_file, 'r') as f:
        data = json.load(f)
        
    cards_by_actor = {}
    
    for card_data in data:
        actor = card_data.get('actor', 'common').lower().replace(' ', '_')
        if actor not in cards_by_actor:
            cards_by_actor[actor] = []
            
        converted = convert_card(card_data)
        cards_by_actor[actor].append(converted)
        
    # Write YAML files
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    for actor, cards in cards_by_actor.items():
        output_path = os.path.join(output_dir, f"{actor}.yaml")
        with open(output_path, 'w') as f:
            yaml.dump(cards, f, sort_keys=False, default_flow_style=False, allow_unicode=True)
        print(f"Wrote {len(cards)} cards to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python migrate.py <input_json> <output_dir>")
        sys.exit(1)
        
    migrate(sys.argv[1], sys.argv[2])
