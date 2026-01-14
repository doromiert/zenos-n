import fontforge
import psMat
import os
import sys
import xml.etree.ElementTree as ET

def get_svg_metrics(svg_path):
    """
    Parses the SVG to find the viewBox.
    Returns (min_x, min_y, width, height).
    Defaults to (0, 0, 12, 12) if not found/parseable.
    """
    try:
        tree = ET.parse(svg_path)
        root = tree.getroot()
        viewbox = root.get('viewBox')
        if viewbox:
            # viewBox format: "min-x min-y width height"
            parts = [float(x) for x in viewbox.replace(',', ' ').split()]
            if len(parts) >= 4:
                return parts[0], parts[1], parts[2], parts[3]
        
        # Fallback: try width/height attributes
        w = float(root.get('width', 12))
        h = float(root.get('height', 12))
        return 0, 0, w, h
        
    except Exception as e:
        print(f"Warning: Could not parse metrics for {svg_path}: {e}")
    return 0, 0, 12, 12

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
    font.os2_panose = (2, 0, 5, 9, 0, 0, 0, 0, 0, 0) # Proportional Sans

    # METRICS FOR 12px GRID
    # We map the visual design height to 1200 font units.
    # Ascent (1000) + Descent (200) = 1200 Total Height.
    EM_SIZE = 1200
    ASCENT = 1000
    font.em = EM_SIZE
    font.ascent = ASCENT
    font.descent = EM_SIZE - ASCENT

    # 2. Define Mapping
    # Colon: 0x3A (Standard), 0x2236 (Ratio - Used by GNOME)
    # Dot: 0x2E (Period), 0x00B7 (Middle Dot), 0x2219 (Bullet Op)
    char_map = { 
        "dot": [0x2E, 0x00B7, 0x2219], 
        "colon": [0x3A, 0x2236] 
    }
    for i in range(97, 123): char_map[chr(i)] = [i, i - 32] # a-z -> A-Z
    for i in range(48, 58): char_map[chr(i)] = [i] # 0-9

    # SPACING CALCULATION
    # 12px height = 1200 units -> 1px = 100 units.
    # Target: 2px gap between glyphs.
    UNITS_PER_PIXEL = EM_SIZE / 12  # 100
    GAP_PX = 2
    PADDING = (GAP_PX * UNITS_PER_PIXEL) / 2  # 100 units

    for fname, codepoints in char_map.items():
        svg_path = os.path.join(src_dir, fname + ".svg")
        if not os.path.exists(svg_path):
            continue

        primary_code = codepoints[0]
        glyph = font.createChar(primary_code)
        
        # Clear any existing data
        glyph.clear()
        
        # Import Outlines
        glyph.importOutlines(svg_path)
        
        # Check Layout
        bbox = glyph.boundingBox()
        imported_h = bbox[3] - bbox[1]

        # Dynamic Scaling & Normalization
        vx, vy, vw, vh = get_svg_metrics(svg_path)
        
        # 1. Normalize Origin
        if imported_h < 50:
            if vx != 0 or vy != 0:
                glyph.transform(psMat.translate(-vx, -vy))
        
            # 2. Calculate Scale Factor (Force strict 1px = 100 units scale)
            scale_factor = 100.0
            
            # 3. Apply Transform (Scale + Flip + Baseline Shift)
            TRANSFORM = psMat.compose(psMat.scale(scale_factor, -scale_factor), psMat.translate(0, ASCENT))
            glyph.transform(TRANSFORM)
        else:
            print(f"   -> Detected auto-scaling (H={imported_h}). Skipping manual scale.")
        
        # 4. Round to Integers
        glyph.round()
        
        # [CRITICAL UPDATE] Geometry Cleanup
        # 1. Correct Direction: Fixes aliasing/rendering issues (Inside vs Outside)
        # 2. Add Extrema: Adds points at min/max X/Y. Essential for clean rasterization.
        # We DO NOT use removeOverlap() as it caused the artifacts.
        glyph.correctDirection()
        glyph.addExtrema()
        
        # 6. Horizontal Ink Trimming
        bbox = glyph.boundingBox()
        xmin = bbox[0]
        if xmin != 0:
            glyph.transform(psMat.translate(-xmin, 0))
        
        # 7. Apply Strict Kerning
        glyph.left_side_bearing = int(PADDING)
        glyph.right_side_bearing = int(PADDING)

        # 8. Auto-Hinting
        glyph.autoHint()

        # Create Aliases
        for alias_code in codepoints[1:]:
            alias_glyph = font.createChar(alias_code)
            alias_glyph.addReference(glyph.glyphname)
            alias_glyph.left_side_bearing = int(PADDING)
            alias_glyph.right_side_bearing = int(PADDING)

    # 4. Save
    output_dir = os.path.dirname(out_file)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Enable OpenType flags for better compatibility
    font.generate(out_file, flags=("opentype", "short-post"))

# --- Execution ---
out_root = os.environ.get('out', '.')
out_dir = f"{out_root}/share/fonts/truetype"

raw_path = os.environ.get('rawPath')
if raw_path:
    generate_font("ZeroClock", "Regular", raw_path, f"{out_dir}/ZeroClock.ttf")

condensed_src = os.environ.get('condensedPath', '')
if condensed_src:
    generate_font("ZeroClock Condensed", "Regular", condensed_src, f"{out_dir}/ZeroClock-Condensed.ttf")