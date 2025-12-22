# zsh-readline Documentation

Complete documentation for the zsh-readline plugin - a ListView-style history prediction system for Zsh.

## Why?

I'm often on Windows (because they force me to) and while I hate PowerShell syntax, I'm absolutely addicted to the PSReadLine Module's ListView functionality. I spent a lot of time trying to get [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete) to behave the way I wanted, but after a while I just got fed up with trying. So I built a plugin that does exactly what I wanted - nothing more, nothing less - and plays nice with the other plugins I use like `zsh-history-substring-search` and `zsh-syntax-highlighting`.

### Compatibility Note: zsh-autosuggestions

**This plugin does not (and should not) play nice with `zsh-autosuggestions`.** Here's why:

- **zsh-autosuggestions** shows a single inline suggestion (like Fish shell) - just one gray suggestion based on history
- **zsh-readline** shows all matching entries in a ListView below the command line - you can see and navigate through multiple options

Since zsh-readline provides a better experience (showing all matches instead of just one), there's no need to use both. Choose one:
- Use **zsh-readline** if you want ListView-style predictions with multiple options
- Use **zsh-autosuggestions** if you prefer a single inline suggestion

They both hook into typing events, so running both would cause conflicts. zsh-readline is essentially a better version for users who want to see all matching entries.

## Documentation Index

- **[Implementation Guide](implementation.md)** - What we built and how it works
- **[Design Decisions](design-decisions.md)** - Key architectural choices and rationale
- **[Technical Details](technical-details.md)** - Deep dive into ZLE, widgets, and internals
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions
- **[Development Notes](development-notes.md)** - Lessons learned during implementation

## Quick Links

- [Installation & Quick Start](../QUICKSTART.md) - Get started in 2 minutes
- [Main README](../README.md) - Project overview

## What This Plugin Does

zsh-readline provides a **ListView-style prediction system** that displays matching history entries below your command line as you type. It's designed to be:

- **Non-intrusive**: Doesn't mess up terminal formatting
- **Lightweight**: Simple, focused implementation
- **Fast**: Real-time updates as you type
- **Compatible**: Works alongside other zsh plugins

## Core Features

**History-based predictions** - Shows matching commands from your history  
**Prefix matching** - Matches entire command prefix (not just first word)  
**Keyboard navigation** - Arrow keys to navigate, Enter to select  
**Real-time updates** - Updates as you type  
**Clean display** - Uses ZLE's message system for reliable rendering  

## Why Not just use PowerShell Core?

While PowerShell's PSReadline provides the functionality I wanted, using PowerShell on Linux has significant drawbacks:

- **Syntax differences**: PowerShell uses different commands (`Get-ChildItem` vs `ls`)
- **Ecosystem incompatibility**: Many Linux tools and scripts expect bash/zsh
- **Plugin limitations**: Can't use native zsh plugins and features
- **Learning curve**: Requires learning PowerShell syntax

And also most importantly just: 'ew, microsoft'

This plugin provides the same ListView experience while keeping you in native zsh with full access to Linux commands and the zsh ecosystem.