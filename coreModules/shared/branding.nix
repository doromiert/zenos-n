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

  # Helper to read fastfetch config
  zenosFastfetchConfig = pkgs.writeText "config.jsonc" (
    builtins.replaceStrings [ "~/.config/fastfetch/ascii.txt" ] [ "/etc/fastfetch/ascii.txt" ] (
      builtins.readFile "${resourcesPath}/fastfetch/zenos.jsonc"
    )
  );

in
{
  meta = {
    description = "Configures system branding, icons, and identification";
    longDescription = ''
      This module manages the visual identity of the system, including:
      - System icons (via `zenos-icons`)
      - Hostname prettification (`machine-info`)
      - Version strings (`/etc/issue`)
      - Fastfetch configuration

      It acts as the central source of truth for branding assets used by other modules (like ZenBoot).
    '';
    maintainers = with lib.maintainers; [ doromiert ];
    license = lib.licenses.napl;
    platforms = lib.platforms.zenos;
  };

  # Define options to replace the old function arguments
  options.zenos.branding = {
    prettyName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The fancy name of the device";
      example = "doromi tul 2";
    };
    icon = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The icon name to use for the device";
    };
  };

  config = {
    environment.systemPackages = [
      pkgs.zenos.icons
      pkgs.fastfetch
    ];

    # --- GNOME Pretty Hostname ---
    environment.etc."machine-info".text = ''
      PRETTY_HOSTNAME="${finalDeviceName}"
    '';

    fonts.packages = with pkgs; [ atkinson-hyperlegible ];
    fonts.fontconfig.defaultFonts.sansSerif = [ "Atkinson Hyperlegible" ];

    # --- System Version ---
    environment.etc."issue".text = ''
      \e[1;35mZenOS ${finalVersionString}\e[0m (\l)
    '';

    system.nixos.label = finalVersionString;
  };
}
