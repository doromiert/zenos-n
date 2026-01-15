{ ... }:

{
  services.flatpak = {
    enable = true;

    # Add Flathub (or other remotes) managed declaratively
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
      # {
      #     name = "flathub-beta";
      #     location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      # }
    ];

    # Optional: Auto-update logic (systemd timer)
    update.auto = {
      enable = true;
      onCalendar = "weekly"; # Default is daily
    };

    # Optional: Uninstall Flatpaks not in this list (Strict declarative mode)
    uninstallUnmanaged = true;
  };
}
