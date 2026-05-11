{ pkgs, ... }:

let
  username = "allison";

  unrealDevAliases = pkgs.writeText "unreal-dev-aliases.sh" ''
    alias cproj='cd /workspace/projects'
  '';

  distroboxIniText = ''
    [unreal-dev]
    pull=true
    image=rockylinux:8
    init=false
    root=false
    replace=true
    start_now=false
    additional_packages="alsa-lib pango libxkbcommon libgbm libXrandr libXdamage libXcomposite-devel at-spi2-atk libxml2-devel nss.x86_64"

    home=/home/${username}/.local/share/distrobox/homes/unreal-dev

    volume="/home/${username}/Projects:/workspace/projects"
    volume="${unrealDevAliases}:/opt/distrobox-aliases/aliases.sh:ro"

    init_hooks="grep -qxF 'source /opt/distrobox-aliases/aliases.sh' ~/.bashrc || echo 'source /opt/distrobox-aliases/aliases.sh' >> ~/.bashrc"
    init_hooks="grep -qxF 'source /opt/distrobox-aliases/aliases.sh' ~/.zshrc || echo 'source /opt/distrobox-aliases/aliases.sh' >> ~/.zshrc"
  '';

  distroboxIniFile = pkgs.writeText "distrobox.ini" distroboxIniText;
in
{
  virtualisation = {
    oci-containers.backend = "podman";

    podman = {
      enable = true;
      dockerCompat = true;

      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    distrobox
    podman
    podman-compose
    passt
    podman-tui
  ];

  systemd.user.services.distrobox-assemble = {
    description = "Create declared Distrobox containers";
    wantedBy = [ "default.target" ];

    path = [
      pkgs.distrobox
      pkgs.podman
      pkgs.shadow
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gnused
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.distrobox}/bin/distrobox-assemble create --file ${distroboxIniFile}";
      ExecStop = "${pkgs.distrobox}/bin/distrobox-assemble rm --file ${distroboxIniFile}";
    };
  };

  services.flatpak.packages = [
    "io.github.dvlv.boxbuddyrs"
  ];

  environment.etc."distrobox/distrobox.ini".text = distroboxIniText;
}
