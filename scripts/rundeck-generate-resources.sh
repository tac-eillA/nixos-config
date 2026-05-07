#!/usr/bin/env bash
set -euo pipefail

repo="${1:-.}"

cd "$repo"

hosts="$(
  nix eval --json --apply builtins.attrNames .#nixosConfigurations \
    | jq -r '.[]'
)"

for host in $hosts; do
  ssh_hostname="$(
    nix eval --raw ".#nixosConfigurations.$host.config.networking.hostName" 2>/dev/null \
      || printf '%s' "$host"
  )"

  tags="nixos"

  if [ -f "hosts/$ssh_hostname/configuration.nix" ]; then
    if grep -q "modules/profiles/server.nix" "hosts/$ssh_hostname/configuration.nix"; then
      tags="$tags,server"
    elif grep -q "modules/profiles/workstation.nix" "hosts/$ssh_hostname/configuration.nix"; then
      tags="$tags,workstation"
    else
      tags="$tags,base"
    fi
  fi

  if [ "$host" = "rundeck" ]; then
    tags="$tags,rundeck"
  fi

  cat <<EOF
$host:
  hostname: $ssh_hostname
  username: rundeck
  nodename: $host
  osFamily: unix
  tags: $tags
EOF
done
