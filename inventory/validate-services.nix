{ hosts, knownRoles, lib, services }:

let
  serviceNames = builtins.attrNames services;
  hostNames = builtins.attrNames hosts;

  requiredFields = [
    "host"
    "role"
    "scheme"
    "port"
    "publishVia"
    "exposure"
  ];

  requiredTextFields = [
    "host"
    "role"
    "scheme"
    "publishVia"
    "exposure"
  ];

  missingRequiredFields = lib.concatMap
    (
      serviceName:
      map (field: "${serviceName}.${field}") (
        lib.filter
          (field: !(builtins.hasAttr field services.${serviceName}))
          requiredFields
      )
    )
    serviceNames;

  invalidTextFields = lib.concatMap
    (
      serviceName:
      map (field: "${serviceName}.${field}") (
        lib.filter
          (
            field:
            !builtins.isString services.${serviceName}.${field}
            || services.${serviceName}.${field} == ""
          )
          requiredTextFields
      )
    )
    serviceNames;

  invalidPorts = lib.filter
    (
      serviceName:
      let
        port = services.${serviceName}.port;
      in
      !builtins.isInt port || port < 1 || port > 65535
    )
    serviceNames;

  undeclaredHosts = lib.filter
    (
      serviceName:
        !(builtins.hasAttr services.${serviceName}.host hosts)
    )
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
    (
      serviceName:
        !(builtins.elem services.${serviceName}.role knownRoles)
    )
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

  allowedExposures = [
    "lan"
    "private"
    "public"
  ];

  unknownSchemes = lib.filter
    (serviceName: !(builtins.elem services.${serviceName}.scheme allowedSchemes))
    serviceNames;

  unknownPublishers = lib.filter
    (serviceName: !(builtins.elem services.${serviceName}.publishVia allowedPublishers))
    serviceNames;

  unknownExposures = lib.filter
    (serviceName: !(builtins.elem services.${serviceName}.exposure allowedExposures))
    serviceNames;

  domainOf = service: service.publicDomain or null;

  invalidDomains = lib.filter
    (
      serviceName:
      let
        domain = domainOf services.${serviceName};
      in
      domain != null && (!builtins.isString domain || domain == "")
    )
    serviceNames;

  cloudflareServiceNames = lib.filter
    (serviceName: services.${serviceName}.publishVia == "cloudflare")
    serviceNames;

  cloudflareWithoutDomains = lib.filter
    (serviceName: domainOf services.${serviceName} == null)
    cloudflareServiceNames;

  cloudflareWithoutPublicExposure = lib.filter
    (serviceName: services.${serviceName}.exposure != "public")
    cloudflareServiceNames;

  publicWithoutPublisher = lib.filter
    (
      serviceName:
      services.${serviceName}.exposure == "public"
      && services.${serviceName}.publishVia != "cloudflare"
    )
    serviceNames;

  nonPublishedWithDomains = lib.filter
    (
      serviceName:
      services.${serviceName}.publishVia == "none"
      && domainOf services.${serviceName} != null
    )
    serviceNames;

  unsupportedProtocolCombinations = lib.filter
    (
      serviceName:
      let
        service = services.${serviceName};
      in
      (service.port == 53 && builtins.elem service.scheme [
        "http"
        "https"
      ])
      || (service.scheme == "dns" && service.port != 53)
      || (
        service.publishVia == "cloudflare"
        && !(builtins.elem service.scheme [
          "http"
          "https"
          "tcp"
        ])
      )
    )
    serviceNames;

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
    (serviceName: lib.toLower (domainOf services.${serviceName}))
    cloudflareServiceNames;

  duplicatePublicDomains = lib.unique (
    lib.filter
      (
        domain:
        lib.length (lib.filter (candidate: candidate == domain) publicDomains) > 1
      )
      publicDomains
  );

  mismatchedRoleSettings = lib.filter
    (
      serviceName:
      let
        service = services.${serviceName};
        roleSettings =
          if builtins.hasAttr service.host hosts
          then hosts.${service.host}.roleSettings.${service.role} or { }
          else { };
        domain = domainOf service;
      in
      (roleSettings ? port && roleSettings.port != service.port)
      || (
        roleSettings ? domain
        && domain != null
        && roleSettings.domain != domain
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

  validatedServices =
    assert lib.assertMsg
      (missingRequiredFields == [ ])
      "Services missing required fields: ${lib.concatStringsSep ", " missingRequiredFields}";
    assert lib.assertMsg
      (invalidTextFields == [ ])
      "Services with invalid text fields: ${lib.concatStringsSep ", " invalidTextFields}";
    assert lib.assertMsg
      (invalidPorts == [ ])
      "Services with invalid ports: ${lib.concatStringsSep ", " invalidPorts}";
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
      (unknownSchemes == [ ])
      "Services use unknown schemes: ${lib.concatStringsSep ", " unknownSchemes}";
    assert lib.assertMsg
      (unknownPublishers == [ ])
      "Services use unknown publication methods: ${lib.concatStringsSep ", " unknownPublishers}";
    assert lib.assertMsg
      (unknownExposures == [ ])
      "Services lack an explicit supported exposure policy: ${lib.concatStringsSep ", " unknownExposures}";
    assert lib.assertMsg
      (invalidDomains == [ ])
      "Services have invalid public domains: ${lib.concatStringsSep ", " invalidDomains}";
    assert lib.assertMsg
      (cloudflareWithoutDomains == [ ])
      "Cloudflare services lack public domains: ${lib.concatStringsSep ", " cloudflareWithoutDomains}";
    assert lib.assertMsg
      (cloudflareWithoutPublicExposure == [ ])
      "Cloudflare services must declare public exposure: ${lib.concatStringsSep ", " cloudflareWithoutPublicExposure}";
    assert lib.assertMsg
      (publicWithoutPublisher == [ ])
      "Public services lack a supported publication policy: ${lib.concatStringsSep ", " publicWithoutPublisher}";
    assert lib.assertMsg
      (nonPublishedWithDomains == [ ])
      "Non-published services retain public domains: ${lib.concatStringsSep ", " nonPublishedWithDomains}";
    assert lib.assertMsg
      (unsupportedProtocolCombinations == [ ])
      "Services use unsupported protocol and port combinations: ${lib.concatStringsSep ", " unsupportedProtocolCombinations}";
    assert lib.assertMsg
      (cloudflareWithoutAddresses == [ ])
      "Cloudflare services require destination addresses: ${lib.concatStringsSep ", " cloudflareWithoutAddresses}";
    assert lib.assertMsg
      (duplicatePublicDomains == [ ])
      "Duplicate public service domains: ${lib.concatStringsSep ", " duplicatePublicDomains}";
    assert lib.assertMsg
      (mismatchedRoleSettings == [ ])
      "Service inventory disagrees with destination role settings: ${lib.concatStringsSep ", " mismatchedRoleSettings}";
    assert lib.assertMsg
      (cloudflareServiceNames == [ ] || lib.length proxyHosts == 1)
      "Cloudflare publication requires exactly one deployable proxy role";
    services;

  publishedServiceNames = lib.filter
    (serviceName: validatedServices.${serviceName}.publishVia == "cloudflare")
    (builtins.attrNames validatedServices);

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
          name = service.publicDomain;
          value = "${service.scheme}://${address}:${toString service.port}";
        }
      )
      publishedServiceNames
  );
in
{
  services = validatedServices;
  inherit cloudflareIngress proxyHosts publishedServices;
}
