{ lib, pkgs, ... }:

{
  # ============================================================================
  #  ThinkPad L13 Specific Scaling (14" 1080p)
  #  Strategy: Native 125% Monitor Scaling + Wayland Enforcement
  # ============================================================================

  # [1] FORCE NATIVE WAYLAND (The "Blur Fix")
  # XWayland apps blur at 125% because they are bitmap-upscaled.
  # We force these apps to use the Wayland protocol directly for crisp rendering.
  environment.sessionVariables = {
    # Firefox / Mozilla
    MOZ_ENABLE_WAYLAND = "1";

    # Electron Apps (VS Code, Discord, Obsidian, etc.)
    # This hints the NixOS wrappers to use Ozone Wayland backend.
    NIXOS_OZONE_WL = "1";

    # Chromium / Electron Fallback
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # [2] DCONF SETTINGS (Behavior & Dock)
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        # [VISUAL DENSITY]
        "org/gnome/desktop/interface" = {
          # We revert to standard scaling (controlled by GNOME Settings -> Display).
          # We do NOT set text-scaling-factor here, letting the OS manage it.

          # Keep cursor large for touch visibility
          cursor-size = lib.gvariant.mkInt32 32;

          # [DISABLE MIDDLE MOUSE PASTE]
          gtk-enable-primary-paste = false;
        };

        # [DOCK SIZING]
        "org/gnome/shell/extensions/dash-to-dock" = {
          # 64px is still the sweet spot for 14" touch
          dash-max-icon-size = lib.gvariant.mkInt32 64;
          custom-theme-shrink = true;
        };
      };
    }
  ];
}
