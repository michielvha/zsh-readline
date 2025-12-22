# Troubleshooting

Common issues and solutions for zsh-readline.

## Predictions Not Showing

### Check History Configuration

Make sure history is enabled in your `.zshrc`:

```zsh
setopt SHARE_HISTORY    # or APPEND_HISTORY
HISTSIZE=10000
SAVEHIST=10000
```

### Check Minimum Input Length

If `ZSH_READLINE_MIN_INPUT` is set too high, predictions won't show:

```zsh
# Default is 1, try lowering if needed
ZSH_READLINE_MIN_INPUT=1
```

### Verify Plugin is Loaded

```zsh
# Check if widgets are registered
zle -l | grep _zsh_readline

# Should show:
# _zsh_readline_self_insert
# _zsh_readline_backward_delete_char
# _zsh_readline_up
# _zsh_readline_down
# _zsh_readline_accept
```

## Arrow Keys Not Working

### Check Key Bindings

Some terminals use different key codes. Check what your terminal sends:

```zsh
# In zsh, type Ctrl+V then press arrow key
# You'll see the key code

# Common codes:
# ^[[A = Up arrow (VT100)
# ^[OA = Up arrow (Application mode)
```

### Add Custom Bindings

If your terminal uses different codes:

```zsh
# Add to .zshrc after sourcing plugin
bindkey '^[A' _zsh_readline_up    # Your terminal's up arrow
bindkey '^[B' _zsh_readline_down   # Your terminal's down arrow
```

### Check for Conflicts

Other plugins might be binding arrow keys:

```zsh
# Check current bindings
bindkey | grep '\[A\|OA'

# If zsh-history-substring-search is active, it might conflict
# Our plugin should handle this, but if issues persist, try:
# Disable history-substring-search when predictions are active
```

## Wrong Item Selected

### Off-by-One Error

If the `>` shows one item but a different item is selected:

**This was a bug we fixed.** Make sure you have the latest version. The fix was:
- Array access: `_zsh_readline_predictions[$((_zsh_readline_selected+1))]`
- Zsh arrays are 1-indexed, selection is 0-based

### Selection Not Moving

If arrow keys don't move the selection:

1. Check if predictions are active: `echo $_zsh_readline_active` (should be 1)
2. Check selection index: `echo $_zsh_readline_selected`
3. Verify key bindings (see above)

## Display Issues

### Predictions Overlap Prompt

If predictions appear to overlap with your prompt:

- This shouldn't happen with `zle -M`, but if it does:
- Try adjusting your prompt
- Check if other plugins are interfering

### Predictions Don't Clear

If predictions stay visible after submitting command:

- Check `zle-line-finish` hook is working
- Verify: `zle -l | grep zle-line-finish`

### Formatting Corruption

If you see weird characters or formatting:

- Make sure you're using `zle -M` (not manual escape codes)
- Check terminal compatibility
- Try a different terminal emulator

## Performance Issues

### Slow Updates

If predictions are slow to update:

1. **Check history size:**
   ```zsh
   echo $HISTSIZE
   fc -l | wc -l
   ```

2. **Large history (>10k entries):**
   - Consider reducing `HISTSIZE`
   - Or implement caching (future feature)

3. **Reduce max predictions:**
   ```zsh
   ZSH_READLINE_MAX_PREDICTIONS=5
   ```

## Plugin Conflicts

### With zsh-autosuggestions

Both plugins hook into typing. They should work together:
- Autosuggestions: inline gray suggestion
- zsh-readline: list below command line

If conflicts occur:
- Try loading order: autosuggestions first, then zsh-readline
- Or disable autosuggestions when ListView is active (future feature)

### With zsh-history-substring-search

Both use arrow keys. Our plugin handles this:
- When predictions active: arrow keys navigate list
- When inactive: arrow keys work normally (history-substring-search)

If issues:
- Check widget wrapping isn't interfering
- Verify fallback to `.up-line-or-history` works

### With zsh-syntax-highlighting

Should work fine together. If issues:
- Check loading order
- Syntax highlighting shouldn't interfere with `zle -M`

## Debugging

### Enable Debug Output

Add to `.zshrc` before sourcing plugin:

```zsh
# Debug mode
_zsh_readline_debug() {
    echo "Active: $_zsh_readline_active"
    echo "Selected: $_zsh_readline_selected"
    echo "Predictions: ${#_zsh_readline_predictions[@]}"
    echo "Last input: $_zsh_readline_last_input"
}
```

### Check Widget State

```zsh
# List all widgets
zle -l | grep _zsh_readline

# Check if widgets are bound
bindkey | grep _zsh_readline
```

### Test History Access

```zsh
# Test if history is accessible
fc -l | head -5

# Test history size
fc -l | wc -l
```

### Test Predictions Function

```zsh
# Test prediction function directly
BUFFER="cd"
_zsh_readline_get_predictions "$BUFFER"
```

## Common Configuration Issues

### Plugin Not Loading

```zsh
# Check if file exists and is readable
ls -l ~/.zsh-readline/zsh-readline.plugin.zsh

# Check if sourced
grep zsh-readline ~/.zshrc

# Try sourcing manually
source ~/.zsh-readline/zsh-readline.plugin.zsh
```

### Configuration Not Applied

Make sure configuration variables are set **before** sourcing:

```zsh
# Correct order
ZSH_READLINE_MAX_PREDICTIONS=15
ZSH_READLINE_MIN_INPUT=2
source ~/.zsh-readline/zsh-readline.plugin.zsh
```

## Getting Help

If issues persist:

1. Check you have the latest version
2. Review [Technical Details](technical-details.md) for implementation specifics
3. Check [Development Notes](development-notes.md) for known issues
4. Verify your zsh version: `zsh --version` (should be 5.0+)

## Reporting Issues

When reporting issues, include:
- Zsh version: `zsh --version`
- Terminal emulator
- Other plugins loaded
- Configuration variables set
- Steps to reproduce
- Expected vs actual behavior

