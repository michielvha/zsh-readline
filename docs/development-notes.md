# Development Notes

Lessons learned, challenges faced, and insights gained during development.

## Major Challenges

### 1. Display System

**Problem:** Initial attempts with manual cursor positioning caused:
- Prompt duplication
- Formatting corruption
- Accumulation of characters
- Terminal-specific issues

**Solution:** Switched to `zle -M` (ZLE message system)

**Lesson:** Use built-in tools when available. ZLE provides `zle -M` specifically for this purpose.

### 2. Array Indexing

**Problem:** Off-by-one errors where selection showed one item but selected another.

**Root cause:** Zsh arrays are 1-indexed, but we used 0-based selection index.

**Solution:** Convert when accessing: `array[$((index+1))]`

**Lesson:** Be explicit about indexing conventions. Document clearly.

### 3. Selection Preservation

**Problem:** Selection reset incorrectly when navigating vs typing.

**Root cause:** Couldn't distinguish between navigation (arrow keys) and typing (input change).

**Solution:** Track last input, preserve selection when input unchanged.

**Lesson:** State management needs clear signals for different modes of operation.

### 4. Matching Algorithm

**Problem:** Iterated through substring → exact → prefix matching based on user feedback.

**Root cause:** Unclear requirements initially.

**Solution:** Prefix matching on entire command (not just first word).

**Lesson:** User feedback is crucial. Iterate quickly based on actual usage.

## Key Insights

### ZLE Message System

`zle -M` is the right tool for displaying messages below the prompt:
- Designed for this exact purpose
- Handles cursor positioning automatically
- Clears previous messages
- Works across terminals

**Don't try to reinvent this with escape codes.**

### Widget Wrapping

Wrapping widgets is straightforward:
```zsh
# Save original
zle -A self-insert _self_insert_original
# Replace
zle -A _my_wrapper self-insert
# In wrapper, call original
zle .self-insert
```

**Always call the original widget** to maintain normal ZLE behavior.

### History Parsing

`fc -l` output format is consistent:
```
   123  command here
```

Split on whitespace, take everything after first field. Simple and reliable.

### State Management

Global state with `typeset -g` works well for widgets:
- Accessible from all widget functions
- Persists across widget calls
- Simple to manage

## Bugs Fixed

### 1. Character Duplication

**Symptom:** First character typed appeared duplicated in suggestions (e.g., `c` → `cclear`)

**Cause:** Variable name collision in command extraction

**Fix:** Use unique variable names, explicit array slicing

### 2. Suggestions Not Clearing

**Symptom:** Suggestions stayed visible when buffer was empty

**Cause:** Not explicitly clearing when input empty

**Fix:** Added explicit clear check in display function

### 3. Wrong Selection

**Symptom:** `>` showed one item but different item was selected

**Cause:** Array indexing off-by-one

**Fix:** Convert 0-based selection to 1-based array access

### 4. Selection Not Moving

**Symptom:** Arrow keys didn't move selection

**Cause:** Selection preservation logic resetting selection during navigation

**Fix:** Track input changes, preserve selection when input unchanged

### 5. Predictions Disappearing

**Symptom:** Predictions disappeared when typing full command

**Cause:** Filtering out exact matches too aggressively

**Fix:** Changed to prefix matching on entire command, not filtering exact matches

## Design Evolution

### Initial Design
- Manual cursor positioning
- Substring matching
- Color highlighting
- Complex state management

### Final Design
- `zle -M` for display
- Prefix matching
- `>` prefix indicator
- Simple state management

**Evolution driven by:**
- User feedback
- Bug fixes
- Simplicity preference
- Reliability requirements

## Performance Observations

### Current Performance
- Fast enough for typical use (<5k history entries)
- ~50-100ms per keystroke for 5k entries
- No noticeable lag

### Potential Issues
- Large histories (>10k entries) could be slow
- No caching currently
- Processes entire history each time

### Future Optimizations
- Cache results for unchanged input
- Limit search to recent N entries
- Debounce updates
- Background processing

## Testing Approach

### Manual Testing
- Tested with various history sizes
- Different terminal emulators
- Various command types
- Navigation scenarios

### User-Driven Testing
- Real-world usage feedback
- Iterative improvements
- Bug reports and fixes

**Lesson:** Real usage reveals issues that testing doesn't.

## Code Quality

### What Worked Well
- Simple, focused functions
- Clear variable names
- Explicit error handling
- Good separation of concerns

### Areas for Improvement
- Could add more comments
- Could extract some magic numbers to constants
- Could add input validation
- Could add unit tests (if testing framework available)

## Future Work

### Completion Integration
- Query zsh completion system
- Display file/command completions
- Merge with history predictions

### Performance
- Cache results
- Limit search range
- Debounce updates

### Features
- Fuzzy matching option
- Color highlighting (if `zle -M` supports it)
- Multi-line command handling
- History number display option

## Lessons for Future Development

1. **Use built-in tools:** `zle -M` instead of escape codes
2. **Be explicit:** Clear indexing, clear state management
3. **Iterate quickly:** User feedback drives better design
4. **Keep it simple:** Simpler is more reliable
5. **Test in real usage:** Manual testing reveals real issues