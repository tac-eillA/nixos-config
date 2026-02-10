# Development Workflow

## Rebuild Commands

Run from repo root:

```bash
sudo nixos-rebuild build --flake .#artemis
sudo nixos-rebuild switch --flake .#artemis
```

Shell menu `Update + Rebuild` performs the same switch flow and now takes a pre-update snapshot first.

If you use zsh helpers (`config/zsh/.zshrc`):

- `nrb` build
- `nrs` switch
- `nrt` test
- `nrr` rollback switch
- `nrbk` rollback on next boot

## Dev Shells

Rust:

```bash
nix develop .#rust
```

Go:

```bash
nix develop .#go
```

## opencode

`opencode` is included in system packages (`modules/packages-core.nix`).

Check install:

```bash
opencode --version
```

## Snapshot Helpers

Interactive wrapper:

```bash
~/.config/shell/bin/shell-snapshot list
~/.config/shell/bin/shell-snapshot create manual
~/.config/shell/bin/shell-snapshot restore
```

Root backend script:

```bash
sudo bash scripts/system-snapshot.sh list
sudo bash scripts/system-snapshot.sh restore <snapshot-name> /etc/nixos
```

Snapshots are read-only and stored under `@snapshots/root` on the Btrfs top-level tree.

## Git Setup

Config files:

- `config/git/config`
- `config/git/ignore`

Set identity once:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```
