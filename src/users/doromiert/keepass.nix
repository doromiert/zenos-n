{ config, ... }:

{

  # 1. Configure KeePassXC Settings via INI
  xdg.configFile."keepassxc/keepassxc.ini".text = ''
    [General]
    ConfigVersion=2
    # Ensure the UI defaults to this database
    LastDatabases=${config.home.homeDirectory}/Passwords/safe.kdbx
    LastOpenDatabases=${config.home.homeDirectory}/Passwords/safe.kdbx
    LastDir=${config.home.homeDirectory}/Passwords

    # Automatically open the database defined above on startup
    OpenPreviousDatabasesOnStartup=true
    MinimizeToTray=true

    [Browser]
    Enabled=true
    Firefox=true
    # Ensure distinct PWA instances don't prompt purely on focus changes
    SearchInAllDatabases=true
  '';

}
