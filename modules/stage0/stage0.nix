{ self, ... }:

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
      options.mobile.stage0 = {
        statusBarLayout = mkOption {
          type =
            with types;
            let
              baseType = [
                ints.positive # `x` terminal characters
                float # percentage
              ];
            in
            listOf (
              oneOf (
                baseType
                ++ [
                  (submodule {
                    options = {
                      layout = mkOption {
                        type = oneOf baseType;
                      };
                      item = mkOption {
                        type = enum [
                          "time"
                          "battery"
                        ];
                      };
                    };
                  })
                ]
              )
            );
          default = [
            6
            {
              layout = 50.0;
              item = "time";
            }
            {
              layout = 50.0;
              item = "battery";
            }
            6
          ];
          description = "List of items that describes the layout of the status bar in stage0-init";
        };
      };

      config = {
        boot.kernelParams = [
          "quiet"
          "rd.systemd.show_status=false"
        ];

        specialisation.stage0.configuration = {
          boot.initrd.systemd =
            let
              stage0-init = lib.getExe self.packages.${config.mobile.localSystem}.stage0-init;
              statusBarLayout =
                config.mobile.stage0.statusBarLayout |> (pkgs.formats.json { }).generate "status-bar-layout.json";
            in
            {
              storePaths = [ stage0-init ];
              services = {
                initrd-find-nixos-closure.enable = false;
                initrd-nixos-activation.enable = false;
                initrd-switch-root.enable = false;

                initrd-init = {
                  description = "Run stage0 init";

                  unitConfig = {
                    RequiresMountsFor = "/sysroot";
                    DefaultDependencies = false;
                  };
                  before = [
                    "initrd.target"
                    "shutdown.target"
                  ];
                  conflicts = [ "shutdown.target" ];
                  requiredBy = [ "initrd.target" ];
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${stage0-init} --status-bar-config ${statusBarLayout}";
                    StandardInput = "tty";
                    StandardOutput = "tty";
                    StandardError = "tty";
                    TTYReset = "yes";
                    TTYVHangup = "yes";
                    TTYPath = "/dev/console";

                    RemainAfterExit = true;
                  };
                };
              };
            };
        };
      };
    };
}
