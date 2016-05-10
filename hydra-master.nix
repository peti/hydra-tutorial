# hydra-master.nix

{ config, pkgs, ... }:

let

  hydraSrc = builtins.fetchTarball https://github.com/nixos/hydra/archive/master.tar.gz;

in
{

  imports = [ ./hydra-common.nix "${hydraSrc}/hydra-module.nix" ];

  assertions = pkgs.lib.singleton {
    assertion = pkgs.system == "x86_64-linux";
    message = "unsupported system ${pkgs.system}";
  };

  environment.etc = pkgs.lib.singleton {
    target = "nix/id_buildfarm";
    source = ./id_buildfarm;
    uid = config.ids.uids.hydra;
    gid = config.ids.gids.hydra;
    mode = "0440";
  };

  networking.firewall.allowedTCPPorts = [ config.services.hydra.port ];

  nix = {
    distributedBuilds = true;
    buildMachines = [
      { hostName = "slave1"; maxJobs = 1; speedFactor = 1; sshKey = "/etc/nix/id_buildfarm"; sshUser = "root"; system = "x86_64-linux"; }
    ];
    extraOptions = "auto-optimise-store = true";
  };

  services.hydra = {
    enable = true;
    hydraURL = "http://hydra.example.org";
    notificationSender = "hydra@example.org";
    port = 8080;
    extraConfig = "binary_cache_secret_key_file = /etc/nix/hydra.example.org-1/secret";
    buildMachinesFiles = [ "/etc/nix/machines" ];
  };

  services.postgresql = {
    package = pkgs.postgresql94;
    dataDir = "/var/db/postgresql-${config.services.postgresql.package.psqlSchema}";
  };

  systemd.services.hydra-manual-setup = {
    description = "Create Admin User for Hydra";
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    wantedBy = [ "multi-user.target" ];
    requires = [ "hydra-init.service" ];
    after = [ "hydra-init.service" ];
    environment = config.systemd.services.hydra-init.environment;
    script = ''
      if [ ! -e ~hydra/.setup-is-complete ]; then
        # create admin user
        /run/current-system/sw/bin/hydra-create-user alice --full-name 'Alice Q. User' --email-address 'alice@example.org' --password foobar --role admin
        # create signing keys
        /run/current-system/sw/bin/install -d -m 551 /etc/nix/hydra.example.org-1
        /run/current-system/sw/bin/nix-store --generate-binary-cache-key hydra.example.org-1 /etc/nix/hydra.example.org-1/secret /etc/nix/hydra.example.org-1/public
        /run/current-system/sw/bin/chown -R hydra:hydra /etc/nix/hydra.example.org-1
        /run/current-system/sw/bin/chmod 440 /etc/nix/hydra.example.org-1/secret
        /run/current-system/sw/bin/chmod 444 /etc/nix/hydra.example.org-1/public
        # done
        touch ~hydra/.setup-is-complete
      fi
    '';
  };

  users.users.hydra-www.uid = config.ids.uids.hydra-www;
  users.users.hydra-queue-runner.uid = config.ids.uids.hydra-queue-runner;
  users.users.hydra.uid = config.ids.uids.hydra;
  users.groups.hydra.gid = config.ids.gids.hydra;

}
