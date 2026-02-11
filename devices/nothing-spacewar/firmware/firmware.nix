{
  perSystem =
    { pkgs, ... }:
    {
      packages.nothing-spacewar-firmware =
        let
          baseFw = pkgs.callPackage ./_base.nix { };
        in
        pkgs.runCommand "nothing-spacewar-firmware" { inherit baseFw; } ''
          mkdir -p $out/lib/firmware
          cp -r ${baseFw}/lib/firmware/* $out/lib/firmware/
          chmod +w -R $out
        '';
    };
}
