{ locale, ... }: # Consumes 'locale' from specialArgs

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

  services.xserver.xkb.layout = locale.kbLayout;
  console.keyMap = locale.kbLayout;
}
