{ inputs, ... }:

{
  perSystem =
    { pkgs, ... }:
    let
      craneLib = inputs.crane.mkLib pkgs;
    in
    {
      packages.stage0-init = craneLib.buildPackage {
        src = craneLib.cleanCargoSource ./.;
        strictDeps = true;

        meta.mainProgram = "stage0-init";
      };
    };
}
