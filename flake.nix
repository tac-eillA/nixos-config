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

      knownFeatures = builtins.attrNames featureModules;

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

      hostNames = builtins.attrNames hostInventory;
      hostDirectories = builtins.readDir ./hosts;
      configuredHostDirectories = lib.filter
        (
          hostname:
          hostDirectories.${hostname} == "directory"
          && builtins.pathExists (./hosts + "/${hostname}/configuration.nix")
        )
        (builtins.attrNames hostDirectories);

      addresses = lib.filter (address: address != null) (
        map (hostname: hostInventory.${hostname}.address or null) hostNames
      );

      duplicateAddresses = lib.unique (
        lib.filter
          (
            address: lib.length (lib.filter (candidate: candidate == address) addresses) > 1
          )
          addresses
      );

      unknownProfiles = lib.filter
        (
          hostname: !(builtins.hasAttr hostInventory.${hostname}.profile profileModules)
        )
        hostNames;

      unknownRoles = lib.concatMap
        (
          hostname:
          map (role: "${hostname}:${role}") (
            lib.filter (role: !(builtins.hasAttr role roleModules)) hostInventory.${hostname}.roles
          )
        )
        hostNames;

      unknownFeatures = lib.concatMap
        (
          hostname:
          map (feature: "${hostname}:${feature}") (
            lib.filter (feature: !(builtins.elem feature knownFeatures)) hostInventory.${hostname}.features
          )
        )
        hostNames;

      duplicateFeatures = lib.filter
        (
          hostname:
          let
            features = hostInventory.${hostname}.features;
          in
          lib.length features != lib.length (lib.unique features)
        )
        hostNames;

      incompatibleProfileFeatures = lib.concatMap
        (
          hostname:
          map (feature: "${hostname}:${feature}") (
            lib.filter
              (
                feature:
                hostInventory.${hostname}.profile != "workstation"
                && builtins.elem feature workstationOnlyFeatures
              )
              hostInventory.${hostname}.features
          )
        )
        hostNames;

      invalidFeatureDependencies = lib.concatMap
        (
          hostname:
          let
            features = hostInventory.${hostname}.features;
          in
          lib.optional
            (
              builtins.elem "tailscale-operator" features
              && (
                !(builtins.elem "tailscale" features)
                || !(builtins.elem "desktop" features)
              )
            )
            "${hostname}:tailscale-operator requires tailscale and desktop"
          ++ lib.optional
            (
              builtins.elem "development-full" features
              && builtins.elem "development-minimal" features
            )
            "${hostname}:select only one development feature"
        )
        hostNames;

      unknownHardwareModules = lib.concatMap
        (
          hostname:
          map (hardwareModule: "${hostname}:${hardwareModule}") (
            lib.filter
              (
                hardwareModule: !(builtins.hasAttr hardwareModule hardwareModules)
              )
              (hostInventory.${hostname}.hardwareModules or [ ])
          )
        )
        hostNames;

      mismatchedRoleSettings = lib.filter
        (
          hostname:
          let
            settings = builtins.attrNames (hostInventory.${hostname}.roleSettings or { });
          in
          lib.any (role: !(builtins.elem role hostInventory.${hostname}.roles)) settings
        )
        hostNames;

      manualProxyIngress = lib.filter
        (
          hostname:
          builtins.hasAttr "ingress" (
            hostInventory.${hostname}.roleSettings.proxy or { }
          )
        )
        hostNames;

      inventoryManagedRoleSettings = [
        "domain"
        "listenAddress"
        "port"
      ];

      manualServiceListenerSettings = lib.concatMap
        (
          hostname:
          lib.concatMap
            (
              role:
              map (setting: "${hostname}:${role}.${setting}") (
                lib.filter
                  (
                    setting:
                    builtins.hasAttr setting (
                      hostInventory.${hostname}.roleSettings.${role} or { }
                    )
                  )
                  inventoryManagedRoleSettings
              )
            )
            hostInventory.${hostname}.roles
        )
        hostNames;

      deployableServerNames = lib.filter
        (
          hostname:
          hostInventory.${hostname}.deployable
          && hostInventory.${hostname}.profile == "server"
        )
        hostNames;

      missingAdministrativePolicies = lib.filter
        (
          hostname:
          lib.attrByPath
            [
              "administration"
              "ssh"
              "exposures"
            ]
            [ ]
            hostInventory.${hostname}
          == [ ]
        )
        deployableServerNames;

      administrativeNetworks = lib.concatMap
        (
          hostname:
          lib.concatMap
            (exposure: exposure.trustedNetworks or [ ])
            (
              lib.attrByPath
                [
                  "administration"
                  "ssh"
                  "exposures"
                ]
                [ ]
                hostInventory.${hostname}
            )
        )
        deployableServerNames;

      undeclaredAdministrativeNetworks = lib.filter
        (
          network:
            !(builtins.elem network (
              lib.concatLists (builtins.attrValues networkInventory)
            ))
        )
        administrativeNetworks;

      missingHostConfigurations = lib.filter
        (
          hostname: !(builtins.pathExists (./hosts + "/${hostname}/configuration.nix"))
        )
        hostNames;

      unregisteredHostDirectories = lib.subtractLists hostNames configuredHostDirectories;

      placeholderDeployments = lib.filter
        (
          hostname:
          hostInventory.${hostname}.deployable
          && builtins.pathExists (./hosts + "/${hostname}/hardware-configuration.nix")
          && lib.hasInfix "replace-me-root" (
            builtins.readFile (./hosts + "/${hostname}/hardware-configuration.nix")
          )
        )
        hostNames;

      validatedHostInventory =
        assert lib.assertMsg
          (
            duplicateAddresses == [ ]
          ) "Duplicate inventory addresses: ${lib.concatStringsSep ", " duplicateAddresses}";
        assert lib.assertMsg
          (
            unknownProfiles == [ ]
          ) "Unknown inventory profiles: ${lib.concatStringsSep ", " unknownProfiles}";
        assert lib.assertMsg
          (
            unknownRoles == [ ]
          ) "Unknown inventory roles: ${lib.concatStringsSep ", " unknownRoles}";
        assert lib.assertMsg
          (
            unknownFeatures == [ ]
          ) "Unknown inventory features: ${lib.concatStringsSep ", " unknownFeatures}";
        assert lib.assertMsg
          (
            duplicateFeatures == [ ]
          ) "Inventory hosts repeat features: ${lib.concatStringsSep ", " duplicateFeatures}";
        assert lib.assertMsg
          (
            incompatibleProfileFeatures == [ ]
          ) "Features incompatible with host profiles: ${lib.concatStringsSep ", " incompatibleProfileFeatures}";
        assert lib.assertMsg
          (
            invalidFeatureDependencies == [ ]
          ) "Invalid feature dependencies: ${lib.concatStringsSep ", " invalidFeatureDependencies}";
        assert lib.assertMsg
          (
            unknownHardwareModules == [ ]
          ) "Unknown inventory hardware modules: ${lib.concatStringsSep ", " unknownHardwareModules}";
        assert lib.assertMsg
          (
            mismatchedRoleSettings == [ ]
          ) "Role settings exist for disabled roles on: ${lib.concatStringsSep ", " mismatchedRoleSettings}";
        assert lib.assertMsg
          (
            manualProxyIngress == [ ]
          ) "Proxy ingress must be generated from service inventory, not set on: ${lib.concatStringsSep ", " manualProxyIngress}";
        assert lib.assertMsg
          (
            manualServiceListenerSettings == [ ]
          ) "Service listeners must be generated from service inventory, not set on: ${lib.concatStringsSep ", " manualServiceListenerSettings}";
        assert lib.assertMsg
          (
            missingAdministrativePolicies == [ ]
          ) "Deployable servers lack an administrative exposure policy: ${lib.concatStringsSep ", " missingAdministrativePolicies}";
        assert lib.assertMsg
          (
            undeclaredAdministrativeNetworks == [ ]
          ) "Administrative access trusts networks absent from network inventory: ${lib.concatStringsSep ", " undeclaredAdministrativeNetworks}";
        assert lib.assertMsg
          (
            missingHostConfigurations == [ ]
          ) "Inventory hosts missing configuration.nix: ${lib.concatStringsSep ", " missingHostConfigurations}";
        assert lib.assertMsg
          (
            unregisteredHostDirectories == [ ]
          ) "Host directories missing from inventory: ${lib.concatStringsSep ", " unregisteredHostDirectories}";
        assert lib.assertMsg
          (
            placeholderDeployments == [ ]
          ) "Deployable hosts still use placeholder disks: ${lib.concatStringsSep ", " placeholderDeployments}";
        hostInventory;

      servicePolicy = import ./inventory/validate-services.nix {
        hosts = validatedHostInventory;
        inherit lib;
        networks = networkInventory;
        knownRoles = builtins.attrNames roleModules;
        services = serviceInventory;
      };

      validatedServiceInventory = servicePolicy.services;

      deployableHosts = builtins.deepSeq servicePolicy (
        lib.filterAttrs (_: host: host.deployable) validatedHostInventory
      );

      mkPkgs =
        hostSystem:
        import nixpkgs {
          system = hostSystem;
        };

      t3codeDevShell =
        let
          pkgs = mkPkgs defaultSystem;
          electronRuntimeLibraries = with pkgs; [
            alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            dbus
            expat
            glib
            libdrm
            libgbm
            libX11
            libXcomposite
            libXcursor
            libXdamage
            libXext
            libXfixes
            libXi
            libXinerama
            libxkbcommon
            libXrandr
            libXxf86vm
            libxcb
            mesa
            nspr
            nss
            pango
            wayland
          ];
          electronRuntimePath = lib.makeLibraryPath electronRuntimeLibraries;
          pkgConfigPath = lib.makeSearchPath "lib/pkgconfig" electronRuntimeLibraries;
        in
        pkgs.mkShell {
          packages = with pkgs; [
            bash
            cargo
            cacert
            coreutils
            curl
            file
            gcc
            gh
            git
            gnumake
            nodejs_24
            pkg-config
            pnpm
            python3
            rustc
            rustfmt
          ];

          shellHook = ''
            export PATH="$HOME/.vite-plus/bin:$PWD/node_modules/.bin:$PATH"
            export PYTHON="${pkgs.python3}/bin/python3"
            export npm_config_python="$PYTHON"
            export LD_LIBRARY_PATH="${electronRuntimePath}:''${LD_LIBRARY_PATH:-}"
            export PKG_CONFIG_PATH="${pkgConfigPath}:''${PKG_CONFIG_PATH:-}"

            missing_tools=()
            for tool in node vp cargo rustfmt; do
              if ! command -v "$tool" >/dev/null 2>&1; then
                missing_tools+=("$tool")
              fi
            done

            if (( ''${#missing_tools[@]} > 0 )); then
              printf 'T3 Code development shell is missing: %s\n' \
                "''${missing_tools[*]}" >&2
              if [[ " ''${missing_tools[*]} " == *" vp "* ]]; then
                printf '%s\n' \
                  'Install Vite+ with: curl -fsSL https://vite.plus | bash' \
                  'Then run: vp env off' >&2
              fi
              return 1
            fi

            printf 'T3 Code shell: node %s, vp %s, cargo %s\n' \
              "$(node --version)" "$(vp --version 2>/dev/null | head -n 1)" \
              "$(cargo --version)"
          '';
        };

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
              services = validatedServiceInventory;
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

      devShells.${defaultSystem}.t3code = t3codeDevShell;

      templates = rec {
        default = host;
        host = {
          path = ./templates/host;
          description = "A share-safe Scylla host configuration";
        };
      };

      formatter.${defaultSystem} = (mkPkgs defaultSystem).nixpkgs-fmt;
    };
}
