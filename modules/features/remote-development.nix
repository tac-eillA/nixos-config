{ config, lib, pkgs, ... }:

let
  userName = config.scylla.user.name;
  homeDirectory = config.users.users.${userName}.home;
  tailscaleInterface = config.services.tailscale.interfaceName;
  # Use the same pinned AppImage package as the desktop application. The
  # nixpkgs CLI package can lag behind the upstream AppImage release.
  t3Package = pkgs.callPackage ../packages/t3code.nix { };
  t3Executable = lib.getExe' t3Package "t3";
  t3Cli = pkgs.writeShellScriptBin "t3" ''
    exec ${t3Executable} "$@"
  '';
  t3Server = pkgs.writeShellApplication {
    name = "t3code-server";
    runtimeInputs = [ config.services.tailscale.package ];
    text = ''
      until tailnet_address="$(tailscale ip -4 2>/dev/null)" && [ -n "$tailnet_address" ]; do
        echo "Waiting for a Tailscale IPv4 address..." >&2
        ${pkgs.coreutils}/bin/sleep 1
      done

      exec ${t3Executable} serve \
        --host 127.0.0.1 \
        --port 3774 \
        --tailscale-serve
    '';
  };
  lockRemoteSession = pkgs.writeShellScript "lock-remote-session" ''
    ${pkgs.coreutils}/bin/sleep 2
    exec ${lib.getExe pkgs.hyprlock} --grace 0 --immediate-render
  '';
  ensureHeadlessOutput = pkgs.writeShellApplication {
    name = "ensure-headless-output";
    runtimeInputs = [ pkgs.hyprland pkgs.jq ];
    text = ''
      if ! hyprctl monitors all -j | jq -e 'any(.[]; .name == "HEADLESS-0")' >/dev/null; then
        hyprctl output create headless HEADLESS-0
      fi
    '';
  };
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

  # NixOS orders tailscaled after NetworkManager-wait-online, but After= does
  # not pull that unit into the transaction. Explicitly require an online
  # network so tailscaled sees the LAN DNS server before configuring MagicDNS.
  systemd.services.tailscaled = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

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

    systemd.user.services.headless-output = {
      Unit = {
        Description = "Create the Hyprland virtual display";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe ensureHeadlessOutput;
        RemainAfterExit = true;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

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
