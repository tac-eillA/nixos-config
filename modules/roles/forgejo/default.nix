{ config, lib, pkgs, ... }:

let
  cfg = config.scylla.roles.forgejo;
  forgejoCfg = config.services.forgejo;
  oidcClientSecretFile = config.sops.secrets."forgejo/authentik-client-secret".path;
  forgejoExe = lib.getExe forgejoCfg.package;
  psqlExe = "${config.services.postgresql.package}/bin/psql";
in
{
  options.scylla.roles.forgejo = {
    enable = lib.mkEnableOption "the Forgejo workload";

    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "git.allie.sh";
      description = "Public Forgejo domain.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "0.0.0.0";
      description = "Address on which Forgejo listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Forgejo HTTP port.";
    };

    oidcSourceName = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "Authentik";
      description = "Display name for the Forgejo OIDC authentication source.";
    };

    oidcClientId = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "forgejo";
      description = "OIDC client identifier.";
    };

    oidcDiscoveryUrl = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "https://auth.allie.sh/application/o/forgejo/.well-known/openid-configuration";
      description = "OIDC discovery URL.";
    };

    installAdminPackages = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install Forgejo administrative tools globally.";
    };

    secretFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/forgejo.yaml;
      description = "SOPS file containing the Forgejo OIDC client secret.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.pathExists cfg.secretFile;
        message = "The Forgejo role secret file does not exist.";
      }
      {
        assertion = config.services.openssh.ports != [ ];
        message = "The Forgejo role requires at least one OpenSSH port.";
      }
    ];

    sops.age = {
      keyFile = "/var/lib/sops-nix/age-key.txt";
      generateKey = false;
    };

    sops.secrets."forgejo/authentik-client-secret" = {
      sopsFile = cfg.secretFile;
      owner = forgejoCfg.user;
      group = forgejoCfg.group;
      mode = "0400";
      restartUnits = [ "forgejo-authentik-oidc.service" ];
    };

    services.forgejo = {
      enable = true;
      package = pkgs.forgejo;

      database.type = "postgres";
      lfs.enable = true;

      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}/";
          HTTP_ADDR = cfg.listenAddress;
          HTTP_PORT = cfg.port;

          START_SSH_SERVER = false;
          SSH_PORT = lib.head config.services.openssh.ports;
        };

        service = {
          DISABLE_REGISTRATION = true;
          REQUIRE_SIGNIN_VIEW = false;
        };

        actions = {
          ENABLED = true;
          DEFAULT_ACTIONS_URL = "github";
        };

        repository.DEFAULT_BRANCH = "main";
        security.INSTALL_LOCK = true;
        session.COOKIE_SECURE = true;
      };
    };

    services.postgresql.enable = true;

    systemd.services.forgejo-authentik-oidc = {
      description = "Ensure Forgejo OIDC source exists";
      after = [
        "forgejo.service"
        "postgresql.service"
      ];
      requires = [
        "forgejo.service"
        "postgresql.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [
        forgejoCfg.package
        config.services.postgresql.package
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gawk
      ];
      script = ''
        set -euo pipefail

        client_secret="$(<"$CREDENTIALS_DIRECTORY/client_secret")"
        auth_id="$(${psqlExe} -Atqc "select id from login_source where name = '${cfg.oidcSourceName}' limit 1;" forgejo || true)"

        common_args=(
          --config "${forgejoCfg.customDir}/conf/app.ini"
          --work-path "${forgejoCfg.stateDir}"
          --name "${cfg.oidcSourceName}"
          --provider openidConnect
          --key "${cfg.oidcClientId}"
          --secret "$client_secret"
          --auto-discover-url "${cfg.oidcDiscoveryUrl}"
          --scopes openid
          --scopes profile
          --scopes email
          --skip-local-2fa
        )

        if [ -n "$auth_id" ]; then
          ${forgejoExe} admin auth update-oauth --id "$auth_id" ''${common_args[@]}
        else
          ${forgejoExe} admin auth add-oauth ''${common_args[@]}
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = forgejoCfg.user;
        Group = forgejoCfg.group;
        LoadCredential = [ "client_secret:${oidcClientSecretFile}" ];
      };
      environment = {
        USER = forgejoCfg.user;
        HOME = forgejoCfg.stateDir;
        FORGEJO_WORK_DIR = forgejoCfg.stateDir;
        FORGEJO_CUSTOM = forgejoCfg.customDir;
      };
    };

    environment.systemPackages = lib.optionals cfg.installAdminPackages [
      pkgs.forgejo-cli
      pkgs.forgejo
    ];
  };
}
