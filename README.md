# ProjectManagerExtension

This extension will use the same file that controls the Project Manager extension for VS Code and expose those projects to the Power Toys Command Palette tool.

Instructions for creating a Command Palette extension can be found at (Extensibilit Overview)[https://learn.microsoft.com/en-us/windows/powertoys/command-palette/extensibility-overview]

The file can be found at [project.json](../../AppData/Roaming/Code/User/globalStorage/alefragnani.project-manager/projects.json).  There is a sample of this files in the `Samples/projects.json` file in this repo.

This extension should also support segment based searching that will assist in searching project names with `-` in them.

For instance, given the project name `platform-core-testy-mctest`, the following search terms should all match:
- p-c-t-m
- t-m
- test-m
- p-c-mctest
- mcte

In particular, the segments of the search don't have to match all of the segments in the match

There should be a file watcher on the project.json file so information is reloaded if the files is changed.