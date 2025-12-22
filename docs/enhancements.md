# Potential Enhancements

The following enhancements should be investigated and tried:

- when we select an entry from the list it is put in on the current line in terminal but not executed making it so we have to press enter twice - we should make it auto apply that when we select it from the list (this should be configurable behaviour) - verify how psreadline does this (for consistency)

- Multi-line command handling

- Color highlighting (uses `>` prefix instead for now) - blue highlighted box could be a cooler way of doing this

- some kind of utility that will wipe all duplicate entries from the history file to help with performance, since the plugin is searching on each stroke we want to have the file be as small as feasible.