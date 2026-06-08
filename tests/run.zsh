#!/usr/bin/env zsh
# Top-level test runner for zsh-readline.
#
# Usage:
#   tests/run.zsh                 # run unit tests against repo plugin (main)
#   tests/run.zsh unit            # unit tests only
#   tests/run.zsh render          # render snapshot tests only (needs tmux)
#   tests/run.zsh all             # unit + render
#   ZSH_READLINE_PLUGIN=/path/to/plugin.zsh tests/run.zsh   # test another build
#
# Exit status is non-zero if any layer fails.

emulate -L zsh
set -o pipefail

local here="${0:A:h}"
local root="${here}/.."
local what="${1:-unit}"

: ${ZSH_READLINE_PLUGIN:="${root}/zsh-readline.plugin.zsh"}
export ZSH_READLINE_PLUGIN

typeset -i rc=0

run_unit() {
  print -r -- "================ UNIT TESTS ================"
  print -r -- "plugin: $ZSH_READLINE_PLUGIN"
  local f
  for f in "${here}"/unit/test_*.zsh; do
    print -r --
    print -r -- ">>> ${f:t}"
    zsh "$f" || rc=1
  done
}

run_render() {
  print -r --
  print -r -- "================ RENDER TESTS ================"
  if ! command -v tmux >/dev/null 2>&1; then
    print -r -- "tmux not found — skipping render layer (run tests/bootstrap.zsh to install)."
    return 0
  fi
  zsh "${here}/render/run_render.zsh" || rc=1
}

case "$what" in
  unit)   run_unit ;;
  render) run_render ;;
  all)    run_unit; run_render ;;
  *) print -r -- "unknown target: $what (use: unit | render | all)"; exit 2 ;;
esac

print -r --
(( rc == 0 )) && print -r -- "ALL GREEN" || print -r -- "SOME TESTS FAILED"
exit $rc
