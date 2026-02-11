{
  perSystem =
    { pkgs, ... }:
    {
      packages.nothing-spacewar-hexagon-firmware =
        let
          baseFw = pkgs.callPackage ./_base.nix { };
        in
        pkgs.runCommand "nothing-spacewar-hexagon-firmware" { } ''
          mkdir -p $out/share/hexagon
          cp -r ${baseFw}/usr/share/qcom/sm7325/nothing/spacewar/* $out/share/hexagon/
        '';
    };
}
