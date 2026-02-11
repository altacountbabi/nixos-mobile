{
  flake.nixosModules.default =
    { lib, ... }:
    let
      inherit (lib) mkOption mkEnableOption types;
    in
    {
      options.mobile = {
        devices = mkOption {
          type = types.submodule {
            options = {
              enable = mkEnableOption "Enable this device";
              name = mkOption {
                type = types.str;
                description = "Name of the device";
              };

              # Packages
              firmware = mkOption {
                type = types.nullOr types.package;
                default = null;
                description = "Firmware package for the device";
              };
              enableFirmware = mkOption {
                type = types.bool;
                default = true;
                description = "Automatically add the firmware to the system configuration";
              };

              kernel = mkOption {
                type = types.nullOr types.package;
                default = null;
                description = "Linux kernel package for the device";
              };
            };
          };
          default = { };
          description = "List of mobile devices that can be enabled";
        };
      };
    };
}
