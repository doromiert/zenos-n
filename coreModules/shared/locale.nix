# @file: coremodules/shared/locale.nix
# @brief: Locale configuration for ZenOS.
# @context: locale configuration
{ locale, lib, ... }:

let
  # Expect locale.kbLayout to be a list, e.g., [ "pl" "ro" "ru" ]
  # Extract the primary layout for the TTY console (only supports one).
  primaryLayout = builtins.head locale.kbLayout;

  # Map X11 layout identifiers to Console keymaps where they differ.
  # [Input (X11)] = "Output (TTY)";
  # Sources: 'man loadkeys', 'localectl list-keymaps' vs 'localectl list-x11-keymap-layouts'
  consoleMap = {
    gb = "uk"; # United Kingdom
    jp = "jp106"; # Japan
    se = "sv-latin1"; # Sweden
    dk = "dk-latin1"; # Denmark
    no = "no-latin1"; # Norway
    pt = "pt-latin1"; # Portugal
    cz = "cz-lat2"; # Czech Republic
    br = "br-abnt2"; # Brazil
    kr = "kr106"; # Korea
    # pl, ro, ru generally map 1:1 to their console equivalents, so defaults work.
  };

  # Determine the console keymap: use the override if it exists, otherwise pass through.
  finalConsoleKeyMap = consoleMap.${primaryLayout} or primaryLayout;
in
{
  time.timeZone = locale.timeZone;

  # Sets the base UI language separately
  i18n.defaultLocale = locale.language;

  # Overrides specific categories with the format locale
  i18n.extraLocaleSettings = {
    LC_ADDRESS = locale.defaultLocale;
    LC_IDENTIFICATION = locale.defaultLocale;
    LC_MEASUREMENT = locale.defaultLocale;
    LC_MONETARY = locale.defaultLocale;
    LC_NAME = locale.defaultLocale;
    LC_NUMERIC = locale.defaultLocale;
    LC_PAPER = locale.defaultLocale;
    LC_TELEPHONE = locale.defaultLocale;
    LC_TIME = locale.defaultLocale;
  };

  # X11/Wayland Configuration
  services.xserver.xkb = {
    # Convert the list ["pl" "ro" "ru"] to "pl,ro,ru" for X11
    layout = lib.concatStringsSep "," locale.kbLayout;

    # Switch layouts using Super+Space (Win+Space)
    options = "grp:win_space_toggle";
  };

  # Console (TTY) Configuration
  # Only supports one active map at boot. Uses the primary (first) layout.
  console.keyMap = finalConsoleKeyMap;
}
