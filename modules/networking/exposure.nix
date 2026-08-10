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
          description = "Unique name for this firewall exposure.";
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

        sources = firewallPolicy.sourcesOption;
      };
    }
  );

  names = map (exposure: exposure.name) cfg;
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
      Host firewall rules declared by the host configuration. An empty source
      list opens the port publicly. Service roles own listener configuration.
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
