{
  self,
  ...
}:

{
  flake.nixosModules.default =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (config.mobile) device localSystem crossPkgs;
    in
    {
      system.build.fastboot-boot-image =
        let
          cmdline = config.boot.kernelParams |> lib.concatStringsSep " ";
          inherit (config.specialisation.stage0.configuration.system.build) kernel initialRamdisk;
        in
        self.lib.${localSystem}.bootimg {
          name = "fastboot-boot-image-${device.id}";
          kernel = "${kernel}/${pkgs.stdenv.hostPlatform.linux-kernel.target}";
          initrd = "${initialRamdisk}/initrd";

          inherit cmdline;
          inherit (device) bootimg;
        };

      system.build.fastboot-system-image =
        let
          make-ext4-fs = crossPkgs.callPackage "${pkgs.path}/nixos/lib/make-ext4-fs.nix";
        in
        (make-ext4-fs {
          storePaths = [ config.system.build.toplevel ];
          volumeLabel = "NIXOS_SYSTEM";
        }).overrideAttrs
          {
            name = "fastboot-system-image-${device.id}";
          };

      # Bundled images with flash script
      system.build.fastboot-images =
        let
          flash-script =
            crossPkgs.writeShellApplication {
              name = "flash";
              runtimeInputs = with pkgs; [
                android-tools
              ];
              text =
                let
                  inherit (device.flashing) steps;
                in
                # bash
                ''
                  dir="$(cd "$(dirname "''${BASH_SOURCE[0]}")"; echo "$PWD")"
                  PS4=" $ "

                  echo "Flashing boot and userdata partitions."
                  (
                  set -x
                  cd "$dir"
                  ${steps |> map (x: "fastboot ${x}") |> lib.concatStringsSep "\n"}
                  )
                  echo "Flashing completed."
                '';
            }
            |> lib.getExe;
        in
        pkgs.linkFarm "fastboot-images-${device.id}" [
          {
            name = "boot.img";
            path = config.system.build.fastboot-boot-image;
          }
          {
            name = "system.img";
            path = config.system.build.fastboot-system-image;
          }
          {
            name = "flash.sh";
            path = flash-script;
          }
        ];
    };
}
