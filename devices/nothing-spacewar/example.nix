{ self, ... }:

{
  flake.nixosConfigurations = self.lib.nixosMobileSystems "nothing-spacewar" {
    modules = [
      {
        mobile.devices.nothing-spacewar.enable = true;

        networking.hostName = "nothing-spacewar";
        networking.networkmanager.enable = true;

        users.users.root = {
          initialPassword = "123";
        };

        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = "yes";

        console.font = "Lat2-Terminus16";
        i18n.defaultLocale = "en_US.UTF-8";

        system.stateVersion = "26.05";
      }
    ];
  };
}
