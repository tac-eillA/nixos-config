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

Add each public route to the proxy host configuration:

```nix
scylla.roles.proxy.ingress = {
  "git.example.com" = "http://10.0.0.13:3000";
};
```

The destination host must allow the proxy address through its firewall. Keep
the role listener, firewall exposure, and proxy route consistent.

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
