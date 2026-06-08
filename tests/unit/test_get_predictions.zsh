#!/usr/bin/env zsh
# Layer 1 — unit tests for _zsh_readline_get_predictions
#
# Run via tests/run.zsh, or directly:
#   zsh tests/unit/test_get_predictions.zsh
#
# Plugin under test is taken from $ZSH_READLINE_PLUGIN (default: repo plugin),
# so the same suite can run against `main` and the PR #4 checkout.

emulate -L zsh
setopt no_unset 2>/dev/null

local here="${0:A:h}"
local root="${here}/../.."
source "${here}/../lib/assert.zsh"

export TEST_HISTORY_FIXTURE="${here}/../fixtures/history.txt"
source "${here}/../lib/history_mock.zsh"

: ${ZSH_READLINE_PLUGIN:="${root}/zsh-readline.plugin.zsh"}
# Defaults the plugin expects to read.
ZSH_READLINE_MAX_PREDICTIONS=10
ZSH_READLINE_MIN_INPUT=1
HISTSIZE=1000
source "$ZSH_READLINE_PLUGIN" 2>/dev/null

# Helper: predictions for an input, joined with '|' for stable assertions.
preds() { _zsh_readline_get_predictions "$1" | tr '\n' '|'; }

describe "prefix matching"
out="$(preds 'git')"
assert_contains "$out" "git status"            "matches 'git status'"
assert_contains "$out" "git commit -m \"wip\"" "preserves quotes in command"
assert_not_contains "$out" "docker ps"         "excludes non-matching prefix"

describe "case-insensitivity"
# fixture has 'GIT log --oneline' (uppercase); input 'git' should still match it
out="$(preds 'git')"
assert_contains "$out" "GIT log --oneline" "lowercase input matches uppercase history"

describe "de-duplication"
# 'docker ps' appears twice in the fixture; should show once
out="$(preds 'docker ps')"
typeset -i count=0
local -a lines; lines=("${(@f)$(_zsh_readline_get_predictions 'docker')}")
for l in "${lines[@]}"; do [[ "$l" == "docker ps" ]] && (( count++ )); done
assert_eq 1 $count "'docker ps' appears exactly once despite duplicate history"

describe "exact match is excluded"
# input that exactly equals a command should not list that command back
# (only strictly longer commands with that prefix are predictions)
local -a dlines; dlines=("${(@f)$(_zsh_readline_get_predictions 'docker ps')}")
typeset -i exact=0
for l in "${dlines[@]}"; do [[ "$l" == "docker ps" ]] && (( exact++ )); done
assert_eq 0 $exact "exact-match command is not echoed back"
# shorter input 'docker' should still surface the longer 'docker ...' commands
assert_contains "$(preds 'docker')" "docker build -t app ." "shorter prefix surfaces longer commands"

describe "MAX_PREDICTIONS cap"
ZSH_READLINE_MAX_PREDICTIONS=2
local -a capped; capped=("${(@f)$(_zsh_readline_get_predictions 'git')}")
assert_eq 2 ${#capped[@]} "respects ZSH_READLINE_MAX_PREDICTIONS=2"
ZSH_READLINE_MAX_PREDICTIONS=10

describe "empty / no-match input"
assert_empty "$(_zsh_readline_get_predictions '')"        "empty input yields nothing"
assert_empty "$(_zsh_readline_get_predictions 'zzzqqq')"  "no-match input yields nothing"

test_summary
