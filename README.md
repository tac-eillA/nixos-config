<p align="center">
  <img src="img/readme/nixos-logo.png" alt="Scylla NixOS logo" width="180">
</p>

<h1 align="center">Scylla</h1>

<p align="center">
  A modular NixOS configuration for workstations and servers.
</p>

Scylla uses Nix flakes to define each host. Host files are in `hosts/`.
Shared modules are in `modules/`.

> [!IMPORTANT]
> This repository contains personal host configurations and encrypted secrets.
> Use the `default` host as the template for a new system. The template does
> not use SOPS secrets.

## Desktop

The workstation profile provides Hyprland, Home Manager, Quickshell, and
desktop applications.

![Scylla desktop with a browser, terminal, media player, and audio controls](img/readme/fullscreen_browser_cider_terminal.png)

![Scylla desktop with a browser and the Zed editor](img/readme/fullscreen_browser_zed.png)

## Main features

- NixOS host configurations for workstations and servers
- Shared base, desktop, workstation, and server profiles
- Home Manager configuration for the primary user
- Hyprland with a Quickshell desktop shell
- SOPS secret management for configured hosts
- Service roles for Authentik, DNS, Forgejo, Headscale, Paperless-ngx, Proxy,
  and Vaultwarden
- Automatic host discovery from the `hosts/` directory
- An installation script for a new or existing host configuration

## Repository layout

| Path | Content |
| --- | --- |
| `flake.nix` | Flake inputs and NixOS host outputs |
| `hosts/` | Host configuration and hardware files |
| `modules/core/` | Shared boot, firewall, network, shell, system, and user settings |
| `modules/profiles/` | Base, server, and workstation composition |
| `modules/features/` | Cross-cutting desktop, development, gaming, and system features |
| `modules/home/scylla/` | Home Manager and desktop user settings |
| `modules/desktop/` | Desktop implementation modules used by the desktop feature |
| `modules/roles/` | Directory-based server workload roles |
| `modules/secrets/` | SOPS declarations and Age key settings |
| `scripts/` | Installation and administration scripts |

## Requirements

Before you use the installation script, make sure that:

- NixOS is installed.
- The system can connect to the network.
- Your user can run `sudo`.
- This repository is at `~/nixos-config`.

Some existing host configurations require a SOPS Age key. Do not deploy one
of these configurations if you do not have the correct key.

## Install a new host

Use this procedure after you install NixOS and clone the repository.

1. Open the repository:

   ```console
   cd ~/nixos-config
   ```

2. Run the installation script:

   ```console
   ./scripts/install.sh
   ```

3. Select `Default`.

4. Enter the new host name.

5. Edit `modules/core/user.nix` when Nano opens.

   Check the user name, full name, home directory, and Git identity. Save the
   file and exit Nano.

The script then does these tasks:

1. It copies the `default` host configuration.
2. It sets the new host name.
3. It generates `hardware-configuration.nix`.
4. It installs the bootloader.
5. It builds the configuration with `nixos-rebuild boot`.

The script does not reboot the system. Reboot the system manually after the
script reports a successful build.

```console
sudo reboot
```

Commit the new `hosts/<host-name>/` directory if you want to keep the host
configuration in the repository.

## Install an existing host

Use this procedure only when the repository already contains the correct host
configuration and hardware file.

1. Run the installation script:

   ```console
   cd ~/nixos-config
   ./scripts/install.sh
   ```

2. Select `Other`.

3. Enter the name of the existing host configuration.

4. Reboot the system after the script reports a successful build.

## Rebuild a host

Run this command to activate a configuration immediately:

```console
sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)
```

Run this command to build the configuration for the next boot:

```console
sudo nixos-rebuild boot --flake ~/nixos-config#$(hostname)
```

After the initial configuration, open a new shell session. The following
aliases are then available:

| Alias | Action |
| --- | --- |
| `update` | Update the flake inputs in `flake.lock` |
| `rebuild` | Build and activate the current host configuration |
| `rebuild-boot` | Build the current host configuration for the next boot |
| `garbage` | Delete old Nix store generations |

The `update` alias does not rebuild the system. Run `rebuild` or
`rebuild-boot` after `update` when you are ready to apply the updated inputs.

## Configure the primary user

The file `modules/core/user.nix` contains the default user information. Other
modules read the `scylla.user` options from this file.

The available options are:

```nix
scylla.user = {
  name = "user-name";
  fullName = "User Name";
  homeDirectory = null; # null uses /home/<user-name>
  git.name = "Git Author";
  git.email = "user@example.com";
};
```

To add another system account, add `users.users.<name>` to a host-specific
module. The `scylla.user` account is the primary Home Manager desktop account.

## Add a host manually

1. Create `hosts/<host-name>/`.

2. Add `configuration.nix`.

3. Import a hardware file and one profile:

   ```nix
   { ... }:

   {
     imports = [
       ./hardware-configuration.nix
       ../../modules/profiles/base.nix
     ];

     networking.hostName = "<host-name>";
   }
   ```

4. Generate the hardware file:

   ```console
   sudo nixos-generate-config --show-hardware-config \
     > hosts/<host-name>/hardware-configuration.nix
   ```

The flake detects the new directory. You do not have to edit `flake.nix`.

## Secret management

Scylla uses `sops-nix` and an Age key at:

```text
/var/lib/sops-nix/age-key.txt
```

The `default` host imports only the base profile. It does not declare a SOPS
secret. Server and workstation profiles can declare secrets.

Do not commit an unencrypted secret or an Age private key.

## Placeholder hosts

Some host directories contain placeholder hardware settings. Do not deploy a
placeholder configuration. Replace its `hardware-configuration.nix` file with
the output from the target system.
