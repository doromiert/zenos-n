{ pkgs, ... }:

{
  # ============================================================================
  #  Tablet Role (Wayland Focused)
  #  Optimizations for touch, stylus, and convertible form factors.
  # ============================================================================

  # [ Hardware: Sensors & Input ]
  # Essential for auto-rotation (accelerometer/gyroscope)
  # GNOME on Wayland reads this directly for screen rotation.
  hardware.sensor.iio.enable = true;

  # Essential for Wacom stylus kernel drivers.
  # Note: 'xsetwacom' command won't work on Wayland; map buttons via GNOME Settings.
  # services.xserver.wacom.enable = true;

  # [ Software: Touch & Handwriting Suite ]
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
    ]);

  # [ Environment Tweaks ]
  environment.variables = {
    # Force Firefox to use native Wayland
    # This enables 1:1 touchpad/touchscreen gestures (pinch-zoom, scroll)
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";

    # Hint Electron apps (VS Code, Discord, etc.) to use Wayland ozone backend
    # Reduces latency and improves touch input
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
