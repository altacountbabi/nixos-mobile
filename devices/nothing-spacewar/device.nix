{ self, ... }:

{
  flake.nixosModules.default =
    { config, lib, ... }:
    let
      device = config.mobile.devices.nothing-spacewar;
      packages = self.packages.${config.mobile.localSystem};
    in
    {
      config = lib.mkMerge [
        {
          mobile.devices.nothing-spacewar = {
            name = "Nothing Phone 1";

            kernel = packages.nothing-spacewar-kernel;
            firmware = packages.nothing-spacewar-firmware;

            bootimg = {
              flash = {
                offset_base = "0x00000000";
                offset_kernel = "0x00008000";
                offset_ramdisk = "0x01000000";
                offset_tags = "0x00000100";
                pagesize = "4096";
              };
              header_version = 2;
              dtb = "${device.kernel}/dtbs/qcom/sm7325-nothing-spacewar.dtb";
            };

            flashing.steps = lib.mkForce [
              "flash boot boot.img"
              "flash userdata system.img"
              "delete dtbo"
              "delete vendor_boot"
            ];
          };
        }

        (lib.mkIf device.enable {
          boot.kernelParams = lib.mkAfter [ "console=ttyMSM0,115200n8" ];
        })
      ];
    };
}
