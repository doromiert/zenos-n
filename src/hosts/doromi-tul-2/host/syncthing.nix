# doromi-tul-2-specific syncthing settings
{
    services.syncthing = {
        dataDir = "/home/doromiert/.local/share/syncthing";
        configDir = "/home/doromiert/.config/syncthing";
        
        folders = {
            "placeholder" = {
                path = "";
                devices = [ ];
                ignorePerms = false;
            };
        };
    };
}