{
  host = {
    name = "artemis";
    system = "x86_64-linux";
    stateVersion = "25.11";
  };

  paths = {
    repoRoot = "/home/allison/Code/nix-files";
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
    framework13 = true;
    nvidiaDesktop = false;
    gaming = true;
  };

  storage = {
    rootFsUuid = "e9a2587e-be17-4b99-9920-b50604647396";
    espFsUuid = "BB64-E186";
    luksPartUuid = "40e7eb2f-14ed-4a85-9641-2eb0e6f2de2b";
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
