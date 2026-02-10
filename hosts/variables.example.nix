{
  host = {
    name = "my-host";
    system = "x86_64-linux";
    stateVersion = "25.11";
  };

  paths = {
    repoRoot = "/home/myuser/nixos-config";
  };

  locale = {
    defaultLocale = "en_US.UTF-8";
    timeZone = "UTC";
    keyMap = "us";
  };

  user = {
    name = "myuser";
    fullName = "My User";
    initialPassword = "changeme";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "docker"
      "lp"
      "scanner"
    ];
  };

  profiles = {
    framework13 = false;
    nvidiaDesktop = false;
    gaming = false;
  };

  storage = {
    rootFsUuid = "ROOT-FS-UUID";
    espFsUuid = "ESP-UUID";
    luksPartUuid = null;
    luksMapperName = "root";

    subvol = {
      root = "@";
      home = "@home";
      log = "@log";
      cache = null;
    };

    cacheMountPoint = "/var/cache";

    btrfsMountOptions = [
      "compress=zstd:3"
      "ssd"
      "space_cache=v2"
    ];

    espMountOptions = [
      "fmask=0022"
      "dmask=0022"
      "utf8"
    ];
  };
}
