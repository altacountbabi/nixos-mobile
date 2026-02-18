{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    crane.url = "github:ipetkov/crane";
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports =
        [
          ./lib
          ./pkgs
          ./devices
          ./modules
        ]
        |> map (x: (inputs.import-tree x).imports)
        |> lib.flatten;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { system, ... }:
        let
          # Mobile usually means aarch64, if it doesn't then is it really mobile?
          targetSystem = "aarch64-linux";
          pkgs = import inputs.nixpkgs (
            if (system != targetSystem) then
              {
                localSystem = system;
                crossSystem = targetSystem;
              }
            else
              {
                system = targetSystem;
              }
          );
        in
        {
          _module.args = {
            inherit pkgs;
          };
        };
    };
}
