# Implementation Guide

zsh-readline is a Zsh plugin that displays history-based predictions in a ListView format below the command line. This document describes what was actually implemented and how it works.

## Core Functionality

### 1. History Matching

**What it does:**
- Searches your zsh history for commands that start with what you've typed
- Uses prefix matching on the entire command (not just the first word)
- Case-insensitive matching
- Deduplicates results (shows each unique command only once)

**How it works:**
```zsh
# Uses fc -l to get history
fc -l -$HISTSIZE -1

# Extracts command from history line (skips history number)
# Format: "   123  command here"
# Splits on whitespace, takes everything after first field

# Matches if command starts with input
if [[ "$cmd_lower" == "$input_lower"* ]]; then
    # Command matches!
fi
```

**Key insight:** We match the entire command prefix, so:
- Typing `make` shows: `make setup`, `make up`, `make fresh`
- Typing `make fresh` shows: `make fresh install`, `make fresh deploy`
- Predictions continue to show as you type longer commands

### 2. Display System

**What it does:**
- Displays predictions below the command line
- Shows selected item with `>` prefix
- Updates in real-time as you type
- Clears when input is empty or too short

**How it works:**
```zsh
# Uses zle -M (ZLE message system)
zle -M "$message"

# Builds message with newlines
# Format:
#   command1
# > command2  (selected)
#   command3
```

**Why `zle -M`?**
- ZLE's built-in message system designed for this exact purpose
- Automatically handles cursor positioning
- Clears previous messages automatically
- Works reliably across terminals
- No manual cursor management needed

**What we tried before:**
- Manual cursor positioning with ANSI escape codes (`\e[s`, `\e[u`, `\e[B`)
- Caused prompt duplication, formatting corruption, accumulation of characters
- `zle -M` solved all these issues

### 3. Navigation

**What it does:**
- Arrow keys navigate the prediction list
- Up/Down move selection
- Enter accepts selected prediction
- Falls back to normal history search when no predictions

**How it works:**
```zsh
# Wraps arrow key widgets
_zsh_readline_up() {
    if [[ $_zsh_readline_active -eq 1 ]]; then
        # Navigate list
        ((_zsh_readline_selected--))
        _zsh_readline_display
    else
        # Normal history search
        zle .up-line-or-history
    fi
}
```

**Selection preservation:**
- Tracks last input to detect navigation vs typing
- When input unchanged (navigating): keeps current selection
- When input changed (typing): tries to preserve selection by finding old command in new list

### 4. Widget Integration

**What it does:**
- Hooks into typing and deletion events
- Updates predictions on every keystroke
- Cleans up when command is submitted

**How it works:**
```zsh
# Wraps self-insert widget
_zsh_readline_self_insert() {
    zle .self-insert  # Call original
    _zsh_readline_display  # Update predictions
}

# Hooks into line editor lifecycle
zle -N zle-line-init _zsh_readline_line_init
zle -N zle-line-finish _zsh_readline_line_finish
```

## Data Structures

### State Variables

```zsh
typeset -g _zsh_readline_predictions=()  # Array of prediction strings
typeset -g _zsh_readline_selected=0       # Index of selected item (0-based)
typeset -g _zsh_readline_active=0         # Whether predictions are showing
typeset -g _zsh_readline_last_input=""    # Last input (for selection preservation)
```

### Configuration

```zsh
ZSH_READLINE_MAX_PREDICTIONS=10  # Max predictions to show
ZSH_READLINE_MIN_INPUT=1         # Min input length before showing
```

## Key Implementation Details

### Array Indexing

**Important:** Zsh arrays are 1-indexed, but we use 0-based indexing for selection.

- Display loop uses 0-based counter: `idx=0`, `idx++`
- Selection index is 0-based: `_zsh_readline_selected=0` (first item)
- When accessing array: `_zsh_readline_predictions[$((_zsh_readline_selected+1))]`

This was a source of bugs - the off-by-one error where selection showed one item but selected another.

### Command Extraction

History lines from `fc -l` have format: `   123  command here`

We extract the command by:
1. Splitting on whitespace: `fields=(${=line})`
2. Taking everything after first field: `cmd="${(j: :)fields[2,-1]}"`
3. Joining with spaces: `${(j: :)array}` joins array elements with space

### Deduplication

Uses associative array to track seen commands:
```zsh
typeset -A seen
if [[ -z "${seen[$cmd]:-}" ]]; then
    seen[$cmd]=1
    # Add to results
fi
```

### Selection Preservation Logic

```zsh
# Check if input changed
if [[ "$input" == "$_zsh_readline_last_input" ]]; then
    # Input unchanged = navigating, keep current selection
else
    # Input changed = typing, try to preserve selection
    # by finding old selected command in new list
fi
```

## Potential enhancements

- File/completion-based predictions (future work)

- Multi-line command handling

- Color highlighting (uses `>` prefix instead for now)

## Won't be included
- History number display (removed since it clutters the UI and servers no purpose)
- Fuzzy matching (uses simple prefix matching instead to mimic psreadline module behaviour)

## Performance Considerations

- History search processes entire history on each keystroke
- For large histories (>10k entries), this could be slow
- Future optimization: cache results, limit search range
- Current implementation is fast enough for typical use (<5k history entries)

## Testing

The plugin was tested with:
- Various history sizes (100 - 5000 entries)
- Different terminal emulators (alacritty, gnome-terminal, etc.)
- Various command types (simple, complex, with special characters)
- Navigation scenarios (typing, deleting, arrow keys)

