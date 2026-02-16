{ self, ... }:

{
  flake.nixosModules.default =
    {
      config,
      lib,
      ...
    }:
    {
      boot.kernelParams = [
        "quiet"
        "rd.systemd.show_status=false"
      ];

      specialisation.stage0.configuration = {
        boot.initrd.systemd =
          let
            stage0-init = lib.getExe self.packages.${config.mobile.localSystem}.stage0-init;
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
                  ExecStart = stage0-init;
                  StandardOutput = "tty";
                  StandardError = "tty";
                  TTYPath = "/dev/console";

                  RemainAfterExit = true;
                };
              };
            };
          };
      };
    };
}
