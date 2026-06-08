#!/usr/bin/env zsh
# Tiny assertion + harness helpers for zsh-readline tests.
# Source this at the top of a test file. Call `test_summary` at the end (or let
# run.zsh do it). Exit status is non-zero if any assertion failed.

typeset -gi _T_PASS=0
typeset -gi _T_FAIL=0
typeset -g  _T_CURRENT=""

# Colors only when attached to a TTY.
if [[ -t 1 ]]; then
  _T_RED=$'\e[31m'; _T_GREEN=$'\e[32m'; _T_DIM=$'\e[2m'; _T_RST=$'\e[0m'
else
  _T_RED=""; _T_GREEN=""; _T_DIM=""; _T_RST=""
fi

# describe "name" — label the current test group (for readable output)
describe() { _T_CURRENT="$1"; print -r -- "${_T_DIM}• $1${_T_RST}"; }

_t_pass() { (( _T_PASS++ )); print -r -- "  ${_T_GREEN}✓${_T_RST} $1"; }
_t_fail() {
  (( _T_FAIL++ ))
  print -r -- "  ${_T_RED}✗ $1${_T_RST}"
  [[ -n "$2" ]] && print -r -- "      expected: ${2}"
  [[ -n "$3" ]] && print -r -- "      actual:   ${3}"
}

# assert_eq <expected> <actual> [message]
assert_eq() {
  local exp="$1" act="$2" msg="${3:-values equal}"
  if [[ "$exp" == "$act" ]]; then _t_pass "$msg"; else _t_fail "$msg" "$exp" "$act"; fi
}

# assert_neq <unexpected> <actual> [message]
assert_neq() {
  local unexp="$1" act="$2" msg="${3:-values differ}"
  if [[ "$unexp" != "$act" ]]; then _t_pass "$msg"; else _t_fail "$msg" "!= $unexp" "$act"; fi
}

# assert_contains <haystack> <needle> [message]
assert_contains() {
  local hay="$1" needle="$2" msg="${3:-contains '$2'}"
  if [[ "$hay" == *"$needle"* ]]; then _t_pass "$msg"; else _t_fail "$msg" "*$needle*" "$hay"; fi
}

# assert_not_contains <haystack> <needle> [message]
assert_not_contains() {
  local hay="$1" needle="$2" msg="${3:-does not contain '$2'}"
  if [[ "$hay" != *"$needle"* ]]; then _t_pass "$msg"; else _t_fail "$msg" "no '$needle'" "$hay"; fi
}

# assert_empty <value> [message]
assert_empty() {
  local val="$1" msg="${2:-is empty}"
  if [[ -z "$val" ]]; then _t_pass "$msg"; else _t_fail "$msg" "(empty)" "$val"; fi
}

test_summary() {
  print -r --
  if (( _T_FAIL == 0 )); then
    print -r -- "${_T_GREEN}PASS${_T_RST} ${_T_PASS} assertion(s)"
    return 0
  else
    print -r -- "${_T_RED}FAIL${_T_RST} ${_T_FAIL} failed, ${_T_PASS} passed"
    return 1
  fi
}
