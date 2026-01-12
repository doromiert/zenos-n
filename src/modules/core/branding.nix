{
  config,
  pkgs,
  lib,
  self,
  devicePrettyName ? null,
  ...
}:

let
  # --- Release Configuration ---
  releaseType = "beta";
  commitId = self.shortRev or "dirty";
  baseVersion = "1.0N";

  version = if releaseType == "beta" then "${baseVersion}b (${commitId})" else baseVersion;

  # --- Device Name Logic ---
  # If devicePrettyName is passed from flake (mkHost), use it.
  # Otherwise fallback to the raw hostname.
  # e.g. "Doromi Tul II" vs "doromi-tul-ii"
  finalDeviceName = if devicePrettyName != null then devicePrettyName else config.networking.hostName;

  # --- Config Variables ---
  distroName = config.system.nixos.distroName or "ZenOS";

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
    env_deviceName = finalDeviceName; # [UPDATED] Use the pretty name

    buildPhase = ''
      # --- ASSET GENERATION ---
      font_bold="${pkgs.atkinson-hyperlegible}/share/fonts/opentype/AtkinsonHyperlegible-Bold.otf"
      font_reg="${pkgs.atkinson-hyperlegible}/share/fonts/opentype/AtkinsonHyperlegible-Regular.otf"

      magick -background none -density 1200 logo.svg -resize 120x120 icon_top.png

      # [UPDATED] Use the pretty Device Name for the top text
      magick -background none -fill white -font "$font_bold" -pointsize 72 label:"$env_deviceName" host_text.png

      magick -background none -fill white -font "$font_reg" -pointsize 32 label:"Powered by" powered_by.png
      magick -background none -density 1200 zenos.svg -resize 64x64 icon_bottom.png
      magick -background none -fill white -font "$font_reg" -pointsize 48 label:"$env_distroName " os_name.png
      magick -background none -fill white -font "$font_bold" -pointsize 48 label:"$env_version" os_version.png
      magick -background none -density 8000 zenos.svg -resize 1640x1640 -channel A -evaluate multiply 0.10 watermark_bg.png
      magick -size 600x600 xc:transparent -fill "#C532FF" -draw "rectangle 250,250 350,350" -blur 0x100 -resize 6000x6000 glow.png
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

      cat > $out/share/plymouth/themes/zenos/zenos.script <<'EOF'
      sw = Window.GetWidth(); sh = Window.GetHeight(); s = sh / 1200;
      fun setup_sprite(img_file) { img = Image(img_file); return Sprite(img.Scale(img.GetWidth() * s * 0.5, img.GetHeight() * s * 0.5)); }

      bg = setup_sprite("watermark_bg.png"); bg.SetX(-100 * s); bg.SetY(604 * s); bg.SetZ(-10);

      glow = setup_sprite("glow.png");
      glow.SetX((507 * s) - (glow.GetImage().GetWidth() / 2));
      glow.SetY((1331 * s) - (glow.GetImage().GetHeight() / 2));
      glow.SetZ(-5);

      top_icon = setup_sprite("icon_top.png"); top_text = setup_sprite("host_text.png");
      gap_top_h = 20 * s; top_w = top_icon.GetImage().GetWidth() + gap_top_h + top_text.GetImage().GetWidth();
      top_h = Math.Max(top_icon.GetImage().GetHeight(), top_text.GetImage().GetHeight());

      lbl = setup_sprite("powered_by.png");
      btm_icon = setup_sprite("icon_bottom.png"); os_name = setup_sprite("os_name.png"); os_ver = setup_sprite("os_version.png");
      gap_btm = 8 * s;
      btm_row_w = btm_icon.GetImage().GetWidth() + gap_btm + os_name.GetImage().GetWidth() + os_ver.GetImage().GetWidth();
      btm_group_w = Math.Max(lbl.GetImage().GetWidth(), btm_row_w);
      btm_group_h = lbl.GetImage().GetHeight() + gap_btm + Math.Max(btm_icon.GetImage().GetHeight(), os_name.GetImage().GetHeight());

      total_w = Math.Max(top_w, btm_group_w);
      total_h = top_h + gap_btm + btm_group_h;
      start_x = (sw - total_w) / 2; start_y = (sh - total_h) / 2;

      top_row_x = start_x + (total_w - top_w) / 2;
      top_icon.SetX(top_row_x); top_icon.SetY(start_y + (top_h - top_icon.GetImage().GetHeight())/2);
      top_text.SetX(top_icon.GetX() + top_icon.GetImage().GetWidth() + gap_top_h); top_text.SetY(start_y + (top_h - top_text.GetImage().GetHeight())/2);

      btm_y = start_y + top_h + gap_btm; btm_x = start_x + (total_w - btm_group_w) / 2;
      lbl.SetX(btm_x + (btm_group_w - lbl.GetImage().GetWidth())/2); lbl.SetY(btm_y);

      row_x = btm_x + (btm_group_w - btm_row_w) / 2; row_y = btm_y + lbl.GetImage().GetHeight() + gap_btm;
      btm_icon.SetX(row_x); btm_icon.SetY(row_y);
      os_name.SetX(row_x + btm_icon.GetImage().GetWidth() + gap_btm); os_name.SetY(row_y);
      os_ver.SetX(os_name.GetX() + os_name.GetImage().GetWidth()); os_ver.SetY(row_y);

      progress = 0;
      fun refresh_callback () { progress++; glow.SetOpacity(0.6 + (Math.Sin(progress / 70) * 0.5)); }
      Plymouth.SetRefreshFunction(refresh_callback);
      EOF
    '';
  };

  # --- Fastfetch Config Pkg ---
  zenosFastfetchConfig = pkgs.writeText "config.jsonc" (
    builtins.replaceStrings [ "~/.config/fastfetch/ascii.txt" ] [ "/etc/fastfetch/ascii.txt" ] (
      builtins.readFile ../../../resources/fastfetch/zenos.jsonc
    )
  );

in
{
  environment.systemPackages = [
    zenosIcons
    zenosPlymouth
    pkgs.hicolor-icon-theme
    pkgs.fastfetch
  ];

  # --- Fastfetch Deployment ---
  environment.etc."fastfetch/config.jsonc".source = zenosFastfetchConfig;
  environment.etc."fastfetch/ascii.txt".source = ../../../resources/fastfetch/ascii.txt;
  environment.variables.FASTFETCH_CONFIG = "/etc/fastfetch/config.jsonc";
  environment.shellAliases.neofetch = "fastfetch";

  # --- GNOME Pretty Hostname ---
  # This lets GNOME Settings > About show "Doromi Tul II" instead of "doromi-tul-ii"
  environment.etc."machine-info".text = ''
    PRETTY_HOSTNAME="${finalDeviceName}"
  '';

  fonts.packages = with pkgs; [ atkinson-hyperlegible ];
  fonts.fontconfig.defaultFonts.sansSerif = [ "Atkinson Hyperlegible" ];

  boot.plymouth = {
    enable = true;
    theme = "zenos";
    themePackages = [ zenosPlymouth ];
  };

  environment.etc."issue".text = ''
    \e[1;35mZenOS ${version}\e[0m (\l)

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
