{ inputs, lib, ... }:

let
  inherit (lib) mkOption types;
in
inputs.flake-parts.lib.mkTransposedPerSystemModule {
  name = "lib";
  option = mkOption {
    # Using `either` here allows us to have `lib.<system>.<anything>` and `lib.<anything>`
    type = with types; either (lazyAttrsOf raw) raw;
    default = { };
    description = ''
      Libraries exported by flake.
    '';
  };
  file = ./lib.nix;
}
