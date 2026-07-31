{ config, lib, ... }:

let
  cfg = config.scylla.roles.technitium-dns;
  roleLib = import ../lib.nix { inherit config lib; };
in
{
  options.scylla.roles.technitium-dns = {
    enable = lib.mkEnableOption "the Technitium DNS workload";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to allow configured DNS and dashboard ports.";
    };

    permittedSources = roleLib.permittedSourcesOption;

    tcpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [
        53
        5380
        53443
      ];
      description = "TCP ports used by DNS and the administrative interfaces.";
    };

    udpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ 53 ];
      description = "UDP ports used by DNS.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.tcpPorts != [ ] && cfg.udpPorts != [ ];
            message = "The Technitium DNS role requires at least one TCP and UDP port.";
          }
        ];

        services.technitium-dns-server = {
          enable = true;
          openFirewall = cfg.openFirewall && cfg.permittedSources == [ ];
          firewallTCPPorts = cfg.tcpPorts;
          firewallUDPPorts = cfg.udpPorts;
        };
      }
      (lib.mkIf (cfg.permittedSources != [ ]) (roleLib.mkRoleFirewall {
        inherit (cfg) permittedSources;
        openFirewall = cfg.openFirewall;
        tcpPorts = cfg.tcpPorts;
        udpPorts = cfg.udpPorts;
      }))
    ]
  );
}
