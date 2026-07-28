#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "${script_dir}/.." && pwd)"
hosts_dir="${repo_dir}/hosts"
default_dir="${hosts_dir}/default"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

valid_hostname() {
  [[ "$1" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]
}

printf 'NixOS configuration installer\n\n'
printf '  1) Default (create a new host from the share-safe template)\n'
printf '  2) Other (use an existing host configuration)\n\n'
read -r -p 'Select host type [1/2]: ' host_type

case "${host_type,,}" in
  1|default)
    read -r -p 'Enter a hostname for this system: ' host
    valid_hostname "$host" \
      || die "Hostname must be 1-63 lowercase letters, numbers, or hyphens, and cannot start or end with a hyphen."

    destination="${hosts_dir}/${host}"
    [[ "$host" != "default" ]] || die '"default" is reserved for the template.'
    [[ ! -e "$destination" ]] || die "Host already exists: ${destination}"
    [[ -f "${default_dir}/configuration.nix" ]] \
      || die "Default host template is missing: ${default_dir}/configuration.nix"

    require_command nixos-generate-config
    require_command sudo

    mkdir -- "$destination"
    cp -- "${default_dir}/configuration.nix" "${destination}/configuration.nix"
    sed -i "s/networking\\.hostName = \"default\";/networking.hostName = \"${host}\";/" \
      "${destination}/configuration.nix"

    printf '\nGenerating hardware configuration for %s...\n' "$host"
    if ! sudo nixos-generate-config --show-hardware-config \
      > "${destination}/hardware-configuration.nix"; then
      rm -f -- \
        "${destination}/configuration.nix" \
        "${destination}/hardware-configuration.nix"
      rmdir -- "$destination" 2>/dev/null || true
      die "Hardware configuration generation failed."
    fi

    printf 'Created host configuration in %s\n' "$destination"
    ;;
  2|other)
    read -r -p 'Enter the existing host configuration name: ' host
    valid_hostname "$host" \
      || die "Invalid host name: ${host}"
    [[ "$host" != "default" ]] || die 'The default template is not deployable directly.'
    [[ -f "${hosts_dir}/${host}/configuration.nix" ]] \
      || die "No configuration found for host '${host}'."
    ;;
  *)
    die "Choose Default (1) or Other (2)."
    ;;
esac

require_command nixos-rebuild
require_command sudo

printf '\nBuilding the boot configuration for %s...\n' "$host"
sudo nixos-rebuild boot \
  --install-bootloader \
  --flake "path:${repo_dir}#${host}"

printf '\nInstallation completed successfully.\n'
printf 'The new configuration will be used on the next boot.\n'
read -r -p 'Press Enter when you are ready to return to the shell, then reboot manually. '
printf 'Run “sudo reboot” whenever you are ready.\n'
