# Potential Enhancements

**The following enhancements should be investigated and tried:**

- Multi-line command handling

- Color highlighting (uses `>` prefix instead for now) - blue highlighted box could be a cooler way of doing this - ofcourse this will only work on a background that is not the same color blue so we should have some kind of check there that will use another color when we have a blue background in terminal... or maybe we just use a lightgrey or something idk we need some kind of contrasting color for each possible background... not sure how effectively we can use zsh to check which current background color we are using and then adding a color that will fit...

- syntax highlighting on the prediction chars that match the text we typed - apparently not supported with zle -M - we have an [extensive research document](./syntax-highlighting-research.md) for this, will change the core of the implementation so should be started on separated feature branch.
<!-- - color highlighting for the commands in the preview examples (they have this in PSReadLine) so if I type a recognised command like `make` it is highlighted in green by default on the terminal because it is recognised by the shell as a command would be great if we could get this in the listview aswell - currently it's all just white -->

---

## Done

### Real time buffer updates

- when we select an entry from the list it is not automatically added on the current line in the terminal - psreadline does this and you can still circle through all the examples that matched what it is that you actually typed in the terminal this way it will auto execute when you select the string from the listview because it is already appended to the current terminal line - I kind of like this behaviour as compoared to what we have now where you just select from the list and then when you enter it gets added to the current terminal line because this means you need to press enter twice each time....

<!-- - we could also go another route where we optionally make it auto apply that which we selected from the list so without adding it to the current terminal line keeping it more as we have it now but this would limit us to add extra chars to the string that we selected... - this should be configurable behaviour ofcourse - disable this by default but make it a possibility to configure, can help in certain workflows but could also be hindering so it would be great to offer as an optional feature I guess - we can use ZSH_READLINE_AUTO_EXEC -->

### History deduplication

- Optional configuration to enable zsh's built-in history deduplication via `ZSH_READLINE_REMOVE_DUPLICATE_HISTORY_ENTRIES=1` - uses zsh's built-in options (`HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`, `HIST_EXPIRE_DUPS_FIRST`) to automatically remove duplicate history entries, improving plugin performance over time. See [history-deduplication-research.md](./history-deduplication-research.md) for details.