# Role-based hosts

Scylla builds each host from inventory data. A host entry selects a profile,
features, roles, address, and deployment state. A role enables one workload.
Keep each host file limited to hardware imports and exceptional settings.

## Add a host to inventory

Use a workstation or server constructor in `inventory/hosts.nix`:

```nix
athena = mkWorkstation {
  hardwareModules = [ "framework-amd-ai-300-series" ];
};

forgejo = mkServer "forgejo" "forgejo" {
  roleSettings.forgejo = {
    installAdminPackages = true;
  };
};
```

Use `placeholderHost` for a host that is visible in inventory but is not ready
for deployment. Set `deployable = false` until the host has valid hardware and
configuration. The flake rejects a deployable host with template disk labels.

## Select features

Each feature name imports one module. A server normally uses these features:

```nix
features = [
  "development-minimal"
  "tailscale"
];
```

A workstation can add desktop, audio, firmware, AppImage, printing, gaming,
Distrobox, development, GitHub secrets, and Tailscale features. Add only the
features that the workstation requires.
`tailscale-operator` requires `tailscale` and `desktop`. Select only one of
`development-minimal` and `development-full`.

The server profile does not include firmware updates. Add `firmware` to a
server only if its hardware needs `fwupd`.

## Configure the primary user

Set the primary user in `modules/profiles/workstation-user.nix`:

```nix
scylla.user = {
  name = "user-name";
  fullName = "User Name";
  homeDirectory = null; # null uses /home/<user-name>
  git.name = "Git Author";
  git.email = "user@example.com";
};
```

The workstation profile imports this module. The `scylla.user` account is the
primary Home Manager account. Add other system accounts in a host-specific
module with `users.users.<name>`.

## Enable a workload role

Role modules are imported centrally and disabled by default. Enable a role in a
host entry. Keep role settings specific to that workload:

```nix
roles = [ "forgejo" ];
roleSettings.forgejo = {
  oidcDiscoveryUrl =
    "https://auth.example.com/application/o/forgejo/.well-known/openid-configuration";
  installAdminPackages = false;
};
```

Disabled roles create no service users, listeners, global packages, or SOPS
declarations. A role does not open firewall ports. Service inventory controls
listener addresses, ports, and domains. Exposure policy controls the allowed
sources.

## Publish a service

Declare service listeners and publication policy in `inventory/services.nix`:

```nix
forgejo = mkProxyService {
  host = "forgejo";
  domain = "git.example.com";
  port = 3000;
};
```

`mkProxyService` creates a TCP listener for HTTP traffic with proxy-only
exposure and a Cloudflare publication. Use `mkDnsService "dns1"` for a DNS
listener. A DNS listener uses TCP and UDP port 53.

The listener domain belongs to the workload. If a service has a Cloudflare
publication, its publication domain must match the listener domain. Do not add
an `ingress` map to the proxy host.

Declare trusted LAN and Tailscale ranges once in `inventory/networks.nix`.
Use LAN-only policy for raw DNS. Use proxy-only policy for DNS dashboards and
application backends. A proxy-only service must trust the deployable proxy
host. Use public exposure only for a listener that has no trusted-source
restriction.

The validator rejects missing or non-deployable hosts, disabled roles,
unsupported protocols, and invalid listener sockets. It also rejects
undeclared networks or hosts, policy mismatches, duplicate domains, manual
listener settings, and invalid Cloudflare destinations.

## Administrative SSH

Deployable servers declare SSH exposure in their host inventory. TCP port 22 is
restricted to the declared LAN and Tailscale networks. The proxy has no
inbound application exposure. The proxy keeps only the administrative SSH
rules.

## Secrets

Role modules use `sops-nix`, the Age key at the following path, and role-specific
ownership and restart settings:

```text
/var/lib/sops-nix/age-key.txt
```

Do not commit an unencrypted secret or an Age private key. The host template
does not declare a SOPS secret.
