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
          boot.initrd.kernelModules = [
            "ufs_qcom"
          ];

          boot.kernelParams = lib.mkAfter [
            "console=ttyMSM0,115200n8"
            "console=tty0"
          ];

          hardware.firmware = [
            (crossPkgs.runCommand "initrd-firmware" { } ''
              cp -vrf ${config.mobile.device.firmware} $out
              chmod -R +w $out

              # Big file, fills and breaks stage-1
              find $out/lib/firmware/qcom/sm7325/ -name "modem.mbn" -type f -delete

              # Copy extra a660 firmware from linux-firmware for the Adreno 642L? see PMOS
              cp -vf ${pkgs.linux-firmware}/lib/firmware/qcom/{a660_sqe.fw,a660_gmu.bin} $out/lib/firmware/qcom

              # Copy extra ath11k firmware from linux-firmware, see PMOS
              cp -vrf ${pkgs.linux-firmware}/lib/firmware/ath11k $out/lib/firmware/ath11k

              # Copy extra qca firmware from linux-firmware, see PMOS
              cp -vrf ${pkgs.linux-firmware}/lib/firmware/qca $out/lib/firmware/qca
            '')
          ];
        })
      ];
    };
}
