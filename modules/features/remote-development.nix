{ config, lib, pkgs, ... }:

let
  userName = config.scylla.user.name;
  homeDirectory = config.users.users.${userName}.home;
  tailscaleInterface = config.services.tailscale.interfaceName;
  t3Executable = lib.getExe' pkgs.t3code "t3";
  t3Cli = pkgs.writeShellScriptBin "t3" ''
    exec ${t3Executable} "$@"
  '';
  t3Server = pkgs.writeShellApplication {
    name = "t3code-server";
    runtimeInputs = [ config.services.tailscale.package ];
    text = ''
      tailnet_address="$(tailscale ip -4)"
      if [ -z "$tailnet_address" ]; then
        echo "Tailscale has no IPv4 address." >&2
        exit 1
      fi

      exec ${t3Executable} serve --host "$tailnet_address" --port 3773
    '';
  };
  lockRemoteSession = pkgs.writeShellScript "lock-remote-session" ''
    ${pkgs.coreutils}/bin/sleep 2
    exec ${lib.getExe pkgs.hyprlock} --grace 0 --immediate-render
  '';
in
{
  services.displayManager.autoLogin = {
    enable = true;
    user = userName;
  };
  services.displayManager.sddm.autoLogin.relogin = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = false;
    openFirewall = false;
    settings = {
      sunshine_name = config.networking.hostName;
      upnp = "disabled";
      address_family = "both";
      origin_web_ui_allowed = "wan";
      capture = "wlr";
      encoder = "vaapi";
    };
    applications.apps = [
      {
        name = "Desktop";
      }
    ];
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings.PermitRootLogin = "no";
  };

  services.tailscale.openFirewall = true;

  users.users.${userName}.extraGroups = [ "uinput" ];

  environment.systemPackages = [
    t3Cli
    pkgs.nodejs_24
  ];

  networking.firewall.interfaces.${tailscaleInterface} = {
    allowedTCPPorts = [
      22
      3773
      47984
      47989
      47990
      48010
    ];
    allowedUDPPorts = [
      47998
      47999
      48000
      48002
      48010
    ];
  };

  systemd.services.t3code-server = {
    description = "T3 Code server on Tailscale";
    wantedBy = [ "multi-user.target" ];
    wants = [ "tailscaled.service" ];
    after = [ "tailscaled.service" ];
    partOf = [ "tailscaled.service" ];
    path = with pkgs; [
      claude-code
      codex
      gh
      git
      opencode
    ];
    environment = {
      HOME = homeDirectory;
      SHELL = lib.getExe pkgs.zsh;
    };
    serviceConfig = {
      User = userName;
      WorkingDirectory = homeDirectory;
      ExecStart = "${t3Server}/bin/t3code-server";
      Restart = "on-failure";
      RestartSec = "5s";
      UMask = "0077";
    };
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };

  security.pam.services.hyprlock = {
    enableGnomeKeyring = true;
    fprintAuth = lib.mkForce false;
  };

  services.fprintd.enable = lib.mkForce false;

  home-manager.users.${userName} = {
    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      hl.monitor({
        output = "HEADLESS-0",
        mode = "2560x1440@60",
        position = "0x0",
        scale = 1,
      })
    '';

    services.hypridle.settings.listener = lib.mkForce [
      {
        timeout = 300;
        on-timeout = "loginctl lock-session";
      }
    ];

    systemd.user.services.remote-session-lock = {
      Unit = {
        Description = "Lock the automatic remote desktop session";
        After = [ "sunshine.service" ];
        Wants = [ "sunshine.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service.ExecStart = lockRemoteSession;
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
