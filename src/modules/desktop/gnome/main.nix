{ pkgs, lib, ... }:

let
  # [HIJACK] Fake gnome-terminal wrapper
  fake-gnome-terminal = pkgs.writeShellScriptBin "gnome-terminal" ''
    exec ${pkgs.kitty}/bin/kitty "$@"
  '';

  # Define custom Forge extension
  forge-custom = pkgs.stdenv.mkDerivation rec {
    pname = "gnome-shell-extension-forge";
    version = "custom";
    src = ../../../../resources/forge; # Adjust path as needed
    dontBuild = true;
    installPhase = ''
      export UUID="forge@jmmaranan.com"
      dest="$out/share/gnome-shell/extensions/$UUID"
      mkdir -p "$dest"
      cp -a . "$dest/"
      if [ -d "$dest/schemas" ]; then
        ${pkgs.glib.dev}/bin/glib-compile-schemas "$dest/schemas"
      fi
    '';
    passthru.extensionUuid = "forge@jmmaranan.com";
  };

  extensions = [
    forge-custom
  ]
  ++ (with pkgs.gnomeExtensions; [
    app-hider
    undecorate
    hide-minimized
    hide-cursor
    burn-my-windows
    compiz-windows-effect
    compiz-alike-magic-lamp-effect
    rounded-window-corners-reborn
    blur-my-shell
    alphabetical-app-grid
    category-sorted-app-grid
    coverflow-alt-tab
    hide-top-bar
    mouse-tail
    window-is-ready-remover
    gsconnect
    clipboard-indicator
    notification-timeout
  ]);
in
{
  imports = [ ./styling.nix ];

  # [FIX] Portal Configuration
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "gnome"
      "gtk"
    ];
  };

  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.udev.packages = with pkgs; [ gnome-settings-daemon ];

  # [KITTY BASE] Desktop-Default Config
  # (Will be overwritten by tablet.nix if imported)
  environment.etc."xdg/kitty/kitty.conf".text = lib.mkDefault ''
    font_family      Atkynson Mono NF
    font_size        11.0
    background #1e1e1e
    foreground #ffffff
    # ... (rest of standard config)
    cursor_shape beam
    window_padding_width 5
    hide_window_decorations yes
  '';

  environment.systemPackages =
    with pkgs;
    [
      gnome-tweaks
      kitty
      fake-gnome-terminal
      nautilus-open-any-terminal
      gnome-extension-manager
      wl-clipboard
      dconf-editor
      # ... (Your standard app list)
      biblioteca
      dialect
      decoder
      raider
      wike
      curtail
      czkawka
      hieroglyphic
      warehouse
      switcheroo
      letterpress
      resources
      icon-library
      pika-backup
      helvum
      commit
    ]
    ++ extensions;

  environment.gnome.excludePackages = (
    with pkgs;
    [
      gnome-photos
      gnome-tour
      gedit
      cheese
      gnome-music
      gnome-maps
      epiphany
      gnome-contacts
      gnome-weather
      gnome-console
    ]
  );

  services.flatpak.packages = [ "com.github.tchx84.Flatseal" ];

  # [DCONF BASE]
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            enable-hot-corners = false;
          };
          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = map (ext: ext.extensionUuid) extensions;
            favorite-apps = [
              "firefox.desktop"
              "org.gnome.Nautilus.desktop"
              "kitty.desktop"
            ];
          };
          "com/github/stunkymonkey/nautilus-open-any-terminal" = {
            terminal = "kitty";
            keybindings = "<Super>t";
            new-tab = true;
          };
          "org/gnome/mutter" = {
            edge-tiling = false;
            center-new-windows = true;
            experimental-features = [
              "scale-monitor-framebuffer"
              "xwayland-native-scaling"
            ];
          };
        };
      }
    ];
  };
}
