{ self, ... }:

{
  flake.nixosModules.default =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      packages = self.packages.${config.mobile.localSystem};
      inherit (config.mobile) device crossPkgs;
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
              dtb = "${config.system.build.kernel}/dtbs/qcom/sm7325-nothing-spacewar.dtb";
            };

            flashing.steps = lib.mkForce [
              "flash boot_a boot.img"
              "flash userdata system.img"
              "erase dtbo"
              "erase vendor_boot"
              "reboot"
            ];
          };
        }

        (lib.mkIf device.enable {
          boot.kernelParams = lib.mkAfter [
            "console=ttyMSM0,115200n8"
            "console=tty0"
            "firmware_class.path=/firmware"
          ];

          boot.initrd.systemd.contents = {
            # TODO: Figure out why battery won't show up in /sys/class/power_supply
            # Copy gpu firmware from linux-firmware for the Adreno 642L
            "/firmware".source = crossPkgs.runCommand "initrd-firmware" { } ''
              mkdir -p $out/qcom/sm7325/nothing/spacewar
              cp -vf ${device.firmware}/lib/firmware/qcom/sm7325/nothing/spacewar/{a660_zap.mbn,adsp.mbn} $out/qcom/sm7325/nothing/spacewar
              cp -vf ${pkgs.linux-firmware}/lib/firmware/qcom/{a660_sqe.fw,a660_gmu.bin} $out/qcom
            '';
          };
        })
      ];
    };
}
