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

def generate_font(family_name, style_name, src_dir, out_file, is_mono=False):
    if not src_dir or not os.path.exists(src_dir):
        print(f"Skipping {family_name}: Directory {src_dir} not found.")
        return

    print(f"Generating {family_name} ({style_name}) [Mono: {is_mono}]...")
    
    # 1. Initialize Font
    font = fontforge.font()
    font.familyname = family_name
    font.fontname = f"{family_name.replace(' ', '')}-{style_name}"
    font.fullname = f"{family_name} {style_name}"
    font.weight = style_name
    font.encoding = "UnicodeFull"
    
    # METRICS
    EM_SIZE = (1400 if is_mono else 1200)
    ASCENT = (1100 if is_mono else 1000)
    DESCENT = (300 if is_mono else 200)
    
    font.em = EM_SIZE
    font.ascent = ASCENT
    font.descent = DESCENT
    
    # Panose: 9 = Monospaced, 0 = Proportional
    if is_mono:
        font.os2_panose = (2, 0, 5, 9, 0, 0, 0, 0, 0, 0)
    else:
        font.os2_panose = (2, 0, 5, 0, 0, 0, 0, 0, 0, 0)

    # CONSTANTS
    UNITS_PER_PIXEL = 100
    GAP_PX = 2
    PAD_UNITS = int((GAP_PX * UNITS_PER_PIXEL) / 2)  # 100 units
    MONO_WIDTH = 1400 # Fixed width for Mono

    # 2. Define Mapping
    char_map = { 
        "dot": [0x2E, 0x00B7, 0x2219], 
        "colon": [0x3A, 0x2236] 
    }
    for i in range(97, 123): char_map[chr(i)] = [i, i - 32] # a-z -> A-Z
    for i in range(48, 58): char_map[chr(i)] = [i] # 0-9

    # 3. Explicitly handle Space (0x20)
    space = font.createChar(32)
    if is_mono:
        space.width = MONO_WIDTH
    else:
        space.width = 300

    for fname, codepoints in char_map.items():
        svg_path = os.path.join(src_dir, fname + ".svg")
        if not os.path.exists(svg_path):
            continue

        primary_code = codepoints[0]
        glyph = font.createChar(primary_code)
        
        glyph.clear()
        glyph.importOutlines(svg_path)
        
        bbox = glyph.boundingBox()
        imported_h = bbox[3] - bbox[1]
        vx, vy, vw, vh = get_svg_metrics(svg_path)

        # ==========================================
        #  BRANCH A: ZERO MONO (New Logic)
        # ==========================================
        if is_mono:
            TARGET_HEIGHT = 1200.0
            ALIGN_TOP = ASCENT - 100 # Vertical Padding (Center in 1400)
            
            base_h = vh if vh > 0 else 12.0
            ideal_scale = TARGET_HEIGHT / base_h
            
            # Case 1: Tiny Import
            if imported_h < 50:
                if vx != 0 or vy != 0:
                    glyph.transform(psMat.translate(-vx, -vy))
                TRANSFORM = psMat.compose(psMat.scale(ideal_scale, -ideal_scale), psMat.translate(0, ALIGN_TOP))
                glyph.transform(TRANSFORM)

            # Case 2: Auto-Scaled Import (Correction)
            else:
                curr_h = glyph.boundingBox()[3] - glyph.boundingBox()[1]
                if curr_h > 0:
                    correction = TARGET_HEIGHT / curr_h
                    if abs(correction - 1.0) > 0.01:
                        glyph.transform(psMat.scale(correction))
                        # Re-align top
                        new_bbox = glyph.boundingBox()
                        shift_y = ALIGN_TOP - new_bbox[3]
                        glyph.transform(psMat.translate(0, shift_y))

            # Standard cleanup
            glyph.round()
            glyph.correctDirection()
            glyph.addExtrema() # Vital for curve rendering

            # Horizontal Centering
            bbox = glyph.boundingBox()
            current_center_x = (bbox[0] + bbox[2]) / 2
            target_center_x = MONO_WIDTH / 2
            glyph.transform(psMat.translate(target_center_x - current_center_x, 0))
            glyph.width = MONO_WIDTH

        # ==========================================
        #  BRANCH B: ZERO CLOCK (Original Logic)
        # ==========================================
        else:
            # Original Logic: Only scale if tiny, hardcoded 100.0 scale, no auto-import correction.
            if imported_h < 50:
                if vx != 0 or vy != 0:
                    glyph.transform(psMat.translate(-vx, -vy))
                
                scale_factor = 100.0
                TRANSFORM = psMat.compose(psMat.scale(scale_factor, -scale_factor), psMat.translate(0, ASCENT))
                glyph.transform(TRANSFORM)
            
            # Standard cleanup
            glyph.round()
            glyph.correctDirection()
            glyph.addExtrema() # Vital for curve rendering
            
            # Zero Trim
            bbox = glyph.boundingBox()
            if bbox[0] != 0:
                glyph.transform(psMat.translate(-bbox[0], 0))
            
            # Bearings
            glyph.left_side_bearing = int(PAD_UNITS)
            glyph.right_side_bearing = int(PAD_UNITS)


        glyph.autoHint()
        
        # --- DEBUG OUTPUT ---
        final_bbox = glyph.boundingBox()
        print(f"    -> FINAL: Width={glyph.width}, Height={final_bbox[3]-final_bbox[1]:.0f}, BBox={final_bbox}")

        # Create Aliases
        for alias_code in codepoints[1:]:
            alias_glyph = font.createChar(alias_code)
            alias_glyph.clear()
            alias_glyph.addReference(glyph.glyphname)
            
            if is_mono:
                alias_glyph.width = MONO_WIDTH  
            else:
                # Original logic: Explicitly set bearings for aliases
                alias_glyph.left_side_bearing = int(PAD_UNITS)
                alias_glyph.right_side_bearing = int(PAD_UNITS)

    # 4. Save
    output_dir = os.path.dirname(out_file)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    print(f"Saving to {out_file}...")
    font.generate(out_file, flags=("opentype", "short-post"))
    font.close()

# --- Execution ---
out_root = os.environ.get('out', '.')
out_dir = f"{out_root}/share/fonts/truetype"

raw_path = os.environ.get('rawPath')
if raw_path:
    generate_font("ZeroClock", "Regular", raw_path, f"{out_dir}/ZeroClock.ttf", is_mono=False)
    generate_font("ZeroMono", "Regular", raw_path, f"{out_dir}/ZeroMono.ttf", is_mono=True)

condensed_src = os.environ.get('condensedPath', '')
if condensed_src:
    generate_font("ZeroClock Condensed", "Regular", condensed_src, f"{out_dir}/ZeroClock-Condensed.ttf", is_mono=False)
    generate_font("ZeroMono Condensed", "Regular", condensed_src, f"{out_dir}/ZeroMono-Condensed.ttf", is_mono=True)
