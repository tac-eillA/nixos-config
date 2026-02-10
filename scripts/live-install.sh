#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

TARGET_ROOT="/mnt"
HOST_NAME="${1:-artemis}"
HOST_DIR_REL="hosts/${HOST_NAME}"

DISK_DEV=""
EFI_PART=""
ROOT_PART=""
SWAP_PART=""
ROOT_DEV=""
ROOT_LUKS_ENABLED="false"
ROOT_LUKS_PASSPHRASE=""
ROOT_LUKS_MAPPER_NAME="root"
ENABLE_CACHE_SUBVOL="false"

INSTALL_USERNAME=""
INSTALL_FULLNAME=""
INSTALL_PASSWORD=""

SYSTEM_NAME="x86_64-linux"
STATE_VERSION="25.11"
DEFAULT_LOCALE="en_US.UTF-8"
TIME_ZONE="UTC"
KEY_MAP="us"

PROFILE_FRAMEWORK13="true"
PROFILE_NVIDIA_DESKTOP="false"
PROFILE_GAMING="true"
REPO_ROOT_TARGET="/etc/nixos"

ROOT_SUBVOL="@"
HOME_SUBVOL="@home"
LOG_SUBVOL="@log"
CACHE_SUBVOL="@cache"

ROOT_FS_UUID=""
ESP_FS_UUID=""
LUKS_PARTUUID=""

print_info() {
  printf "\n${GREEN}%s${NC}\n" "$1"
}

print_warn() {
  printf "${YELLOW}%s${NC}\n" "$1"
}

print_error() {
  printf "${RED}Error: %s${NC}\n" "$1" >&2
}

cleanup() {
  set +e
  print_info "Cleaning up mounts and mappings..."

  if mountpoint -q "${TARGET_ROOT}/boot"; then
    umount "${TARGET_ROOT}/boot"
  fi
  if mountpoint -q "${TARGET_ROOT}/home"; then
    umount "${TARGET_ROOT}/home"
  fi
  if mountpoint -q "${TARGET_ROOT}/var/log"; then
    umount "${TARGET_ROOT}/var/log"
  fi
  if mountpoint -q "${TARGET_ROOT}/var/cache"; then
    umount "${TARGET_ROOT}/var/cache"
  fi
  if mountpoint -q "${TARGET_ROOT}"; then
    umount -R "${TARGET_ROOT}"
  fi

  if [[ -n "${SWAP_PART}" ]]; then
    swapoff "${SWAP_PART}" 2>/dev/null || true
  fi

  if [[ "${ROOT_LUKS_ENABLED}" == "true" ]]; then
    cryptsetup luksClose "${ROOT_LUKS_MAPPER_NAME}" 2>/dev/null || true
  fi
}

trap cleanup EXIT

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    print_error "Required command is missing: ${cmd}"
    exit 1
  fi
}

ask_default() {
  local prompt="$1"
  local default_value="$2"
  local input=""

  read -r -p "${prompt} [${default_value}]: " input
  printf '%s\n' "${input:-${default_value}}"
}

ask_yes_no() {
  local prompt="$1"
  local default_value="$2"
  local input=""

  while true; do
    read -r -p "${prompt} [${default_value}]: " input
    input="${input:-${default_value}}"
    case "${input,,}" in
      y|yes) printf '%s\n' "true"; return ;;
      n|no) printf '%s\n' "false"; return ;;
      *) print_warn "Please answer yes or no." ;;
    esac
  done
}

ask_password() {
  local prompt="$1"
  local pw1=""
  local pw2=""

  while true; do
    read -r -s -p "${prompt}: " pw1
    printf '\n'
    read -r -s -p "Confirm ${prompt}: " pw2
    printf '\n'

    if [[ -z "${pw1}" ]]; then
      print_warn "Password cannot be empty."
      continue
    fi
    if [[ "${pw1}" != "${pw2}" ]]; then
      print_warn "Passwords do not match."
      continue
    fi

    printf '%s\n' "${pw1}"
    return
  done
}

escape_nix_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s\n' "${value}"
}

partition_path() {
  local disk="$1"
  local index="$2"

  if [[ "${disk}" =~ (nvme|mmcblk|loop) ]]; then
    printf '%s\n' "${disk}p${index}"
  else
    printf '%s\n' "${disk}${index}"
  fi
}

normalize_partition_input() {
  local value="$1"
  if [[ "${value}" == /dev/* ]]; then
    printf '%s\n' "${value}"
  else
    printf '/dev/%s\n' "${value}"
  fi
}

ensure_live_environment() {
  local root_fs
  root_fs="$(findmnt -n -o FSTYPE / || true)"

  # Most NixOS live media use tmpfs for /, but some environments use overlay.
  case "${root_fs}" in
    tmpfs|overlay)
      ;;
    *)
      print_warn "Detected root filesystem '${root_fs}', not a typical live-media root."
      if [[ "$(ask_yes_no "Continue anyway?" "no")" != "true" ]]; then
        print_error "Aborted: unsupported or unexpected live environment."
        exit 1
      fi
      ;;
  esac

  if [[ ! -d /sys/firmware/efi ]]; then
    print_error "UEFI firmware was not detected. This installer currently supports UEFI installs."
    exit 1
  fi

  if [[ "$(id -u)" -ne 0 ]]; then
    print_error "Run this script as root."
    exit 1
  fi
}

ensure_host_exists() {
  if [[ ! -d "${REPO_ROOT}/${HOST_DIR_REL}" ]]; then
    print_error "Host directory not found: ${REPO_ROOT}/${HOST_DIR_REL}"
    print_warn "Create host scaffolding first (configuration.nix + hardware-configuration.nix)."
    exit 1
  fi
}

select_disk() {
  print_info "Available disks:"
  lsblk -d -o NAME,SIZE,MODEL,TYPE | awk '$4 == "disk" {print}'

  while true; do
    local disk_name
    read -r -p "Select install disk (e.g. nvme0n1): " disk_name
    if [[ -b "/dev/${disk_name}" ]]; then
      DISK_DEV="/dev/${disk_name}"
      return
    fi
    print_warn "Invalid disk: /dev/${disk_name}"
  done
}

auto_partition_disk() {
  local swap_gib
  local efi_end_mib=513
  local swap_end_mib

  swap_gib="$(ask_default "Swap size in GiB (0 to disable)" "8")"
  if [[ ! "${swap_gib}" =~ ^[0-9]+$ ]]; then
    print_error "Swap size must be numeric."
    exit 1
  fi

  print_warn "This will erase all data on ${DISK_DEV}."
  local confirmed
  confirmed="$(ask_yes_no "Proceed with disk wipe and partitioning?" "no")"
  if [[ "${confirmed}" != "true" ]]; then
    print_error "Aborted by user."
    exit 1
  fi

  wipefs -af "${DISK_DEV}"

  if [[ "${swap_gib}" -eq 0 ]]; then
    parted -s "${DISK_DEV}" \
      mklabel gpt \
      mkpart primary fat32 1MiB ${efi_end_mib}MiB \
      set 1 esp on \
      mkpart primary ${efi_end_mib}MiB 100%

    EFI_PART="$(partition_path "${DISK_DEV}" 1)"
    ROOT_PART="$(partition_path "${DISK_DEV}" 2)"
    SWAP_PART=""
  else
    swap_end_mib=$((efi_end_mib + swap_gib * 1024))

    parted -s "${DISK_DEV}" \
      mklabel gpt \
      mkpart primary fat32 1MiB ${efi_end_mib}MiB \
      set 1 esp on \
      mkpart primary linux-swap ${efi_end_mib}MiB ${swap_end_mib}MiB \
      mkpart primary ${swap_end_mib}MiB 100%

    EFI_PART="$(partition_path "${DISK_DEV}" 1)"
    SWAP_PART="$(partition_path "${DISK_DEV}" 2)"
    ROOT_PART="$(partition_path "${DISK_DEV}" 3)"
  fi

  partprobe "${DISK_DEV}"
  # Wait for partition nodes to appear before formatting/mounting.
  if command -v udevadm >/dev/null 2>&1; then
    udevadm settle
  else
    sleep 1
  fi
}

manual_partition_disk() {
  require_cmd cfdisk

  print_info "Launching cfdisk for ${DISK_DEV}."
  cfdisk "${DISK_DEV}"

  # Ensure partition device nodes are refreshed after manual edits.
  partprobe "${DISK_DEV}"
  if command -v udevadm >/dev/null 2>&1; then
    udevadm settle
  else
    sleep 1
  fi

  while true; do
    EFI_PART="$(normalize_partition_input "$(ask_default "EFI partition (name or /dev path)" "$(basename "$(partition_path "${DISK_DEV}" 1)")")")"
    [[ -b "${EFI_PART}" ]] && break
    print_warn "Invalid EFI partition: ${EFI_PART}"
  done

  while true; do
    ROOT_PART="$(normalize_partition_input "$(ask_default "Root partition (name or /dev path)" "$(basename "$(partition_path "${DISK_DEV}" 2)")")")"
    if [[ -b "${ROOT_PART}" && "${ROOT_PART}" != "${EFI_PART}" ]]; then
      break
    fi
    print_warn "Invalid root partition: ${ROOT_PART}"
  done

  local swap_input
  swap_input="$(ask_default "Swap partition (name or /dev path, empty to disable)" "")"
  if [[ -n "${swap_input}" ]]; then
    SWAP_PART="$(normalize_partition_input "${swap_input}")"
    if [[ ! -b "${SWAP_PART}" ]]; then
      print_warn "Invalid swap partition. Swap disabled."
      SWAP_PART=""
    fi
  else
    SWAP_PART=""
  fi
}

setup_root_luks_if_enabled() {
  if [[ "${ROOT_LUKS_ENABLED}" != "true" ]]; then
    ROOT_DEV="${ROOT_PART}"
    return
  fi

  print_info "Setting up LUKS on ${ROOT_PART}"
  printf '%s' "${ROOT_LUKS_PASSPHRASE}" | cryptsetup luksFormat --type luks2 "${ROOT_PART}" -
  printf '%s' "${ROOT_LUKS_PASSPHRASE}" | cryptsetup luksOpen "${ROOT_PART}" "${ROOT_LUKS_MAPPER_NAME}" -
  ROOT_DEV="/dev/mapper/${ROOT_LUKS_MAPPER_NAME}"
}

format_and_mount_filesystems() {
  print_info "Formatting partitions..."
  mkfs.fat -F32 "${EFI_PART}"
  mkfs.btrfs -f "${ROOT_DEV}"

  if [[ -n "${SWAP_PART}" ]]; then
    mkswap "${SWAP_PART}"
  fi

  print_info "Creating btrfs subvolumes..."
  mount "${ROOT_DEV}" "${TARGET_ROOT}"
  btrfs subvolume create "${TARGET_ROOT}/${ROOT_SUBVOL}"
  btrfs subvolume create "${TARGET_ROOT}/${HOME_SUBVOL}"
  btrfs subvolume create "${TARGET_ROOT}/${LOG_SUBVOL}"
  if [[ "${ENABLE_CACHE_SUBVOL}" == "true" ]]; then
    btrfs subvolume create "${TARGET_ROOT}/${CACHE_SUBVOL}"
  fi
  umount "${TARGET_ROOT}"

  print_info "Mounting target layout..."
  mount -o "subvol=${ROOT_SUBVOL},compress=zstd:3,ssd,space_cache=v2" "${ROOT_DEV}" "${TARGET_ROOT}"
  mkdir -p "${TARGET_ROOT}/boot" "${TARGET_ROOT}/home" "${TARGET_ROOT}/var/log"
  mount -o "subvol=${HOME_SUBVOL},compress=zstd:3,ssd,space_cache=v2" "${ROOT_DEV}" "${TARGET_ROOT}/home"
  mount -o "subvol=${LOG_SUBVOL},compress=zstd:3,ssd,space_cache=v2" "${ROOT_DEV}" "${TARGET_ROOT}/var/log"

  if [[ "${ENABLE_CACHE_SUBVOL}" == "true" ]]; then
    mkdir -p "${TARGET_ROOT}/var/cache"
    mount -o "subvol=${CACHE_SUBVOL},compress=zstd:3,ssd,space_cache=v2" "${ROOT_DEV}" "${TARGET_ROOT}/var/cache"
  fi

  mount "${EFI_PART}" "${TARGET_ROOT}/boot"

  if [[ -n "${SWAP_PART}" ]]; then
    swapon "${SWAP_PART}"
  fi
}

copy_repo_to_target() {
  print_info "Copying flake repo to ${TARGET_ROOT}/etc/nixos..."
  mkdir -p "${TARGET_ROOT}/etc/nixos"
  cp -a "${REPO_ROOT}/." "${TARGET_ROOT}/etc/nixos/"
}

write_variables_file() {
  local target_vars_file
  local escaped_full_name
  local escaped_repo_root
  target_vars_file="${TARGET_ROOT}/etc/nixos/${HOST_DIR_REL}/variables.nix"
  escaped_full_name="$(escape_nix_string "${INSTALL_FULLNAME}")"
  escaped_repo_root="$(escape_nix_string "${REPO_ROOT_TARGET}")"

  ROOT_FS_UUID="$(blkid -s UUID -o value "${ROOT_DEV}")"
  ESP_FS_UUID="$(blkid -s UUID -o value "${EFI_PART}")"

  if [[ "${ROOT_LUKS_ENABLED}" == "true" ]]; then
    LUKS_PARTUUID="$(blkid -s PARTUUID -o value "${ROOT_PART}")"
  else
    LUKS_PARTUUID=""
  fi

  local luks_partuuid_nix="null"
  if [[ -n "${LUKS_PARTUUID}" ]]; then
    luks_partuuid_nix="\"${LUKS_PARTUUID}\""
  fi

  local cache_subvol_nix="null"
  if [[ "${ENABLE_CACHE_SUBVOL}" == "true" ]]; then
    cache_subvol_nix="\"${CACHE_SUBVOL}\""
  fi

  cat > "${target_vars_file}" <<EOF
{
  host = {
    name = "${HOST_NAME}";
    system = "${SYSTEM_NAME}";
    stateVersion = "${STATE_VERSION}";
  };

  paths = {
    repoRoot = "${escaped_repo_root}";
  };

  locale = {
    defaultLocale = "${DEFAULT_LOCALE}";
    timeZone = "${TIME_ZONE}";
    keyMap = "${KEY_MAP}";
  };

  user = {
    name = "${INSTALL_USERNAME}";
    fullName = "${escaped_full_name}";
    initialPassword = "changeme";
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
    framework13 = ${PROFILE_FRAMEWORK13};
    nvidiaDesktop = ${PROFILE_NVIDIA_DESKTOP};
    gaming = ${PROFILE_GAMING};
  };

  storage = {
    rootFsUuid = "${ROOT_FS_UUID}";
    espFsUuid = "${ESP_FS_UUID}";
    luksPartUuid = ${luks_partuuid_nix};
    luksMapperName = "${ROOT_LUKS_MAPPER_NAME}";

    subvol = {
      root = "${ROOT_SUBVOL}";
      home = "${HOME_SUBVOL}";
      log = "${LOG_SUBVOL}";
      cache = ${cache_subvol_nix};
    };

    cacheMountPoint = "/var/cache";

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

  print_info "Wrote host variables: ${target_vars_file}"
}

generate_hardware_config() {
  local target_hw_file
  target_hw_file="${TARGET_ROOT}/etc/nixos/${HOST_DIR_REL}/hardware-configuration.nix"

  print_info "Generating hardware configuration..."
  nixos-generate-config --root "${TARGET_ROOT}" --show-hardware-config > "${target_hw_file}"
}

optionally_edit_variables() {
  local target_vars_file
  target_vars_file="${TARGET_ROOT}/etc/nixos/${HOST_DIR_REL}/variables.nix"

  local default_editor=""
  for e in nano vim vi; do
    if command -v "$e" >/dev/null 2>&1; then
      default_editor="$e"
      break
    fi
  done

  if [[ -z "${default_editor}" ]]; then
    print_warn "No editor found; skipping manual variables edit."
    return
  fi

  local edit_now
  edit_now="$(ask_yes_no "Edit variables file before install?" "yes")"
  if [[ "${edit_now}" != "true" ]]; then
    return
  fi

  print_info "Opening ${target_vars_file} in ${default_editor}"
  "${default_editor}" "${target_vars_file}"
}

collect_install_identity() {
  local user_default
  user_default="${SUDO_USER:-nixos}"

  while true; do
    INSTALL_USERNAME="$(ask_default "Primary username (linux account)" "${user_default}")"
    if [[ "${INSTALL_USERNAME}" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
      break
    fi
    print_warn "Username must match: ^[a-z_][a-z0-9_-]*$"
  done

  INSTALL_FULLNAME="$(ask_default "Full name" "${INSTALL_USERNAME}")"
  INSTALL_PASSWORD="$(ask_password "User password")"
  REPO_ROOT_TARGET="$(ask_default "Repo root path on installed system (absolute path)" "/home/${INSTALL_USERNAME}/nixos-config")"

  DEFAULT_LOCALE="$(ask_default "Locale (e.g. en_US.UTF-8)" "${DEFAULT_LOCALE}")"
  TIME_ZONE="$(ask_default "Time zone (e.g. UTC or America/New_York)" "${TIME_ZONE}")"
  KEY_MAP="$(ask_default "Console keymap (e.g. us)" "${KEY_MAP}")"

  PROFILE_FRAMEWORK13="$(ask_yes_no "Enable Framework13 profile?" "yes")"
  PROFILE_NVIDIA_DESKTOP="$(ask_yes_no "Enable NVIDIA desktop profile?" "no")"
  PROFILE_GAMING="$(ask_yes_no "Enable gaming profile?" "yes")"
}

copy_repo_to_runtime_location() {
  local runtime_root
  runtime_root="${REPO_ROOT_TARGET}"

  if [[ "${runtime_root}" == "/etc/nixos" ]]; then
    return
  fi

  if [[ "${runtime_root}" != /* ]]; then
    print_warn "Repo root path must be absolute. Falling back to /etc/nixos."
    REPO_ROOT_TARGET="/etc/nixos"
    return
  fi

  print_info "Copying repo to runtime location: ${runtime_root}"
  mkdir -p "${TARGET_ROOT}${runtime_root}"
  cp -a "${TARGET_ROOT}/etc/nixos/." "${TARGET_ROOT}${runtime_root}/"

  if [[ "${runtime_root}" == "/home/${INSTALL_USERNAME}" || "${runtime_root}" == /home/${INSTALL_USERNAME}/* ]]; then
    nixos-enter --root "${TARGET_ROOT}" -c "chown -R ${INSTALL_USERNAME}:users '${runtime_root}'" || true
  fi
}

configure_storage_choices() {
  ROOT_LUKS_ENABLED="$(ask_yes_no "Encrypt root with LUKS?" "yes")"
  if [[ "${ROOT_LUKS_ENABLED}" == "true" ]]; then
    ROOT_LUKS_PASSPHRASE="$(ask_password "LUKS password")"
  fi

  ENABLE_CACHE_SUBVOL="$(ask_yes_no "Create dedicated cache subvolume (@cache)?" "no")"
}

confirm_install_plan() {
  print_info "Install plan summary"
  printf '  Host:            %s\n' "${HOST_NAME}"
  printf '  User:            %s (%s)\n' "${INSTALL_USERNAME}" "${INSTALL_FULLNAME}"
  printf '  Disk:            %s\n' "${DISK_DEV}"
  printf '  EFI partition:   %s\n' "${EFI_PART}"
  printf '  Root partition:  %s\n' "${ROOT_PART}"
  printf '  Swap partition:  %s\n' "${SWAP_PART:-disabled}"
  printf '  Root encryption: %s\n' "$( [[ "${ROOT_LUKS_ENABLED}" == "true" ]] && printf '%s' enabled || printf '%s' disabled )"
  printf '  Cache subvolume: %s\n' "$( [[ "${ENABLE_CACHE_SUBVOL}" == "true" ]] && printf '%s' enabled || printf '%s' disabled )"
  printf '  Repo path:       %s\n' "${REPO_ROOT_TARGET}"

  print_warn "The next step formats partitions and installs the system."
  if [[ "$(ask_yes_no "Proceed with formatting and installation?" "no")" != "true" ]]; then
    print_error "Aborted by user before formatting."
    exit 1
  fi
}

partition_menu() {
  print_info "Partitioning method"
  printf '1) Automatic (wipe selected disk and create EFI/swap/root)\n'
  printf '2) Manual (run cfdisk, then select existing partitions)\n'

  local choice
  choice="$(ask_default "Choose partitioning mode" "1")"

  select_disk
  case "${choice}" in
    1) auto_partition_disk ;;
    2) manual_partition_disk ;;
    *) print_error "Invalid choice: ${choice}"; exit 1 ;;
  esac
}

install_system() {
  if ! nix eval --raw "${TARGET_ROOT}/etc/nixos#nixosConfigurations.${HOST_NAME}.config.networking.hostName" >/dev/null 2>&1; then
    print_error "Flake does not define nixosConfigurations.${HOST_NAME}."
    print_error "Add that host to flake outputs or install with a defined host (for this repo: artemis)."
    exit 1
  fi

  print_info "Installing NixOS using flake host ${HOST_NAME}..."
  nixos-install --root "${TARGET_ROOT}" --flake "${TARGET_ROOT}/etc/nixos#${HOST_NAME}" --no-root-passwd
}

set_user_password() {
  print_info "Setting password for ${INSTALL_USERNAME}..."
  printf '%s\n' "${INSTALL_USERNAME}:${INSTALL_PASSWORD}" | nixos-enter --root "${TARGET_ROOT}" -c "chpasswd"
}

main() {
  require_cmd lsblk
  require_cmd findmnt
  require_cmd parted
  require_cmd mkfs.fat
  require_cmd mkfs.btrfs
  require_cmd nixos-install
  require_cmd nixos-generate-config
  require_cmd nix
  require_cmd cryptsetup
  require_cmd blkid

  ensure_live_environment
  ensure_host_exists

  print_info "Interactive NixOS live installer"
  print_info "Target host: ${HOST_NAME}"
  print_info "Repo source: ${REPO_ROOT}"
  print_warn "Press Ctrl+C at any prompt to abort safely."

  collect_install_identity
  partition_menu
  configure_storage_choices
  confirm_install_plan

  setup_root_luks_if_enabled
  format_and_mount_filesystems

  copy_repo_to_target
  generate_hardware_config
  write_variables_file
  optionally_edit_variables

  install_system
  set_user_password
  copy_repo_to_runtime_location

  print_info "Installation complete. You can reboot now."
  print_info "After reboot: sign in, run 'nixos-rebuild switch --flake ${REPO_ROOT_TARGET}#${HOST_NAME}', then verify shell menu actions."
}

main "$@"
