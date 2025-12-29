# doromi-server-specific syncthing settings
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