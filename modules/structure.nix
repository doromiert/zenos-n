{
  lib,
  config,
  pkgs,
  ...
}:
let
  types = lib.types;
  cfg = config.zenos;
in
{
  options.zenos = {
    # --- 1. Identity & Branding ---
    deviceIcon = lib.mkOption {
      type = types.str;
      default = "negzero";
      description = "Icon name for branding";
    };

    prettyName = lib.mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "Fancy device name";
    };

    isServer = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Whether this machine is a headless server";
    };

    # --- 2. User Management ---
    users = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of users to create";
    };

    admin = lib.mkOption {
      type = types.str;
      description = "Primary admin user (gets wheel access)";
    };

    # --- 3. Locale & System Settings ---
    locale = {
      timeZone = lib.mkOption {
        type = types.str;
        default = "UTC";
      };
      language = lib.mkOption {
        type = types.str;
        default = "en_US.UTF-8";
      };
      defaultLocale = lib.mkOption {
        type = types.str;
        default = "en_US.UTF-8";
      };
      kbLayout = lib.mkOption {
        type = types.str;
        default = "us";
      };
    };

    # --- 4. File System Stub (ZenFS) ---
    zenfs = {
      rootUUID = lib.mkOption {
        type = types.str;
        default = "";
      };
      bootUUID = lib.mkOption {
        type = types.str;
        default = "";
      };
    };

    # --- 5. Dynamic Modules ---
    modules = lib.mkOption {
      description = "Dynamic module imports by category";
      default = { };
      type = types.attrsOf (types.either (types.listOf types.str) (types.enum [ "*" ]));
    };

    deviceConfigs = lib.mkOption {
      description = "Device specific hardware configurations";
      type = types.attrsOf types.anything;
      default = { };
    };

    # --- 6. Core Module Exclusions ---
    excludedCoreModules = lib.mkOption {
      description = "List of core modules to disable by category";
      type = types.attrsOf (types.listOf types.str);
      default = { };
    };
  };

  config = {
    # Map Branding
    zenos.branding.prettyName = cfg.prettyName;
    zenos.branding.icon = cfg.deviceIcon;

    # Map Locale
    time.timeZone = cfg.locale.timeZone;
    i18n.defaultLocale = cfg.locale.defaultLocale;
    services.xserver.xkb.layout = cfg.locale.kbLayout;
    console.keyMap = cfg.locale.kbLayout;

    # Map Users
    users.users = lib.genAttrs cfg.users (name: {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "video"
        "audio"
      ]
      ++ (lib.optional (name == cfg.admin) "wheel");
      shell = pkgs.fish;
    });

    # Map Disabled Modules
    disabledModules = lib.flatten (
      lib.mapAttrsToList (
        category: modules: map (name: "coremodules/${category}/${name}.nix") modules
      ) cfg.excludedCoreModules
    );
  };
}
