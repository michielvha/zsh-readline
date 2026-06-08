#!/usr/bin/env zsh
# Layer 0 — provisioning for the render tests.
#
# Makes the render layer hermetic: installs tmux if missing, and vendors pinned
# co-plugins into tests/.vendor/ so we never read the developer's installed copy.
# Vendored prompt fixtures live in tests/fixtures/prompts/ and are committed
# (they're tiny), so they don't need fetching.
#
# Usage: zsh tests/bootstrap.zsh

emulate -L zsh
set -o pipefail

local here="${0:A:h}"
local vendor="${here}/.vendor"
mkdir -p "$vendor"

print -r -- "== Layer 0 provisioning =="

# --- tmux ---
if command -v tmux >/dev/null 2>&1; then
  print -r -- "tmux: present ($(tmux -V))"
else
  print -r -- "tmux: missing — installing..."
  if command -v brew >/dev/null 2>&1; then
    brew install tmux
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y tmux
  else
    print -r -- "!! no brew/apt-get — install tmux manually" >&2
    exit 1
  fi
fi

# --- vendored co-plugins (pinned) ---
clone_pinned() {
  local name="$1" url="$2" ref="$3" dir="${vendor}/$1"
  if [[ -d "$dir/.git" ]]; then
    print -r -- "${name}: present"
    return
  fi
  print -r -- "${name}: cloning ${ref}..."
  git clone --quiet "$url" "$dir"
  git -C "$dir" checkout --quiet "$ref"
}

clone_pinned zsh-autosuggestions \
  https://github.com/zsh-users/zsh-autosuggestions.git v0.7.0
clone_pinned zsh-syntax-highlighting \
  https://github.com/zsh-users/zsh-syntax-highlighting.git 0.8.0

print -r -- "== provisioning done =="
print -r -- "vendor dir: $vendor"
