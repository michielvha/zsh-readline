# Quick Start Guide

## Installation

### Option 1: Quick Install (Recommended)
```bash
cd ~/Documents/zsh-readline
./install.sh
source ~/.zshrc
```

### Option 2: Manual Install
Add this line to your `~/.zshrc`:
```zsh
source ~/Documents/zsh-readline/zsh-readline.plugin.zsh
```

Then reload:
```bash
source ~/.zshrc
```

## Basic Usage

1. **Start typing** any command
2. **See predictions** appear below your command line showing matching history entries
3. **Navigate** with ↑/↓ arrow keys
4. **Select** with Enter, or just keep typing

## Example

Type `make` and you'll see:
```
  make setup
> make up
  make fresh
```

Use arrow keys to select, Enter to accept.

## Configuration (Optional)

Add before the `source` line in `.zshrc`:
```zsh
# Show up to 15 predictions
ZSH_READLINE_MAX_PREDICTIONS=15

# Only show predictions after typing 2 characters
ZSH_READLINE_MIN_INPUT=2

```

## Troubleshooting

**No predictions showing?**
- Make sure you have history enabled: `setopt SHARE_HISTORY`
- Check your `HISTSIZE` is reasonable (try `HISTSIZE=10000`)

**Arrow keys not working?**
- Try: `bindkey '^[A' _zsh_readline_up` and `bindkey '^[B' _zsh_readline_down`

**Display looks weird?**
- The plugin uses `zle -M` which should work with most terminals
- If you have issues, try a different terminal emulator

## How It's Different from zsh-autocomplete

- **Simpler**: Only does history predictions, not full completion
- **Less disruptive**: Uses zle's message system instead of modifying the command line
- **Focused**: Designed specifically for ListView-style predictions
- **No jumping**: Predictions appear below without moving your prompt

## Next Steps

- Read [docs/](docs/) for complete documentation
- See [README.md](README.md) for overview
- Check [docs/troubleshooting.md](docs/troubleshooting.md) if you have issues

