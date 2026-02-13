{ self, inputs, ... }:

{
  # Wrapper around `nixosSystem` which generates two nixos configurations, a normal one and one for cross compilation on x86_64.
  # You will need to add `boot.binfmt.emulatedSystems = [ "aarch64-linux" ];` to your host config for the x86_64-cross config as not everything is cross compiled, otherwise you'd have to compile all of nixpkgs yourself, only local packages like your device's kernel are cross compiled.
  flake.lib.nixosMobileSystems =
    name: args:
    let
      inherit (inputs.nixpkgs.lib) nixosSystem removeAttrs;
      args' = removeAttrs args [ "modules" ];
    in
    {
      ${name} =
        nixosSystem {
          system = "aarch64-linux";
          modules = [ self.nixosModules.default ] ++ args.modules;
        }
        // args';
      "${name}-x86_64-cross" =
        nixosSystem {
          system = "aarch64-linux";
          modules = [
            self.nixosModules.default
            {
              mobile.localSystem = "x86_64-linux";
            }
          ]
          ++ args.modules;
        }
        // args';
    };
}
