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
- **`zle -M`** (message) does NOT support colors (confirmed)
- Some sources suggest using `zle -R` with prompt expansion for colored output

### Example from Research
```zsh
function show_colored_message() {
  local message="%F{cyan}Your colored message here%f"
  zle -R "$message"
}
```

**Note:** This needs verification - `zle -R` might be for refreshing the current line, not displaying messages below it.

## Next Steps (Research Only)

1. **Verify `zle -R` usage**
   - Check if `zle -R` can display messages below prompt
   - Or if it only refreshes the current command line
   - Test if prompt expansion works with `zle -R`

2. **Find quicknir's actual implementation**
   - Look for the GitHub link mentioned in Reddit thread
   - Study the `apply_format_to_substr` function
   - Understand how they handle indexing with escape codes

3. **Examine zsh-autocomplete source directly**
   - Clone the repo and examine their display code
   - Find how they display colored listview items
   - Check if they use `zle -M`, `zle -R`, or manual cursor positioning

4. **Research manual cursor positioning fixes**
   - Find solutions to prompt duplication issues
   - Look for proper cursor save/restore techniques
   - Check if there are zsh-specific methods

## References

- Reddit thread: https://www.reddit.com/r/zsh/comments/how_to_colorformat_a_zle_highlight_region/
- quicknir's implementation: https://github.com/quicknir/config/blob/5229319c3eb4f19ddadc9014e0ee2d54cb18e02f/terminal/zdotdir/my_rc.zsh#L430
- romkatv's suggestions: Use `${(%)arg}` instead of `$(print -P -- arg)`, use `${(Oa)history[@]}`

## Notes

- **DO NOT IMPLEMENT YET** - This is research only
- Need to understand the full approach before attempting
- Must verify it will work with our use case (listview predictions, not history)

