{ inputs, lib, ... }:

let
  inherit (lib) mkOption types;
in
inputs.flake-parts.lib.mkTransposedPerSystemModule {
  name = "lib";
  option = mkOption {
    type = types.lazyAttrsOf types.anything;
    default = { };
    description = ''
      Libraries exported by flake.
    '';
  };
  file = ./lib.nix;
}
