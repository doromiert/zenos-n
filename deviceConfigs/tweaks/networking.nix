{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zenos.deviceConfigs.tweaks.networking or { enable = false; };
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Load TCP BBR module
    boot.kernelModules = [ "tcp_bbr" ];

    boot.kernel.sysctl = {
      # 1. Congestion Control & Queuing
      # BBR: Model-based congestion control, excellent for high throughput/internet
      "net.ipv4.tcp_congestion_control" = "bbr";
      # CAKE: The gold standard for fighting bufferbloat (latency under load)
      "net.core.default_qdisc" = "cake";

      # 2. Connection Handling (High Load / P2P)
      "net.core.somaxconn" = 8192; # Max backlog for listening sockets
      "net.ipv4.tcp_max_syn_backlog" = 8192; # Max backlog for embryonic connections
      "net.ipv4.tcp_slow_start_after_idle" = 0; # Don't reset window after idle

      # 3. Latency Reductions
      "net.ipv4.tcp_fastopen" = 3; # Enable TCP Fast Open (Listener + Requester)
      "net.ipv4.tcp_mtu_probing" = 1; # Helper for blackhole routers
    };
  };
}
