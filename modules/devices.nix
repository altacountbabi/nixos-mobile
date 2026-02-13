{
  flake.nixosModules.default =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption mkEnableOption types;
    in
    {
      options.mobile = {
        devices = mkOption {
          type = types.attrsOf (
            types.submodule {
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

                bootimg = {
                  flash =
                    let
                      opt =
                        description:
                        mkOption {
                          type = types.str;
                          inherit description;
                        };
                    in
                    {
                      offset_base = opt "Base offset for the boot image";
                      offset_kernel = opt "Kernel offset in the boot image";
                      offset_ramdisk = opt "Ramdisk offset in the boot image";
                      offset_tags = opt "Tags offset in the boot image";
                      pagesize = opt "Page size for the boot image";
                    };

                  header_version = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Boot image header version";
                  };

                  dtb = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "Device tree blob for the device";
                  };
                };

                flashing.steps = mkOption {
                  type = with types; listOf str;
                  default = [ ];
                  description = "Sequential steps to take with fastboot";
                };
              };
            }
          );
          default = { };
          description = "List of supported mobile devices";
        };
      };

      config =
        let
          devices =
            config.mobile.devices
            |> lib.filterAttrs (_: v: v.enable)
            |> lib.mapAttrsToList (k: v: { id = k; } // v);
          device = lib.head devices;
        in
        {
          assertions = [
            {
              assertion =
                let
                  enabledDevices = devices |> lib.filter (x: x.enable);
                in
                (lib.length enabledDevices) <= 1;
              message = "More than one device enabled";
            }
          ];

          hardware.firmware = lib.mkIf device.enableFirmware [
            device.firmware
          ];

          boot.kernelPackages = pkgs.linuxPackagesFor device.kernel;
        };
    };
}
