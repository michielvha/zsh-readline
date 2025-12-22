# Technical Details

Deep dive into the technical implementation, ZLE internals, and how everything works together.

## ZLE (Zsh Line Editor) Overview

ZLE is Zsh's command-line editing system. It provides:
- Widget system for custom key bindings
- Hooks for lifecycle events
- Message system for displaying information
- Buffer management for command line

### Key ZLE Concepts

**Widgets:** Functions bound to key sequences
```zsh
zle -N my_widget _my_widget_function
bindkey '^X' my_widget
```

**Widget Wrapping:** Override default widgets
```zsh
# Save original
zle -A self-insert _self_insert_original
# Replace with wrapper
zle -A _my_wrapper self-insert
```

**Hooks:** Lifecycle events
```zsh
zle -N zle-line-init _on_line_init
zle -N zle-line-finish _on_line_finish
```

**Message System:** Display below prompt
```zsh
zle -M "message"  # Display message
zle -M ""         # Clear message
```

## Widget System

### Widget Wrappers

We wrap two default widgets:

1. **`self-insert`**: Called on every character typed
```zsh
_zsh_readline_self_insert() {
    zle .self-insert              # Call original widget
    _zsh_readline_display         # Update predictions
}
```

2. **`backward-delete-char`**: Called on backspace
```zsh
_zsh_readline_backward_delete_char() {
    zle .backward-delete-char     # Call original widget
    _zsh_readline_display         # Update predictions
}
```

**Why wrap?** We need to update predictions on every keystroke. Wrapping allows us to intercept typing without breaking normal ZLE behavior.

### Navigation Widgets

We create custom widgets for arrow keys:

```zsh
_zsh_readline_up() {
    if [[ $_zsh_readline_active -eq 1 ]]; then
        # Navigate prediction list
        ((_zsh_readline_selected--))
        _zsh_readline_display
    else
        # Fall back to normal history
        zle .up-line-or-history
    fi
}
```

**Key insight:** Only intercept when predictions are active. Otherwise, let normal ZLE behavior work.

### Accept Widget

```zsh
_zsh_readline_accept() {
    if [[ $_zsh_readline_active -eq 1 ]]; then
        # Get selected command (convert 0-based to 1-based)
        local cmd="${_zsh_readline_predictions[$((_zsh_readline_selected+1))]}"
        BUFFER="$cmd"
        CURSOR=${#BUFFER}
        zle -M ""  # Clear predictions
    else
        # Normal Enter behavior
        zle .accept-line
    fi
}
```

## History Access

### Getting History

```zsh
fc -l -$HISTSIZE -1
```

- `-l`: List format (with history numbers)
- `-$HISTSIZE`: Start from oldest entry
- `-1`: End at most recent entry

**Output format:**
```
   123  command here
   124  another command
```

### Parsing History

```zsh
# Split line on whitespace
fields=(${=line})

# Get command (everything after history number)
cmd="${(j: :)fields[2,-1]}"
```

**Zsh parameter expansion:**
- `${=line}`: Split on whitespace into array
- `${(j: :)array}`: Join array with spaces
- `${array[2,-1]}`: Slice from index 2 to end

### Matching Logic

```zsh
# Case-insensitive comparison
local cmd_lower="${(L)cmd}"
local input_lower="${(L)input}"

# Prefix match: command starts with input and is longer
if [[ "$cmd_lower" == "$input_lower"* ]] && [[ ${#cmd_lower} -gt ${#input_lower} ]]; then
    # Match!
fi
```

**Zsh parameter expansion:**
- `${(L)var}`: Convert to lowercase
- `${#var}`: Length of string
- `[[ "$str1" == "$str2"* ]]`: Prefix match

## Display System

### Building the Message

```zsh
local msg=""
local idx=0
for cmd in "${_zsh_readline_predictions[@]}"; do
    local prefix="  "
    [[ $idx -eq $_zsh_readline_selected ]] && prefix="> "
    
    [[ -n "$msg" ]] && msg+=$'\n'
    msg+="${prefix}${show}"
    ((idx++))
done

zle -M "$msg"
```

**Key points:**
- Build message with newlines (`$'\n'`)
- Mark selected item with `>` prefix
- `zle -M` handles display and cursor positioning

### Why `zle -M` Works

`zle -M` is ZLE's message system:
- Designed for displaying information below the prompt
- Automatically handles cursor save/restore
- Clears previous messages
- Works across terminals
- Doesn't interfere with command line editing

**Alternative (manual escape codes) failed because:**
- Cursor save/restore (`\e[s`, `\e[u`) unreliable
- Terminal-specific behavior
- Prompt duplication issues
- Formatting corruption

## State Management

### Global State Variables

```zsh
typeset -g _zsh_readline_predictions=()  # Array of predictions
typeset -g _zsh_readline_selected=0      # Selection index (0-based)
typeset -g _zsh_readline_active=0        # Whether showing predictions
typeset -g _zsh_readline_last_input=""    # Last input (for preservation)
```

**Why `typeset -g`?**
- `-g`: Global scope (accessible everywhere)
- Needed because widgets are called in different contexts

### Selection Preservation

```zsh
# Track input changes
if [[ "$input" == "$_zsh_readline_last_input" ]]; then
    # Input unchanged = navigating, keep selection
else
    # Input changed = typing, try to preserve
    # by finding old selected command in new list
fi
_zsh_readline_last_input="$input"
```

**Why this works:**
- Navigation doesn't change input → keep selection
- Typing changes input → try to preserve by finding old command

## Array Indexing Quirks

### Zsh Arrays are 1-indexed

```zsh
array=(a b c)
echo $array[1]  # "a" (first element)
echo $array[0]  # Empty (doesn't exist)
```

### Our Approach

- **Selection index:** 0-based (`_zsh_readline_selected=0` for first item)
- **Display loop:** 0-based counter (`idx=0`, `idx++`)
- **Array access:** Convert to 1-based (`array[$((idx+1))]`)

**Bug fix:** Off-by-one error where selection showed one item but selected another. Fixed by adding `+1` when accessing array.

## Performance Considerations

### Current Implementation

- Processes entire history on each keystroke
- No caching
- No search range limiting

### For Large Histories

With 10,000+ history entries:
- Search takes ~100-200ms per keystroke
- Noticeable lag

### Potential Optimizations

1. **Cache results:** Store predictions for input, reuse if input unchanged
2. **Limit search range:** Only search recent N entries
3. **Debounce:** Delay update slightly to avoid processing every keystroke
4. **Background processing:** Search in background, update when ready

**Current performance:** Fast enough for typical use (<5k entries).

## Terminal Compatibility

### Tested Terminals

- ✅ Alacritty
- ✅ GNOME Terminal
- ✅ Konsole
- ✅ xterm
- ✅ tmux/screen

### Key Codes

Arrow keys have different codes:
```zsh
bindkey '^[[A' _zsh_readline_up   # VT100-style
bindkey '^[OA' _zsh_readline_up   # Application mode
```

We bind both variants for compatibility.

## Error Handling

### History Access

```zsh
fc -l -$HISTSIZE -1 2>/dev/null
```

Redirect errors to `/dev/null` in case history is empty or unavailable.

### Empty Input

```zsh
if [[ -z "$input" ]] || [[ ${#input} -lt $ZSH_READLINE_MIN_INPUT ]]; then
    _zsh_readline_active=0
    zle -M ""
    return
fi
```

Clear predictions when input is empty or too short.

### Bounds Checking

```zsh
[[ $_zsh_readline_selected -ge ${#_zsh_readline_predictions[@]} ]] && _zsh_readline_selected=0
[[ $_zsh_readline_selected -lt 0 ]] && _zsh_readline_selected=0
```

Ensure selection index is always valid.

## Integration Points

### With Other Plugins

**zsh-syntax-highlighting:**
- No conflict: We don't modify command line
- Works together: Syntax highlighting on line, predictions below

**zsh-autosuggestions:**
- Potential conflict: Both hook into typing
- Solution: Can run together (autosuggestions inline, predictions below)

**zsh-history-substring-search:**
- Arrow key conflict: Both use arrow keys
- Solution: Our plugin intercepts when active, falls back when inactive

### ZLE Lifecycle

```zsh
zle-line-init    # Called when starting new line
zle-line-finish  # Called when submitting line
```

We use these hooks to:
- Reset state on new line
- Clear predictions on submit

