{ hosts, knownRoles, lib, networks, services }:

let
  serviceNames = builtins.attrNames services;
  hostNames = builtins.attrNames hosts;
  declaredNetworks = lib.unique (lib.concatLists (builtins.attrValues networks));

  requiredTopLevelFields = [
    "host"
    "role"
    "listener"
    "exposure"
    "publication"
  ];

  requiredSectionFields = {
    listener = [
      "address"
      "domain"
      "port"
      "protocols"
      "scheme"
    ];
    exposure = [
      "classification"
      "trustedHosts"
      "trustedNetworks"
      "consumedByProxy"
    ];
    publication = [
      "via"
      "domain"
    ];
  };

  missingTopLevelFields = lib.concatMap
    (
      serviceName:
      map (field: "${serviceName}.${field}") (
        lib.filter
          (field: !(builtins.hasAttr field services.${serviceName}))
          requiredTopLevelFields
      )
    )
    serviceNames;

  invalidSections = lib.concatMap
    (
      serviceName:
      map (section: "${serviceName}.${section}") (
        lib.filter
          (section: !builtins.isAttrs services.${serviceName}.${section})
          (builtins.attrNames requiredSectionFields)
      )
    )
    serviceNames;

  missingSectionFields = lib.concatMap
    (
      serviceName:
      lib.concatMap
        (
          section:
          map (field: "${serviceName}.${section}.${field}") (
            lib.filter
              (field: !(builtins.hasAttr field services.${serviceName}.${section}))
              requiredSectionFields.${section}
          )
        )
        (builtins.attrNames requiredSectionFields)
    )
    serviceNames;

  isNonEmptyString = value: builtins.isString value && value != "";
  isNonEmptyStringList =
    value:
    builtins.isList value
    && lib.all isNonEmptyString value;

  invalidFieldTypes = lib.concatMap
    (
      serviceName:
      let
        service = services.${serviceName};
      in
      lib.optional (!isNonEmptyString service.host) "${serviceName}.host"
      ++ lib.optional (!isNonEmptyString service.role) "${serviceName}.role"
      ++ lib.optional (!isNonEmptyString service.listener.address) "${serviceName}.listener.address"
      ++ lib.optional
        (
          service.listener.domain != null
          && !isNonEmptyString service.listener.domain
        )
        "${serviceName}.listener.domain"
      ++ lib.optional (!builtins.isInt service.listener.port) "${serviceName}.listener.port"
      ++ lib.optional
        (!isNonEmptyStringList service.listener.protocols)
        "${serviceName}.listener.protocols"
      ++ lib.optional (!isNonEmptyString service.listener.scheme) "${serviceName}.listener.scheme"
      ++ lib.optional
        (!isNonEmptyString service.exposure.classification)
        "${serviceName}.exposure.classification"
      ++ lib.optional
        (!isNonEmptyStringList service.exposure.trustedHosts)
        "${serviceName}.exposure.trustedHosts"
      ++ lib.optional
        (!isNonEmptyStringList service.exposure.trustedNetworks)
        "${serviceName}.exposure.trustedNetworks"
      ++ lib.optional
        (!builtins.isBool service.exposure.consumedByProxy)
        "${serviceName}.exposure.consumedByProxy"
      ++ lib.optional (!isNonEmptyString service.publication.via) "${serviceName}.publication.via"
      ++ lib.optional
        (
          service.publication.domain != null
          && !isNonEmptyString service.publication.domain
        )
        "${serviceName}.publication.domain"
    )
    serviceNames;

  invalidPorts = lib.filter
    (
      serviceName:
      let
        port = services.${serviceName}.listener.port;
      in
      port < 1 || port > 65535
    )
    serviceNames;

  undeclaredHosts = lib.filter
    (serviceName: !(builtins.hasAttr services.${serviceName}.host hosts))
    serviceNames;

  nonDeployableHosts = lib.filter
    (
      serviceName:
      let
        hostname = services.${serviceName}.host;
      in
      builtins.hasAttr hostname hosts && !hosts.${hostname}.deployable
    )
    serviceNames;

  unknownRoles = lib.filter
    (serviceName: !(builtins.elem services.${serviceName}.role knownRoles))
    serviceNames;

  disabledDestinationRoles = lib.filter
    (
      serviceName:
      let
        service = services.${serviceName};
      in
      builtins.hasAttr service.host hosts
      && !(builtins.elem service.role hosts.${service.host}.roles)
    )
    serviceNames;

  allowedProtocols = [
    "tcp"
    "udp"
  ];

  allowedSchemes = [
    "dns"
    "http"
    "https"
    "tcp"
  ];

  allowedPublishers = [
    "cloudflare"
    "none"
  ];

  allowedClassifications = [
    "lan-only"
    "proxy-only"
    "tailscale-only"
    "public"
  ];

  unknownProtocols = lib.concatMap
    (
      serviceName:
      map (protocol: "${serviceName}:${protocol}") (
        lib.filter
          (protocol: !(builtins.elem protocol allowedProtocols))
          services.${serviceName}.listener.protocols
      )
    )
    serviceNames;

  duplicateProtocols = lib.filter
    (
      serviceName:
      let
        protocols = services.${serviceName}.listener.protocols;
      in
      lib.length protocols != lib.length (lib.unique protocols)
    )
    serviceNames;

  unknownSchemes = lib.filter
    (
      serviceName:
        !(builtins.elem services.${serviceName}.listener.scheme allowedSchemes)
    )
    serviceNames;

  unknownPublishers = lib.filter
    (
      serviceName:
        !(builtins.elem services.${serviceName}.publication.via allowedPublishers)
    )
    serviceNames;

  unknownClassifications = lib.filter
    (
      serviceName:
        !(builtins.elem
          services.${serviceName}.exposure.classification
          allowedClassifications)
    )
    serviceNames;

  invalidListenerAddresses = lib.filter
    (
      serviceName:
      let
        service = services.${serviceName};
        hostAddress =
          if builtins.hasAttr service.host hosts
          then hosts.${service.host}.address or null
          else null;
      in
        !(builtins.elem service.listener.address (
          [
            "0.0.0.0"
            "::"
            "127.0.0.1"
            "::1"
          ]
          ++ lib.optional (hostAddress != null) hostAddress
        ))
    )
    serviceNames;

  undeclaredTrustedHosts = lib.concatMap
    (
      serviceName:
      map (hostname: "${serviceName}:${hostname}") (
        lib.filter
          (hostname: !(builtins.hasAttr hostname hosts))
          services.${serviceName}.exposure.trustedHosts
      )
    )
    serviceNames;

  unusableTrustedHosts = lib.concatMap
    (
      serviceName:
      map (hostname: "${serviceName}:${hostname}") (
        lib.filter
          (
            hostname:
            builtins.hasAttr hostname hosts
            && (
              !hosts.${hostname}.deployable
              || (hosts.${hostname}.address or null) == null
            )
          )
          services.${serviceName}.exposure.trustedHosts
      )
    )
    serviceNames;

  undeclaredTrustedNetworks = lib.concatMap
    (
      serviceName:
      map (network: "${serviceName}:${network}") (
        lib.filter
          (network: !(builtins.elem network declaredNetworks))
          services.${serviceName}.exposure.trustedNetworks
      )
    )
    serviceNames;

  proxyHosts = lib.filter
    (
      hostname:
      hosts.${hostname}.deployable
      && builtins.elem "proxy" hosts.${hostname}.roles
    )
    hostNames;

  sourceForHost =
    hostname:
    let
      address = hosts.${hostname}.address;
    in
    "${address}/${if lib.hasInfix ":" address then "128" else "32"}";

  resolvedSources =
    service:
    lib.unique (
      lib.concatMap
        (
          hostname:
          if
            builtins.hasAttr hostname hosts
            && hosts.${hostname}.deployable
            && (hosts.${hostname}.address or null) != null
          then [ (sourceForHost hostname) ]
          else [ ]
        )
        service.exposure.trustedHosts
      ++ service.exposure.trustedNetworks
    );

  restrictedWithoutSources = lib.filter
    (
      serviceName:
      services.${serviceName}.exposure.classification != "public"
      && resolvedSources services.${serviceName} == [ ]
    )
    serviceNames;

  publicWithTrustedSources = lib.filter
    (
      serviceName:
      services.${serviceName}.exposure.classification == "public"
      && resolvedSources services.${serviceName} != [ ]
    )
    serviceNames;

  lanPolicyDrift = lib.filter
    (
      serviceName:
      let
        exposure = services.${serviceName}.exposure;
      in
      exposure.classification == "lan-only"
      && (
        exposure.trustedHosts != [ ]
        || lib.any
          (network: !(builtins.elem network networks.lan))
          exposure.trustedNetworks
      )
    )
    serviceNames;

  tailscalePolicyDrift = lib.filter
    (
      serviceName:
      let
        exposure = services.${serviceName}.exposure;
      in
      exposure.classification == "tailscale-only"
      && (
        exposure.trustedHosts != [ ]
        || lib.any
          (network: !(builtins.elem network networks.tailscale))
          exposure.trustedNetworks
      )
    )
    serviceNames;

  proxyPolicyDrift = lib.filter
    (
      serviceName:
      let
        exposure = services.${serviceName}.exposure;
      in
      exposure.classification == "proxy-only"
      && (
        lib.sort builtins.lessThan exposure.trustedHosts
        != lib.sort builtins.lessThan proxyHosts
        || exposure.trustedNetworks != [ ]
        || !exposure.consumedByProxy
      )
    )
    serviceNames;

  proxyConsumersWithoutTrust = lib.filter
    (
      serviceName:
      let
        exposure = services.${serviceName}.exposure;
      in
      exposure.consumedByProxy
      && lib.any
        (proxyHost: !(builtins.elem proxyHost exposure.trustedHosts))
        proxyHosts
    )
    serviceNames;

  publicProxyConsumers = lib.filter
    (
      serviceName:
      services.${serviceName}.exposure.classification == "public"
      && services.${serviceName}.exposure.consumedByProxy
    )
    serviceNames;

  proxyConsumersWithLoopbackListeners = lib.filter
    (
      serviceName:
      services.${serviceName}.exposure.consumedByProxy
      && builtins.elem services.${serviceName}.listener.address [
        "127.0.0.1"
        "::1"
      ]
    )
    serviceNames;

  protocolSetEquals =
    actual: expected:
    lib.sort builtins.lessThan actual
    == lib.sort builtins.lessThan expected;

  unsupportedProtocolCombinations = lib.filter
    (
      serviceName:
      let
        listener = services.${serviceName}.listener;
      in
      (
        listener.port == 53
        && builtins.elem listener.scheme [
          "http"
          "https"
        ]
      )
      || (
        listener.scheme == "dns"
        && (
          listener.port != 53
          || !(protocolSetEquals listener.protocols [
            "tcp"
            "udp"
          ])
        )
      )
      || (
        builtins.elem listener.scheme [
          "http"
          "https"
        ]
        && !(protocolSetEquals listener.protocols [ "tcp" ])
      )
      || (
        listener.scheme == "tcp"
        && !(protocolSetEquals listener.protocols [ "tcp" ])
      )
    )
    serviceNames;

  listenerSocketKeys = lib.concatMap
    (
      serviceName:
      let
        service = services.${serviceName};
      in
      map
        (
          protocol:
          "${service.host}|${service.listener.address}|${toString service.listener.port}|${protocol}"
        )
        service.listener.protocols
    )
    serviceNames;

  duplicateListenerSockets = lib.unique (
    lib.filter
      (
        socket:
        lib.length (lib.filter (candidate: candidate == socket) listenerSocketKeys) > 1
      )
      listenerSocketKeys
  );

  cloudflareServiceNames = lib.filter
    (serviceName: services.${serviceName}.publication.via == "cloudflare")
    serviceNames;

  cloudflareWithoutDomains = lib.filter
    (serviceName: services.${serviceName}.publication.domain == null)
    cloudflareServiceNames;

  cloudflareWithoutProxyPolicy = lib.filter
    (
      serviceName:
      let
        service = services.${serviceName};
      in
      service.exposure.classification != "proxy-only"
      || !service.exposure.consumedByProxy
    )
    cloudflareServiceNames;

  cloudflareDomainMismatches = lib.filter
    (
      serviceName:
      services.${serviceName}.publication.domain
      != services.${serviceName}.listener.domain
    )
    cloudflareServiceNames;

  nonPublishedWithDomains = lib.filter
    (
      serviceName:
      services.${serviceName}.publication.via == "none"
      && services.${serviceName}.publication.domain != null
    )
    serviceNames;

  unsupportedCloudflareSchemes = lib.filter
    (
      serviceName:
        !(builtins.elem services.${serviceName}.listener.scheme [
          "http"
          "https"
          "tcp"
        ])
    )
    cloudflareServiceNames;

  cloudflareWithoutAddresses = lib.filter
    (
      serviceName:
      let
        hostname = services.${serviceName}.host;
      in
      !(builtins.hasAttr hostname hosts) || (hosts.${hostname}.address or null) == null
    )
    cloudflareServiceNames;

  publicDomains = map
    (serviceName: lib.toLower services.${serviceName}.publication.domain)
    cloudflareServiceNames;

  duplicatePublicDomains = lib.unique (
    lib.filter
      (
        domain:
        lib.length (lib.filter (candidate: candidate == domain) publicDomains) > 1
      )
      publicDomains
  );

  inventoryManagedListenerRoles = [
    "authentik"
    "forgejo"
    "headscale"
    "paperless-ngx"
    "vaultwarden"
  ];

  inventoryManagedListenerNames = lib.filter
    (
      serviceName:
      builtins.elem
        services.${serviceName}.role
        inventoryManagedListenerRoles
    )
    serviceNames;

  duplicateManagedRoleListeners = lib.unique (
    lib.filter
      (
        hostRole:
        lib.length
          (
            lib.filter
              (
                serviceName:
                "${services.${serviceName}.host}:${services.${serviceName}.role}" == hostRole
              )
              inventoryManagedListenerNames
          ) > 1
      )
      (map
        (
          serviceName:
          "${services.${serviceName}.host}:${services.${serviceName}.role}"
        )
        inventoryManagedListenerNames)
  );

  managedListenersWithoutDomains = lib.filter
    (
      serviceName:
      services.${serviceName}.listener.domain == null
    )
    inventoryManagedListenerNames;

  enabledManagedHostRoles = lib.concatMap
    (
      hostname:
      map (role: "${hostname}:${role}") (
        lib.filter
          (role: builtins.elem role inventoryManagedListenerRoles)
          hosts.${hostname}.roles
      )
    )
    hostNames;

  managedRolesWithoutListeners = lib.filter
    (
      hostRole:
        !(builtins.elem hostRole (
          map
            (
              serviceName:
              "${services.${serviceName}.host}:${services.${serviceName}.role}"
            )
            inventoryManagedListenerNames
        ))
    )
    enabledManagedHostRoles;

  validatedServices =
    assert lib.assertMsg
      (missingTopLevelFields == [ ])
      "Services missing required fields: ${lib.concatStringsSep ", " missingTopLevelFields}";
    assert lib.assertMsg
      (invalidSections == [ ])
      "Service sections must be attribute sets: ${lib.concatStringsSep ", " invalidSections}";
    assert lib.assertMsg
      (missingSectionFields == [ ])
      "Service sections missing required fields: ${lib.concatStringsSep ", " missingSectionFields}";
    assert lib.assertMsg
      (invalidFieldTypes == [ ])
      "Services contain invalid field types: ${lib.concatStringsSep ", " invalidFieldTypes}";
    assert lib.assertMsg
      (invalidPorts == [ ])
      "Services contain invalid listener ports: ${lib.concatStringsSep ", " invalidPorts}";
    assert lib.assertMsg
      (undeclaredHosts == [ ])
      "Services reference undeclared hosts: ${lib.concatStringsSep ", " undeclaredHosts}";
    assert lib.assertMsg
      (nonDeployableHosts == [ ])
      "Services reference non-deployable hosts: ${lib.concatStringsSep ", " nonDeployableHosts}";
    assert lib.assertMsg
      (unknownRoles == [ ])
      "Services reference unknown roles: ${lib.concatStringsSep ", " unknownRoles}";
    assert lib.assertMsg
      (disabledDestinationRoles == [ ])
      "Services reference roles disabled on their destination: ${lib.concatStringsSep ", " disabledDestinationRoles}";
    assert lib.assertMsg
      (unknownProtocols == [ ])
      "Services use unknown transport protocols: ${lib.concatStringsSep ", " unknownProtocols}";
    assert lib.assertMsg
      (duplicateProtocols == [ ])
      "Services repeat transport protocols: ${lib.concatStringsSep ", " duplicateProtocols}";
    assert lib.assertMsg
      (unknownSchemes == [ ])
      "Services use unknown application schemes: ${lib.concatStringsSep ", " unknownSchemes}";
    assert lib.assertMsg
      (unknownPublishers == [ ])
      "Services use unknown publication methods: ${lib.concatStringsSep ", " unknownPublishers}";
    assert lib.assertMsg
      (unknownClassifications == [ ])
      "Services use unknown exposure classifications: ${lib.concatStringsSep ", " unknownClassifications}";
    assert lib.assertMsg
      (invalidListenerAddresses == [ ])
      "Services use listener addresses outside their destination host: ${lib.concatStringsSep ", " invalidListenerAddresses}";
    assert lib.assertMsg
      (undeclaredTrustedHosts == [ ])
      "Services trust undeclared hosts: ${lib.concatStringsSep ", " undeclaredTrustedHosts}";
    assert lib.assertMsg
      (unusableTrustedHosts == [ ])
      "Services trust hosts without deployable addresses: ${lib.concatStringsSep ", " unusableTrustedHosts}";
    assert lib.assertMsg
      (undeclaredTrustedNetworks == [ ])
      "Services trust networks absent from network inventory: ${lib.concatStringsSep ", " undeclaredTrustedNetworks}";
    assert lib.assertMsg
      (restrictedWithoutSources == [ ])
      "Restricted services require trusted sources: ${lib.concatStringsSep ", " restrictedWithoutSources}";
    assert lib.assertMsg
      (publicWithTrustedSources == [ ])
      "Public services cannot retain trusted-source restrictions: ${lib.concatStringsSep ", " publicWithTrustedSources}";
    assert lib.assertMsg
      (lanPolicyDrift == [ ])
      "LAN-only services may trust only declared LAN networks: ${lib.concatStringsSep ", " lanPolicyDrift}";
    assert lib.assertMsg
      (tailscalePolicyDrift == [ ])
      "Tailscale-only services may trust only declared Tailscale networks: ${lib.concatStringsSep ", " tailscalePolicyDrift}";
    assert lib.assertMsg
      (proxyPolicyDrift == [ ])
      "Proxy-only services must trust exactly the deployable proxy and be consumed by it: ${lib.concatStringsSep ", " proxyPolicyDrift}";
    assert lib.assertMsg
      (proxyConsumersWithoutTrust == [ ])
      "Proxy-consumed services must trust every deployable proxy: ${lib.concatStringsSep ", " proxyConsumersWithoutTrust}";
    assert lib.assertMsg
      (publicProxyConsumers == [ ])
      "Public listeners cannot also be classified as proxy-consumed backends: ${lib.concatStringsSep ", " publicProxyConsumers}";
    assert lib.assertMsg
      (proxyConsumersWithLoopbackListeners == [ ])
      "Proxy-consumed listeners cannot bind only to loopback: ${lib.concatStringsSep ", " proxyConsumersWithLoopbackListeners}";
    assert lib.assertMsg
      (unsupportedProtocolCombinations == [ ])
      "Services use unsupported listener scheme, port, or protocol combinations: ${lib.concatStringsSep ", " unsupportedProtocolCombinations}";
    assert lib.assertMsg
      (duplicateListenerSockets == [ ])
      "Services declare duplicate listener sockets: ${lib.concatStringsSep ", " duplicateListenerSockets}";
    assert lib.assertMsg
      (cloudflareWithoutDomains == [ ])
      "Cloudflare services lack public domains: ${lib.concatStringsSep ", " cloudflareWithoutDomains}";
    assert lib.assertMsg
      (cloudflareWithoutProxyPolicy == [ ])
      "Cloudflare origins must use proxy-only exposure: ${lib.concatStringsSep ", " cloudflareWithoutProxyPolicy}";
    assert lib.assertMsg
      (cloudflareDomainMismatches == [ ])
      "Cloudflare publication domains must match listener domains: ${lib.concatStringsSep ", " cloudflareDomainMismatches}";
    assert lib.assertMsg
      (nonPublishedWithDomains == [ ])
      "Non-published services retain public domains: ${lib.concatStringsSep ", " nonPublishedWithDomains}";
    assert lib.assertMsg
      (unsupportedCloudflareSchemes == [ ])
      "Cloudflare services use unsupported origin schemes: ${lib.concatStringsSep ", " unsupportedCloudflareSchemes}";
    assert lib.assertMsg
      (cloudflareWithoutAddresses == [ ])
      "Cloudflare services require destination addresses: ${lib.concatStringsSep ", " cloudflareWithoutAddresses}";
    assert lib.assertMsg
      (duplicatePublicDomains == [ ])
      "Duplicate public service domains: ${lib.concatStringsSep ", " duplicatePublicDomains}";
    assert lib.assertMsg
      (duplicateManagedRoleListeners == [ ])
      "Roles with generated listeners require exactly one service: ${lib.concatStringsSep ", " duplicateManagedRoleListeners}";
    assert lib.assertMsg
      (managedListenersWithoutDomains == [ ])
      "Roles with generated listeners require a domain: ${lib.concatStringsSep ", " managedListenersWithoutDomains}";
    assert lib.assertMsg
      (managedRolesWithoutListeners == [ ])
      "Inventory-managed roles require exactly one service listener: ${lib.concatStringsSep ", " managedRolesWithoutListeners}";
    assert lib.assertMsg
      (
        cloudflareServiceNames == [ ]
        || lib.length proxyHosts == 1
      )
      "Cloudflare publication requires exactly one deployable proxy role";
    services;

  validatedServiceNames = builtins.attrNames validatedServices;

  publishedServiceNames = lib.filter
    (
      serviceName:
      validatedServices.${serviceName}.publication.via == "cloudflare"
    )
    validatedServiceNames;

  publishedServices = lib.genAttrs publishedServiceNames
    (serviceName: validatedServices.${serviceName});

  cloudflareIngress = builtins.listToAttrs (
    map
      (
        serviceName:
        let
          service = publishedServices.${serviceName};
          address = hosts.${service.host}.address;
        in
        {
          name = service.publication.domain;
          value =
            "${service.listener.scheme}://${address}:"
            + toString service.listener.port;
        }
      )
      publishedServiceNames
  );

  servicesForHost =
    hostname:
    lib.filter
      (serviceName: validatedServices.${serviceName}.host == hostname)
      validatedServiceNames;

  roleSettingsByHost = lib.genAttrs hostNames
    (
      hostname:
      lib.genAttrs hosts.${hostname}.roles
        (
          role:
          let
            matches = lib.filter
              (
                serviceName:
                validatedServices.${serviceName}.host == hostname
                && validatedServices.${serviceName}.role == role
              )
              inventoryManagedListenerNames;
          in
          if builtins.elem role inventoryManagedListenerRoles && matches != [ ]
          then
            let
              service = validatedServices.${lib.head matches};
            in
            {
              domain = service.listener.domain;
              listenAddress = service.listener.address;
              port = service.listener.port;
            }
          else { }
        )
    );

  exposuresByHost = lib.genAttrs hostNames
    (
      hostname:
      map
        (
          serviceName:
          let
            service = validatedServices.${serviceName};
          in
          {
            name = serviceName;
            inherit (service.listener) address port protocols;
            inherit (service.exposure) classification consumedByProxy;
            sources = resolvedSources service;
          }
        )
        (servicesForHost hostname)
    );
in
{
  services = validatedServices;
  inherit
    cloudflareIngress
    exposuresByHost
    proxyHosts
    publishedServices
    roleSettingsByHost
    ;
}
