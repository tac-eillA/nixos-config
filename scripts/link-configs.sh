#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${NIXOS_CONFIG_REPO:-/etc/nixos}"
SOURCE_DIR="${REPO_ROOT}/config"
TARGET_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}"

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "[link-configs] source directory missing: ${SOURCE_DIR}" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"

for entry in "${SOURCE_DIR}"/*; do
  name="$(basename "${entry}")"
  dest="${TARGET_DIR}/${name}"

  if [[ -e "${dest}" && ! -L "${dest}" ]]; then
    backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
    mv "${dest}" "${backup}"
  fi

  ln -sfn "${entry}" "${dest}"
done

echo "[link-configs] linked config from ${SOURCE_DIR} to ${TARGET_DIR}"
