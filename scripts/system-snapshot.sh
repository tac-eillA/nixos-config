#!/usr/bin/env bash
set -euo pipefail

SNAPSHOT_TOP_SUBVOL="${SHELL_SNAPSHOT_SUBVOL:-@snapshots}"
SNAPSHOT_SCOPE_DIR="root"

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "${cmd}" >&2
    exit 1
  fi
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

normalize_subvol() {
  local value="$1"
  value="${value#/}"
  while [[ "${value}" == */ ]]; do
    value="${value%/}"
  done
  printf '%s\n' "${value}"
}

sanitize_label() {
  local value="$1"
  value="${value// /-}"
  value="$(printf '%s' "${value}" | tr -cd '[:alnum:]._-')"
  if [[ -z "${value}" ]]; then
    value="manual"
  fi
  printf '%s\n' "${value}"
}

extract_root_subvol() {
  local opts="$1"
  local from_opts=""
  from_opts="$(printf '%s\n' "${opts}" | tr ',' '\n' | awk -F= '$1 == "subvol" { print $2; exit }')"
  if [[ -n "${from_opts}" ]]; then
    printf '%s\n' "${from_opts}"
    return
  fi

  local from_show=""
  from_show="$(btrfs subvolume show / 2>/dev/null | awk -F': ' '/^Name:/ { print $2; exit }')"
  printf '%s\n' "${from_show}"
}

cleanup_mount() {
  if [[ -n "${TOPLEVEL_MOUNT:-}" ]] && mountpoint -q "${TOPLEVEL_MOUNT}"; then
    umount "${TOPLEVEL_MOUNT}" || true
  fi
  if [[ -n "${TOPLEVEL_MOUNT:-}" ]] && [[ -d "${TOPLEVEL_MOUNT}" ]]; then
    rmdir "${TOPLEVEL_MOUNT}" || true
  fi
}

setup_context() {
  if [[ "$(id -u)" -ne 0 ]]; then
    die "Run as root (use sudo)."
  fi

  require_cmd findmnt
  require_cmd mountpoint
  require_cmd mount
  require_cmd umount
  require_cmd btrfs

  ROOT_FSTYPE="$(findmnt -n -o FSTYPE /)"
  [[ "${ROOT_FSTYPE}" == "btrfs" ]] || die "Root filesystem is not btrfs."

  ROOT_SOURCE="$(findmnt -n -o SOURCE /)"
  [[ -n "${ROOT_SOURCE}" ]] || die "Unable to detect root source device."

  ROOT_OPTIONS="$(findmnt -n -o OPTIONS /)"
  ROOT_SUBVOL="$(extract_root_subvol "${ROOT_OPTIONS}")"
  ROOT_SUBVOL="$(normalize_subvol "${ROOT_SUBVOL}")"
  [[ -n "${ROOT_SUBVOL}" ]] || die "Unable to detect root subvolume path."
  [[ "${ROOT_SUBVOL}" != "<FS_TREE>" ]] || die "Root appears to be top-level btrfs tree; unsupported."

  TOPLEVEL_MOUNT="$(mktemp -d /run/shell-snapshot.XXXXXX)"
  mount -o subvolid=5 "${ROOT_SOURCE}" "${TOPLEVEL_MOUNT}"

  ROOT_SUBVOL_PATH="${TOPLEVEL_MOUNT}/${ROOT_SUBVOL}"
  [[ -d "${ROOT_SUBVOL_PATH}" ]] || die "Root subvolume path not found: ${ROOT_SUBVOL_PATH}"

  SNAPSHOT_TOP_PATH="${TOPLEVEL_MOUNT}/${SNAPSHOT_TOP_SUBVOL}"
  SNAPSHOT_ROOT_PATH="${SNAPSHOT_TOP_PATH}/${SNAPSHOT_SCOPE_DIR}"
}

ensure_snapshot_root() {
  if [[ ! -e "${SNAPSHOT_TOP_PATH}" ]]; then
    btrfs subvolume create "${SNAPSHOT_TOP_PATH}" >/dev/null
  fi

  [[ -d "${SNAPSHOT_TOP_PATH}" ]] || die "Snapshot root path is invalid: ${SNAPSHOT_TOP_PATH}"
  mkdir -p "${SNAPSHOT_ROOT_PATH}"
}

create_snapshot() {
  local label="$1"
  local safe_label=""
  local stamp=""
  local snapshot_name=""
  local snapshot_path=""

  ensure_snapshot_root

  safe_label="$(sanitize_label "${label}")"
  stamp="$(date +%Y%m%d-%H%M%S)"
  snapshot_name="${stamp}-${safe_label}"
  snapshot_path="${SNAPSHOT_ROOT_PATH}/${snapshot_name}"

  btrfs subvolume snapshot -r "${ROOT_SUBVOL_PATH}" "${snapshot_path}" >/dev/null
  printf '%s\n' "${snapshot_name}"
}

list_snapshot_names() {
  ensure_snapshot_root
  find "${SNAPSHOT_ROOT_PATH}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r
}

cmd_create() {
  local label="${1:-manual}"
  local snapshot_name=""

  snapshot_name="$(create_snapshot "${label}")"
  printf 'Created snapshot: %s\n' "${snapshot_name}"
}

cmd_list() {
  local plain_mode="${1:-false}"
  local snapshots=()
  local i=1

  mapfile -t snapshots < <(list_snapshot_names)

  if [[ "${plain_mode}" == "true" ]]; then
    if [[ "${#snapshots[@]}" -gt 0 ]]; then
      printf '%s\n' "${snapshots[@]}"
    fi
    return
  fi

  if [[ "${#snapshots[@]}" -eq 0 ]]; then
    printf 'No snapshots found.\n'
    return
  fi

  printf 'Available snapshots (%s):\n' "${SNAPSHOT_TOP_SUBVOL}/${SNAPSHOT_SCOPE_DIR}"
  for snapshot in "${snapshots[@]}"; do
    printf '  %2d) %s\n' "${i}" "${snapshot}"
    i=$((i + 1))
  done
}

validate_restore_target() {
  local target_path="$1"

  [[ "${target_path}" == /* ]] || die "Restore target must be an absolute path."
  [[ "${target_path}" != "/" ]] || die "Refusing to restore to /"

  case "${target_path}" in
    /proc|/proc/*|/sys|/sys/*|/dev|/dev/*|/run|/run/*)
      die "Refusing to restore into runtime filesystem path: ${target_path}"
      ;;
  esac
}

cmd_restore() {
  local snapshot_name="$1"
  local target_path="$2"
  local target_rel=""
  local source_path=""
  local backup_label=""
  local backup_name=""

  require_cmd rsync

  validate_restore_target "${target_path}"

  ensure_snapshot_root
  [[ -d "${SNAPSHOT_ROOT_PATH}/${snapshot_name}" ]] || die "Snapshot not found: ${snapshot_name}"

  target_rel="${target_path#/}"
  source_path="${SNAPSHOT_ROOT_PATH}/${snapshot_name}/${target_rel}"

  [[ -e "${source_path}" ]] || die "Path not found in snapshot: ${target_path}"

  backup_label="pre-restore-$(printf '%s' "${target_rel}" | tr '/' '-')"
  backup_name="$(create_snapshot "${backup_label}")"
  printf 'Created safety snapshot: %s\n' "${backup_name}"

  if [[ -d "${source_path}" ]]; then
    mkdir -p "${target_path}"
    rsync -aAXH --numeric-ids "${source_path}/" "${target_path}/"
  else
    mkdir -p "$(dirname "${target_path}")"
    rsync -aAXH --numeric-ids "${source_path}" "${target_path}"
  fi

  printf 'Restored %s from snapshot %s\n' "${target_path}" "${snapshot_name}"
}

usage() {
  cat <<'EOF'
Usage:
  system-snapshot.sh create [label]
  system-snapshot.sh list [--plain]
  system-snapshot.sh restore <snapshot-name> <absolute-path>

Notes:
  - create: makes a read-only btrfs snapshot of the current root subvolume.
  - restore: path-level restore only; does not perform full root rollback.
EOF
}

main() {
  local cmd="${1:-}"

  case "${cmd}" in
    -h|--help|help|"")
      usage
      return
      ;;
  esac

  # Ensure temporary top-level mount is always cleaned up, including early failures.
  trap cleanup_mount EXIT
  setup_context

  case "${cmd}" in
    create)
      shift || true
      cmd_create "${1:-manual}"
      ;;
    list)
      shift || true
      if [[ "${1:-}" == "--plain" ]]; then
        cmd_list true
      else
        cmd_list false
      fi
      ;;
    restore)
      shift || true
      [[ $# -eq 2 ]] || die "restore requires <snapshot-name> <absolute-path>"
      cmd_restore "$1" "$2"
      ;;
    *)
      die "Unknown command: ${cmd}"
      ;;
  esac
}

main "$@"
