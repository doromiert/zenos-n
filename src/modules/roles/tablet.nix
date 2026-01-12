{ pkgs, lib, ... }:

{
  # ============================================================================
  #  Tablet Role (Wayland Focused)
  #  Optimizations for touch, stylus, and convertible form factors.
  # ============================================================================

  # [ Hardware: Sensors & Input ]
  hardware.sensor.iio.enable = true; # Auto-rotation

  # [ Software: Touch Suite ]
  environment.systemPackages =
    with pkgs;
    [
      rnote # Vector sketching (Rust/GTK4)
      foliate # Touch-friendly eBook reader
      iio-sensor-proxy # Sensor driver
      wl-clipboard # Needed for wayland scripts
      satty # Screenshot annotation
    ]
    ++ (with pkgs.gnomeExtensions; [
      gjs-osk # Better On-Screen Keyboard
      touchup # Touch tweaks
      screen-rotate # Rotation button
      dash-to-dock # ESSENTIAL for tablets (Persistent dock)
    ]);

  # [ Environment Tweaks ]
  environment.variables = {
    # Force Firefox to use native Wayland (1:1 gestures)
    MOZ_ENABLE_WAYLAND = "1";
    # Electron apps (VS Code, Discord) touch latency fix
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  # [ KITTY: Touch Override ]
  # We use mkForce to overwrite the desktop kitty.conf with this touch version.
  # NOTE: Includes font bumps that pair well with scaling, but defined here
  # to avoid file conflicts in /etc.
  environment.etc."xdg/kitty/kitty.conf".text = lib.mkForce ''
    # --- Touch Optimized Font ---
    # Larger font for legibility in handheld mode
    font_family      Atkynson Mono NF
    font_size        13.5

    # --- Touch UX ---
    touch_scroll_multiplier 5.0
    mouse_hide_wait 3.0

    # Large padding for dragging window with touch
    window_padding_width 12
    hide_window_decorations yes

    # --- Adwaita Dark Colors ---
    background #1e1e1e
    foreground #ffffff
    selection_background #3584e4
    selection_foreground #ffffff
    url_color #3584e4
    cursor #ffffff
    color0 #241f31
    color1 #c01c28
    color2 #2ec27e
    color3 #f5c211
    color4 #1e78e4
    color5 #9841bb
    color6 #0ab9dc
    color7 #c0bfbc
    color8 #5e5c64
    color9 #ed333b
    color10 #57e389
    color11 #f8e45c
    color12 #51a1ff
    color13 #c061cb
    color14 #4fd2fd
    color15 #ffffff

    # --- Animations ---
    cursor_shape beam
    cursor_beam_thickness 2.0
    cursor_blink_interval 0.5
    cursor_trail 3

    # Performance
    repaint_delay 8
    sync_to_monitor yes

    # [DISABLE MIDDLE MOUSE PASTE]
    # Unbind middle click to prevent accidental pastes on touch
    mouse_map middle release ungrabbed no_op
  '';

  # [ DCONF: Tablet Behavior ]
  # Pure behavioral settings, resolution independent.
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        # Dock Behavior (Size is handled in hardware scaling module)
        "org/gnome/shell/extensions/dash-to-dock" = {
          click-action = "minimize-or-previews";
          dock-position = "BOTTOM";
          extend-height = false;
          transparency-mode = "FIXED";
        };

        # On-Screen Keyboard behavior
        "org/gnome/desktop/a11y/applications" = {
          screen-keyboard-enabled = true;
        };
      };
    }
  ];
}
