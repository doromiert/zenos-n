# will contain the -0 ZenOS N branding
{ ... }: {
    system.nixos.variant_id = "N";
    system.nixos.variantName = "NixOS-based version";
    system.nixos.codeName = "Cacao";
    system.nixos.label = "zenOS";

    environment.etc."os-release".text = ''
        NAME="ZenOS N"
        VERSION="1.0"
        ID=ZenOS
        ID_LIKE=nixos
        PRETTY_NAME="ZenOS 1.0N"
        VERSION_CODENAME=ZenOS
        HOME_URL="https://nixos.org"
    '';
}