{ config, ... }:

{
  imports = [ ./runtime-age.nix ];

  sops = {
    secrets."rundeck/managed-password-hash" = {
      sopsFile = ../../secrets/common.yaml;
      neededForUsers = true;
    };
  };

  management.rundeckManaged.passwordHashFile =
    config.sops.secrets."rundeck/managed-password-hash".path;

  management.rundeckManaged.publicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4Kz5TVpctMr4v0wiXVUkxMIiHJPnNimmN8iT4Ifz0K allison@athena"
  ];
}
