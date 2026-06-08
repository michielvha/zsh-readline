# hooky.zsh-theme — simulates a theme/plugin that installs its OWN zle-line-init
# widget (powerlevel10k, agnoster transient prompt, zsh-autosuggestions, etc. all
# do this). This is the exact shape that PR #4 is about: if zsh-readline installs
# its line-init hook with `zle -N zle-line-init ...` it CLOBBERS this one.
#
# The hook appends to $HOOKY_MARKER every time it runs, so a test can detect
# whether the theme's hook survived after the plugin loaded — without needing to
# scrape the screen.

PROMPT='HK %1~ %# '
RPROMPT=''

_hooky_line_init() {
  print -r -- "hooky-ran" >> "${HOOKY_MARKER:-/tmp/hooky_marker}"
}
zle -N zle-line-init _hooky_line_init
