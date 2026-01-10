{
  config,
  pkgs,
  lib,
  self,
  ...
}:

let
  # --- Release Configuration ---
  # [Toggle] Set to "stable" or "beta"
  releaseType = "beta";

  # --- Dynamic Version Logic ---
  # Grab the commit hash from the flake (requires 'self' in specialArgs)
  # Defaults to "dirty" if changes aren't committed.
  commitId = self.shortRev or "dirty";

  baseVersion = "1.0N";

  version = if releaseType == "beta" then "${baseVersion}b (${commitId})" else baseVersion;

  # --- Config Variables ---
  distroName = config.system.nixos.distroName or "ZenOS";
  hostName = config.networking.hostName;

  # --- [1] The Icon Theme ---
  zenosIcons = pkgs.runCommand "zenos-icon-theme" { } ''
    mkdir -p $out/share/icons
    cp -r ${../../../resources/hicolor} $out/share/icons/hicolor
  '';

  # --- [2] The Plymouth Boot Theme ---
  zenosPlymouth = pkgs.stdenv.mkDerivation {
    pname = "zenos-plymouth";
    version = "1.0";

    src = ../../../resources/plymouth;
    nativeBuildInputs = [ pkgs.imagemagick ];

    env_distroName = distroName;
    env_version = version;
    env_hostName = hostName;

    buildPhase = ''
      # --- ASSET GENERATION (OPTIMIZED) ---
      font_bold="${pkgs.atkinson-hyperlegible}/share/fonts/opentype/AtkinsonHyperlegible-Bold.otf"
      font_reg="${pkgs.atkinson-hyperlegible}/share/fonts/opentype/AtkinsonHyperlegible-Regular.otf"

      # 1. Top Block: Logo (Target 120px)
      # Density 1200 on 16px SVG -> ~266px raw. Good quality downscale.
      magick -background none -density 1200 logo.svg -resize 120x120 icon_top.png

      # 2. Top Block: Hostname
      magick -background none -fill white -font "$font_bold" \
        -pointsize 72 label:"$env_hostName" host_text.png

      # 3. Bottom Block: "Powered by"
      magick -background none -fill white -font "$font_reg" \
        -pointsize 32 label:"Powered by" powered_by.png

      # 4. Bottom Block: ZenOS Icon (Target 64px)
      magick -background none -density 1200 zenos.svg -resize 64x64 icon_bottom.png

      # 5. Bottom Block: ZenOS Text
      magick -background none -fill white -font "$font_reg" -pointsize 48 label:"$env_distroName " os_name.png
      magick -background none -fill white -font "$font_bold" -pointsize 48 label:"$env_version" os_version.png

      # 6. Watermark (Target 1640px)
      # [FIX] Density increased to 8000. 
      # Calculation: (1640px / 16px base) * 72dpi = 7380. Using 8000 ensures crisp edges.
      magick -background none -density 8000 zenos.svg -resize 1640x1640 \
        -channel A -evaluate multiply 0.10 watermark_bg.png

      # 7. Glow (OPTIMIZED - The Speed Fix)
      # Old: 6000x6000px canvas, 1000px blur -> Billions of CPU ops.
      # New: 600x600px canvas, 100px blur -> Instant.
      # We render at 10% scale and resize up. Blurs scale perfectly with no quality loss.
      magick -size 600x600 xc:transparent -fill "#C532FF" \
        -draw "rectangle 250,250 350,350" -blur 0x100 \
        -resize 6000x6000 \
        glow.png
    '';

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/zenos
      cp *.png $out/share/plymouth/themes/zenos/

      cat > $out/share/plymouth/themes/zenos/zenos.plymouth <<EOF
      [Plymouth Theme]
      Name=ZenOS
      Description=ZenOS Boot Animation
      ModuleName=script

      [script]
      ImageDir=$out/share/plymouth/themes/zenos
      ScriptFile=$out/share/plymouth/themes/zenos/zenos.script
      EOF

      # --- ANIMATION SCRIPT (Figma Precise Layout) ---
      cat > $out/share/plymouth/themes/zenos/zenos.script <<'EOF'
      sw = Window.GetWidth();
      sh = Window.GetHeight();
      s = sh / 1200; # Figma Baseline Height

      fun setup_sprite(img_file) {
        img = Image(img_file);
        # Downscale by 0.5 because assets are generated at 2x density
        scaled_img = img.Scale(img.GetWidth() * s * 0.5, img.GetHeight() * s * 0.5);
        return Sprite(scaled_img);
      }

      # 1. Background Watermark
      # Figma: x: -100, y: 604
      bg = setup_sprite("watermark_bg.png");
      bg.SetX(-100 * s); 
      bg.SetY(604 * s); 
      bg.SetZ(-10);

      # 2. Glow
      # Figma: x: 257, y: 1081, w: 500, h: 500.
      # Center = 257 + 250 = 507. Y Center = 1081 + 250 = 1331.
      glow = setup_sprite("glow.png");

      # We calculate position based on the center point to handle the massive canvas padding
      glow_target_center_x = 507 * s;
      glow_target_center_y = 1331 * s;

      glow.SetX(glow_target_center_x - (glow.GetImage().GetWidth() / 2));
      glow.SetY(glow_target_center_y - (glow.GetImage().GetHeight() / 2));
      glow.SetZ(-5);

      # 3. Top Group (Horizontal)
      top_icon = setup_sprite("icon_top.png");
      top_text = setup_sprite("host_text.png");

      gap_top_h = 20 * s;
      top_w = top_icon.GetImage().GetWidth() + gap_top_h + top_text.GetImage().GetWidth();
      top_h = Math.Max(top_icon.GetImage().GetHeight(), top_text.GetImage().GetHeight());

      # 4. Bottom Group (Vertical Stack)
      lbl_powered = setup_sprite("powered_by.png");

      # Bottom Row (Icon + Name + Version)
      btm_icon = setup_sprite("icon_bottom.png");
      os_name = setup_sprite("os_name.png");
      os_ver = setup_sprite("os_version.png");

      gap_btm_v = 8 * s;
      gap_btm_h = 8 * s;

      btm_row_w = btm_icon.GetImage().GetWidth() + gap_btm_h + os_name.GetImage().GetWidth() + os_ver.GetImage().GetWidth();
      btm_row_h = Math.Max(btm_icon.GetImage().GetHeight(), Math.Max(os_name.GetImage().GetHeight(), os_ver.GetImage().GetHeight()));

      # Total Bottom Group Width (Label vs Row)
      btm_group_w = Math.Max(lbl_powered.GetImage().GetWidth(), btm_row_w);
      btm_group_h = lbl_powered.GetImage().GetHeight() + gap_btm_v + btm_row_h;

      # 5. Global Alignment (Center Everything)
      gap_global_v = 8 * s;
      total_w = Math.Max(top_w, btm_group_w);
      total_h = top_h + gap_global_v + btm_group_h;

      start_x = (sw - total_w) / 2;
      start_y = (sh - total_h) / 2;

      # --- PLACEMENT ---

      # Top Row (Centered horizontally within global width)
      top_row_start_x = start_x + (total_w - top_w) / 2;

      top_icon.SetX(top_row_start_x);
      top_icon.SetY(start_y + (top_h - top_icon.GetImage().GetHeight())/2);

      top_text.SetX(top_icon.GetX() + top_icon.GetImage().GetWidth() + gap_top_h);
      top_text.SetY(start_y + (top_h - top_text.GetImage().GetHeight())/2);

      # Bottom Group Start Y
      btm_group_start_y = start_y + top_h + gap_global_v;
      btm_group_start_x = start_x + (total_w - btm_group_w) / 2;

      # Powered By Label (Centered within Bottom Group)
      lbl_powered.SetX(btm_group_start_x + (btm_group_w - lbl_powered.GetImage().GetWidth()) / 2);
      lbl_powered.SetY(btm_group_start_y);

      # Bottom Row (Centered within Bottom Group)
      btm_row_start_x = btm_group_start_x + (btm_group_w - btm_row_w) / 2;
      btm_row_y = btm_group_start_y + lbl_powered.GetImage().GetHeight() + gap_btm_v;

      btm_icon.SetX(btm_row_start_x);
      btm_icon.SetY(btm_row_y + (btm_row_h - btm_icon.GetImage().GetHeight()) / 2);

      os_name.SetX(btm_icon.GetX() + btm_icon.GetImage().GetWidth() + gap_btm_h);
      os_name.SetY(btm_row_y + (btm_row_h - os_name.GetImage().GetHeight()) / 2);

      os_ver.SetX(os_name.GetX() + os_name.GetImage().GetWidth());
      os_ver.SetY(os_name.GetY()); # Same baseline/height logic

      # Animation
      progress = 0;
      fun refresh_callback () {
        progress++;
        glow.SetOpacity(0.6 + (Math.Sin(progress / 70) * 0.3));
      }
      Plymouth.SetRefreshFunction(refresh_callback);
      EOF
    '';
  };

in
{
  environment.systemPackages = [
    zenosIcons
    zenosPlymouth
    pkgs.hicolor-icon-theme
  ];

  fonts.packages = with pkgs; [ atkinson-hyperlegible ];
  fonts.fontconfig.defaultFonts.sansSerif = [ "Atkinson Hyperlegible" ];

  boot.plymouth = {
    enable = true;
    theme = "zenos";
    themePackages = [ zenosPlymouth ];
  };

  environment.etc."issue".text = ''
    \e[1;35mZenOS 1.0N\e[0m (\l)

  '';

  system.nixos = {
    distroName = "ZenOS";
    distroId = "zenos";
    variant_id = "n";
  };

  environment.etc."os-release".text = lib.mkForce ''
    NAME="ZenOS"
    ID=zenos
    ID_LIKE="nixos"
    VERSION="${version}"
    PRETTY_NAME="ZenOS ${version}"
    VERSION_CODENAME="Cacao"
    LOGO=zenos
    HOME_URL="https://nixos.org"
  '';
}
