# @file: coremodules/shared/security.nix
# @brief: Security configuration for ZenOS.
# @context: security configuration

{ ... }:
{
  networking = {

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
      allowedUDPPorts = [
        53
        5002
        5001
        5000
        3478
        3479
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
        {
          from = 49152;
          to = 65535;
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
