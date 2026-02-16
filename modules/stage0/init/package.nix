{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs) rustPlatform;
    in
    {
      packages.stage0-init = rustPlatform.buildRustPackage {
        pname = "stage0-init";
        version = "0.1.0";

        src = lib.cleanSource ./.;

        cargoHash = "sha256-FW9yxqqO4I0k5FPGEvjSizWN7MIuHXrEfNnSHvnO1u8=";

        meta.mainProgram = "stage0-init";
      };
    };
}
