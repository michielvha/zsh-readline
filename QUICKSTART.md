# Quick Start Guide

Get up and running with zsh-readline in 2 minutes.

## Installation

### Option 1: Quick Install Script
```bash
cd ~/Documents/zsh-readline
./install.sh
source ~/.zshrc
```

### Option 2: Manual Install
Add to your `~/.zshrc`:
```zsh
source ~/Documents/zsh-readline/zsh-readline.plugin.zsh
```

### Option 3: Using zi (Plugin Manager)
```zsh
zi light michielvha/zsh-readline
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

## Quick Configuration (Optional)

Add before the `source` line in `.zshrc`:
```zsh
ZSH_READLINE_MAX_PREDICTIONS=15
ZSH_READLINE_MIN_INPUT=2
source ~/Documents/zsh-readline/zsh-readline.plugin.zsh
```

## Requirements

Make sure history is enabled in your `.zshrc`:
```zsh
setopt SHARE_HISTORY  # or APPEND_HISTORY
HISTSIZE=10000
```

## Next Steps

- See [README.md](README.md) for complete documentation
- Check [docs/troubleshooting.md](docs/troubleshooting.md) if you have issues
- Read [docs/](docs/) for technical details
