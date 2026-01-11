{ locale, ... }:

let
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
  };

  # Determine the console keymap: use the override if it exists, otherwise pass through.
  finalConsoleKeyMap = consoleMap.${locale.kbLayout} or locale.kbLayout;
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

  # X11/Wayland expects the standard code (e.g. 'gb', 'jp')
  services.xserver.xkb.layout = locale.kbLayout;

  # Console (TTY) expects the specific legacy map (e.g. 'uk', 'jp106')
  console.keyMap = finalConsoleKeyMap;
}
