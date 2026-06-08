#!/usr/bin/env zsh
# Layer 2 — render snapshot tests. Drives a real interactive zsh in tmux.
#
#   ZSH_READLINE_PLUGIN=...  plugin to test (default: repo plugin)
#   RENDER_TAG=...           label for snapshot output dir (default: main)
#
# Snapshots are written to tests/render/snapshots/<tag>/ for manual/CI diffing.
# Assertions encode what a CORRECT plugin must do; running this against `main`
# is expected to FAIL the hook-preservation check (that documents the PR #4 bug),
# while the PR #4 build should pass it.

emulate -L zsh
local here="${0:A:h}"
source "${here}/../lib/assert.zsh"
source "${here}/lib.zsh"

: ${ZSH_READLINE_PLUGIN:="${here}/../../zsh-readline.plugin.zsh"}
export ZSH_READLINE_PLUGIN
: ${RENDER_TAG:=main}

local prompts="${here}/../fixtures/prompts"
local snapdir="${here}/snapshots/${RENDER_TAG}"
mkdir -p "$snapdir"
local workdir; workdir="$(mktemp -d)"

print -r -- "plugin: $ZSH_READLINE_PLUGIN"
print -r -- "tag:    $RENDER_TAG"
print -r -- "snaps:  $snapdir"

trap 'render_shutdown; rm -rf "$workdir"' EXIT INT TERM

# ---------------------------------------------------------------------------
describe "A1: theme's own zle-line-init survives plugin load (hook clobbering)"
# Load the hooky theme (registers zle-line-init), THEN the plugin. If the plugin
# installs its hook with `zle -N zle-line-init` it destroys the theme's; if it
# uses add-zle-hook-widget the theme's hook is preserved.
local zdot="${workdir}/hooky"
local marker="${workdir}/hooky_marker"
: > "$marker"
build_zdotdir "$zdot" "${prompts}/hooky.zsh-theme"
render_start hooky "$zdot" "$marker"
# open a couple more prompts to give the hook chances to run
render_type hooky "echo one"; render_send hooky Enter
render_capture hooky > "${snapdir}/hooky.txt"
render_stop hooky
local hook_runs=$(grep -c hooky-ran "$marker" 2>/dev/null); hook_runs=${hook_runs:-0}
print -r -- "    (theme hook fired ${hook_runs} time(s))"
if (( hook_runs >= 1 )); then
  _t_pass "theme zle-line-init preserved after plugin load"
else
  _t_fail "theme zle-line-init was CLOBBERED by the plugin" ">=1 hook run" "0 hook runs"
fi

# ---------------------------------------------------------------------------
describe "B: prediction list renders below a single-line prompt"
local zdotB="${workdir}/single"
build_zdotdir "$zdotB" "${prompts}/single-line.zsh-theme"
render_start single "$zdotB"
render_type single "git "
local capB; capB="$(render_capture single)"
print -r -- "$capB" > "${snapdir}/single-git.txt"
assert_contains "$capB" "git status"  "list shows a 'git ...' prediction"
assert_contains "$capB" ">"           "selected-row marker '>' present"
assert_contains "$capB" "SL"          "prompt/theme line still intact"
# navigate down once, selection marker should move onto a prediction
render_send single Down
local capBnav; capBnav="$(render_capture single)"
print -r -- "$capBnav" > "${snapdir}/single-git-down.txt"
assert_contains "$capBnav" "> git"    "after Down, '>' marks a git prediction"
render_stop single

# ---------------------------------------------------------------------------
describe "C: list cleanup when it shrinks (A2 padding question)"
# Type 'git ' (many matches) then narrow to a rarer prefix so the list shrinks.
# A correct redraw leaves NO stale prediction rows from the larger list.
local zdotC="${workdir}/shrink"
build_zdotdir "$zdotC" "${prompts}/single-line.zsh-theme"
render_start shrink "$zdotC"
render_type shrink "git "
local big; big="$(render_capture shrink)"
local big_rows=$(print -r -- "$big" | grep -c '^[[:space:]]*[>[:space:]] ')
# narrow: continue typing to 'git reb' -> should match only 'git rebase -i HEAD~3'
render_type shrink "reb"
local small; small="$(render_capture shrink)"
print -r -- "$small" > "${snapdir}/shrink-git-reb.txt"
local small_rows=$(print -r -- "$small" | grep -c 'git rebase')
print -r -- "    (wide list ~${big_rows} rows; narrowed list shows 'git rebase')"
assert_contains "$small" "git rebase -i HEAD~3" "narrowed list shows the single match"
# stale-row check: 'git status'/'git commit' must be GONE after narrowing
assert_not_contains "$small" "git status" "no stale 'git status' row after shrink"
assert_not_contains "$small" "git commit" "no stale 'git commit' row after shrink"
render_stop shrink

render_shutdown
test_summary
