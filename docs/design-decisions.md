# Design Decisions

This document explains the key architectural and design decisions made during development, and why they were chosen.

## 1. Display Method: `zle -M` vs Manual Cursor Positioning

### Decision
Use `zle -M` (ZLE message system) for displaying predictions.

### Why
**Initial approach:** Manual cursor positioning with ANSI escape codes:
```zsh
print -rn -- $'\e[s'      # Save cursor
print -rn -- $'\e[B'      # Move down
print -r -- "$line"        # Print content
print -rn -- $'\e[u'      # Restore cursor
```

**Problems encountered:**
- Prompt duplication/repetition
- Formatting corruption
- Accumulation of `>` characters
- Display issues when pressing arrow keys
- Terminal-specific behavior differences

**Solution:** `zle -M "message"`
- ZLE's built-in message system designed for this purpose
- Automatically handles cursor positioning
- Clears previous messages automatically
- Works reliably across terminals
- No manual cursor management

**Key insight:** ZLE provides `zle -M` specifically for displaying messages below the prompt without interfering with the command line. Using it instead of manual escape codes solved all display issues.

## 2. Matching Algorithm: Prefix vs Substring vs Exact

### Decision
Use prefix matching on the entire command (not just first word).

### Why
**Initial approach:** Substring matching (command contains input anywhere)
- Too broad, showed irrelevant matches
- User feedback: "we should not just search for any random string"

**Tried:** Exact matching
- Too strict, didn't show predictions when typing
- User feedback: "DONT DO EXACT MATCH PREFIX WAS PERFECT"

**Final:** Prefix matching on entire command
- Typing `make` shows: `make setup`, `make up`, `make fresh`
- Typing `make fresh` shows: `make fresh install`, `make fresh deploy`
- Predictions continue to show as you type longer commands
- Matches user expectation: "any kind of string that starts the same way"

**Implementation:**
```zsh
# Match entire command prefix
if [[ "$cmd_lower" == "$input_lower"* ]] && [[ ${#cmd_lower} -gt ${#input_lower} ]]; then
    # Command starts with input and is longer
fi
```

## 3. Selection Indicator: `>` Prefix vs Color Highlighting

### Decision
Use `>` prefix for selected item.

### Why
**Initial approach:** Color highlighting with ANSI escape codes
- More visually appealing
- But caused issues with `zle -M` (escape codes not always interpreted correctly)

**Alternative:** `>` prefix
- Simple, works everywhere
- Clear visual indicator
- No terminal compatibility issues
- User preference: "i like the highlight not the > but you are getting closer" → but `>` proved more reliable

**Final:** `>` prefix for reliability and simplicity.

## 4. Array Indexing: 0-based vs 1-based

### Decision
Use 0-based indexing for selection, convert to 1-based when accessing arrays.

### Why
**Zsh arrays are 1-indexed**, but:
- Display loop naturally uses 0-based counter: `idx=0`, `idx++`
- Selection index starts at 0: `_zsh_readline_selected=0`
- When accessing: `_zsh_readline_predictions[$((_zsh_readline_selected+1))]`

**Bug encountered:** Off-by-one error where selection showed one item but selected another. Fixed by adding `+1` when accessing array.

## 5. Selection Preservation: When to Preserve vs Reset

### Decision
Preserve selection when navigating (input unchanged), reset when typing (input changed).

### Why
**Problem:** When user navigates with arrow keys, then types, selection was being reset incorrectly.

**Solution:** Track last input
```zsh
if [[ "$input" == "$_zsh_readline_last_input" ]]; then
    # Input unchanged = navigating, keep current selection
else
    # Input changed = typing, try to preserve by finding old command in new list
fi
```

**Result:** Arrow keys work correctly, selection preserved when possible during typing.

## 6. Widget Wrapping Strategy

### Decision
Wrap `self-insert` and `backward-delete-char`, use hooks for lifecycle.

### Why
**Minimal approach:**
- Only wrap widgets we need to intercept
- Use ZLE hooks (`zle-line-init`, `zle-line-finish`) for cleanup
- Doesn't interfere with other plugins

**Alternative considered:** Wrap more widgets, but unnecessary complexity.

## 7. History Number Display

### Decision
Don't show history numbers in predictions.

### Why
**User feedback:** "there is no need to mention which line in the history it is on - psreadline does not do this either"

**Removed:** History number prefix from display.

## 8. Deduplication Strategy

### Decision
Use associative array to ensure each unique command appears only once.

### Why
**User requirement:** "if clear is in the history 50 times and i type it I only wanna see 1 suggestion for it"

**Implementation:**
```zsh
typeset -A seen
if [[ -z "${seen[$cmd]:-}" ]]; then
    seen[$cmd]=1
    # Add to results
fi
```

## 9. Minimum Input Length

### Decision
Default to `ZSH_READLINE_MIN_INPUT=1` (show predictions after 1 character).

### Why
**User experience:** Show predictions as early as possible. Can be configured if too noisy.

## 10. Maximum Predictions

### Decision
Default to `ZSH_READLINE_MAX_PREDICTIONS=10`.

### Why
**Balance:** Enough options without overwhelming the display. Configurable for user preference.

## Design Principles Applied

1. **Simplicity over features**: Focused on core functionality
2. **Reliability over fancy**: `>` prefix instead of colors
3. **Use built-in tools**: `zle -M` instead of manual escape codes
4. **User feedback driven**: Many decisions based on actual usage feedback
5. **Incremental improvement**: Fixed bugs one at a time, tested each change

## Trade-offs Made

- **Display simplicity**: `>` prefix instead of color highlighting (reliability)
- **Matching simplicity**: Prefix matching instead of fuzzy matching (performance, clarity)
- **Feature scope**: History-only instead of completion integration (focus, complexity)
- **Performance**: Process entire history each time instead of caching (simplicity)

## Future Considerations

- **Completion integration**: Query zsh completion system for file/command completions
- **Fuzzy matching**: Optional fuzzy matching for better results
- **Performance optimization**: Cache results, limit search range for large histories
- **Color highlighting**: Revisit if `zle -M` color support improves

