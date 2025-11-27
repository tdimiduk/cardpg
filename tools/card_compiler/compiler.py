import argparse
import yaml
import json
import sys
import os
import re
from typing import List, Dict, Any, Optional

# --- DSL Parsing ---

def parse_stack_power(expr: str) -> Dict[str, Any]:
    # e.g. "{Red} + 2" -> { "base": "Red", "modifier": 2 }
    # This is a simplification. The Haskell StackPower type is likely more complex.
    # For now, we'll pass it as a string or simple object.
    return {"expression": expr}

def parse_rule(rule_str: str) -> Dict[str, Any]:
    # 1. Attack
    # "Attack({Color}): Strength = {Color} + Mod" or "Attack {Color}: Strength {Color} + Mod"
    match = re.match(r"Attack\s*(?:[\({]\s*)?(.*?)[\)}]?\s*:\s*Strength\s*=?\s*(.*)", rule_str, re.IGNORECASE)
    if match:
        color_str = match.group(1).strip()
        # Clean up braces if they were captured inside
        color = color_str.replace('{', '').replace('}', '').strip()
        
        power = match.group(2).strip()
        return {
            "type": "attack",
            "power": parse_stack_power(power),
            "resistedBy": "defense", # Default?
            "effect": None # TODO: Parse trailing effects
        }

    # 2. Defend
    # "Defend({Color}): Strength = {Color} + Mod"
    match = re.match(r"Defend\s*(?:[\({]\s*)?(.*?)[\)}]?\s*:\s*Strength\s*=?\s*(.*)", rule_str, re.IGNORECASE)
    if match:
        color_group = match.group(1)
        # Handle "Red} or {Yellow" or "Red|Yellow"
        colors = [c.strip().replace('{', '').replace('}', '') for c in re.split(r'\||\bor\b', color_group)]
        power = match.group(2).strip()
        return {
            "type": "defend",
            "power": parse_stack_power(power),
            "resists": colors,
            "effect": None
        }

    # 3. Passive
    match = re.match(r"Passive:\s*(.*)", rule_str, re.IGNORECASE)
    if match:
        return {
            "type": "passive",
            "bonus": parse_stack_power(match.group(1)),
            "condition": None
        }

    # 4. General / Action
    match = re.match(r"Action:\s*(.*)", rule_str, re.IGNORECASE)
    if match:
        return {
            "type": "general",
            "effect": match.group(1),
            "power": None,
            "cost": None
        }
        
    # 4. Fallback -> Narrative
    # Strip common prefixes for cleaner UI
    clean_text = rule_str
    for prefix in ["Effect:", "Note:"]:
        if clean_text.lower().startswith(prefix.lower()):
            clean_text = clean_text[len(prefix):].strip()

    return {
        "type": "narrative",
        "text": clean_text
    }

# --- Validation & Compilation ---

def validate_card(card: Dict[str, Any], filename: str, index: int) -> List[str]:
    errors = []
    
    if 'name' not in card:
        errors.append(f"Card #{index+1} in {filename}: Missing 'name'")
    
    # Category Inference
    is_deck_card = 'stats' in card
    is_table_card = 'defense' in card or 'resilience' in card or 'traits' in card
    
    if is_deck_card and is_table_card:
         errors.append(f"Card '{card.get('name')}' in {filename}: Ambiguous category (has both stats and defense/traits)")

    if is_table_card:
        if 'defense' not in card and 'resilience' not in card and 'traits' not in card:
             # This check is redundant due to is_table_card definition, but useful if we change logic
             pass
        # Warn if Item missing defense (User request)
        if card.get('type') == 'Item' and 'defense' not in card:
            print(f"Warning: Item '{card.get('name')}' in {filename} missing 'defense' field.")

    return errors

def compile_card(card: Dict[str, Any]) -> Dict[str, Any]:
    # Transform YAML card to JSON structure matching Haskell types
    
    compiled = {
        "id": card.get('id', card['name'].lower().replace(' ', '-')),
        "name": card['name'],
        "tags": card.get('tags', []),
        "flavor": card.get('flavor')
    }

    # Deck Card Fields
    if 'stats' in card:
        compiled['stats'] = card['stats']
        compiled['cost'] = card.get('cost', {}).get('resources')
        
        rules = []
        for r in card.get('rules', []):
            rules.append(parse_rule(r))
        compiled['rules'] = rules
        
    # Table Card Fields
    if 'defense' in card:
        compiled['defense'] = card['defense']
    if 'resilience' in card:
        compiled['resilience'] = card['resilience']
    if 'traits' in card:
        compiled['traits'] = card['traits'] # Assuming traits are just strings for now? Haskell might expect RulePassive

    return compiled

def load_and_compile(files: List[str]) -> List[Dict[str, Any]]:
    all_cards = []
    all_errors = []

    for filepath in files:
        if not os.path.exists(filepath):
            print(f"Warning: File not found: {filepath}")
            continue
            
        try:
            with open(filepath, 'r') as f:
                data = yaml.safe_load(f)
                
            if not isinstance(data, list):
                all_errors.append(f"{filepath}: Root must be a list of cards")
                continue

            for i, card in enumerate(data):
                errors = validate_card(card, filepath, i)
                if errors:
                    all_errors.extend(errors)
                else:
                    compiled_card = compile_card(card)
                    all_cards.append(compiled_card)

        except yaml.YAMLError as e:
            all_errors.append(f"{filepath}: YAML Error: {e}")

    if all_errors:
        print("Validation Errors:")
        for err in all_errors:
            print(f"  - {err}")
        sys.exit(1)
        
    return all_cards

def main():
    parser = argparse.ArgumentParser(description="CardPG Card Compiler")
    parser.add_argument('files', nargs='+', help="Input YAML files")
    parser.add_argument('--output', '-o', help="Output JSON file for VTT")
    
    args = parser.parse_args()
    
    print(f"Compiling {len(args.files)} files...")
    cards = load_and_compile(args.files)
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(cards, f, indent=2)
        print(f"Wrote {len(cards)} cards to {args.output}")
    else:
        print(f"Successfully compiled {len(cards)} cards (dry run).")

if __name__ == "__main__":
    main()
