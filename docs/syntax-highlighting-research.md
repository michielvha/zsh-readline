# Syntax Highlighting Research

## Key Finding from Reddit Thread

From: https://www.reddit.com/r/zsh/comments/how_to_colorformat_a_zle_highlight_region/

### The Problem
- ZLE highlight regions (used by zsh-syntax-highlighting) are in format: `"0 2 fg=blue 3 6 fg=cyan,underline"`
- These need to be converted to ANSI escape codes to embed in strings
- ZLE doesn't expose an API for this conversion

### The Solution (from quicknir)
- Implemented a function to convert ZLE highlight regions to ANSI escape codes
- Uses `fast-syntax-highlighting` to get highlight regions
- Converts format like `fg=blue` to ANSI codes like `\033[34m`
- Implementation referenced: https://github.com/quicknir/config/blob/5229319c3eb4f19ddadc9014e0ee2d54cb18e02f/terminal/zdotdir/my_rc.zsh#L430

### Key Insights from romkatv (powerlevel10k author)
1. **No ZLE API exists** for converting highlight regions to ANSI codes
2. **Not too difficult to implement** in zsh
3. **Use `${(%)arg}` instead of `$(print -P -- arg)`** to avoid fork
4. **Use `${(Oa)history[@]}`** to iterate history in order

### The Challenge
- When converting regions to ANSI codes, the escape codes become part of the string
- This messes up indexing when applying multiple regions
- Need to carefully track positions as you insert escape codes

## Our Situation

### Current State
- We use `zle -M` to display predictions (plain text only)
- `zle -M` does NOT support colors (confirmed by multiple sources)
- All attempts to add colors to `zle -M` messages failed

### What We Need
- A way to display colored text below the command line
- The Reddit thread approach converts ZLE regions to ANSI codes for embedding in strings
- But we still need a way to DISPLAY those colored strings below the prompt

### Possible Approaches

1. **Manual cursor positioning** (what we tried before, had issues)
   - Use `print` with ANSI codes directly
   - Save/restore cursor position
   - Issues: prompt duplication, cursor positioning problems

2. **Use zsh-syntax-highlighting's highlight regions**
   - Get highlight regions for each prediction command
   - Convert regions to ANSI codes (using approach from Reddit thread)
   - Display using manual cursor positioning (fix the issues)

3. **Check how zsh-autocomplete actually does it**
   - They claim to show colored text in listview
   - Need to examine their source code directly
   - They might use a different method than `zle -M`

## Key Discovery: `zle -R` vs `zle -M`

### Important Finding
- **`zle -R`** (refresh) might support prompt expansion sequences
- **`zle -M`** (message) does NOT support colors (confirmed by multiple sources)
- Some sources suggest using `zle -R` with prompt expansion for colored output
- However, `zle -R` is typically for refreshing the current command line, not displaying messages below it

### Example from Research
```zsh
function show_colored_message() {
  local message="%F{cyan}Your colored message here%f"
  zle -R "$message"
}
```

**Note:** This needs verification - `zle -R` might be for refreshing the current line, not displaying messages below it. According to some sources, `zle -R` also strips escape sequences.

### Confirmed Limitations
- **`zle -M`**: Does NOT support ANSI escape codes (strips them)
- **`zle -R`**: Also may strip escape sequences according to some sources
- Both commands are designed to prevent screen modifications

## Research Findings Summary

### Confirmed Facts
1. **`zle -M` does NOT support colors** - strips ANSI escape codes
2. **`zle -R` also likely strips escape codes** - designed to prevent screen modifications
3. **Both commands are security features** - prevent unintended screen changes

### The Real Solution (from research)
The Reddit thread shows converting ZLE highlight regions to ANSI codes, but that's for embedding in strings (like history files). The display method is still unclear.

### How zsh-autocomplete Might Do It
- They use Zsh's completion system which has built-in color support
- Completion listings use `list-colors` zstyle which supports colors
- They might be using the completion menu system, not `zle -M`

### Key Insight
**We might be using the wrong display method entirely!**
- `zle -M` is for plain text messages
- Completion menus have built-in color support via `list-colors`
- We might need to use Zsh's completion system instead of `zle -M`

## Next Steps (Research Only)

1. **Investigate Zsh completion system**
   - Check if we can use completion menu for listview
   - Research `list-colors` zstyle for colored completions
   - See if completion system can display history-based predictions

2. **Find quicknir's actual implementation**
   - Access: https://github.com/quicknir/config/blob/5229319c3eb4f19ddadc9014e0ee2d54cb18e02f/terminal/zdotdir/my_rc.zsh#L430
   - Study the `apply_format_to_substr` function
   - Understand how they handle indexing with escape codes
   - Note: This is for history files, not live display

3. **Examine zsh-autocomplete source directly**
   - Check if they use completion system or custom display
   - Find their actual display mechanism
   - See if they use `zle -M` at all for listview

4. **Research manual cursor positioning fixes**
   - Find solutions to prompt duplication issues
   - Look for proper cursor save/restore techniques
   - Check if there are zsh-specific methods
   - Consider using `print` with proper cursor management

## References

- Reddit thread: https://www.reddit.com/r/zsh/comments/how_to_colorformat_a_zle_highlight_region/
- quicknir's implementation: https://github.com/quicknir/config/blob/5229319c3eb4f19ddadc9014e0ee2d54cb18e02f/terminal/zdotdir/my_rc.zsh#L430
- romkatv's suggestions: Use `${(%)arg}` instead of `$(print -P -- arg)`, use `${(Oa)history[@]}`

## Technical Details from Research

### Converting ZLE Highlight Regions to ANSI Codes

From the Reddit thread, the format is:
- Input: `"0 2 fg=blue 3 6 fg=cyan,underline"`
- This means: characters 0-2 are blue, characters 3-6 are cyan with underline
- Need to convert `fg=blue` → `\033[34m`, `fg=cyan,underline` → `\033[36;4m`

### The Indexing Problem
When inserting ANSI codes into a string:
- Original: `"ls vim"` (7 chars)
- After first region (0-2): `"\033[34mls\033[0m vim"` (now longer!)
- When applying second region (3-6), the indices are wrong because escape codes changed the length
- Solution: Apply regions in reverse order (from end to start) OR track cumulative offset

### romkatv's Optimization Tips
- `${(%)arg}` - expands prompt sequences without forking (faster than `$(print -P -- arg)`)
- `${(Oa)history[@]}` - iterates history in order (oldest first)

## Critical Question

**How do we DISPLAY the colored string once we have it?**

The Reddit thread converts regions to ANSI codes for storing in history files. But for live display below the prompt:
- `zle -M` doesn't work (strips codes) - CONFIRMED
- `zle -R` probably doesn't work either - NEEDS VERIFICATION
- Manual cursor positioning had issues before - NEEDS FIXING
- **NEW:** `print -P` with `zle reset-prompt` might work - NEEDS TESTING

## Most Promising Approach

Based on research, the most promising approach is:
1. Use `print -P` with prompt expansion sequences to output colored text
2. This outputs directly to terminal (bypasses zle -M)
3. Then use `zle reset-prompt` and `zle -R` to redraw the command line
4. This should display colored text below the prompt

**Key insight:** Don't use `zle -M` at all - use `print` directly and then redraw the prompt!

## Possible Solutions to Investigate

1. **Print with prompt expansion + reset-prompt** (PROMISING)
   - Use `print -P` with prompt expansion sequences (`%F{color}`)
   - Then call `zle reset-prompt` to redraw the prompt
   - Then call `zle -R` to refresh the display
   - Example from research:
     ```zsh
     print -P "%F{cyan}Colored message%f"
     zle reset-prompt
     zle -R
     ```
   - This might work because `print -P` outputs directly to terminal (not through zle -M)
   - Need to test if this displays below the prompt correctly

2. **Fixed manual cursor positioning**
   - Use proper cursor save/restore: `\033[s` and `\033[u`
   - Clear the area before printing
   - Use `print -rn` for raw output
   - Might need to hook into `zle-line-pre-redraw` to avoid conflicts
   - Previous attempts had prompt duplication issues - need to find the fix

3. **Use completion system**
   - Zsh's completion menu supports colors via `list-colors`
   - But we're not using completions, we're using history
   - Might be able to fake it or use completion hooks

4. **Direct terminal output with proper management**
   - Use `print` with ANSI codes
   - Calculate exact positions
   - Clear and redraw on every update
   - Handle terminal resize events

## Notes

- **DO NOT IMPLEMENT YET** - This is research only
- Need to understand the full approach before attempting
- Must verify it will work with our use case (listview predictions, not history)
- The Reddit solution is for history files, not live display - we need a different approach for display

