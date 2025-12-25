# Syntax Highlighting Limitation

## Issue
Attempts to add syntax highlighting to listview predictions using ANSI escape codes or zsh prompt expansion sequences with `zle -M` have failed. The escape codes are displayed literally as text instead of being interpreted as colors.

## Finding
`zle -M` (ZLE message system) **does not support colored output**. It only displays plain text messages below the command line.

## Attempted Approaches (None Worked)
1. Raw ANSI escape codes: `\033[32m`, `\e[32m`, etc.
2. Zsh prompt expansion sequences: `%F{green}`, `%f`, etc.
3. Using `print -P` to expand sequences before passing to `zle -M`
4. Various escape code formats and wrappers

All resulted in literal display of escape codes in the terminal.

## Possible Alternatives (Not Implemented)
1. **Manual cursor positioning with ANSI codes**: The original implementation tried this but had issues with prompt duplication and cursor positioning. This approach might work if those issues are resolved.

2. **Different display method**: Find an alternative to `zle -M` that supports colors (if one exists).

3. **Accept limitation**: Keep listview predictions as plain text only.

## Reference
- Original buffer update implementation works correctly (commit 92c328a)
- All color highlighting attempts failed and were reverted

## Status
Syntax highlighting for listview predictions is currently **not implemented** due to `zle -M` limitations.

