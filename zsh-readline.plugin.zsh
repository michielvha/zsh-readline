#!/usr/bin/env zsh
# zsh-readline: ListView predictions using zle -M

# Configuration
typeset -g ZSH_READLINE_MAX_PREDICTIONS=${ZSH_READLINE_MAX_PREDICTIONS:-10}
typeset -g ZSH_READLINE_MIN_INPUT=${ZSH_READLINE_MIN_INPUT:-1}

# State
typeset -g _zsh_readline_predictions=()
typeset -g _zsh_readline_selected=0
typeset -g _zsh_readline_active=0
typeset -g _zsh_readline_last_input=""

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
    
    # Clear if empty or too short
    if [[ -z "$input" ]] || [[ ${#input} -lt $ZSH_READLINE_MIN_INPUT ]]; then
        _zsh_readline_active=0
        _zsh_readline_predictions=()
        _zsh_readline_selected=0
        zle -M ""
        return
    fi
    
    # Get predictions
    local output
    output=$(_zsh_readline_get_predictions "$input")
    
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
    
    # Check if input changed (simple way to detect if we're navigating vs typing)
    local input_changed=1
    if [[ "$input" == "$_zsh_readline_last_input" ]]; then
        input_changed=0
    fi
    _zsh_readline_last_input="$input"
    
    # Only preserve selection if input changed (when typing)
    # If input didn't change (when navigating), keep current selection
    if [[ $input_changed -eq 1 ]] && [[ -n "$old_selected_cmd" ]] && [[ $old_selected -lt ${#old_predictions[@]} ]]; then
        # Input changed - try to find old selected command in new list
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
    fi
    # If input didn't change, keep current selection (for navigation)
    
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
        [[ $_zsh_readline_selected -gt 0 ]] && ((_zsh_readline_selected--))
        _zsh_readline_display
    else
        zle .up-line-or-history
    fi
}

_zsh_readline_down() {
    if [[ $_zsh_readline_active -eq 1 ]] && [[ ${#_zsh_readline_predictions[@]} -gt 0 ]]; then
        local max=$((${#_zsh_readline_predictions[@]} - 1))
        [[ $_zsh_readline_selected -lt $max ]] && ((_zsh_readline_selected++))
        _zsh_readline_display
    else
        zle .down-line-or-history
    fi
}

# Accept
_zsh_readline_accept() {
    if [[ $_zsh_readline_active -eq 1 ]] && [[ ${#_zsh_readline_predictions[@]} -gt 0 ]]; then
        # Ensure selection is in bounds
        [[ $_zsh_readline_selected -ge ${#_zsh_readline_predictions[@]} ]] && _zsh_readline_selected=0
        [[ $_zsh_readline_selected -lt 0 ]] && _zsh_readline_selected=0
        
        # Get the selected command (zsh arrays are 1-indexed, so add 1)
        local selected_cmd="${_zsh_readline_predictions[$((_zsh_readline_selected+1))]}"
        
        # Clear and set buffer
        _zsh_readline_active=0
        _zsh_readline_selected=0
        zle -M ""
        
        BUFFER="$selected_cmd"
        CURSOR=${#BUFFER}
        zle -R
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
