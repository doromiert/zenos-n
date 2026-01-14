import fontforge
import os
import sys

def generate_font(family_name, style_name, src_dir, out_file):
    if not src_dir or not os.path.exists(src_dir):
        print(f"Skipping {style_name}: Directory not found.")
        return

    print(f"Generating {family_name} ({style_name})...")
    
    # 1. Initialize Font
    font = fontforge.font()
    font.familyname = family_name
    font.fontname = f"{family_name.replace(' ', '')}-{style_name}"
    font.fullname = f"{family_name} {style_name}"
    font.weight = style_name
    font.encoding = "UnicodeFull"
    
    # Proportion: Proportional Sans (2, 0, 5, 9...)
    font.panose = (2, 0, 5, 9, 0, 0, 0, 0, 0, 0)

    # 2. Define Mapping
    # Maps specific filenames to Unicode points
    char_map = { "dot": [0x2E], "colon": [0x3A] }
    for i in range(97, 123): char_map[chr(i)] = [i, i - 32] # a-z -> A-Z
    for i in range(48, 58): char_map[chr(i)] = [i] # 0-9

    # 3. Import & Spacing
    # PADDING controls the natural whitespace around the glyph
    PADDING = 80
    font.ascent = 800
    font.descent = 200
    font.em = 1000

    for fname, codepoints in char_map.items():
        svg_path = os.path.join(src_dir, fname + ".svg")
        if not os.path.exists(svg_path):
            continue

        primary_code = codepoints[0]
        glyph = font.createChar(primary_code)
        glyph.importOutlines(svg_path)
        
        # Natural Width Logic
        # Set bearings to PADDING. FontForge calculates width automatically.
        # Width = left_bearing + (xmax - xmin) + right_bearing
        glyph.left_side_bearing = PADDING
        glyph.right_side_bearing = PADDING

        # Create Aliases (e.g., mapping 'a' to 'A')
        for alias_code in codepoints[1:]:
            font.selection.select(alias_code)
            font.copyReference()
            alias_glyph = font.createChar(alias_code)
            alias_glyph.addReference(primary_code)
            # Re-apply bearings to alias
            alias_glyph.left_side_bearing = PADDING
            alias_glyph.right_side_bearing = PADDING

    # 4. Save
    output_dir = os.path.dirname(out_file)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    font.generate(out_file)

# --- Execution ---
# Paths are expected to be provided via environment variables by Nix
out_root = os.environ.get('out', '.')
out_dir = f"{out_root}/share/fonts/truetype"

# 1. Regular
raw_path = os.environ.get('rawPath')
if raw_path:
    generate_font("ZeroClock", "Regular", raw_path, f"{out_dir}/ZeroClock.ttf")

# 2. Condensed (Conditional)
condensed_src = os.environ.get('condensedPath', '')
if condensed_src:
    generate_font("ZeroClock Condensed", "Regular", condensed_src, f"{out_dir}/ZeroClock-Condensed.ttf")