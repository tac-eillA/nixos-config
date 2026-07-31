{ config, lib }:

let
  sourceType = lib.types.strMatching "[0-9A-Fa-f:.]+(/[0-9]{1,3})?";

  renderIptablesRules =
    { command
    , ports
    , protocol
    , sources
    ,
    }:
    lib.concatMapStrings
      (
        source:
        lib.concatMapStrings
          (
            port: ''
              ${command} -w -A nixos-fw -p ${protocol} -s ${lib.escapeShellArg source} --dport ${toString port} -j nixos-fw-accept
            ''
          )
          ports
      )
      sources;

  renderNftablesRules =
    { addressFamily
    , ports
    , protocol
    , sources
    ,
    }:
    lib.optionalString (sources != [ ] && ports != [ ]) ''
      ${addressFamily} saddr { ${lib.concatStringsSep ", " sources} } ${protocol} dport { ${lib.concatMapStringsSep ", " toString ports} } accept
    '';
in
{
  permittedSourcesOption = lib.mkOption {
    type = lib.types.listOf sourceType;
    default = [ ];
    example = [
      "10.254.1.215/32"
      "fd00::/8"
    ];
    description = ''
      Source addresses or CIDR networks allowed through the firewall. An empty
      list preserves unrestricted access to the role's open ports.
    '';
  };

  mkRoleFirewall =
    { openFirewall
    , permittedSources
    , tcpPorts ? [ ]
    , udpPorts ? [ ]
    ,
    }:
    let
      restricted = openFirewall && permittedSources != [ ];
      ipv4Sources = lib.filter (source: !(lib.hasInfix ":" source)) permittedSources;
      ipv6Sources = lib.filter (source: lib.hasInfix ":" source) permittedSources;
    in
    {
      networking.firewall = {
        allowedTCPPorts = lib.mkIf (openFirewall && !restricted) tcpPorts;
        allowedUDPPorts = lib.mkIf (openFirewall && !restricted) udpPorts;

        extraCommands = lib.mkIf (restricted && config.networking.firewall.backend == "iptables") (
          renderIptablesRules
            {
              command = "iptables";
              ports = tcpPorts;
              protocol = "tcp";
              sources = ipv4Sources;
            }
          + renderIptablesRules {
            command = "iptables";
            ports = udpPorts;
            protocol = "udp";
            sources = ipv4Sources;
          }
          + renderIptablesRules {
            command = "ip6tables";
            ports = tcpPorts;
            protocol = "tcp";
            sources = ipv6Sources;
          }
          + renderIptablesRules {
            command = "ip6tables";
            ports = udpPorts;
            protocol = "udp";
            sources = ipv6Sources;
          }
        );

        extraInputRules = lib.mkIf (restricted && config.networking.firewall.backend == "nftables") (
          renderNftablesRules
            {
              addressFamily = "ip";
              ports = tcpPorts;
              protocol = "tcp";
              sources = ipv4Sources;
            }
          + renderNftablesRules {
            addressFamily = "ip";
            ports = udpPorts;
            protocol = "udp";
            sources = ipv4Sources;
          }
          + renderNftablesRules {
            addressFamily = "ip6";
            ports = tcpPorts;
            protocol = "tcp";
            sources = ipv6Sources;
          }
          + renderNftablesRules {
            addressFamily = "ip6";
            ports = udpPorts;
            protocol = "udp";
            sources = ipv6Sources;
          }
        );
      };
    };
}
