# zsh-readline

A Zsh plugin that provides ListView-style history predictions - displays matching history entries in a list below your command line as you type.

<video src="https://github.com/user-attachments/assets/99ab1fc8-b48f-4a81-9bbc-bf4b1dfbf490" controls loop muted autoplay></video>

## Features

> [!NOTE]
> This plugin is intentionally focused on history-based predictions with prefix matching. For file/completion-based predictions, zsh's built-in completion system already handles this. For fuzzy matching, see [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete) - this plugin intentionally uses prefix matching to match PSReadline's behavior.

- **ListView-style predictions**: Shows matching history entries in a list below your command line
- **Real-time filtering**: Updates as you type
- **Keyboard navigation**: Use ↑/↓ arrow keys to navigate, Enter to select
- **Non-intrusive**: Uses ZLE's message system - doesn't mess up terminal formatting
- **Lightweight**: Simple, focused implementation
- **Prefix matching**: Matches entire command prefix (not just first word)

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for quick installation and basic usage examples.

## Documentation

Complete documentation is available in the [`docs/`](docs/) folder:

- **[Implementation Guide](docs/implementation.md)** - What we built and how it works
- **[Design Decisions](docs/design-decisions.md)** - Architectural choices and rationale
- **[Technical Details](docs/technical-details.md)** - Deep dive into ZLE and internals
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Development Notes](docs/development-notes.md)** - Lessons learned

## Installation

### Manual Installation

1. Clone or download this repository:
```bash
git clone https://github.com/michielvha/zsh-readline.git ~/.zsh-readline
```

2. Add to your `.zshrc`:
```zsh
source ~/.zsh-readline/zsh-readline.plugin.zsh
```

### Using a Plugin Manager

#### Oh My Zsh
```zsh
# Add to ~/.zshrc
plugins=(... zsh-readline)

# Then symlink or clone to ~/.oh-my-zsh/custom/plugins/zsh-readline/
```

#### zi (formerly zinit)
```zsh
# Using zi (recommended - zinit successor)
zi light michielvha/zsh-readline

# Or with configuration
zi light michielvha/zsh-readline
ZSH_READLINE_MAX_PREDICTIONS=15
ZSH_READLINE_MIN_INPUT=2
```

**Note:** `zi` is the successor to `zinit` (which is deprecated). The plugin is compatible with both, but `zi` is recommended.

## Configuration

You can customize the behavior by setting these variables before sourcing the plugin:

```zsh
# Maximum number of predictions to show (default: 10)
ZSH_READLINE_MAX_PREDICTIONS=15

# Minimum input length before showing predictions (default: 1)
ZSH_READLINE_MIN_INPUT=2

# Then source the plugin
source ~/.zsh-readline/zsh-readline.plugin.zsh
```

## Usage

1. Start typing a command - matching history entries appear below your command line
2. Use ↑/↓ arrow keys to navigate the list
3. Press Enter to select a prediction (or just continue typing)
4. The list automatically clears when you submit the command

See [QUICKSTART.md](QUICKSTART.md) for a quick example.

## How It Works

- **History Matching**: Searches your zsh history for commands starting with what you've typed (case-insensitive, prefix match)
- **Display**: Uses `zle -M` (ZLE's message system) to show predictions below the command line
- **Navigation**: Arrow keys navigate the list when predictions are active, otherwise they work normally
- **Selection**: Enter accepts the selected prediction, or submits your command if no predictions are active

## Requirements

- Zsh 5.0 or later
- History enabled in your `.zshrc`:
  ```zsh
  setopt SHARE_HISTORY  # or APPEND_HISTORY
  HISTSIZE=10000
  ```

## Comparison with Other Solutions

### vs. zsh-autocomplete
- **Simpler**: Focused only on history predictions, not full completion system
- **Less disruptive**: Uses `zle -M` instead of modifying the command line
- **More predictable**: Clean, focused behavior

### vs. zsh-autosuggestions
- **ListView style**: Shows multiple options in a list, not just one inline suggestion
- **Interactive**: You can navigate and select from multiple matches

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for detailed troubleshooting guide.

**Quick fixes:**
- **Predictions not showing**: Make sure history is enabled (`setopt SHARE_HISTORY`) and `HISTSIZE` is set
- **Arrow keys not working**: Check key bindings, some terminals use different codes
- **Display issues**: The plugin uses `zle -M` which should work with most terminals

## Limitations

- Performance may degrade with very large histories (>10k entries)