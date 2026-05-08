{ config, lib, pkgs, ... }:

let
  domain = "rundeck.allie.sh";
  authDomain = "auth.allie.sh";
  port = 4440;
  stateDir = "/var/lib/rundeck";
  runtimeDir = "/run/rundeck";
  configDir = "${runtimeDir}/etc";
  projectDir = "${stateDir}/projects";
  projectName = "nixos";
  resourcesFile = "${projectDir}/${projectName}/etc/resources.yaml";
  generateResourcesPkg = pkgs.writeShellApplication {
    name = "rundeck-generate-resources";
    runtimeInputs = with pkgs; [
      jq
      nix
      gnugrep
    ];
    text = builtins.readFile ../../scripts/rundeck-generate-resources.sh;
  };
  rundeckExe = lib.getExe pkgs.rundeck;
  generateResources = lib.getExe generateResourcesPkg;
in
{
  sops.secrets = {
    "rundeck/postgres-password" = {
      sopsFile = ../../secrets/rundeck.yaml;
      owner = "rundeck";
      group = "rundeck";
      mode = "0400";
    };

    "rundeck/authentik-client-secret" = {
      sopsFile = ../../secrets/rundeck.yaml;
      owner = "rundeck";
      group = "rundeck";
      mode = "0400";
    };

    "rundeck/ssh-ed25519" = {
      sopsFile = ../../secrets/rundeck.yaml;
      owner = "rundeck";
      group = "rundeck";
      mode = "0400";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "rundeck" ];
    ensureUsers = [
      {
        name = "rundeck";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.rundeck-postgresql-password = {
    description = "Set Rundeck PostgreSQL password";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      LoadCredential = [ "postgres-password:${config.sops.secrets."rundeck/postgres-password".path}" ];
    };

    script = ''
      set -euo pipefail

      password="$(<"$CREDENTIALS_DIRECTORY/postgres-password")"

      psql \
        --set=ON_ERROR_STOP=1 \
        --set=password="$password" \
        --command="ALTER USER rundeck WITH PASSWORD :'password';" \
        postgres
    '';
  };

  systemd.services.rundeck = {
    description = "Rundeck automation server";
    after = [
      "network-online.target"
      "postgresql.service"
      "rundeck-postgresql-password.service"
    ];
    wants = [ "network-online.target" ];
    requires = [
      "postgresql.service"
      "rundeck-postgresql-password.service"
    ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      bash
      coreutils
      git
      nix
      openssh
      rundeck-cli
      sudo
    ];

    preStart = ''
      set -euo pipefail

      install -d -m 0750 -o rundeck -g rundeck "${stateDir}"
      install -d -m 0750 -o rundeck -g rundeck "${configDir}"
      install -d -m 0750 -o rundeck -g rundeck "${stateDir}/server"
      install -d -m 0750 -o rundeck -g rundeck "${stateDir}/logs"
      install -d -m 0750 -o rundeck -g rundeck "${stateDir}/tmp"
      install -d -m 0750 -o rundeck -g rundeck "${stateDir}/var"
      install -d -m 0750 -o rundeck -g rundeck "${stateDir}/work"
      install -d -m 0750 -o rundeck -g rundeck "${projectDir}/${projectName}/etc"

      db_password="$(<"$CREDENTIALS_DIRECTORY/postgres_password")"
      oidc_secret="$(<"$CREDENTIALS_DIRECTORY/oidc_client_secret")"

      cat > "${configDir}/rundeck-config.properties" <<EOF
      grails.serverURL=https://${domain}
      server.servlet.context-path=/
      rundeck.executionMode=active
      rundeck.jetty.connector.forwarded=true

      dataSource.driverClassName=org.postgresql.Driver
      dataSource.url=jdbc:postgresql://127.0.0.1:5432/rundeck
      dataSource.username=rundeck
      dataSource.password=$db_password
      dataSource.dbCreate=update

      rundeck.security.oauth.authentik.autoConfigUrl=https://${authDomain}/application/o/rundeck/.well-known/openid-configuration
      rundeck.security.oauth.authentik.clientId=rundeck
      rundeck.security.oauth.authentik.clientSecret=$oidc_secret
      rundeck.security.oauth.authentik.scope=openid profile email
      rundeck.security.oauth.authentik.authorityProperty=groups
      EOF

      cat > "${configDir}/framework.properties" <<EOF
      framework.server.name=rundeck
      framework.server.hostname=${domain}
      framework.server.port=${toString port}
      framework.server.url=https://${domain}
      framework.rundeck.url=https://${domain}
      framework.ssh.user=rundeck
      framework.ssh.keypath=$CREDENTIALS_DIRECTORY/ssh_private_key
      EOF

      cat > "${projectDir}/${projectName}/etc/project.properties" <<EOF
      project.name=${projectName}
      resources.source.1.type=file
      resources.source.1.config.file=${resourcesFile}
      resources.source.1.config.format=resourceyaml
      service.NodeExecutor.default.provider=jsch-ssh
      service.FileCopier.default.provider=jsch-scp
      project.ssh-authentication=privateKey
      project.ssh-keypath=$CREDENTIALS_DIRECTORY/ssh_private_key
      EOF

      if [ -d "${stateDir}/nixos-config/.git" ]; then
        ${generateResources} "${stateDir}/nixos-config" > "${resourcesFile}"
      elif [ ! -e "${resourcesFile}" ]; then
        cat > "${resourcesFile}" <<EOF
      rundeck:
        hostname: rundeck
        username: rundeck
        nodename: rundeck
        osFamily: unix
        tags: server,nixos,rundeck
      EOF
      fi

      chown -R rundeck:rundeck "${configDir}" "${projectDir}/${projectName}"
      chmod 0640 "${configDir}/rundeck-config.properties" "${configDir}/framework.properties"
      chmod 0640 "${projectDir}/${projectName}/etc/project.properties" "${resourcesFile}"
    '';

    environment = {
      JAVA_TOOL_OPTIONS = lib.concatStringsSep " " [
        "-Dserver.address=0.0.0.0"
        "-Dserver.port=${toString port}"
        "-Drdeck.base=${stateDir}"
        "-Drundeck.server.configDir=${configDir}"
        "-Drundeck.server.dataDir=${stateDir}/data"
        "-Drundeck.server.logDir=${stateDir}/logs"
        "-Dserver.datastore.path=${stateDir}/data"
        "-Djava.io.tmpdir=${stateDir}/tmp"
      ];
    };

    serviceConfig = {
      User = "rundeck";
      Group = "rundeck";
      WorkingDirectory = stateDir;
      StateDirectory = "rundeck";
      RuntimeDirectory = "rundeck";
      RuntimeDirectoryMode = "0750";
      LoadCredential = [
        "postgres_password:${config.sops.secrets."rundeck/postgres-password".path}"
        "oidc_client_secret:${config.sops.secrets."rundeck/authentik-client-secret".path}"
        "ssh_private_key:${config.sops.secrets."rundeck/ssh-ed25519".path}"
      ];
      PermissionsStartOnly = true;
      ExecStart = lib.concatStringsSep " " [
        rundeckExe
        "--basedir ${stateDir}"
        "--configdir ${configDir}"
        "--projectdir ${projectDir}"
        "--serverdir ${stateDir}/server"
      ];
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  environment.etc."rundeck/jobs/nixos-starter.yaml".text = ''
    - defaultTab: nodes
      description: Run read-only host diagnostics.
      executionEnabled: true
      id: nixos-diagnostics
      loglevel: INFO
      name: NixOS Diagnostics
      nodeFilterEditable: true
      nodefilters:
        dispatch:
          keepgoing: false
          rankOrder: ascending
          successOnEmptyNodeFilter: false
          threadcount: '5'
        filter: tags: nixos
      nodesSelectedByDefault: true
      scheduleEnabled: true
      sequence:
        keepgoing: false
        strategy: node-first
        commands:
          - exec: hostnamectl && nixos-version && uptime

    - defaultTab: nodes
      description: Pull the config repo and build the selected host with a prompted sudo password.
      executionEnabled: true
      id: nixos-rebuild-switch
      loglevel: INFO
      name: NixOS Rebuild Switch
      nodeFilterEditable: true
      nodefilters:
        dispatch:
          keepgoing: false
          rankOrder: ascending
          successOnEmptyNodeFilter: false
          threadcount: '1'
        filter: tags: nixos
      nodesSelectedByDefault: false
      options:
        - name: sudo_password
          secure: true
          storagePath: null
          valueExposed: true
      scheduleEnabled: true
      sequence:
        keepgoing: false
        strategy: node-first
        commands:
          - exec: cd ~/nixos-config && git pull --ff-only && printf '%s\n' "''${option.sudo_password}" | sudo -S nixos-rebuild switch --flake ".#''${node.name}"
  '';

  networking.firewall.allowedTCPPorts = [
    22
    port
  ];

  environment.systemPackages = with pkgs; [
    generateResourcesPkg
    git
    nix
    openssh
    postgresql
    rundeck
    rundeck-cli
  ];
}
