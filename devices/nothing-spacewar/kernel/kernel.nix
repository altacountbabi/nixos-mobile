{
  perSystem =
    { self', pkgs, ... }:
    {
      packages.nothing-spacewar-kernel = self'.lib.buildKernel {
        version = "6.18.8";
        src = pkgs.fetchFromGitHub {
          owner = "sc7280-mainline";
          repo = "linux";
          rev = "bac90cb175d0f0f74780806b64028ea1903856ed";
          hash = "sha256-na+vg4v6jI3rtiPBnbCUDDlULDvNpDAyfyH9jAOLbdc=";
        };

        patches = [
          ./audio.patch
        ];

        isModular = true;
        isCompressed = "gz";
      };
    };
}
