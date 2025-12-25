#!/usr/bin/env zsh
# zsh-readline: ListView predictions using zle -M

# Configuration
typeset -g ZSH_READLINE_MAX_PREDICTIONS=${ZSH_READLINE_MAX_PREDICTIONS:-10}
typeset -g ZSH_READLINE_MIN_INPUT=${ZSH_READLINE_MIN_INPUT:-1}
typeset -g ZSH_READLINE_REMOVE_DUPLICATE_HISTORY_ENTRIES=${ZSH_READLINE_REMOVE_DUPLICATE_HISTORY_ENTRIES:-0}

# Configure history deduplication if enabled
if [[ ${ZSH_READLINE_REMOVE_DUPLICATE_HISTORY_ENTRIES:-0} -eq 1 ]]; then
    setopt HIST_IGNORE_ALL_DUPS    # Remove all previous occurrences when duplicate is added
    setopt HIST_SAVE_NO_DUPS       # Don't write duplicates to file
    setopt HIST_EXPIRE_DUPS_FIRST  # Remove duplicates first when trimming history
fi

# State
typeset -g _zsh_readline_predictions=()
typeset -g _zsh_readline_selected=0
typeset -g _zsh_readline_active=0
typeset -g _zsh_readline_last_input=""
typeset -g _zsh_readline_original_input=""

# Get predictions - match entire command prefix
_zsh_readline_get_predictions() {
    local input="$1"
    [[ -z "$input" ]] && return
    
    local input_lower="${(L)input}"
    typeset -A seen
    
    local -a lines
    lines=(${(f)"$(fc -l -$HISTSIZE -1 2>/dev/null)"})
    
    for line in "${lines[@]}"; do
        [[ -z "$line" ]] && continue
        
        local -a fields
        fields=(${=line})
        [[ ${#fields[@]} -lt 2 ]] && continue
        
        local cmd="${(j: :)fields[2,-1]}"
        [[ -z "$cmd" ]] && continue
        
        # Match entire command prefix (not just first word)
        local cmd_lower="${(L)cmd}"
        
        # Command must start with input and be longer
        if [[ "$cmd_lower" == "$input_lower"* ]] && [[ ${#cmd_lower} -gt ${#input_lower} ]]; then
            # Don't show exact match
            [[ "$cmd_lower" == "$input_lower" ]] && continue
            
            if [[ -z "${seen[$cmd]:-}" ]]; then
                seen[$cmd]=1
                print -r -- "$cmd"
                [[ ${#seen[@]} -ge $ZSH_READLINE_MAX_PREDICTIONS ]] && break
            fi
        fi
    done
}

# Display using zle -M
_zsh_readline_display() {
    local input="$BUFFER"
    
    # Check if input changed (simple way to detect if we're navigating vs typing)
    local input_changed=1
    if [[ "$input" == "$_zsh_readline_last_input" ]]; then
        input_changed=0
    fi
    
    # If input changed (user is typing), update original input first
    if [[ $input_changed -eq 1 ]]; then
        _zsh_readline_original_input="$input"
    fi
    
    # Determine prediction base: use original_input when navigating, BUFFER when typing
    local prediction_base="$input"
    if [[ -n "$_zsh_readline_original_input" ]] && [[ "$input" != "$_zsh_readline_original_input" ]]; then
        # Navigating: BUFFER is a prediction, use original_input for predictions
        prediction_base="$_zsh_readline_original_input"
    fi
    
    # Clear if empty or too short
    if [[ -z "$prediction_base" ]] || [[ ${#prediction_base} -lt $ZSH_READLINE_MIN_INPUT ]]; then
        _zsh_readline_active=0
        _zsh_readline_predictions=()
        _zsh_readline_selected=0
        zle -M ""
        return
    fi
    
    # Get predictions based on what user typed (original_input when navigating, BUFFER when typing)
    local output
    output=$(_zsh_readline_get_predictions "$prediction_base")
    
    # Store old predictions to preserve selection if possible
    local -a old_predictions=("${_zsh_readline_predictions[@]}")
    local old_selected="$_zsh_readline_selected"
    local old_selected_cmd=""
    [[ $old_selected -lt ${#old_predictions[@]} ]] && old_selected_cmd="${old_predictions[$old_selected]}"
    
    _zsh_readline_predictions=()
    if [[ -n "$output" ]]; then
        local -a all
        all=(${(f)output})
        
        typeset -A final
        for p in "${all[@]}"; do
            [[ -z "$p" ]] && continue
            p="${p##[[:space:]]}"
            p="${p%%[[:space:]]}"
            [[ -z "$p" ]] && continue
            
            if [[ -z "${final[$p]:-}" ]]; then
                final[$p]=1
                _zsh_readline_predictions+=("$p")
                [[ ${#_zsh_readline_predictions[@]} -ge $ZSH_READLINE_MAX_PREDICTIONS ]] && break
            fi
        done
    fi
    
    if [[ ${#_zsh_readline_predictions[@]} -eq 0 ]]; then
        _zsh_readline_active=0
        _zsh_readline_selected=0
        zle -M ""
        return
    fi
    
    _zsh_readline_active=1
    
    # If input changed (user is typing), reset selection appropriately
    if [[ $input_changed -eq 1 ]]; then
        # Try to preserve selection by finding old selected command in new list
        if [[ -n "$old_selected_cmd" ]] && [[ $old_selected -lt ${#old_predictions[@]} ]]; then
            local new_idx=0
            local found=0
            for cmd in "${_zsh_readline_predictions[@]}"; do
                if [[ "$cmd" == "$old_selected_cmd" ]]; then
                    _zsh_readline_selected=$new_idx
                    found=1
                    break
                fi
                ((new_idx++))
            done
            # If not found, reset to 0
            if [[ $found -eq 0 ]]; then
                _zsh_readline_selected=0
            fi
        else
            _zsh_readline_selected=0
        fi
    fi
    # If input didn't change, keep current selection (for navigation)
    
    _zsh_readline_last_input="$input"
    
    # Final bounds check (0-based indexing)
    [[ $_zsh_readline_selected -ge ${#_zsh_readline_predictions[@]} ]] && _zsh_readline_selected=0
    [[ $_zsh_readline_selected -lt 0 ]] && _zsh_readline_selected=0
    
    # Build message for zle -M
    local msg=""
    local idx=0
    for cmd in "${_zsh_readline_predictions[@]}"; do
        local prefix="  "
        [[ $idx -eq $_zsh_readline_selected ]] && prefix="> "
        
        local show="$cmd"
        [[ ${#show} -gt 100 ]] && show="${show:0:100}..."
        
        [[ -n "$msg" ]] && msg+=$'\n'
        msg+="${prefix}${show}"
        ((idx++))
    done
    
    zle -M "$msg"
}

# Wrappers
_zsh_readline_self_insert() {
    zle .self-insert
    _zsh_readline_display
}

_zsh_readline_backward_delete_char() {
    zle .backward-delete-char
    _zsh_readline_display
}

# Navigation
_zsh_readline_up() {
    if [[ $_zsh_readline_active -eq 1 ]] && [[ ${#_zsh_readline_predictions[@]} -gt 0 ]]; then
        # If at index 0, restore original input; otherwise go to previous prediction
        if [[ $_zsh_readline_selected -eq 0 ]]; then
            # Restore original input
            BUFFER="$_zsh_readline_original_input"
            CURSOR=${#BUFFER}
            # Set last_input to prevent display() from updating original_input
            _zsh_readline_last_input="$BUFFER"
        else
            # Go to previous prediction
            ((_zsh_readline_selected--))
            local selected_cmd="${_zsh_readline_predictions[$((_zsh_readline_selected+1))]}"
            BUFFER="$selected_cmd"
            CURSOR=${#BUFFER}
            # Set last_input to prevent display() from updating original_input
            _zsh_readline_last_input="$BUFFER"
        fi
        _zsh_readline_display
    else
        zle .up-line-or-history
    fi
}

_zsh_readline_down() {
    if [[ $_zsh_readline_active -eq 1 ]] && [[ ${#_zsh_readline_predictions[@]} -gt 0 ]]; then
        # If BUFFER matches original input, start at first prediction
        if [[ "$BUFFER" == "$_zsh_readline_original_input" ]]; then
            _zsh_readline_selected=0
        else
            local max=$((${#_zsh_readline_predictions[@]} - 1))
            # If at max, wrap to 0; otherwise go to next prediction
            if [[ $_zsh_readline_selected -lt $max ]]; then
                ((_zsh_readline_selected++))
            else
                _zsh_readline_selected=0
            fi
        fi
        # Update BUFFER with selected prediction
        local selected_cmd="${_zsh_readline_predictions[$((_zsh_readline_selected+1))]}"
        BUFFER="$selected_cmd"
        CURSOR=${#BUFFER}
        # Set last_input to prevent display() from updating original_input
        _zsh_readline_last_input="$BUFFER"
        _zsh_readline_display
    else
        zle .down-line-or-history
    fi
}

# Accept
_zsh_readline_accept() {
    if [[ $_zsh_readline_active -eq 1 ]] && [[ ${#_zsh_readline_predictions[@]} -gt 0 ]]; then
        # BUFFER already contains the selected command (from navigation) or original input
        # Just execute it - no need to set BUFFER again
        _zsh_readline_active=0
        _zsh_readline_selected=0
        zle -M ""
        zle .accept-line
    else
        zle .accept-line
    fi
}

# Register
zle -N _zsh_readline_self_insert
zle -N _zsh_readline_backward_delete_char
zle -N _zsh_readline_up
zle -N _zsh_readline_down
zle -N _zsh_readline_accept

# Hooks
_zsh_readline_line_init() {
    _zsh_readline_active=0
    _zsh_readline_selected=0
    _zsh_readline_last_input=""
    _zsh_readline_original_input=""
}

_zsh_readline_line_finish() {
    zle -M ""
    _zsh_readline_active=0
    _zsh_readline_selected=0
}

zle -N zle-line-init _zsh_readline_line_init
zle -N zle-line-finish _zsh_readline_line_finish

# Replace widgets
if ! zle -l _zsh_readline_self_insert_orig >/dev/null 2>&1; then
    zle -A self-insert _zsh_readline_self_insert_orig
fi
zle -A _zsh_readline_self_insert self-insert

if ! zle -l _zsh_readline_backward_delete_char_orig >/dev/null 2>&1; then
    zle -A backward-delete-char _zsh_readline_backward_delete_char_orig
fi
zle -A _zsh_readline_backward_delete_char backward-delete-char

# Bind keys
bindkey '^[[A' _zsh_readline_up
bindkey '^[OA' _zsh_readline_up
bindkey '^[[B' _zsh_readline_down
bindkey '^[OB' _zsh_readline_down
bindkey '^M' _zsh_readline_accept
