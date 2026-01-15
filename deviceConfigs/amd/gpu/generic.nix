{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.amd.gpu.generic or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Load AMDGPU driver
    services.xserver.videoDrivers = [ "amdgpu" ];
    boot.initrd.kernelModules = [ "amdgpu" ];

    # Enable OpenGL/Vulkan
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
