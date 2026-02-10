#!/usr/bin/env bash
set -euo pipefail

DOOM_DIR="${HOME}/.config/emacs"
export DOOMDIR="${HOME}/.config/doom"

if [[ ! -d "${DOOM_DIR}" ]]; then
  git clone --depth 1 https://github.com/doomemacs/doomemacs "${DOOM_DIR}"
fi

"${DOOM_DIR}/bin/doom" install --force
"${DOOM_DIR}/bin/doom" sync

echo "Doom Emacs installed and synced."
