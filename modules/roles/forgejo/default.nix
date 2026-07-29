{ config, lib, pkgs, ... }:

let
  cfg = config.services.forgejo;
  domain = "git.allie.sh";
  authDomain = "auth.allie.sh";
  httpPort = 3000;
  oidcSourceName = "Authentik";
  oidcClientId = "forgejo";
  oidcClientSecretFile = config.sops.secrets."forgejo/authentik-client-secret".path;
  oidcDiscoveryUrl = "https://${authDomain}/application/o/forgejo/.well-known/openid-configuration";
  forgejoExe = lib.getExe cfg.package;
  psqlExe = "${config.services.postgresql.package}/bin/psql";
in
{
  imports = [ ../../secrets/runtime-age.nix ];

  sops.secrets."forgejo/authentik-client-secret" = {
    sopsFile = ../../../secrets/forgejo.yaml;
    owner = cfg.user;
    group = cfg.group;
    mode = "0400";
  };

  services.forgejo = {
    enable = true;
    package = pkgs.forgejo;

    database = {
      type = "postgres";
    };

    lfs.enable = true;

    settings = {
      server = {
        DOMAIN = domain;
        ROOT_URL = "https://${domain}/";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = httpPort;

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

      repository = {
        DEFAULT_BRANCH = "main";
      };

      security = {
        INSTALL_LOCK = true;
      };

      session = {
        COOKIE_SECURE = true;
      };
    };
  };

  services.postgresql.enable = true;

  systemd.services.forgejo-authentik-oidc = {
    description = "Ensure Forgejo Authentik OIDC source exists";
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
      cfg.package
      config.services.postgresql.package
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gawk
    ];
    script = ''
      set -euo pipefail

      client_secret="$(<"$CREDENTIALS_DIRECTORY/client_secret")"
      auth_id="$(${psqlExe} -Atqc "select id from login_source where name = '${oidcSourceName}' limit 1;" forgejo || true)"

      common_args=(
        --config "${cfg.customDir}/conf/app.ini"
        --work-path "${cfg.stateDir}"
        --name "${oidcSourceName}"
        --provider openidConnect
        --key "${oidcClientId}"
        --secret "$client_secret"
        --auto-discover-url "${oidcDiscoveryUrl}"
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
      User = cfg.user;
      Group = cfg.group;
      LoadCredential = [ "client_secret:${oidcClientSecretFile}" ];
    };
    environment = {
      USER = cfg.user;
      HOME = cfg.stateDir;
      FORGEJO_WORK_DIR = cfg.stateDir;
      FORGEJO_CUSTOM = cfg.customDir;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      22
      80
      443
      3000
    ];
  };

  environment.systemPackages = with pkgs; [
    forgejo-cli
    forgejo
  ];
}
