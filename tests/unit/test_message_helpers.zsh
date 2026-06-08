#!/usr/bin/env zsh
# Layer 1 — unit tests for the PR #4 message helpers:
#   _zsh_readline__count_lines, _zsh_readline__set_message, _zsh_readline__clear_message
#
# These functions exist only on the PR #4 branch. When run against `main` the
# suite self-skips (reports 0 assertions, exit 0) so it's safe in both checkouts.
#
# _zsh_readline__set_message calls `zle -M`/`zle -R`, which require an active
# widget. We can't enter ZLE non-interactively, so we shadow `zle` with a stub
# that captures the message that *would* be displayed. That lets us assert the
# padding math (and pin the behavior of the masked `cur_lines` assignment, which
# only round-trips because the variable is integer-typed).

emulate -L zsh

local here="${0:A:h}"
local root="${here}/../.."
source "${here}/../lib/assert.zsh"

: ${ZSH_READLINE_PLUGIN:="${root}/zsh-readline.plugin.zsh"}
ZSH_READLINE_MAX_PREDICTIONS=10
ZSH_READLINE_MIN_INPUT=1
HISTSIZE=1000
source "$ZSH_READLINE_PLUGIN" 2>/dev/null

if (( ! $+functions[_zsh_readline__set_message] )); then
  print -r -- "${_T_DIM}(skip) message helpers not present in this plugin (expected on main)${_T_RST}"
  test_summary
  return 0 2>/dev/null || exit 0
fi

# Stub zle to capture the displayed message.
typeset -g _CAPTURED_MSG=""
zle() {
  case "$1" in
    -M) _CAPTURED_MSG="$2" ;;
    *)  : ;;   # -R and friends: no-op in tests
  esac
}
_count_displayed_lines() { local m="$1"; [[ -z "$m" ]] && { print 0; return; }; local -a p=("${(@ps:\n:)m}"); print ${#p[@]}; }

describe "_zsh_readline__count_lines"
assert_eq 0 "$(_zsh_readline__count_lines '')"             "empty string -> 0"
assert_eq 1 "$(_zsh_readline__count_lines 'one')"          "single line -> 1"
assert_eq 2 "$(_zsh_readline__count_lines $'one\ntwo')"    "two lines -> 2"

describe "_zsh_readline__set_message tracks height"
_zsh_readline_prev_msg_lines=0
_zsh_readline__set_message $'a\nb\nc'
assert_eq 3 "$_zsh_readline_prev_msg_lines" "prev height set to 3 after 3-line message"
assert_eq 3 "$(_count_displayed_lines "$_CAPTURED_MSG")" "displays 3 lines"

describe "_zsh_readline__set_message pads a shrinking message"
# previous message was 5 lines; new message is 2 lines -> should pad to 5
_zsh_readline_prev_msg_lines=5
_zsh_readline__set_message $'x\ny'
assert_eq 5 "$(_count_displayed_lines "$_CAPTURED_MSG")" "shorter message padded up to previous height (5)"
# Pins the A2 'cur_lines=_zsh_readline_prev_msg_lines' (missing $) behavior:
# after padding, prev height must remain the previous value, not collapse to 2.
assert_eq 5 "$_zsh_readline_prev_msg_lines" "prev height stays 5 after padding (masked-bug behavior pinned)"

describe "_zsh_readline__set_message does not over-pad a growing message"
_zsh_readline_prev_msg_lines=2
_zsh_readline__set_message $'a\nb\nc\nd'
assert_eq 4 "$(_count_displayed_lines "$_CAPTURED_MSG")" "growing message not padded"
assert_eq 4 "$_zsh_readline_prev_msg_lines" "prev height grows to 4"

describe "_zsh_readline__clear_message resets state"
_zsh_readline_prev_msg_lines=7
_CAPTURED_MSG="stale"
_zsh_readline__clear_message
assert_eq 0 "$_zsh_readline_prev_msg_lines" "prev height reset to 0"
assert_empty "$_CAPTURED_MSG" "cleared message is empty"

test_summary
