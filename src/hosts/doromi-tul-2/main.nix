# kitchen sink for doromi-tul-2
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
libfreenect2 = pkgs.stdenv.mkDerivation rec {
    pname = "libfreenect2";
    version = "0.2.0";

    src = pkgs.fetchFromGitHub {
      owner = "OpenKinect";
      repo = "libfreenect2";
      rev = "v${version}";
      hash = "sha256-5JjZANfkkgK8YRXrdfOCXOBMXxW+UNv6JiNfEDUQscc=";
    };

    nativeBuildInputs = with pkgs; [
      cmake
      libusb1
      pkg-config
    ];

    buildInputs = with pkgs; [
      pkg-config
      libusb1
      libusb1
      glfw3
      libjpeg_turbo
      libGL
      libGLU
      opencl-headers
      ocl-icd
    ];

    cmakeFlags = [
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.10"
      "-DBUILD_EXAMPLES=ON"
      "-DENABLE_OPENGL=ON"
      "-DENABLE_OPENCL=OFF"
      "-DENABLE_CUDA=OFF"
    ];

    postInstall = ''
      mkdir -p $out/lib/udev/rules.d
      cp ../platform/linux/udev/90-kinect2.rules $out/lib/udev/rules.d/90-kinect2.rules
    '';
  };
ryubing-canary = pkgs.appimageTools.wrapType2 {
    pname = "ryubing-canary";
    version = "1.3.274";
    src = pkgs.fetchurl {
      url = "https://git.ryujinx.app/Ryubing/Canary/releases/download/1.3.274/ryujinx-canary-1.3.274-x64.AppImage";
      hash = "sha256-bCmqYv2tCnF9oVlnTulArfcPm2yrZntWMjJcz1pe96U=";
    };
    extraPkgs = pkgs: [
      pkgs.libx11
      pkgs.vulkan-loader
      pkgs.openal
      pkgs.icu
    ];
  };
in
{
  systemd.services.plymouth-quit-wait.enable = lib.mkForce false;

  # [3] Bonus: Kill Network Wait (2.4s saved)
  # Your blame logs showed this was also a major blocker.
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.ModemManager.enable = lib.mkForce false;
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  environment.systemPackages = [
    pkgs.solaar
    libfreenect2
    inputs.zenpkgs.packages."x86_64-linux".themes.wallpapers.destination-2

    ryubing-canary
  ];

  services.udev.extraRules = ''
    ACTION=="remove", GOTO="solaar_end"
    SUBSYSTEM!="hidraw", GOTO="solaar_end"
    ATTRS{idVendor}=="046d", GOTO="solaar_apply"
    KERNELS=="0005:046D:*", GOTO="solaar_apply"
    GOTO="solaar_end"
    LABEL="solaar_apply"
    TAG+="uaccess"
    LABEL="solaar_end"
      # Xbox NUI Sensor (Kinect v2)
      SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02c4", MODE="0666", GROUP="video"
      SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02d8", MODE="0666", GROUP="video"
      SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02d9", MODE="0666", GROUP="video"
    '';

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_HL-1210W";
        deviceUri = "usb://Brother/HL-1210W%20series?serial=E76028K2N488127";
        model = "drv:///brlaser.drv/br1210.ppd";
        location = "USB";
      }
    ];
    ensureDefaultPrinter = "Brother_HL-1210W";
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      brlaser
      gutenprint
    ];
  };

  # in your configuration.nix or relevant module
  hardware.logitech.wireless.enable = true;


  # services.logiops = {
  #   enable = true;
  #   config = {
  #     devices = [
  #       {
  #         name = "MX Master 4";
  #         dpi = 1500;
  #         buttons = [
  #           # {
  #           #   # haptic button CID — 0x0109 from your screenshot
  #           #   cid = (fromTOML "hex = 0x0109").hex;
  #           #   action = {
  #           #     type = "CycleDPI";
  #           #     dpis = [ 400 1500 ];  # toggles on press, not hold — see note below
  #           #   };
  #           # }
  #           {
  #             # gesture button, typically 0xc3
  #             cid = (fromTOML "hex = 0xC3").hex;
  #             action = {
  #               type = "Gestures";
  #               gestures = [
  #                 {
  #                   direction = "Up";
  #                   mode = "OnRelease";
  #                   action = { type = "Keypress"; keys = [ "KEY_LEFTMETA" ]; };
  #                 }
  #                 {
  #                   direction = "Down";
  #                   mode = "OnRelease";
  #                   action = { type = "Keypress"; keys = [ "KEY_LEFTMETA" ]; };
  #                 }
  #                 {
  #                   direction = "Left";
  #                   mode = "OnRelease";
  #                   action = { type = "Keypress"; keys = [ "KEY_LEFTCTRL" "KEY_LEFTALT" "KEY_RIGHT" ]; };
  #                 }
  #                 {
  #                   direction = "Right";
  #                   mode = "OnRelease";
  #                   action = { type = "Keypress"; keys = [ "KEY_LEFTCTRL" "KEY_LEFTALT" "KEY_LEFT" ]; };
  #                 }
  #                 {
  #                   direction = "None";
  #                   mode = "OnRelease";
  #                   action = { type = "Keypress"; keys = [ "KEY_LEFTMETA" ]; };
  #                 }
  #               ];
  #             };
  #           }
  #         ];
  #       }
  #     ];
  #   };
  # };

  services.masterfulGestures = {
    enable = true;
    trigger = "BTN_FORWARD";
    mouse = "/dev/input/by-id/usb-Logitech_USB_Receiver-if01-event-mouse";
    user = "doromiert";
  };
}
