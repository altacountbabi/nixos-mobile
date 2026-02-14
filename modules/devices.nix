{
  flake.nixosModules.default =
    { config, lib, ... }:
    let
      inherit (lib) mkOption mkEnableOption types;
      deviceType = types.submodule {
        options = {
          enable = mkEnableOption "Enable this device";
          id = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Used in `config.mobile.device`, set to the key in the `config.mobile.devices` attrset";
            internal = true;
          };
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
      };
    in
    {
      options.mobile = {
        devices = mkOption {
          type = types.attrsOf deviceType;
          default = { };
          description = "List of supported mobile devices";
        };
        device = mkOption {
          type = deviceType;
          default =
            config.mobile.devices
            |> lib.filterAttrs (_: v: v.enable)
            |> lib.mapAttrsToList (k: v: v // { id = k; })
            |> lib.head;
          description = "Currently enabled device";
          internal = true;
        };
      };

      config =
        let
          devices =
            config.mobile.devices
            |> lib.filterAttrs (_: v: v.enable)
            |> lib.mapAttrsToList (k: v: { id = k; } // v);
          inherit (config.mobile) device;
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

          hardware.enableRedistributableFirmware = true;

          boot.initrd.systemd.enable = true;
        };
    };
}
