{ self, ... }:

{
  flake.nixosConfigurations = self.lib.nixosMobileSystems "nothing-spacewar" {
    modules = [
      (
        { pkgs, ... }:
        {
          mobile.devices.nothing-spacewar.enable = true;

          networking.hostName = "nothing-spacewar";
          networking.networkmanager.enable = true;

          users.users.root = {
            initialPassword = "123";
          };

          environment.systemPackages = with pkgs; [
            gnome-console
            loupe
            nautilus
            firefox
            phosh-mobile-settings
          ];

          services.openssh.enable = true;
          services.openssh.settings.PermitRootLogin = "yes";

          i18n.defaultLocale = "en_US.UTF-8";

          system.stateVersion = "26.05";
        }
      )
    ];
  };
}
