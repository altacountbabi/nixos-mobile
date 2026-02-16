{
  flake.nixosModules.default =
    {
      config,
      pkgs,
      ...
    }:
    {
      config = {
        boot.kernelPackages = pkgs.linuxPackagesFor config.mobile.device.kernel;
      };
    };
}
