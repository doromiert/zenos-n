{ pkgs, lib, ... }:

{
  # [P13.9] System-Wide Network Optimization
  # Applies the installer's speed tweaks to the permanent system.

  networking = {
    # 1. DNS Turbo (Cloudflare / Google)
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    
    # 2. TCP Optimization (BBR Congestion Control)
    # BBR (Bottleneck Bandwidth and Round-trip propagation time) is significantly 
    # faster/smoother on modern networks than the default Cubic.
  };

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    
    # Increase TCP window sizes for high-bandwidth WAN connections
    "net.core.wmem_max" = 1073741824; # 1GB
    "net.core.rmem_max" = 1073741824;
    "net.ipv4.tcp_rmem" = "4096 87380 1073741824";
    "net.ipv4.tcp_wmem" = "4096 87380 1073741824";
  };
}
