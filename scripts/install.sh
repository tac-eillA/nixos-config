#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "${script_dir}/.." && pwd)"
hosts_dir="${repo_dir}/hosts"
template_dir="${repo_dir}/templates/host"
inventory_file="${repo_dir}/inventory/hosts.nix"

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
    [[ -f "${template_dir}/configuration.nix" ]] \
      || die "Host template is missing: ${template_dir}/configuration.nix"

    require_command nixos-generate-config
    require_command nano
    require_command sudo

    printf '\nWorkstation user defaults are kept in modules/profiles/workstation-user.nix.\n'
    printf 'Nano will open so you can review the username, display name, home directory, and Git identity.\n'
    read -r -p 'Press Enter to open the user configuration. '
    nano "${repo_dir}/modules/profiles/workstation-user.nix"

    mkdir -- "$destination"
    cp -- "${template_dir}/configuration.nix" "${destination}/configuration.nix"

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
    printf '\nAdd %s to inventory/hosts.nix and mark it deployable when ready.\n' "$host"
    printf 'Nano will open the host inventory now.\n'
    read -r -p 'Press Enter to open the host inventory. '
    nano "$inventory_file"
    ;;
  2|other)
    read -r -p 'Enter the existing host configuration name: ' host
    valid_hostname "$host" \
      || die "Invalid host name: ${host}"
    [[ "$host" != "default" ]] || die 'The default template is not deployable directly.'
    [[ -f "${hosts_dir}/${host}/configuration.nix" ]] \
      || die "No configuration found for host '${host}'."

    hardware_file="${hosts_dir}/${host}/hardware-configuration.nix"
    if [[ -f "$hardware_file" ]] && grep -q 'replace-me-root' "$hardware_file"; then
      require_command nixos-generate-config
      require_command sudo

      printf '\nGenerating hardware configuration for %s...\n' "$host"
      generated_hardware="${hardware_file}.new"
      if sudo nixos-generate-config --show-hardware-config > "$generated_hardware"; then
        mv -- "$generated_hardware" "$hardware_file"
      else
        rm -f -- "$generated_hardware"
        die "Hardware configuration generation failed."
      fi
    fi
    ;;
  *)
    die "Choose Default (1) or Other (2)."
    ;;
esac

require_command nix
require_command nixos-rebuild
require_command sudo

if ! configured_hostname="$(
  nix eval --offline --raw \
    "path:${repo_dir}#nixosConfigurations.${host}.config.networking.hostName" \
    2>/dev/null
)"; then
  die "Host '${host}' is not declared as deployable in inventory/hosts.nix."
fi

[[ "$configured_hostname" == "$host" ]] \
  || die "Inventory output '${host}' evaluated with hostname '${configured_hostname}'."

printf '\nBuilding the boot configuration for %s...\n' "$host"
sudo nixos-rebuild boot \
  --install-bootloader \
  --flake "path:${repo_dir}#${host}"

printf '\nInstallation completed successfully.\n'
printf 'The new configuration will be used on the next boot.\n'
read -r -p 'Press Enter when you are ready to return to the shell, then reboot manually. '
printf 'Run “sudo reboot” whenever you are ready.\n'
