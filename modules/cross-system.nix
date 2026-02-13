{ inputs, ... }:

{
  flake.nixosModules.default =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.mobile = {
        localSystem = mkOption {
          type = types.str;
          default = pkgs.stdenv.hostPlatform.system;
          description = ''
            Which system to use for things that must be compiled locally like the kernel of a device.
            This is different from `nixpkgs.localSystem` as it doesn't affect the rest of nixpkgs. If we used a different `localSystem` and `crossSystem` in the nixpkgs config, we'd have to compile all of nixpkgs ourselves as the cross compiled packages are not cached, only native ones.
          '';
          internal = true;
        };

        crossPkgs = mkOption {
          type = types.raw;
          default =
            let
              targetSystem = "aarch64-linux";
              system = config.mobile.localSystem;
            in
            import inputs.nixpkgs (
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
          description = "Used primarily when calling functions from nixpkgs that should run natively on x86_64.";
          internal = true;
          readOnly = true;
        };
      };
    };
}
