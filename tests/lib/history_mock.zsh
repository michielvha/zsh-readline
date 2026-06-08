#!/usr/bin/env zsh
# Deterministic history mock for unit tests.
#
# The plugin reads history with a single call: `fc -l -$HISTSIZE -1`. That call
# is fragile in a non-interactive shell (it errors when there are fewer events
# than HISTSIZE). For unit tests we don't care about zsh's history machinery —
# only that the plugin parses the `fc -l` *format* correctly. So we shadow the
# `fc` builtin with a function that emits a fixed fixture in that exact format:
#
#       <leading spaces><event number><two spaces><command>
#
# Set TEST_HISTORY_FIXTURE to a file with one command per line before sourcing.
# The plugin under test then sees a known, ordered history regardless of the
# host machine. The real `fc` path is exercised for real in the Layer 2 render
# tests, which run an actual interactive shell.

: ${TEST_HISTORY_FIXTURE:=${0:A:h}/../fixtures/history.txt}

fc() {
  # Only intercept the list form the plugin uses (`fc -l ...`). Anything else
  # falls through to the real builtin so we don't break unrelated callers.
  if [[ "$1" != "-l" ]]; then
    builtin fc "$@"
    return
  fi
  local -a cmds
  cmds=("${(@f)$(<"$TEST_HISTORY_FIXTURE")}")
  local i=1 line
  for line in "${cmds[@]}"; do
    [[ -z "$line" ]] && continue
    printf '%5d  %s\n' "$i" "$line"
    (( i++ ))
  done
}
