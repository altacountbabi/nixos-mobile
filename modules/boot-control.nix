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
      options.mobile = {
        boot-control.enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enables usage of boot-control to mark A/B boot as successful";
        };
      };

      config = lib.mkIf config.mobile.boot-control.enable {
        systemd.services.boot-control =
          let
            boot-control = self.lib.${pkgs.stdenv.hostPlatform.system}.nushellScript {
              name = "boot-control";
              packages = [
                pkgs.gptfdisk
              ];
              text = # nu
                ''
                  let data = "/dev/disk/by-partlabel/boot_a" | path expand | path parse | get stem | parse -r "(?P<disk>[a-z]+)(?P<part>\\d+)" | first
                  # 54th bit is the successful boot marker
                  sgdisk /dev/($data.disk) --attributes=($data.part):set:54
                '';
            };
          in
          {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            description = "Mark boot as successful";
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = lib.getExe boot-control;
            };
          };
      };
    };
}
