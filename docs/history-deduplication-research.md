# History Deduplication

## Overview

The plugin can optionally enable zsh's built-in history deduplication to improve performance by reducing the number of duplicate entries in history.

## How It Works

When enabled, the plugin configures zsh's built-in history options:

- **`HIST_IGNORE_ALL_DUPS`**: Removes all previous occurrences when a duplicate command is added
- **`HIST_SAVE_NO_DUPS`**: Avoids writing duplicates to the history file
- **`HIST_EXPIRE_DUPS_FIRST`**: Removes duplicates first when trimming history

## Configuration

Enable by setting before sourcing the plugin:

```zsh
ZSH_READLINE_REMOVE_DUPLICATE_HISTORY_ENTRIES=1
source ~/.zsh-readline/zsh-readline.plugin.zsh
```

**Default**: Disabled (0)

## Implementation

The plugin simply sets zsh options based on the configuration:

```zsh
if [[ ${ZSH_READLINE_REMOVE_DUPLICATE_HISTORY_ENTRIES:-0} -eq 1 ]]; then
    setopt HIST_IGNORE_ALL_DUPS
    setopt HIST_SAVE_NO_DUPS
    setopt HIST_EXPIRE_DUPS_FIRST
fi
```

## Performance Impact

- **Immediate**: New duplicates are prevented as commands are used
- **Gradual**: Existing duplicates are removed over time as commands are reused
- **Result**: Smaller history file = faster parsing on each keystroke

## Notes

- Duplicates are removed gradually as commands are reused (not all at once)
- Uses zsh's built-in mechanisms - no custom code or file manipulation
- Safe and automatic - no backups or manual intervention needed

## References

- Zsh documentation: `man zshoptions` (HIST_IGNORE_DUPS, etc.)
