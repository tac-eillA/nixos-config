<p align="center">
  <img src="img/readme/nixos-logo.png" alt="Scylla NixOS logo" width="180">
</p>

<h1 align="center">Scylla</h1>

<p align="center">
  A modular NixOS configuration for workstations and servers.
</p>

Scylla uses Nix flakes to define each host. The flake discovers each
`hosts/<name>/configuration.nix` file. Each host selects one profile and owns
its name, address, roles, firewall rules, hardware, and overrides. Shared
modules are in `modules/`.

> [!IMPORTANT]
> This repository contains personal host configurations and encrypted secrets.
> Use the share-safe host template for a new system. The template does not
> contain SOPS secrets and is not a host output.

## Start here

- [Install a new or existing host](INSTALLATION.md).
- [Configure role-based hosts and services](ROLE-BASED-HOSTS.md).
- [Configure the Quickshell desktop](modules/home/scylla/hyprland/quickshell/README.md).

## Features

- NixOS configurations for workstations and servers.
- Manual host configuration in each host folder.
- Workstation and server profiles with shared module imports.
- Hyprland with a Quickshell desktop shell.
- SOPS and Age secret management for configured hosts.
- Service roles for Authentik, DNS, Forgejo, Headscale, Paperless-ngx,
  Proxy, and Vaultwarden.
- Source-restricted firewall rules for server services and administration.

![Scylla desktop with a browser, terminal, media player, and audio controls](img/readme/fullscreen_browser_cider_terminal.png)

![Scylla desktop with a browser and the Zed editor](img/readme/fullscreen_browser_zed.png)

## Repository map

| Path | Content |
| --- | --- |
| `flake.nix` | Flake inputs and automatic host discovery |
| `hosts/` | Manual host configuration and hardware files |
| `templates/host/` | Share-safe host template |
| `modules/core/` | Settings shared by every host |
| `modules/profiles/` | Server and workstation composition |
| `modules/features/` | Desktop, development, gaming, and system features |
| `modules/networking/` | Source-restricted firewall policy |
| `modules/home/scylla/` | Home Manager and desktop settings |
| `modules/roles/` | Directory-based server workload roles |
| `modules/secrets/` | SOPS declarations and Age settings |
| `scripts/` | Installation and administration scripts |

## Common operations

Check every host without building it:

```console
nix flake check --no-build --show-trace
```

Activate the current host configuration:

```console
sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)
```

Build the current host configuration for the next boot:

```console
sudo nixos-rebuild boot --flake ~/nixos-config#$(hostname)
```

After the first configuration, open a new shell session. The configuration
provides `update`, `rebuild`, `rebuild-boot`, and `garbage` aliases. The
`update` alias updates `flake.lock`; it does not rebuild the system.

## Secrets

Scylla uses `sops-nix` with the Age key at:

```text
/var/lib/sops-nix/age-key.txt
```

Do not commit an unencrypted secret or an Age private key. Role modules declare
their SOPS files and restart targets.

## Desktop documentation

The [Quickshell README](modules/home/scylla/hyprland/quickshell/README.md)
describes the shell composition, IPC targets, display profiles, adaptive
profiles, and keybindings.
