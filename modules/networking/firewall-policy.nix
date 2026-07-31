{ lib }:

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
  sourcesOption = lib.mkOption {
    type = lib.types.listOf sourceType;
    default = [ ];
    example = [
      "10.254.1.215/32"
      "fd00::/8"
    ];
    description = ''
      Source addresses or CIDR networks allowed through the firewall. An empty
      list represents an explicitly public exposure.
    '';
  };

  mkFirewallPolicies =
    { backend
    , policies
    ,
    }:
    let
      publicPolicies = lib.filter (policy: policy.sources == [ ]) policies;
      restrictedPolicies = lib.filter (policy: policy.sources != [ ]) policies;

      renderIptablesPolicy =
        policy:
        let
          ipv4Sources = lib.filter
            (source: !(lib.hasInfix ":" source))
            policy.sources;
          ipv6Sources = lib.filter
            (source: lib.hasInfix ":" source)
            policy.sources;
        in
        renderIptablesRules
          {
            command = "iptables";
            ports = policy.tcpPorts;
            protocol = "tcp";
            sources = ipv4Sources;
          }
        + renderIptablesRules {
          command = "iptables";
          ports = policy.udpPorts;
          protocol = "udp";
          sources = ipv4Sources;
        }
        + renderIptablesRules {
          command = "ip6tables";
          ports = policy.tcpPorts;
          protocol = "tcp";
          sources = ipv6Sources;
        }
        + renderIptablesRules {
          command = "ip6tables";
          ports = policy.udpPorts;
          protocol = "udp";
          sources = ipv6Sources;
        };

      renderNftablesPolicy =
        policy:
        let
          ipv4Sources = lib.filter
            (source: !(lib.hasInfix ":" source))
            policy.sources;
          ipv6Sources = lib.filter
            (source: lib.hasInfix ":" source)
            policy.sources;
        in
        renderNftablesRules
          {
            addressFamily = "ip";
            ports = policy.tcpPorts;
            protocol = "tcp";
            sources = ipv4Sources;
          }
        + renderNftablesRules {
          addressFamily = "ip";
          ports = policy.udpPorts;
          protocol = "udp";
          sources = ipv4Sources;
        }
        + renderNftablesRules {
          addressFamily = "ip6";
          ports = policy.tcpPorts;
          protocol = "tcp";
          sources = ipv6Sources;
        }
        + renderNftablesRules {
          addressFamily = "ip6";
          ports = policy.udpPorts;
          protocol = "udp";
          sources = ipv6Sources;
        };
    in
    {
      networking.firewall = {
        allowedTCPPorts = lib.unique (
          lib.concatMap (policy: policy.tcpPorts) publicPolicies
        );
        allowedUDPPorts = lib.unique (
          lib.concatMap (policy: policy.udpPorts) publicPolicies
        );

        extraCommands = lib.mkIf (backend == "iptables") (
          lib.concatMapStrings renderIptablesPolicy restrictedPolicies
        );

        extraInputRules = lib.mkIf (backend == "nftables") (
          lib.concatMapStrings renderNftablesPolicy restrictedPolicies
        );
      };
    };
}
