# Role-based hosts

Each host directory contains its complete host configuration. The flake finds
every `hosts/<name>/configuration.nix` file automatically.

## Select a profile

Import one shared profile in each host configuration:

```nix
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
  ];

  networking.hostName = "athena";
}
```

Use `workstation.nix` for desktop systems. It imports the desktop, development,
gaming, printing, firmware, Home Manager, Flatpak, and secret modules.

Use `server.nix` for servers. It imports the core, administration, Tailscale,
firewall, SOPS, and workload role modules.

## Configure the primary user

Set workstation user defaults in `modules/profiles/workstation-user.nix`:

```nix
scylla.user = {
  name = "user-name";
  fullName = "User Name";
  homeDirectory = null;
  git.name = "Git Author";
  git.email = "user@example.com";
};
```

A null home directory uses `/home/<user-name>`. Add other accounts in the
applicable host configuration.

## Configure a server

Set the host name and address in the server configuration:

```nix
networking.hostName = "forgejo";
systemd.network.networks."10-uplink".address = [ "10.254.1.213/24" ];
```

The server profile enables systemd-networkd, DHCP, OpenSSH, QEMU guest support,
and Tailscale. Host files can also add a static address.

## Enable a workload role

The server profile imports every role module. All roles are disabled by
default. Enable and configure one role in the applicable host file:

```nix
scylla.roles.forgejo = {
  enable = true;
  domain = "git.example.com";
  listenAddress = "10.0.0.13";
  port = 3000;
  oidcDiscoveryUrl =
    "https://auth.example.com/application/o/forgejo/.well-known/openid-configuration";
};
```

Role settings control the workload listener. They do not open firewall ports.

## Declare firewall access

Declare each allowed listener in the same host file:

```nix
scylla.network.exposures = [
  {
    name = "forgejo";
    port = 3000;
    protocols = [ "tcp" ];
    sources = [ "10.0.0.15/32" ];
  }
];
```

Each source can be an address or a network. An empty source list opens the port
publicly. Each host must use unique exposure names.

The server profile declares LAN and Tailscale access to OpenSSH. DNS hosts
declare TCP and UDP port 53 access for the LAN.

## Publish a service

The proxy host is intended to run on a public VPS. Caddy terminates HTTPS there
and reaches each standalone service host through Tailscale MagicDNS:

```nix
scylla.roles.proxy = {
  enable = true;
  ingress = {
    "git.example.com" = "http://forgejo:3000";
  };
};
```

Point the public DNS record at the VPS and allow TCP port 80 plus TCP and UDP
port 443 through both the host and provider firewalls. The VPS and backend must
be members of the same tailnet, with MagicDNS enabled.

Every ingress entry is publicly reachable through Caddy. Tailscale protects the
VPS-to-backend hop; it does not authenticate internet clients at the Caddy
frontend. Remove administrative routes or add an authentication layer if they
must remain private.

Backend listeners must accept traffic on their Tailscale address. The current
host examples listen on all addresses and admit `100.64.0.0/10` at the NixOS
firewall. Narrow that source to the proxy's stable Tailscale `/32` when it is
known, and use Tailscale grants as the primary authorization boundary. A tagged
policy can grant the proxy only the required service ports:

```json
{
  "tagOwners": {
    "tag:public-proxy": ["autogroup:admin"],
    "tag:authentik": ["autogroup:admin"],
    "tag:dns-dashboard": ["autogroup:admin"],
    "tag:forgejo": ["autogroup:admin"],
    "tag:vaultwarden": ["autogroup:admin"]
  },
  "grants": [
    { "src": ["tag:public-proxy"], "dst": ["tag:authentik"], "ip": ["tcp:9000"] },
    { "src": ["tag:public-proxy"], "dst": ["tag:dns-dashboard"], "ip": ["tcp:5380"] },
    { "src": ["tag:public-proxy"], "dst": ["tag:forgejo"], "ip": ["tcp:3000"] },
    { "src": ["tag:public-proxy"], "dst": ["tag:vaultwarden"], "ip": ["tcp:8222"] }
  ]
}
```

Keep each role listener, firewall exposure, Caddy route, and tailnet grant in
sync. Caddy handles HTTP and HTTPS; Forgejo SSH remains a direct LAN or
Tailscale connection unless a separate TCP forwarding design is added.

## Add a host

Create `hosts/<name>/configuration.nix` and its hardware file. Import one
profile and set `networking.hostName`. The flake creates the host output from
the directory name.

Replace all template disk labels before you install the host. The flake does
not track a separate deployment state.

## Secrets

Role modules use `sops-nix` and this Age key:

```text
/var/lib/sops-nix/age-key.txt
```

Do not commit an unencrypted secret or an Age private key. The workstation
profile also uses this key for the GitHub CLI configuration.
