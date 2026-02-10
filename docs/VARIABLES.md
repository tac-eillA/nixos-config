# Host Variables Model

Machine/user knobs are centralized in `hosts/<host>/variables.nix`.

This keeps modules generic and makes per-host updates easy.

## File Location

- Active host example: `hosts/artemis/variables.nix`
- Template: `hosts/variables.example.nix`
- Generator: `scripts/bootstrap-variables.sh`

## Structure

```nix
{
  host = {
    name = "artemis";
    system = "x86_64-linux";
    stateVersion = "25.11";
  };

  paths = {
    repoRoot = "/home/allison/nixos-config";
  };

  locale = {
    defaultLocale = "en_US.UTF-8";
    timeZone = "US/Pacific";
    keyMap = "us";
  };

  user = {
    name = "allison";
    fullName = "Allison";
    initialPassword = "changeme";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  profiles = {
    framework13 = true;
    nvidiaDesktop = false;
    gaming = true;
  };

  storage = {
    rootFsUuid = "...";
    espFsUuid = "...";
    luksPartUuid = "..."; # or null
    luksMapperName = "root";
    subvol = {
      root = "@";
      home = "@home";
      log = "@log";
      cache = null;
    };
  };
}
```

## Interactive Generator

```bash
./scripts/bootstrap-variables.sh artemis
```

It will:

- detect likely defaults from current machine
- prompt you to confirm/edit
- validate key fields (host name, username pattern, absolute paths)
- show a final summary for confirmation before writing
- write `hosts/artemis/variables.nix`
- back up old variables file if one exists
