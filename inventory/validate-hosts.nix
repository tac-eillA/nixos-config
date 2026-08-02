{ hosts
, knownFeatures
, knownHardwareModules
, knownProfiles
, knownRoles
, lib
, networks
, workstationOnlyFeatures
,
}:

let
  validation = import ./validation-helpers.nix { inherit lib; };
  hostNames = builtins.attrNames hosts;
  hostsPath = ../hosts;
  hostDirectories = builtins.readDir hostsPath;
  configuredHostDirectories = lib.filter
    (
      hostname:
      hostDirectories.${hostname} == "directory"
      && builtins.pathExists (hostsPath + "/${hostname}/configuration.nix")
    )
    (builtins.attrNames hostDirectories);

  addresses = lib.filter (address: address != null) (
    map (hostname: hosts.${hostname}.address or null) hostNames
  );

  duplicateAddresses = lib.unique (
    lib.filter
      (
        address: lib.length (lib.filter (candidate: candidate == address) addresses) > 1
      )
      addresses
  );

  unknownProfiles = lib.filter
    (hostname: !(builtins.elem hosts.${hostname}.profile knownProfiles))
    hostNames;

  unknownRoles = lib.concatMap
    (
      hostname:
      map (role: "${hostname}:${role}") (
        lib.filter (role: !(builtins.elem role knownRoles)) hosts.${hostname}.roles
      )
    )
    hostNames;

  unknownFeatures = lib.concatMap
    (
      hostname:
      map (feature: "${hostname}:${feature}") (
        lib.filter
          (feature: !(builtins.elem feature knownFeatures))
          hosts.${hostname}.features
      )
    )
    hostNames;

  duplicateFeatures = lib.filter
    (
      hostname:
      let
        features = hosts.${hostname}.features;
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
            hosts.${hostname}.profile != "workstation"
            && builtins.elem feature workstationOnlyFeatures
          )
          hosts.${hostname}.features
      )
    )
    hostNames;

  invalidFeatureDependencies = lib.concatMap
    (
      hostname:
      let
        features = hosts.${hostname}.features;
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
          (hardwareModule: !(builtins.elem hardwareModule knownHardwareModules))
          (hosts.${hostname}.hardwareModules or [ ])
      )
    )
    hostNames;

  mismatchedRoleSettings = lib.filter
    (
      hostname:
      let
        settings = builtins.attrNames (hosts.${hostname}.roleSettings or { });
      in
      lib.any (role: !(builtins.elem role hosts.${hostname}.roles)) settings
    )
    hostNames;

  manualProxyIngress = lib.filter
    (
      hostname:
      builtins.hasAttr "ingress" (hosts.${hostname}.roleSettings.proxy or { })
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
                builtins.hasAttr setting (hosts.${hostname}.roleSettings.${role} or { })
              )
              inventoryManagedRoleSettings
          )
        )
        hosts.${hostname}.roles
    )
    hostNames;

  deployableServerNames = lib.filter
    (hostname: hosts.${hostname}.deployable && hosts.${hostname}.profile == "server")
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
        hosts.${hostname}
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
            hosts.${hostname}
        )
    )
    deployableServerNames;

  undeclaredAdministrativeNetworks = lib.filter
    (
      network:
        !(builtins.elem network (
          lib.concatLists (builtins.attrValues networks)
        ))
    )
    administrativeNetworks;

  missingHostConfigurations = lib.filter
    (
      hostname:
        !(builtins.pathExists (hostsPath + "/${hostname}/configuration.nix"))
    )
    hostNames;

  unregisteredHostDirectories = lib.subtractLists hostNames configuredHostDirectories;

  placeholderDeployments = lib.filter
    (
      hostname:
      hosts.${hostname}.deployable
      && builtins.pathExists (hostsPath + "/${hostname}/hardware-configuration.nix")
      && lib.hasInfix "replace-me-root" (
        builtins.readFile (hostsPath + "/${hostname}/hardware-configuration.nix")
      )
    )
    hostNames;
in
validation.assertChecks [
  (validation.checkEmpty "Duplicate inventory addresses" duplicateAddresses)
  (validation.checkEmpty "Unknown inventory profiles" unknownProfiles)
  (validation.checkEmpty "Unknown inventory roles" unknownRoles)
  (validation.checkEmpty "Unknown inventory features" unknownFeatures)
  (validation.checkEmpty "Inventory hosts repeat features" duplicateFeatures)
  (validation.checkEmpty "Features incompatible with host profiles" incompatibleProfileFeatures)
  (validation.checkEmpty "Invalid feature dependencies" invalidFeatureDependencies)
  (validation.checkEmpty "Unknown inventory hardware modules" unknownHardwareModules)
  (validation.checkEmpty "Role settings exist for disabled roles on" mismatchedRoleSettings)
  (validation.checkEmpty "Proxy ingress must be generated from service inventory, not set on" manualProxyIngress)
  (validation.checkEmpty "Service listeners must be generated from service inventory, not set on" manualServiceListenerSettings)
  (validation.checkEmpty "Deployable servers lack an administrative exposure policy" missingAdministrativePolicies)
  (validation.checkEmpty "Administrative access trusts networks absent from network inventory" undeclaredAdministrativeNetworks)
  (validation.checkEmpty "Inventory hosts missing configuration.nix" missingHostConfigurations)
  (validation.checkEmpty "Host directories missing from inventory" unregisteredHostDirectories)
  (validation.checkEmpty "Deployable hosts still use placeholder disks" placeholderDeployments)
]
  hosts
