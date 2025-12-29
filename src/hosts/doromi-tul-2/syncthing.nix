# doromi-tul-2-specific syncthing settings
{
    services.syncthing = {
        dataDir = "/home/doromiert/.local/share/syncthing";
        configDir = "/home/doromiert/.config/syncthing";
        
        folders = {
            # 1. Books
            "books" = {
                id = "6dovv-1tpo9";
                path = "/home/doromiert/Documents/books";
                devices = [ "doromi-tul-2" "doromipad" ];
                versioning = { type = "staggered"; params = { cleanInterval = "3600"; maxAge = "15552000"; }; };
            };
            
            # 2. Obsidian (Rondomix)
            "obsidian-rondomix" = {
                id = "75ycc-ar6pj";
                path = "/home/doromiert/Documents/rondomix";
                devices = [ "doromi-tul-2" "doromipad" ];
                versioning = { type = "simple"; params = { keep = "10"; }; };
            };

            # 3. Obsidian (-0)
            "obsidian-negative-zero" = {
                id = "Negative Zero";
                path = "/mnt/data/backups/obsidian/-0";
                devices = [ "doromi-tul-2" "doromipad" "np2" "quest" ];
                versioning = { type = "simple"; params = { keep = "10"; }; };
            };

            # 4. Obsidian (School)
            "obsidian-school" = {
                id = "o2qk0-vgpjz";
                path = "/mnt/data/backups/obsidian/school";
                devices = [ "doromi-tul-2" "doromipad" "np2" "quest" ];
                versioning = { type = "simple"; params = { keep = "10"; }; };
            };

            # 5. Obsidian (Ixni)
            "obsidian-ixni" = {
                id = "dlebo-khhal";
                path = "/mnt/data/backups/obsidian/ixni";
                devices = [ "doromi-tul-2" "doromipad" "np2" "quest" ];
                versioning = { type = "simple"; params = { keep = "10"; }; };
            };

            # 6. Passwords (KeePass)
            "passwords" = {
                id = "passwords";
                path = "/mnt/data/backups/Passwords";
                devices = [ "doromi-tul-2" "doromipad" "np2" "quest" ];
                versioning = { type = "simple"; params = { keep = "5"; }; };
            };

            # 7. Music (Receive Only from Main PC)
            "Music" = {
                id = "Music";
                path = "/mnt/data/media/Music";
                devices = [ "doromi-tul-2" "doromipad" "np2" "quest" ]; 
                type = "receiveonly";
            };
        };
    };
}