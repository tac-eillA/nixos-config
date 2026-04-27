{ config, ... }:

let
  domain = "paperless.allie.sh";
  port = 28981;
  passwordFile = "/var/lib/secrets/paperless-admin-password";
in
{
  services.openssh.enable = true;
  services.qemuGuest.enable = true;

  services.paperless = {
    enable = true;
    address = "0.0.0.0";
    inherit domain port passwordFile;
    database.createLocally = true;
    configureTika = true;

    settings = {
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_CONSUMER_RECURSIVE = true;
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      port
    ];
  };

  environment.systemPackages = [
    config.services.paperless.manage
  ];
}
