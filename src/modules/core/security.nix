# will contain useful security stuff
{ ... }:
{
  networking = {

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ]; # SSH, HTTP, HTTPS
      allowedUDPPorts = [ 53 ]; # DNS
    };
  };
  security = {
    # passwordPolicy = {
    #     minLength = 12;
    #     requireUppercase = true;
    #     requireLowercase = true;
    #     requireNumbers = true;
    #     requireSpecialChars = true;
    # };
    rtkit.enable = true;
  };
}
