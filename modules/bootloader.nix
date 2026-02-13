{
  flake.nixosModules.default = {
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = false;
  };
}
