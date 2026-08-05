{
  description = "Scylla — reusable NixOS configurations for my hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      defaultSystem = "x86_64-linux";
      lib = nixpkgs.lib;
      flatpakModule = inputs."nix-flatpak".nixosModules.nix-flatpak;
      hostInventory = import ./inventory/hosts.nix;
      networkInventory = import ./inventory/networks.nix;
      serviceInventory = import ./inventory/services.nix {
        hosts = hostInventory;
        networks = networkInventory;
      };

      profileModules = {
        base = ./modules/profiles/base.nix;
        server = ./modules/profiles/server.nix;
        workstation = ./modules/profiles/workstation.nix;
      };

      roleModules = {
        authentik = ./modules/roles/authentik;
        forgejo = ./modules/roles/forgejo;
        headscale = ./modules/roles/headscale;
        paperless-ngx = ./modules/roles/paperless-ngx;
        proxy = ./modules/roles/proxy;
        technitium-dns = ./modules/roles/technitium-dns;
        vaultwarden = ./modules/roles/vaultwarden;
      };

      featureModules = {
        appimage = ./modules/features/appimage.nix;
        audio = ./modules/features/audio.nix;
        desktop = ./modules/features/desktop.nix;
        development-full = ./modules/features/development/full.nix;
        development-minimal = ./modules/features/development/minimal.nix;
        distrobox = ./modules/features/distrobox.nix;
        firmware = ./modules/features/firmware.nix;
        gaming = ./modules/features/gaming.nix;
        github-secret = ./modules/secrets/github.nix;
        printing = ./modules/features/printing.nix;
        tailscale = ./modules/features/tailscale.nix;
        tailscale-operator = ./modules/features/tailscale-operator.nix;
      };

      hardwareModules = {
        framework-amd-ai-300-series =
          inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series;
      };

      workstationOnlyFeatures = [
        "appimage"
        "audio"
        "desktop"
        "development-full"
        "distrobox"
        "gaming"
        "github-secret"
        "printing"
        "tailscale-operator"
      ];

      validatedHostInventory = import ./inventory/validate-hosts.nix {
        hosts = hostInventory;
        knownFeatures = builtins.attrNames featureModules;
        knownHardwareModules = builtins.attrNames hardwareModules;
        knownProfiles = builtins.attrNames profileModules;
        knownRoles = builtins.attrNames roleModules;
        networks = networkInventory;
        inherit lib workstationOnlyFeatures;
      };

      servicePolicy = import ./inventory/validate-services.nix {
        hosts = validatedHostInventory;
        inherit lib;
        networks = networkInventory;
        knownRoles = builtins.attrNames roleModules;
        services = serviceInventory;
      };

      deployableHosts = builtins.deepSeq servicePolicy (
        lib.filterAttrs (_: host: host.deployable) validatedHostInventory
      );

      mkHost =
        hostname:
        let
          hostMeta = deployableHosts.${hostname};
          system = hostMeta.system;
          pkgsStable = import inputs.nix-stable {
            inherit system;
            config.allowUnfree = true;
          };
          enabledRoles = lib.genAttrs hostMeta.roles (
            role:
            {
              enable = true;
            }
            // (hostMeta.roleSettings.${role} or { })
            // (servicePolicy.roleSettingsByHost.${hostname}.${role} or { })
            // lib.optionalAttrs (role == "proxy") {
              ingress = servicePolicy.cloudflareIngress;
            }
          );
          sshPolicy = hostMeta.administration.ssh or null;
          administrativeExposures =
            if sshPolicy == null
            then [ ]
            else
              map
                (
                  exposure:
                  {
                    name = "openssh-${exposure.classification}";
                    address = hostMeta.address;
                    port = sshPolicy.port;
                    protocols = [ "tcp" ];
                    inherit (exposure) classification;
                    sources = exposure.trustedNetworks;
                    consumedByProxy = false;
                  }
                )
                sshPolicy.exposures;
        in
        lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs pkgsStable hostMeta;
            inventory = {
              hosts = validatedHostInventory;
              networks = networkInventory;
              services = servicePolicy.services;
            };
          };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./modules/networking/exposure.nix
          ]
          ++ lib.optionals (hostMeta.profile == "workstation") [
            flatpakModule
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "before-home-manager";
              home-manager.extraSpecialArgs = { inherit pkgsStable; };
            }
          ]
          ++ map (hardwareModule: hardwareModules.${hardwareModule}) (
            hostMeta.hardwareModules or [ ]
          )
          ++ [
            profileModules.${hostMeta.profile}
          ]
          ++ map (feature: featureModules.${feature}) hostMeta.features
          ++ builtins.attrValues roleModules
          ++ [
            {
              networking.hostName = hostname;
              systemd.network.networks."10-uplink".address = lib.optional
                (
                  hostMeta.address != null
                ) "${hostMeta.address}/24";
              scylla.roles = enabledRoles;
              scylla.network.exposures =
                servicePolicy.exposuresByHost.${hostname}
                  ++ administrativeExposures;
            }
            ./hosts/${hostname}/configuration.nix
          ];
        };
    in
    {
      nixosConfigurations = lib.genAttrs (builtins.attrNames deployableHosts) mkHost;

      templates = rec {
        default = host;
        host = {
          path = ./templates/host;
          description = "A share-safe Scylla host configuration";
        };
      };

      formatter.${defaultSystem} = (import nixpkgs {
        system = defaultSystem;
      }).nixpkgs-fmt;
    };
}
