import os
import argparse

"""
SVG Sword Generator

This script generates SVG icons of crossed swords, specifically modeled after Oakeshott Type XVII swords.
It was originally created to generate favicons for the CardPG VTT project.

Usage:
    python3 svg_sword_generator.py --output_dir ./output --name my_sword

"""

def get_svg(defs, content, bg_type="card", bg_color="#f8f9fa"):
    bg_element = ""
    if bg_type == "card":
        bg_element = f"""
        <!-- Card Background -->
        <rect x="10" y="8" width="44" height="56" rx="4" ry="4" fill="{bg_color}" stroke="#343a40" stroke-width="3"/>
        <!-- Inner Detail -->
        <rect x="14" y="12" width="36" height="48" rx="2" ry="2" fill="none" stroke="#dee2e6" stroke-width="1"/>
        """
    elif bg_type == "shield":
        bg_element = f"""
        <!-- Shield Background -->
        <path d="M12 12 Q 32 4, 52 12 V 28 Q 32 60, 12 28 Z" fill="{bg_color}" stroke="#343a40" stroke-width="2" />
        """

    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    {defs}
  </defs>
  {bg_element}
  <!-- Icon Content -->
  {content}
</svg>"""

def create_sword_def(id_name, grip_color, guard_color="#adb5bd", pommel_color="#adb5bd"):
    
    # Blade Geometry: Compound Taper
    # Guard at Y=42. Tip at Y=4.
    # Taper point at Y=8.
    blade_path = """
    <path d="M32 4 L 33.25 8 L 34 42 L 32 46 L 30 42 L 30.75 8 Z" fill="#e9ecef" stroke="#495057" stroke-width="1" />
    """

    # Guard Geometry: Wide V
    # Width 10 (27 to 37).
    # Center 32, 42.
    guard_path = f"""
    <path d="M27 39.5 L 32 42 L 37 39.5 L 37 41.5 L 32 44 L 27 41.5 Z" fill="{guard_color}" stroke="{guard_color}" stroke-width="1" />
    """

    return f"""
<g id="{id_name}">
    <!-- Blade -->
    {blade_path}
    <!-- Ridge -->
    <path d="M32 4 L 32 40" stroke="#868e96" stroke-width="0.5" />
    
    <!-- Guard -->
    {guard_path}
    
    <!-- Grip (Black, segmented) -->
    <path d="M31 43 L 31 53 H 33 L 33 43" fill="{grip_color}" />
    <path d="M31 46 H 33" stroke="#343a40" stroke-width="0.5" />
    <path d="M31 49 H 33" stroke="#343a40" stroke-width="0.5" />
    
    <!-- Pommel -->
    <path d="M30.5 53 L 29.5 55 L 32 57 L 34.5 55 L 33.5 53 Z" fill="{pommel_color}" stroke="{guard_color}" stroke-width="1" />
</g>
"""

def generate_sword_icon(output_path, grip_color="#212529", bg_type="card", bg_color="#f8f9fa"):
    sword_id = "sword-icon"
    sword_def = create_sword_def(sword_id, grip_color)
    
    # Final Geometry Parameters
    angle = 35
    offset = 2
    group_y = 4
    scale = 0.9
    
    content = f"""
    <g transform="translate(0, {group_y})">
        <g transform="translate(32, 32) scale({scale}) translate(-32, -32)">
            <g transform="translate(32, 32) rotate(-{angle}) translate(-32, -32)">
                <use href="#{sword_id}" transform="translate(0, {offset})" />
            </g>
            <g transform="translate(32, 32) rotate({angle}) translate(-32, -32)">
                <use href="#{sword_id}" transform="translate(0, {offset})" />
            </g>
        </g>
    </g>
    """
    
    with open(output_path, "w") as f:
        f.write(get_svg(sword_def, content, bg_type, bg_color))
    print(f"Generated sword icon at {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate SVG sword icons.")
    parser.add_argument("--output", default="sword.svg", help="Output file path")
    parser.add_argument("--grip_color", default="#212529", help="Hex color for the grip")
    parser.add_argument("--bg_type", default="card", choices=["card", "shield"], help="Background type")
    parser.add_argument("--bg_color", default="#f8f9fa", help="Hex color for the background")
    
    args = parser.parse_args()
    
    generate_sword_icon(args.output, args.grip_color, args.bg_type, args.bg_color)
