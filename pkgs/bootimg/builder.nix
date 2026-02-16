{
  perSystem =
    { pkgs, lib, ... }:
    {
      lib.bootimg =
        {
          name,
          kernel,
          initrd,
          cmdline,
          bootimg,
        }:
        let
          inherit (lib) optionalString;
          inherit (bootimg) dtb header_version;
        in
        pkgs.runCommand name
          {
            nativeBuildInputs = with pkgs.buildPackages; [
              android-tools
            ];
            inherit kernel;
          }
          ''
            PS4=" $ "
            (
            set -x
            mkbootimg \
              --kernel  $kernel \
              ${optionalString (dtb != null) "--dtb ${dtb}"} \
              --ramdisk ${initrd} \
              --cmdline       "${cmdline}" \
              ${optionalString (header_version != null) "--header_version ${toString header_version}"} \
              --base           ${bootimg.flash.offset_base} \
              --kernel_offset  ${bootimg.flash.offset_kernel} \
              --ramdisk_offset ${bootimg.flash.offset_ramdisk} \
              --tags_offset    ${bootimg.flash.offset_tags} \
              --pagesize       ${bootimg.flash.pagesize} \
              -o $out
            )
          '';
    };
}
