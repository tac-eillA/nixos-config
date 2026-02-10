#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

default_host="$(hostnamectl --static 2>/dev/null || hostname)"
host_name="${1:-${default_host}}"
host_dir="${REPO_ROOT}/hosts/${host_name}"
target_file="${host_dir}/variables.nix"

print_info() {
  printf '\n[bootstrap] %s\n' "$1"
}

print_warn() {
  printf '[bootstrap] warning: %s\n' "$1" >&2
}

print_error() {
  printf '[bootstrap] error: %s\n' "$1" >&2
}

detect_system() {
  case "$(uname -m)" in
    x86_64) printf '%s\n' "x86_64-linux" ;;
    aarch64) printf '%s\n' "aarch64-linux" ;;
    *) printf '%s\n' "x86_64-linux" ;;
  esac
}

detect_locale() {
  if [[ -f /etc/locale.conf ]]; then
    awk -F= '/^LANG=/{print $2; exit}' /etc/locale.conf
  else
    printf '%s\n' "en_US.UTF-8"
  fi
}

detect_keymap() {
  if command -v localectl >/dev/null 2>&1; then
    localectl status 2>/dev/null | awk -F: '/VC Keymap:/{gsub(/^[ \t]+/, "", $2); print $2; exit}'
  fi
}

detect_timezone() {
  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl show -p Timezone --value 2>/dev/null
  fi
}

find_uuid_for_mount() {
  local mountpoint="$1"
  findmnt -no UUID "$mountpoint" 2>/dev/null || true
}

find_subvol_for_mount() {
  local mountpoint="$1"
  findmnt -no OPTIONS "$mountpoint" 2>/dev/null | tr ',' '\n' | awk -F= '/^subvol=/{print $2; exit}' || true
}

find_luks_partuuid() {
  sed -n 's/.*cryptdevice=PARTUUID=\([^: ]*\):.*/\1/p' /proc/cmdline 2>/dev/null || true
}

prompt_default() {
  local label="$1"
  local current_default="$2"
  local answer=""

  read -r -p "${label} [${current_default}]: " answer
  if [[ -z "${answer}" ]]; then
    printf '%s\n' "${current_default}"
  else
    printf '%s\n' "${answer}"
  fi
}

prompt_bool() {
  local label="$1"
  local current_default="$2"
  local answer=""

  while true; do
    read -r -p "${label} [${current_default}]: " answer
    answer="${answer:-${current_default}}"
    case "${answer,,}" in
      y|yes|true|1) printf '%s\n' "true"; return ;;
      n|no|false|0) printf '%s\n' "false"; return ;;
      *) printf 'Please answer yes or no.\n' ;;
    esac
  done
}

prompt_required() {
  local label="$1"
  local current_default="$2"
  local value=""

  while true; do
    value="$(prompt_default "${label}" "${current_default}")"
    if [[ -n "${value}" ]]; then
      printf '%s\n' "${value}"
      return
    fi
    print_warn "${label} cannot be empty."
  done
}

prompt_absolute_path() {
  local label="$1"
  local current_default="$2"
  local value=""

  while true; do
    value="$(prompt_default "${label}" "${current_default}")"
    if [[ "${value}" == /* ]]; then
      printf '%s\n' "${value}"
      return
    fi
    print_warn "Please provide an absolute path."
  done
}

escape_nix_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s\n' "${value}"
}

system_default="$(detect_system)"
username_default="${SUDO_USER:-${USER}}"
fullname_default="${SUDO_USER:-${USER}}"
state_version_default="25.11"
repo_root_default="${REPO_ROOT}"
locale_default="$(detect_locale)"
timezone_default="$(detect_timezone)"
keymap_default="$(detect_keymap)"

root_uuid_default="$(find_uuid_for_mount /)"
esp_uuid_default="$(find_uuid_for_mount /boot)"
luks_partuuid_default="$(find_luks_partuuid)"

root_subvol_default="$(find_subvol_for_mount /)"
home_subvol_default="$(find_subvol_for_mount /home)"
log_subvol_default="$(find_subvol_for_mount /var/log)"
cache_subvol_default="$(find_subvol_for_mount /var/cache)"

locale_default="${locale_default:-en_US.UTF-8}"
timezone_default="${timezone_default:-UTC}"
keymap_default="${keymap_default:-us}"
root_subvol_default="${root_subvol_default:-@}"
home_subvol_default="${home_subvol_default:-@home}"
log_subvol_default="${log_subvol_default:-@log}"
cache_subvol_default="${cache_subvol_default:-}"

confirm_write_plan() {
  print_info "Review variables to be written"
  printf '  Host:            %s\n' "${host_name}"
  printf '  System:          %s\n' "${system_name}"
  printf '  State version:   %s\n' "${state_version}"
  printf '  User:            %s (%s)\n' "${username}" "${full_name}"
  printf '  Repo path:       %s\n' "${repo_root}"
  printf '  Locale/Time:     %s / %s\n' "${default_locale}" "${time_zone}"
  printf '  Root UUID:       %s\n' "${root_uuid}"
  printf '  EFI UUID:        %s\n' "${esp_uuid}"
  printf '  LUKS PARTUUID:   %s\n' "${luks_partuuid:-disabled}"
  printf '  Subvols:         root=%s home=%s log=%s cache=%s\n' "${root_subvol}" "${home_subvol}" "${log_subvol}" "${cache_subvol:-disabled}"
  printf '  Profiles:        framework13=%s nvidiaDesktop=%s gaming=%s\n' "${framework13_profile}" "${nvidia_profile}" "${gaming_profile}"
  printf '  Output file:     %s\n' "${target_file}"

  if [[ "$(prompt_bool "Write variables.nix with these values?" "yes")" != "true" ]]; then
    print_error "Aborted before writing variables file."
    exit 1
  fi
}

print_info "Bootstrap variables"
printf 'Host template source: %s\n' "${host_dir}"
printf 'Press Enter to accept defaults.\n\n'

host_name="$(prompt_required "Host name (flake attr + networking.hostName)" "${host_name}")"
while [[ ! "${host_name}" =~ ^[a-zA-Z0-9._-]+$ ]]; do
  print_warn "Host name may only contain letters, numbers, dot, underscore, and dash."
  host_name="$(prompt_required "Host name (flake attr + networking.hostName)" "${host_name}")"
done

# Recompute destination paths after any host name edits.
host_dir="${REPO_ROOT}/hosts/${host_name}"
target_file="${host_dir}/variables.nix"

system_name="$(prompt_required "System (x86_64-linux or aarch64-linux)" "${system_default}")"
state_version="$(prompt_required "State version (e.g. 25.11)" "${state_version_default}")"
repo_root="$(prompt_absolute_path "Repo root path on this system (absolute path)" "${repo_root_default}")"

username="$(prompt_required "Primary username (linux account)" "${username_default}")"
while [[ ! "${username}" =~ ^[a-z_][a-z0-9_-]*$ ]]; do
  print_warn "Username must match: ^[a-z_][a-z0-9_-]*$"
  username="$(prompt_required "Primary username (linux account)" "${username_default}")"
done

full_name="$(prompt_required "Full name (display name)" "${fullname_default}")"
initial_password="$(prompt_required "Initial password (first boot)" "changeme")"

default_locale="$(prompt_required "Default locale (e.g. en_US.UTF-8)" "${locale_default}")"
time_zone="$(prompt_required "Time zone (e.g. UTC or America/New_York)" "${timezone_default}")"
key_map="$(prompt_required "Console keymap (e.g. us)" "${keymap_default}")"

root_uuid="$(prompt_required "Root filesystem UUID" "${root_uuid_default}")"
esp_uuid="$(prompt_required "EFI partition UUID" "${esp_uuid_default}")"
luks_partuuid="$(prompt_default "LUKS partition PARTUUID (empty disables disk unlock in initrd)" "${luks_partuuid_default}")"

root_subvol="$(prompt_required "Root subvolume name" "${root_subvol_default}")"
home_subvol="$(prompt_required "Home subvolume name" "${home_subvol_default}")"
log_subvol="$(prompt_required "Log subvolume name" "${log_subvol_default}")"
cache_subvol="$(prompt_default "Cache subvolume name (empty to disable)" "${cache_subvol_default}")"
cache_mount_point="$(prompt_absolute_path "Cache mount point (absolute path)" "/var/cache")"

framework13_profile="$(prompt_bool "Enable Framework13 profile? (yes/no)" "yes")"
nvidia_profile="$(prompt_bool "Enable NVIDIA desktop profile? (yes/no)" "no")"
gaming_profile="$(prompt_bool "Enable gaming profile? (yes/no)" "yes")"

confirm_write_plan

mkdir -p "${host_dir}"

if [[ -f "${target_file}" ]]; then
  backup_file="${target_file}.backup.$(date +%Y%m%d%H%M%S)"
  cp "${target_file}" "${backup_file}"
  printf 'Existing variables backed up to %s\n' "${backup_file}"
fi

full_name="$(escape_nix_string "${full_name}")"
initial_password="$(escape_nix_string "${initial_password}")"
repo_root="$(escape_nix_string "${repo_root}")"

luks_partuuid_nix="null"
if [[ -n "${luks_partuuid}" ]]; then
  luks_partuuid_nix="\"${luks_partuuid}\""
fi

cache_subvol_nix="null"
if [[ -n "${cache_subvol}" ]]; then
  cache_subvol_nix="\"${cache_subvol}\""
fi

cat > "${target_file}" <<EOF
{
  host = {
    name = "${host_name}";
    system = "${system_name}";
    stateVersion = "${state_version}";
  };

  paths = {
    repoRoot = "${repo_root}";
  };

  locale = {
    defaultLocale = "${default_locale}";
    timeZone = "${time_zone}";
    keyMap = "${key_map}";
  };

  user = {
    name = "${username}";
    fullName = "${full_name}";
    initialPassword = "${initial_password}";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "docker"
      "lp"
      "scanner"
    ];
  };

  profiles = {
    framework13 = ${framework13_profile};
    nvidiaDesktop = ${nvidia_profile};
    gaming = ${gaming_profile};
  };

  storage = {
    rootFsUuid = "${root_uuid}";
    espFsUuid = "${esp_uuid}";
    luksPartUuid = ${luks_partuuid_nix};
    luksMapperName = "root";

    subvol = {
      root = "${root_subvol}";
      home = "${home_subvol}";
      log = "${log_subvol}";
      cache = ${cache_subvol_nix};
    };

    cacheMountPoint = "${cache_mount_point}";

    btrfsMountOptions = [
      "compress=zstd:3"
      "ssd"
      "space_cache=v2"
    ];

    espMountOptions = [
      "fmask=0022"
      "dmask=0022"
      "utf8"
    ];
  };
}
EOF

printf '\nWrote %s\n' "${target_file}"
printf 'Review values, then run: sudo nixos-rebuild build --flake %q#%s\n' "${repo_root}" "${host_name}"
