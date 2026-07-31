{ config, lib, ... }:

let
  cfg = config.scylla.network.exposures;
  firewallPolicy = import ./firewall-policy.nix { inherit lib; };

  exposureType = lib.types.submodule (
    { ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.nonEmptyStr;
          description = "Stable inventory name for this exposure.";
        };

        address = lib.mkOption {
          type = lib.types.nonEmptyStr;
          description = "Address on which the corresponding service listens.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          description = "Listener port governed by this exposure.";
        };

        protocols = lib.mkOption {
          type = lib.types.listOf (lib.types.enum [
            "tcp"
            "udp"
          ]);
          description = "Transport protocols governed by this exposure.";
        };

        classification = lib.mkOption {
          type = lib.types.enum [
            "lan-only"
            "proxy-only"
            "tailscale-only"
            "public"
          ];
          description = "Reachability class assigned by inventory policy.";
        };

        sources = firewallPolicy.sourcesOption;

        consumedByProxy = lib.mkOption {
          type = lib.types.bool;
          description = "Whether the central proxy connects to this listener.";
        };
      };
    }
  );

  names = map (exposure: exposure.name) cfg;
  restrictedWithoutSources = map
    (exposure: exposure.name)
    (
      lib.filter
        (
          exposure:
          exposure.classification != "public"
          && exposure.sources == [ ]
        )
        cfg
    );
  publicWithSources = map
    (exposure: exposure.name)
    (
      lib.filter
        (
          exposure:
          exposure.classification == "public"
          && exposure.sources != [ ]
        )
        cfg
    );
  emptyProtocolSets = map
    (exposure: exposure.name)
    (lib.filter (exposure: exposure.protocols == [ ]) cfg);
  duplicateProtocolSets = map
    (exposure: exposure.name)
    (
      lib.filter
        (
          exposure:
          lib.length exposure.protocols
          != lib.length (lib.unique exposure.protocols)
        )
        cfg
    );

  policies = map
    (
      exposure:
      {
        inherit (exposure) sources;
        tcpPorts = lib.optional
          (builtins.elem "tcp" exposure.protocols)
          exposure.port;
        udpPorts = lib.optional
          (builtins.elem "udp" exposure.protocols)
          exposure.port;
      }
    )
    cfg;
in
{
  options.scylla.network.exposures = lib.mkOption {
    type = lib.types.listOf exposureType;
    default = [ ];
    description = ''
      Host firewall policy generated from service and administrative inventory.
      Listener configuration remains owned by the service role.
    '';
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = lib.length names == lib.length (lib.unique names);
          message = "Host exposure names must be unique.";
        }
        {
          assertion = restrictedWithoutSources == [ ];
          message =
            "Restricted host exposures require trusted sources: "
            + lib.concatStringsSep ", " restrictedWithoutSources;
        }
        {
          assertion = publicWithSources == [ ];
          message =
            "Public host exposures cannot retain trusted sources: "
            + lib.concatStringsSep ", " publicWithSources;
        }
        {
          assertion = emptyProtocolSets == [ ];
          message =
            "Host exposures require at least one transport protocol: "
            + lib.concatStringsSep ", " emptyProtocolSets;
        }
        {
          assertion = duplicateProtocolSets == [ ];
          message =
            "Host exposures cannot repeat transport protocols: "
            + lib.concatStringsSep ", " duplicateProtocolSets;
        }
      ];
    }
    (firewallPolicy.mkFirewallPolicies {
      backend = config.networking.firewall.backend;
      inherit policies;
    })
  ];
}
