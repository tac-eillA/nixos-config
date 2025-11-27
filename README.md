<h1 align="center">
   <img src="/img/nixos-logo.png" width="100px" /> 
   <br>
      My NixOS Configuration
   <br>
      <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="600px" />
    <br>
   <div align="center">
</h1>
## Installation

> [!Note]
> Before proceeding with the installation, check these files and adjust them for your system:
>
> - `hosts/default/variables.nix`: Contains host-specific variables.
> - `hosts/default/host-packages.nix`: Lists installed packages for the host.
> - `hosts/default/configuration.nix`: Module imports for the host and extra configuration.

<!-- You can install this configuration either on a running system or from the NixOS live installer. The minimal ISO is recommended and can be downloaded from the [official NixOS website](https://nixos.org/download/#nixos-iso). -->

You can install on a running system or from the NixOS live installer. Get the minimal ISO from the [NixOS website](https://nixos.org/download/#nixos-iso).

### Installation Steps

1. Clone the Repository:

<!-- 2. Navigate to the Directory: -->

2. Change Directory:

```bash
cd ~/hyprnix
```

3. Run the Installer:

```bash
./install.sh
```

<!-- The script handles host setup, username configuration, and automatically generates `hardware-configuration.nix` based on your hardware. -->

The install and rebuild scripts automate the setup process, including hosts, username, and applying the configuration. It also automatically generates the hardware-configuration.nix file based on your system's detected hardware, eliminating the need to manually generate it.

## Usage

### Managing Hosts

**Method 1: Automatic** - run the installer again to select or create another host:

```bash
./install.sh
```

**Method 2: Manual:**

1. Copy `hosts/default` to a new directory (e.g., `hosts/Laptop`)
2. Edit the new host's `variables.nix` and `host-packages.nix`
3. Add the host to `flake.nix`:


<!-- 4. Rebuild with the new hostname (see below) -->

4. Rebuild with the new hostname using either `nixos-rebuild` or `nh` (see [Rebuilding](#rebuilding) below). Once rebuilt, any rebuilding method can be used, as the host name will be implicitly recognised.

### Rebuilding

Apply configuration changes:

- **Keyboard shortcut:** `Super + U`
- **rebuild script:** `rebuild`
- **nixos-rebuild:** `sudo nixos-rebuild switch --flake ~/hyprnix#<HOST>`
- **nh:** `nh os switch --hostname <HOST>`

Replace `<HOST>` with the name of your host (e.g., `Laptop`).

### Rollbacks

List generations:

```bash
list-gens
```

Rollback to generation N:

```bash
rollback N
```

Replace `N` with the generation number (e.g., `69`).

### Keybindings

View all keybindings with `Super + ?` or `Super + Ctrl + K`.

## Credits/Inspiration

| Credit                                      | Reason                                      |
| ------------------------------------------- | ------------------------------------------- |
| [Sly-Harvey](//github.com/Sly-Harvey/NixOS) | Thanks for creating such a wonderful config |
| [Nixy](https://github.com/anotherhadi/nixy) | Amazing Neovim config                       |
