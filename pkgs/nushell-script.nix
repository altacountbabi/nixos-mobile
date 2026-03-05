{
  perSystem =
    { pkgs, lib, ... }:
    {
      lib.nushellScript =
        {
          name,
          text,
          packages ? [ ],
        }:
        let
          path = lib.makeBinPath packages;
        in
        pkgs.writeTextFile {
          inherit name;
          destination = "/bin/${name}";
          executable = true;
          text = # nushell
            ''
              #!${lib.getExe pkgs.nushell}
              $env.PATH = $"${path}:($env.PATH | str join ":")"

              ${text}
            '';
        };
    };
}
