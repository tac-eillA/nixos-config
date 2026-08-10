# Install Scylla

This guide installs a new host or an existing host from this repository.

## Requirements

Before you start, confirm these requirements:

- NixOS is installed.
- The system has a network connection.
- Your user can run `sudo`.
- The `nano` editor is installed.
- The repository is at `~/nixos-config`.
- You have the required SOPS Age key for the selected host.

The workstation profile uses encrypted GitHub settings. Server roles can also
require the Age key at `/var/lib/sops-nix/age-key.txt`.

## Install a new host

Use this procedure after you install NixOS and clone the repository.

1. Open the repository:

   ```console
   cd ~/nixos-config
   ```

2. Run the installer:

   ```console
   ./scripts/install.sh
   ```

3. Select `Default`.

4. Enter the new host name.

5. When Nano opens `modules/profiles/workstation-user.nix`, check the user
   name, full name, home directory, and Git identity. Save the file and exit
   Nano.

6. When the installer opens the host configuration, check its profile. Add
   host-specific settings before you continue.

The installer performs these actions:

1. Copies the host configuration template.
2. Generates `hardware-configuration.nix`.
3. Opens the new host configuration.
4. Checks that the flake exposes the requested host.
5. Installs the bootloader.
6. Builds the configuration for the next boot.

The installer does not reboot the system. Reboot after a successful build:

```console
sudo reboot
```

Commit the new `hosts/<host-name>/` directory to keep the host in the
repository.

## Install an existing host

Use this procedure only if the repository contains the correct host
configuration. The installer replaces template hardware data on the target.

1. Open the repository and run the installer:

   ```console
   cd ~/nixos-config
   ./scripts/install.sh
   ```

2. Select `Other`.

3. Enter the existing host name.

4. Reboot after the installer reports a successful build.

## Create a host manually

Use this procedure if you do not want to use the installer.

1. Create the host directory from the template:

   ```console
   mkdir hosts/<host-name>
   cp templates/host/configuration.nix hosts/<host-name>/configuration.nix
   ```

2. Import the hardware file and one profile. Set the host name:

   ```nix
   { ... }:

   {
     imports = [
       ./hardware-configuration.nix
       ../../modules/profiles/workstation.nix
     ];

     networking.hostName = "<host-name>";
   }
   ```

   Import `server.nix` instead for a server.

3. Generate the hardware file:

   ```console
   sudo nixos-generate-config --show-hardware-config \
     > hosts/<host-name>/hardware-configuration.nix
   ```

4. Add host-specific settings to `configuration.nix`. The flake discovers the
   host configuration automatically.

## Rebuild a host

Use `switch` to activate a configuration now:

```console
sudo nixos-rebuild switch --flake ~/nixos-config#$(hostname)
```

Use `boot` to activate a configuration after the next reboot:

```console
sudo nixos-rebuild boot --flake ~/nixos-config#$(hostname)
```
