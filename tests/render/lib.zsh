#!/usr/bin/env zsh
# Render-test helpers: drive a real interactive zsh inside a fixed-size tmux
# session and snapshot the rendered screen with capture-pane.
#
# Everything runs on a private tmux socket (-L) so it never touches the
# developer's own tmux server, and under a generated ZDOTDIR with `zsh -d`
# (skip /etc rcs) so the host environment can't leak in.

emulate -L zsh

typeset -g RENDER_ROOT="${0:A:h}/../.."
typeset -g RENDER_TESTS="${0:A:h}/.."
typeset -g RENDER_SOCK="zshrl-test-$$"
typeset -g RENDER_COLS=80 RENDER_ROWS=24

# build_zdotdir <zdotdir> <theme-file> [coplugin-dir ...]
# Generates a .zshrc that loads a known history, the theme, optional co-plugins,
# and the plugin under test ($ZSH_READLINE_PLUGIN). History is sized so the
# plugin's `fc -l -$HISTSIZE -1` doesn't underflow.
build_zdotdir() {
  local zdot="$1" theme="$2"; shift 2
  local -a coplugins=("$@")
  mkdir -p "$zdot"

  local histfile="${zdot}/.zsh_history"
  cp "${RENDER_TESTS}/fixtures/history.txt" "$histfile"
  local hist_count=$(grep -c . "$histfile")

  {
    print -r -- "# generated test rc"
    print -r -- "setopt PROMPT_SUBST"
    print -r -- "HISTFILE='${histfile}'"
    print -r -- "HISTSIZE=${hist_count}"
    print -r -- "SAVEHIST=${hist_count}"
    print -r -- "fc -R '${histfile}'"
    print -r -- "# --- theme ---"
    print -r -- "source '${theme}'"
    local cp
    for cp in "${coplugins[@]}"; do
      print -r -- "source '${cp}'"
    done
    print -r -- "# --- plugin under test ---"
    print -r -- "source '${ZSH_READLINE_PLUGIN}'"
  } > "${zdot}/.zshrc"
}

# render_start <name> <zdotdir> [marker-file]
render_start() {
  local name="$1" zdot="$2" marker="${3:-/dev/null}"
  tmux -L "$RENDER_SOCK" new-session -d -s "$name" \
       -x "$RENDER_COLS" -y "$RENDER_ROWS" \
       -e "ZDOTDIR=${zdot}" -e "HOOKY_MARKER=${marker}" \
       "zsh -d -i"
  sleep 1   # let the first prompt (and zle-line-init) settle
}

# render_send <name> <key...>  — names like Down/Enter/C-c interpreted by tmux
render_send()    { tmux -L "$RENDER_SOCK" send-keys -t "$1" "${@:2}"; sleep 0.4; }
# render_type <name> <literal-string>
render_type()    { tmux -L "$RENDER_SOCK" send-keys -t "$1" -l "$2"; sleep 0.5; }
# render_capture <name> -> prints the visible pane as plain text
render_capture() { tmux -L "$RENDER_SOCK" capture-pane -t "$1" -p; }
render_stop()    { tmux -L "$RENDER_SOCK" kill-session -t "$1" 2>/dev/null; }
render_shutdown(){ tmux -L "$RENDER_SOCK" kill-server 2>/dev/null; }

# strip_blanks <text> -> collapse to non-empty, right-trimmed lines (for stable diffs)
strip_blanks() {
  local line
  while IFS= read -r line; do
    line="${line%%[[:space:]]##}"   # right-trim
    [[ -n "$line" ]] && print -r -- "$line"
  done
}
