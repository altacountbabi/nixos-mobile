{
  flake.nixosModules.default =
    { config, lib, ... }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.mobile = {
        rootfs.label = mkOption {
          type = types.str;
          default = "NIXOS_SYSTEM";
          description = "Filesystem label";
        };
      };

      config = {
        fileSystems = {
          "/" = lib.mkDefault {
            device = "/dev/disk/by-label/${config.mobile.rootfs.label}";
            fsType = "ext4";
            autoResize = true;
          };
        };
      };
    };
}
