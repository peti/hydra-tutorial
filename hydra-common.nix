# hydra-common.nix

{

  deployment.targetEnv = "virtualbox";
  deployment.virtualbox.memorySize = 4096; # Mbytes
  deployment.virtualbox.headless = true;

  i18n.defaultLocale = "en_US.UTF-8";

  nix.useChroot = true;
  nix.nrBuildUsers = 30;

  services.nixosManual.showManual = false;
  services.ntp.enable = false;
  services.openssh.allowSFTP = false;
  services.openssh.passwordAuthentication = false;

  users = {
    mutableUsers = false;
    users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
  };

}
