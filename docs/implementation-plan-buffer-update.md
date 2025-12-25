# Implementation Plan: Real-time BUFFER Updates (PowerShell ReadLine Style)

## Goal
Make the plugin behave like PowerShell ReadLine where navigating through predictions updates the command line buffer in real-time, allowing users to continue typing after selecting a prediction.

## Current Behavior
- Navigation (up/down) only changes selection indicator in message display
- BUFFER is NOT updated until Enter is pressed
- Requires pressing Enter twice (once to accept selection, once to execute)

## Desired Behavior
- When pressing DOWN: Update BUFFER with selected prediction, cycle through all matches
- When pressing UP at index 0: Restore original typed input (not the first prediction)
- Selected prediction appears directly in the terminal line
- User can continue typing after selecting a prediction
- Pressing Enter executes current BUFFER (no double-press needed)

## State Changes Needed

### New State Variable
```zsh
typeset -g _zsh_readline_original_input=""
```
Tracks the original input typed by user before navigation started. This allows us to restore it when going back up past the first prediction.

### State Management Logic
1. **When user types (self-insert/delete):**
   - Update `_zsh_readline_original_input` = current BUFFER
   - This becomes the new "base" for navigation

2. **When user navigates (up/down):**
   - DO NOT update `_zsh_readline_original_input`
   - Update BUFFER with selected prediction
   - When at index 0 and pressing UP, restore `_zsh_readline_original_input` to BUFFER

## Implementation Steps

### Step 1: Add Original Input Tracking
- Add `_zsh_readline_original_input` state variable
- Initialize in `_zsh_readline_line_init()`

### Step 2: Update `_zsh_readline_display()` 
- When input changes (user is typing):
  - Set `_zsh_readline_original_input = BUFFER`
  - Reset selection to 0
- When input unchanged (user is navigating):
  - Keep current selection
  - DO NOT update `_zsh_readline_original_input`

### Step 3: Update `_zsh_readline_up()`
- If `_zsh_readline_selected == 0`:
  - Restore BUFFER to `_zsh_readline_original_input`
  - Keep selection at 0
  - Update display
- Else:
  - Decrement selection
  - Update BUFFER with selected prediction
  - Update display

### Step 4: Update `_zsh_readline_down()`
- Increment selection (if not at max)
- Update BUFFER with selected prediction
- Update display

### Step 5: Simplify `_zsh_readline_accept()`
- Since BUFFER already contains the selected command (when navigating) or original input (when at index 0)
- Just execute the current BUFFER
- Clear predictions and state

### Step 6: Handle Edge Cases
- When predictions change while navigating, selection should adjust but BUFFER should stay consistent
- When user types after navigating, update original_input to new typed value
- Ensure cursor position is at end of BUFFER after navigation

## Key Implementation Details

### Detecting Navigation vs Typing
Use the existing `_zsh_readline_last_input` comparison:
- If `BUFFER == _zsh_readline_last_input`: Navigation (arrow keys)
- If `BUFFER != _zsh_readline_last_input`: Typing (character input)

### Updating BUFFER During Navigation
```zsh
# In _zsh_readline_up/_zsh_readline_down
local selected_cmd="${_zsh_readline_predictions[$((_zsh_readline_selected+1))]}"
BUFFER="$selected_cmd"
CURSOR=${#BUFFER}  # Move cursor to end
```

### Restoring Original Input
```zsh
# When at index 0 and pressing UP
BUFFER="$_zsh_readline_original_input"
CURSOR=${#BUFFER}
```

### Updating Original Input When Typing
```zsh
# In _zsh_readline_display when input changed
if [[ "$input" != "$_zsh_readline_last_input" ]]; then
    _zsh_readline_original_input="$input"
fi
```

## Testing Scenarios

1. **Type → Navigate Down → Navigate Up → Restore Original**
   - Type "ssh sys"
   - Press DOWN → BUFFER = first prediction
   - Press DOWN → BUFFER = second prediction  
   - Press UP → BUFFER = first prediction
   - Press UP → BUFFER = "ssh sys" (original)

2. **Navigate → Continue Typing**
   - Type "ssh sys"
   - Press DOWN → BUFFER = first prediction
   - Type "admin" → BUFFER = "first_prediction" + "admin", original_input updated

3. **Navigate → Execute**
   - Type "ssh sys"
   - Press DOWN → BUFFER = first prediction
   - Press Enter → Executes first prediction

4. **Type → Execute (no navigation)**
   - Type "ssh sys"
   - Press Enter → Executes "ssh sys" (normal behavior)

## Potential Issues to Watch For

1. **Circular reference**: When updating BUFFER during navigation, `_zsh_readline_display()` might detect it as "input changed" and reset original_input
   - Solution: Use a flag or skip original_input update when in navigation mode

2. **Selection sync**: BUFFER might not match selected prediction after predictions refresh
   - Solution: After refreshing predictions, check if current BUFFER matches any prediction, adjust selection accordingly

3. **Cursor position**: Ensure cursor is always at end after navigation
   - Solution: Set `CURSOR=${#BUFFER}` after each BUFFER update

4. **Edge case at index 0**: When at index 0, pressing UP should restore original, but what if original IS the first prediction?
   - Solution: Always restore original when at index 0 and pressing UP, regardless of match

