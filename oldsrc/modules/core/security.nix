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
      allowedUDPPorts = [
        53
        5002
        5001
        5000
      ];
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
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
