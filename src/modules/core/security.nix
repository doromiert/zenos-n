# will contain useful security stuff
{ ... }: {
    security = {
        enableFirewall = true;
        firewall = {
            allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
            allowedUDPPorts = [ 53 ]; # DNS
        };
        enableAppArmor = false;
        enableSELinux = false; # Choose based on your needs
        # passwordPolicy = {
        #     minLength = 12;
        #     requireUppercase = true;
        #     requireLowercase = true;
        #     requireNumbers = true;
        #     requireSpecialChars = true;
        # };
        disableRootLogin = true;
    };
}