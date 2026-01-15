{
  config,
  pkgs,
  lib,
  self,
  version,
  ...
}:

let
  # --- Version Logic ---
  inherit (version) type majorVer variant;
  baseVersion = "${majorVer}${variant}";

  # Commit ID Logic
  commitId = if (self ? shortRev) then self.shortRev else "${self.dirtyShortRev or "unknown"}";

  # Construct the final string
  finalVersionString = if type == "beta" then "${baseVersion}b (${commitId})" else baseVersion;

  # --- Config Access ---
  cfg = config.zenos.branding;

  # Resolve the icon (defaulting to negzero if not set)
  icon = if cfg.icon != null then cfg.icon else "negzero";

  # Resolve the pretty name
  finalDeviceName = if cfg.prettyName != null then cfg.prettyName else config.networking.hostName;

  # --- Resource Paths ---
  # Note: Adjusted path depth to match coremodules/shared/branding.nix (2 levels deep)
  resourcesPath = ../../../resources;

  # --- [1] The Icon Theme ---
  zenosIcons = pkgs.runCommand "zenos-icon-theme" { } ''
    mkdir -p $out/share/icons
    cp -r ${resourcesPath}/hicolor $out/share/icons/hicolor
  '';

  # --- [2] The Plymouth Theme (Restored) ---
  zenosPlymouth = pkgs.runCommand "plymouth-theme-zenos" { } ''
    mkdir -p $out/share/plymouth/themes/zenos
    cp -r ${resourcesPath}/plymouth/zenos/* $out/share/plymouth/themes/zenos

    # If a custom icon is set and exists, overwrite the logo
    if [ "${icon}" != "negzero" ]; then
       if [ -e ${resourcesPath}/hicolor/256x256/apps/${icon}.png ]; then
         cp -f ${resourcesPath}/hicolor/256x256/apps/${icon}.png $out/share/plymouth/themes/zenos/logo.png
       fi
    fi
  '';

  # Helper to read fastfetch config
  zenosFastfetchConfig = pkgs.writeText "config.jsonc" (
    builtins.replaceStrings [ "~/.config/fastfetch/ascii.txt" ] [ "/etc/fastfetch/ascii.txt" ] (
      builtins.readFile "${resourcesPath}/fastfetch/zenos.jsonc"
    )
  );

in
{
  # Define options to replace the old function arguments
  options.zenos.branding = {
    prettyName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The fancy name of the device (e.g. 'Doromi Tul II')";
    };
    icon = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The icon name to use for the device";
    };
  };

  config = {
    environment.systemPackages = [
      zenosIcons
      zenosPlymouth
      pkgs.hicolor-icon-theme
      pkgs.fastfetch
    ];

    # --- Fastfetch Deployment ---
    environment.etc."fastfetch/config.jsonc".source = zenosFastfetchConfig;
    environment.etc."fastfetch/ascii.txt".source = "${resourcesPath}/fastfetch/ascii.txt";
    environment.variables.FASTFETCH_CONFIG = "/etc/fastfetch/config.jsonc";
    environment.shellAliases.neofetch = "fastfetch";

    # --- GNOME Pretty Hostname ---
    environment.etc."machine-info".text = ''
      PRETTY_HOSTNAME="${finalDeviceName}"
    '';

    fonts.packages = with pkgs; [ atkinson-hyperlegible ];
    fonts.fontconfig.defaultFonts.sansSerif = [ "Atkinson Hyperlegible" ];

    # --- Plymouth Config (Restored) ---
    boot.plymouth = {
      enable = true;
      theme = "zenos";
      themePackages = [ zenosPlymouth ];
    };

    # --- System Version ---
    environment.etc."issue".text = ''
      \e[1;35mZenOS ${finalVersionString}\e[0m (\l)

    '';

    system.nixos.label = finalVersionString;
  };
}
