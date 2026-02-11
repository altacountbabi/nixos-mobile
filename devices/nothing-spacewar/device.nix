{ self, ... }:

{
  flake.nixosModules.default =
    { pkgs, ... }:
    {
      mobile.devices.nothing-spacewar = {
        name = "Nothing Phone 1";

        kernel = self.packages.${pkgs.stdenv.hostPlatform.system}.nothing-spacewar-kernel;
      };
    };
}
