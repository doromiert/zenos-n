{ config, pkgs, ... }:

{
  xdg.configFile."autostart/org.keepassxc.KeePassXC.desktop".source =
    "${pkgs.keepassxc}/share/applications/org.keepassxc.KeePassXC.desktop";

  # 1. Configure KeePassXC Settings via INI
  xdg.configFile."keepassxc/keepassxc.ini".text = ''
    [General]
    ConfigVersion=2
    # Ensure the UI defaults to this database
    LastDatabases=${config.home.homeDirectory}/Passwords/Safe.kdbx
    LastOpenDatabases=${config.home.homeDirectory}/Passwords/Safe.kdbx
    LastDir=${config.home.homeDirectory}/Passwords
    MinimizeAfterUnlock=true

    [GUI]
    ApplicationTheme=classic
    MinimizeOnStartup=true
    TrayIconAppearance=monochrome-light
    OpenPreviousDatabasesOnStartup=true
    MinimizeToTray=true

    [Browser]
    Enabled=true
    Firefox=true
    # Ensure distinct PWA instances don't prompt purely on focus changes
    SearchInAllDatabases=true
    AlwaysAllowAccess=true
    CustomProxyLocation=
    Enabled=true

    [PasswordGenerator]
    AdditionalChars=
    ExcludedChars=
    Length=60

    [Security]
    LockDatabaseIdle=false
  '';

  home.packages = with pkgs; [
    keepassxc
  ];
}
